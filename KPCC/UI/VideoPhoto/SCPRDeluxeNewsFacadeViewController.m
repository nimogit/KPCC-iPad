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
  
  //self.headlineLabel.backgroundColor = [UIColor redColor];
  //self.blurbLabel.backgroundColor = [UIColor blueColor];
  
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
  
  CGFloat textPadding = [Utilities isLandscape] ? 12.0 : 8.0;
  
  if ( !self.verticalOrSquareAsset ) {
    [[DesignManager shared] avoidNeighbor:self.categorySeatView
                                 withView:self.headlineLabel
                                direction:NeighborDirectionAbove
                                  padding:textPadding];
  } else {
    [[DesignManager shared] avoidNeighbor:self.timestampLabel
                                 withView:self.headlineLabel
                                direction:NeighborDirectionAbove
                                  padding:textPadding];
  }
  
  if ( !snapForNoAsset && !self.verticalOrSquareAsset ) {
    
    NSString *cleanTeaser = [Utilities unwebbifyString:[pvArticle objectForKey:@"teaser"]];
    [self.blurbLabel italicizeText:cleanTeaser
                            bold:NO
                   respectHeight:YES];
    
    CGFloat adjustedSpace = self.view.frame.size.height - (self.headlineLabel.frame.origin.y+self.headlineLabel.frame.size.height) - 4.0;
    
    CGSize blurbSize = [self.blurbLabel.text sizeOfStringWithFont:self.blurbLabel.font
                                                constrainedToSize:CGSizeMake(self.blurbLabel.frame.size.width,
                                                                             adjustedSpace)];
    
    CGFloat totalHeight = self.splashImage.frame.origin.y+self.splashImage.frame.size.height+self.categorySeatView.frame.size.height+2.0+self.headlineLabel.frame.size.height+2.0+blurbSize.height;
    
    CGFloat snappedHeight = totalHeight+3.0 >= self.cardView.frame.size.height ? ceilf(blurbSize.height)-self.blurbLabel.font.pointSize : ceilf(blurbSize.height);
    
    //NSLog(@"Height compare: %1.1f calculates vs. %1.1f static",totalHeight+3.0,self.cardView.frame.size.height);
    self.blurbLabel.frame = CGRectMake(self.blurbLabel.frame.origin.x,
                                       self.blurbLabel.frame.origin.y,
                                       self.blurbLabel.frame.size.width,
                                       snappedHeight);
    
    if ( [Utilities isLandscape] ) {
      [[DesignManager shared] avoidNeighbor:self.categorySeatView
                                   withView:self.headlineLabel
                                  direction:NeighborDirectionAbove
                                    padding:10.0];
      
      [[DesignManager shared] avoidNeighbor:self.headlineLabel
                                   withView:self.blurbLabel
                                  direction:NeighborDirectionAbove
                                    padding:10.0];
    }
    
  } else {
    
    NSString *filtered = [Utilities unwebbifyString:[pvArticle objectForKey:@"body"]
                                  respectLinebreaks:YES];
    
    NSInteger limit = 500;
    
    BOOL special = NO;
    if ( self.verticalOrSquareAsset && self.embiggened && [Utilities isLandscape] ) {
      special = YES;
      limit = 400;
    }
    
    /*[self.blurbLabel decentCharLimitForMe]*/;
    
    if ( [filtered length] > limit ) {
      
      NSInteger end = limit;
      while ( end > limit - (int)ceilf(limit/2) ) {
        if ( [filtered characterAtIndex:end] == ' ' ) {
          break;
        }
        end--;
      }
      
      filtered = [filtered substringToIndex:end];
      filtered = [filtered stringByAppendingString:@" •••"];

      
    }
    
    if ( !special ) {
      /*[self.blurbLabel titleizeText:filtered
                               bold:NO
                      respectHeight:YES];*/
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
  
  CGSize sizeGuess = [self.blurbLabel.text sizeOfStringWithFont:self.blurbLabel.font
                                                   constrainedToSize:CGSizeMake(self.blurbLabel.frame.size.width,
                                                                                MAXFLOAT)];
  BOOL isTruncating = abs(sizeGuess.height-self.blurbLabel.frame.size.height) > 1.0;
  
  CGFloat padding = [Utilities isIOS7] ? 8.0 : 3.0;
  if ( self.embiggened ) {
    padding = [Utilities isIOS7] ? 4.0 : 4.0;
  }
  
  if ( isTruncating ) {
    NSInteger nlines = [self.blurbLabel approximateNumberOfLines];
    //NSLog(@"Approximate number of lines for truncated text %@ : %d",self.blurbLabel.text,nlines);
    if ( nlines <= 1 ) {
      padding = [Utilities isIOS7] ? 0.0 : 0.0;
    }
    
    if ( self.verticalOrSquareAsset ) {
      self.blurbLabel.frame = CGRectMake(self.blurbLabel.frame.origin.x,
                                         self.blurbLabel.frame.origin.y,
                                         self.blurbLabel.frame.size.width,
                                         self.blurbLabel.frame.size.height-self.blurbLabel.font.pointSize-4.0);
      
      if ( [self.headlineLabel approximateNumberOfLines] > 1 ) {
        padding = -2.0;
      }
    }
  }
  
  [[DesignManager shared] avoidNeighbor:self.headlineLabel
                               withView:self.blurbLabel
                              direction:NeighborDirectionAbove
                                padding:padding];
  
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
    [[DesignManager shared] avoidNeighbor:self.categorySeatView
                                 withView:self.headlineLabel
                                direction:NeighborDirectionAbove
                                  padding:4.0];
    [[DesignManager shared] avoidNeighbor:self.headlineLabel
                                 withView:self.grayLineDivider
                                direction:NeighborDirectionAbove
                                  padding:4.0];
    [[DesignManager shared] avoidNeighbor:self.grayLineDivider
                                 withView:self.blurbLabel
                                direction:NeighborDirectionAbove
                                  padding:5.0];
  }
  
  // Resize the timestamp label to fit its content, allowing the social count view to have proper padding constraints.
  CGRect beforeFrame = self.timestampLabel.frame;
  [self.timestampLabel sizeToFit];
  CGRect afterFrame = self.timestampLabel.frame;
  self.timestampLabel.frame = CGRectMake(beforeFrame.origin.x + beforeFrame.size.width - afterFrame.size.width,
                                         self.timestampLabel.frame.origin.y,
                                         self.timestampLabel.frame.size.width,
                                         beforeFrame.size.height);

  // Set and position labels for social count data.
  if ([pvArticle objectForKey:@"social_data"]) {
    [self.socialCountView setHidden:NO];
    
    [[DesignManager shared] avoidNeighbor:self.categorySeatView
                                   withView:self.socialCountView
                                  direction:NeighborDirectionToLeft
                                    padding:2.0];

    [self.facebookCountLabel setFont:([[DesignManager shared] latoRegular: 13.0])];
    [self.facebookCountLabel setText:[Utilities prettyStringFromSocialCount:[[[pvArticle objectForKey:@"social_data"] objectForKey:@"facebook_count"] integerValue]]];

    // Resize Facebook count frame to fit.
    CGRect origFacebookFrame = self.facebookCountLabel.frame;
    [self.facebookCountLabel sizeToFit];
    self.facebookCountLabel.frame = CGRectMake(self.facebookCountLabel.frame.origin.x,
                                               origFacebookFrame.origin.y,
                                               self.facebookCountLabel.frame.size.width,
                                               origFacebookFrame.size.height);
    
    // Space the vertical line divider 6px to right of Facebook count label.
    [[DesignManager shared] avoidNeighbor:self.facebookCountLabel
                                 withView:self.socialLineDivider
                                direction:NeighborDirectionToLeft
                                  padding:6.0];

    // Space the twitter Logo 6px to right of vertical line divider.
    self.twitterLogoImage.frame = CGRectMake(self.socialLineDivider.frame.origin.x + 6,
                                             self.twitterLogoImage.frame.origin.y,
                                             self.twitterLogoImage.frame.size.width,
                                             self.twitterLogoImage.frame.size.height);

    [self.twitterCountLabel setFont:([[DesignManager shared] latoRegular: 13.0])];
    [self.twitterCountLabel setText:[Utilities prettyStringFromSocialCount:[[[pvArticle objectForKey:@"social_data"] objectForKey:@"twitter_count"] integerValue]]];
    self.twitterCountLabel.frame = CGRectMake(self.twitterLogoImage.frame.origin.x + 20,
                                              self.twitterCountLabel.frame.origin.y,
                                              self.twitterCountLabel.frame.size.width,
                                              self.twitterCountLabel.frame.size.height);
    
    // Resize Twitter count frame to fit its contents.
    CGRect origTwitterFrame = self.twitterCountLabel.frame;
    [self.twitterCountLabel sizeToFit];
    self.twitterCountLabel.frame = CGRectMake(self.twitterCountLabel.frame.origin.x,
                                              origTwitterFrame.origin.y,
                                              self.twitterCountLabel.frame.size.width,
                                              origTwitterFrame.size.height);
    
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
    
    CGSize width = CGSizeZero;
    
    
    width = [self.slideshowLabel.text sizeOfStringWithFont:self.slideshowLabel.font
                                         constrainedToSize:CGSizeMake(MAXFLOAT,self.slideshowLabel.frame.size.height)];
    
    
    CGFloat finalWidth = [Utilities isIOS7] ? ceilf(width.width) : width.width;
    
    self.slideshowLabel.frame = CGRectMake(self.slideshowLabel.frame.origin.x,
                                           self.slideshowLabel.frame.origin.y,
                                           finalWidth+2.0,
                                           self.slideshowLabel.frame.size.height);
    
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
    
    CGSize width = CGSizeZero;
    
    
    width = [self.slideshowLabel.text sizeOfStringWithFont:self.slideshowLabel.font
                                         constrainedToSize:CGSizeMake(MAXFLOAT,self.slideshowLabel.frame.size.height)];
    
    
    CGFloat finalWidth = [Utilities isIOS7] ? ceilf(width.width) : width.width;
    
    self.slideshowLabel.frame = CGRectMake(self.slideshowLabel.frame.origin.x,
                                           self.slideshowLabel.frame.origin.y,
                                           finalWidth+2.0,
                                           self.slideshowLabel.frame.size.height);
    
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
    NSString *slideshow = [NSString stringWithFormat:@"%d %@",[assets count],noun];
    [self.categoryLabel titleizeText:slideshow
                                bold:NO];
    
    CGSize width = CGSizeZero;
    
    width = [self.slideshowLabel.text sizeOfStringWithFont:self.slideshowLabel.font
                                         constrainedToSize:CGSizeMake(MAXFLOAT,self.slideshowLabel.frame.size.height)];
    
    CGFloat finalWidth = [Utilities isIOS7] ? ceilf(width.width) : width.width;
    
    self.categoryLabel.frame = CGRectMake(self.categoryLabel.frame.origin.x,
                                          self.categoryLabel.frame.origin.y,
                                          finalWidth,
                                          self.categoryLabel.frame.size.height);
    
    [self.slideshowLabel titleizeText:self.slideshowLabel.text
                                 bold:YES];
    
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
    
    self.categoryLabel.alpha = 0.0;
    
    
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
