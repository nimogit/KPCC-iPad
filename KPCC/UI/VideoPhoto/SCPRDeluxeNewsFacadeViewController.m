//
//  SCPRDeluxeNewsFacadeViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRDeluxeNewsFacadeViewController.h"
#import "SCPRDeluxeNewsViewController.h"
#import "global.h"

#define kTruncatedBodyThreshold 500

@interface SCPRDeluxeNewsFacadeViewController ()

@end

@implementation SCPRDeluxeNewsFacadeViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

  [self arm];
  
}

- (void)arm {
  self.originalBlurbFrame = self.blurbLabel.frame;
  self.originalHeadlineFrame = self.headlineLabel.frame;
  
  self.timestampLabel.textColor = [[DesignManager shared] silverTextColor];
  self.categorySeatView.backgroundColor = [[DesignManager shared] periwinkleColor];
  self.bluePaddingView.backgroundColor = [[DesignManager shared] periwinkleColor];
  //self.cardView.layer.cornerRadius = 4.0;
  self.cardView.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
  self.cardView.layer.borderWidth = 1.0;
  self.cardView.backgroundColor = [UIColor whiteColor];
  self.headlineLabel.textColor = [[DesignManager shared] consistentCharcolColor];
  self.blurbLabel.textColor = [[DesignManager shared] number3pencilColor];
  //self.view.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  self.splashImage.contentMode = UIViewContentModeScaleAspectFill;
  self.splashImage.clipsToBounds = YES;
  self.tapperButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0,0.0,self.view.frame.size.width,
                                                                 self.view.frame.size.height)];
  [self.view addSubview:self.tapperButton];
    [self.tapperButton addTarget:self
                        action:@selector(buttonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
  self.view.userInteractionEnabled = YES;
  
  self.view.backgroundColor = [UIColor whiteColor];
}

- (void)buttonTapped:(id)sender {
 /* if ( [self.category rangeOfString:@"VIDEO"].location == 0 ) {
    
    SCPRAppDelegate *del = [Utilities del];
    self.floatingVideoController = [[SCPRFloatingEmbedViewController alloc]
                                    initWithNibName:[[DesignManager shared]
                                                     xibForPlatformWithName:@"SCPRFloatingEmbedViewController"]
                                    bundle:nil];
    
    
    
    [del cloakUIWithCustomView:self.floatingVideoController
                   dismissible:YES];
    [self.floatingVideoController setupWithPVArticle:self.pvArticle];
    
  } else {*/
  
  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

  CGFloat leftPadding = [Utilities isLandscape] ? 6.0 : 4.0;
  self.spinner.alpha = 0.0;
  [self.spinner setColor:[[DesignManager shared] darkoalColor]];
  
  [self.cardView addSubview:self.spinner];
  
  CGFloat factor = [Utilities isLandscape] ? 0.7 : 0.65;
  self.spinner.transform = CGAffineTransformMakeScale(factor, factor);
  
  self.spinner.autoresizingMask = UIViewAutoresizingNone;
  
  [[DesignManager shared] alignVerticalCenterOf:self.spinner
                                       withView:self.categorySeatView];
  
  if (self.socialCountView.isHidden) {
    [[DesignManager shared] avoidNeighbor:self.categorySeatView
                                 withView:self.spinner
                                direction:NeighborDirectionToLeft
                                  padding:leftPadding];
  } else {
    if (self.twitterCountLabel.isHidden) {
      [[DesignManager shared] avoidNeighbor:self.timestampLabel
                                   withView:self.spinner
                                  direction:NeighborDirectionToRight
                                    padding:leftPadding];
    } else {
      [[DesignManager shared] avoidNeighbor:self.socialCountView
                                   withView:self.spinner
                                  direction:NeighborDirectionToLeft
                                    padding:leftPadding];
    }
  }
  
  
  CGFloat nudgeAmount = [Utilities isLandscape] ? 3.0 : 3.0;
  [[DesignManager shared] nudge:self.spinner
                      direction:NeighborDirectionBelow
                         amount:nudgeAmount];
  
  
  [UIView animateWithDuration:.15 animations:^{
    self.spinner.alpha = 1.0;
    [self.spinner startAnimating];
  } completion:^(BOOL finished) {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideSpinner)
                                                 name:@"single_article_finished_loading"
                                               object:nil];
    
    SCPRDeluxeNewsViewController *vpc = (SCPRDeluxeNewsViewController*)self.parentPVController;
    [vpc handleDrillDown:self.pvArticle];
    
  }];

    
  //}
}

- (void)hideSpinner {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"single_article_finished_loading"
                                                object:nil];
  
  [self.spinner removeFromSuperview];
  self.spinner = nil;
}

- (void)mergeWithPVArticle:(NSDictionary *)pvArticle {
  
  BOOL special = NO;
  self.pvArticle = pvArticle;
  self.blurbLabel.textColor = [[DesignManager shared] darkoalColor];
  BOOL snapForNoAsset = NO;
  if ( [Utilities pureNil:[pvArticle objectForKey:@"assets"]] && !self.embiggened ) {
    snapForNoAsset = YES;
  } else {
    
    NSString *aspect = [[DesignManager shared] aspectCodeForContentItem:pvArticle
                                                                quality:AssetQualityFull];
    
    if ( [aspect rangeOfString:@"23"].location != NSNotFound ||
        [aspect rangeOfString:@"34"].location != NSNotFound ||
        [aspect rangeOfString:@"Sq"].location != NSNotFound ) {
      self.verticalOrSquareAsset = YES;
      if ( !self.embiggened ) {
        self.verticalOrSquareAsset = NO;
      }
    }
    
  }
  
  if ( [pvArticle objectForKey:@"short_title"] ) {
#ifdef FAKE_LONG_TITLE
    [self.headlineLabel sansifyTitleText:@"Pitchfork vegan aesthetic, incididunt assumenda commodo in wayfarers sint. Voluptate try-hard odio, incididunt pork belly irony craft beer Echo Park polaroid single-origin coffee ea nesciunt. Eu aliquip nostrud, ethnic viral dolor proident organic odio narwhal McSweeney's +1 wolf. Et chambray Intelligentsia church-key aliqua 8-bit."
                                    bold:YES
                           respectHeight:YES];
#else
    [self.headlineLabel sansifyTitleText:[pvArticle objectForKey:@"short_title"]
                                    bold:!snapForNoAsset

     
     respectHeight:YES];
#endif
  } else {
      [self.headlineLabel sansifyTitleText:[pvArticle objectForKey:@"title"]
                                       bold:!snapForNoAsset
                             respectHeight:YES];
  }
  
  [self.tapperButton setAccessibilityLabel:self.headlineLabel.text];
  
  
  if ( !snapForNoAsset && !self.verticalOrSquareAsset ) {
    
    NSString *cleanTeaser = [Utilities unwebbifyString:[pvArticle objectForKey:@"teaser"]];
    [self.blurbLabel italicizeText:cleanTeaser
                            bold:NO
                   respectHeight:YES];


    
  } else {
    
    NSString *filtered = [Utilities unwebbifyString:[pvArticle objectForKey:@"body"]
                                  respectLinebreaks:YES];
    

    
    if ( !special ) {

      if ( snapForNoAsset ) {
        
        [self.blurbLabel standardizeText:filtered
                                  bold:NO
                         respectHeight:NO
                              withFont:@"PTSerif-Regular"
                       verticalFanning:4.0];
      } else {
        
        [self.blurbLabel italicizeText:filtered
                                  bold:NO
                         respectHeight:YES];
        
      }
    } else {
      [self.blurbLabel standardizeText:filtered
                                  bold:NO
                         respectHeight:NO
                              withFont:@"Lato-Light"
                       verticalFanning:4.0];
    }
    
    [self.view bringSubviewToFront:self.tapperButton];
    
  }
  
  NSString *dateString = [pvArticle objectForKey:@"published_at"];
  NSString *formatted = [Utilities prettyStringFromRFCDateString:dateString];
  NSDate *dStr = [Utilities dateFromRFCString:dateString];
  if ( [dStr isToday] ) {
    formatted = [dStr prettyCompare:[NSDate date]];
  } else if ( [dStr isYesterday] ) {
    formatted = @"YESTERDAY";
  } else {
    formatted = [NSDate stringFromDate:dStr
                            withFormat:@"EEE MMM d, h:mm a"];
  }
  
  if ( self.contentType == ScreenContentTypeEventsPage ) {
    NSDictionary *location = [pvArticle objectForKey:@"location"];
    if ( ![Utilities pureNil:location] ) {
      NSString *title = [location objectForKey:@"title"];
      [self.timestampLabel titleizeText:[title uppercaseString]
                                   bold:NO];
    }
  } else {
    [self.timestampLabel titleizeText:[formatted uppercaseString]
                               bold:NO];
  }
  
  SCPRDeluxeNewsViewController *vpc = (SCPRDeluxeNewsViewController*)self.parentPVController;
  if ( vpc && vpc.contentType == ScreenContentTypeVideoPhotoPage ) {
    [self handleCategoryForPhotoVideo];
  } else {
    [self handleCategoryForComposite];
  }
  
  [self snapCategorySeat];
  
  NSString *bigASSet = @"";
  
  if ( ![Utilities isRetina] ) {
    if ( !self.embiggened ) {
      bigASSet = [Utilities extractImageURLFromBlob:pvArticle
                                            quality:AssetQualitySmall
                                       forceQuality:YES];
    } else {
      bigASSet = [Utilities extractImageURLFromBlob:pvArticle
                                            quality:AssetQualityLarge];
    }
  } else {
    if ( !self.embiggened ) {
      bigASSet = [Utilities extractImageURLFromBlob:pvArticle
                                            quality:AssetQualityLarge];
    } else {
      bigASSet = [Utilities extractImageURLFromBlob:pvArticle
                                 quality:AssetQualityFull
                            forceQuality:NO];
    }
  }
  
  if ( ![self.imgUrl isEqualToString:bigASSet] ) {
    [self.splashImage loadImage:bigASSet];
    self.imgUrl = bigASSet;
  }
  
  if ( snapForNoAsset && !self.verticalOrSquareAsset ) {
    self.noAsset = YES;
  }
  



  // Set and position labels for social count data.
  if ([pvArticle objectForKey:@"social_data"]) {
    [self.socialCountView setHidden:NO];
    

    [self.facebookCountLabel setFont:([[DesignManager shared] latoRegular: 13.0])];
    [self.facebookCountLabel setText:[Utilities prettyStringFromSocialCount:[[[pvArticle objectForKey:@"social_data"] objectForKey:@"facebook_count"] integerValue]]];


    
    // Space the twitter Logo 6px to right of vertical line divider.

    [self.twitterCountLabel setFont:([[DesignManager shared] latoRegular: 13.0])];
    [self.twitterCountLabel setText:[Utilities prettyStringFromSocialCount:[[[pvArticle objectForKey:@"social_data"] objectForKey:@"twitter_count"] integerValue]]];

    
    // Resize Twitter count frame to fit its contents.

    
    // Hide the Twitter share count if it conflicts with the timestamp label.
    if (self.socialCountView.frame.origin.x + self.socialCountView.frame.size.width >= self.timestampLabel.frame.origin.x) {
      [self.socialLineDivider setHidden:YES];
      [self.twitterLogoImage setHidden:YES];
      [self.twitterCountLabel setHidden:YES];
    } else {
      [self.socialLineDivider setHidden:NO];
      [self.twitterLogoImage setHidden:NO];
      [self.twitterCountLabel setHidden:NO];
    }
  } else {
      [self.socialCountView setHidden:YES];
      [self.facebookCountLabel setText:[NSString stringWithFormat:@""]];
      [self.twitterCountLabel setText:[NSString stringWithFormat:@""]];
  }
  
  [self.view setNeedsUpdateConstraints];
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];
  [self.view updateConstraintsIfNeeded];
}

- (void)handleCategoryForComposite {
  if ( self.contentType == ScreenContentTypeCompositePage ) {
    
    NSString *title = @"MISCELLANEOUS";

    NSDictionary *category = [self.pvArticle objectForKey:@"category"];
    if ( ![Utilities pureNil:category] ) {
      title = [(NSString*)[category objectForKey:@"title"] uppercaseString];

      // If we have a really long category title (ie. "Immigration and Emerging Communities"),
      // use the shorter "slug" name and uppercase it.
      if (title.length > 25) {
        title = [(NSString*)[category objectForKey:@"slug"] uppercaseString];
      }
    }
    
    [self.slideshowLabel titleizeText:title
                                 bold:YES];
    
    self.categoryLabel.alpha = 0.0;
    self.playOverlayImage.alpha = [[ContentManager shared] storyHasVideoAsset:self.pvArticle] ? 1.0 : 0.0;
  }
  if ( self.contentType == ScreenContentTypeEventsPage ) {
    
    if ( self.embiggened ) {
      
      self.categorySeatView.backgroundColor = [[DesignManager shared] auburnColor];
      self.bluePaddingView.backgroundColor = [[DesignManager shared] auburnColor];
      if ( [[ContentManager shared] storyHasYouTubeAsset:self.pvArticle] ) {
        self.playOverlayImage.alpha = 1.0;
        [self.slideshowLabel titleizeText:@"LIVE VIDEO"
                                     bold:YES];
        self.categoryLabel.alpha = 0.0;
      }
      
    } else {
      
      NSString *dateString = [self.pvArticle objectForKey:@"starts_at"];
      NSString *formatted = [Utilities prettyStringFromRFCDateString:dateString];
      [self.slideshowLabel titleizeText:[formatted uppercaseString]
                                   bold:YES];
      self.categoryLabel.alpha = 0.0;
      
      CGFloat alpha = 0.0;
      alpha = [[ScheduleManager shared] eventIsLive:self.pvArticle] ? 1.0 : 0.0;
      self.playOverlayImage.alpha = alpha;
      
    }
    
  }
  
}

- (void)handleCategoryForPhotoVideo {
  
  NSDictionary *category = [self.pvArticle objectForKey:@"category"];
  NSString *title = @"MISCELLANEOUS";
  if ( ![Utilities pureNil:category] ) {
    title = [(NSString*)[category objectForKey:@"title"] uppercaseString];
  }
  
  self.category = title;
  
  if ( [title rangeOfString:@"IMAGES"].location == 0 ) {
    NSArray *assets = [self.pvArticle objectForKey:@"assets"];
    
    NSString *noun = [assets count] == 1 ? @"PHOTO" : @"PHOTOS";
    NSString *slideshow = [NSString stringWithFormat:@"SLIDESHOW: %d %@",[assets count],noun];
    
    NSMutableAttributedString *ms = [[NSMutableAttributedString alloc] initWithString:slideshow
                                                                           attributes:@{}];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    attributes[NSFontAttributeName] = [UIFont fontWithName:@"Lato-Bold"
                                                      size:self.slideshowLabel.font.pointSize];
    
    NSInteger len = [@"SLIDESHOW:" length];
    [ms setAttributes:attributes
                range:NSMakeRange(0, len)];
    
    NSMutableDictionary *regular = [NSMutableDictionary new];
    attributes[NSFontAttributeName] = [UIFont fontWithName:@"Lato-Regular"
                                                      size:self.slideshowLabel.font.pointSize];
    
    [ms setAttributes:regular
                range:NSMakeRange(len, [ms.string length]-len)];
    
    self.slideshowLabel.attributedText = ms;
    
  } else {
    
    [self.slideshowLabel titleizeText:title
                                 bold:YES];
    
    CGSize width = CGSizeZero;
    
    
    width = [self.slideshowLabel.text sizeOfStringWithFont:self.slideshowLabel.font
                                         constrainedToSize:CGSizeMake(MAXFLOAT,self.slideshowLabel.frame.size.height)];
    
    
    CGFloat finalWidth = [Utilities isIOS7] ? ceilf(width.width) : width.width;
    
    self.slideshowLabel.frame = CGRectMake(self.slideshowLabel.frame.origin.x,
                                           self.slideshowLabel.frame.origin.y,
                                           finalWidth,
                                           self.slideshowLabel.frame.size.height);
    
    
    
  }
  
  self.playOverlayImage.alpha = [[ContentManager shared] storyHasVideoAsset:self.pvArticle] ? 1.0 : 0.0;
}

- (void)snapCategorySeat {
  
  CGFloat seatWidth = 0.0;
  CGFloat leftMargin = self.slideshowLabel.frame.origin.x;
  seatWidth += leftMargin;
  seatWidth += self.slideshowLabel.frame.size.width;
  
  if ( self.categoryLabel.alpha == 0.0 ) {
    seatWidth += leftMargin;
  } else {
    seatWidth = leftMargin + self.categoryLabel.frame.origin.x+self.categoryLabel.frame.size.width + leftMargin;
  }
  
  if ( [Utilities isIOS7] ) {
    seatWidth = ceilf(seatWidth);
  }
  
  self.categorySeatView.frame = CGRectMake(self.categorySeatView.frame.origin.x,
                                           self.categorySeatView.frame.origin.y,
                                           seatWidth,
                                           self.categorySeatView.frame.size.height);
  
  if ( self.contentType == ScreenContentTypeEventsPage ) {
    CGFloat padding = ([Utilities isLandscape] || self.embiggened) ? 8.0 : 6.0;
    
    self.timestampLabel.frame = CGRectMake(self.categorySeatView.frame.origin.x+self.categorySeatView.frame.size.width,
                                           self.timestampLabel.frame.origin.y,
                                           self.cardView.frame.size.width-self.categorySeatView.frame.size.width-(2*padding),
                                           self.timestampLabel.frame.size.height);
  }
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
