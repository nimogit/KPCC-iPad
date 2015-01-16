//
//  SCPRSingleArticleViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 4/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSingleArticleViewController.h"
#import "SCPRHBTView.h"
#import "SCPRNewsPageViewController.h"
#import "SCPRNewsPageContainerController.h"
#import "SBJson.h"
#import "UIImageView+Analysis.h"
#import "SCPRSingleArticleCollectionViewController.h"
#import "SCPRExternalWebContentViewController.h"
#import "SCPREditionAtomViewController.h"
#import "SCPREditionMoleculeViewController.h"

@interface SCPRSingleArticleViewController() <UIPopoverControllerDelegate>

@end

@implementation SCPRSingleArticleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
      // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self stretch];
  
  [self.activity startAnimating];

  self.view.backgroundColor = [UIColor whiteColor];
  self.masterContentScroller.backgroundColor = [UIColor whiteColor];

  self.webContentLoader.webView.alpha = 0.0;
  self.textSheetView.alpha = 0.0;
  self.cloakView.alpha = 1.0;
  self.queueButton.alpha = 0.0;
  self.basicTemplate.headLine.textColor = [UIColor blackColor];
  self.basicTemplate.byLine.textColor = [UIColor blackColor];
  self.basicTemplate.aspectCode = @"SingleArticle";
  self.basicTemplate.backgroundColor = [UIColor whiteColor];
  self.textSheetView.backgroundColor = [UIColor whiteColor];
  
  
  self.basicTemplate.templateStyle = NewsPageTemplateSingleArticle;
  self.socialSheetView.alpha = 0.0;
  self.categorySeat.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  
  if (!self.relatedArticle) {
    [[NetworkManager shared] fetchContentForSingleArticle:self.relatedURL display:self];
  }

  self.shareDrawer = [[Utilities del] viewController].globalShareDrawer;
  

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(adjustUIForQueue:)
                                               name:@"notify_listeners_of_queue_change"
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [[[Utilities del] globalTitleBar] applyKpccLogo];
}

- (void)viewWillAppear:(BOOL)animated {
  if (self.fromSnapshot) {
    SCPRViewController *svc = [[Utilities del] viewController];
    
    CGFloat offset = [Utilities isIOS7] ? -40.0 : -60.0;
    [UIView animateWithDuration:0.22 animations:^{
      [svc.mainPageScroller setContentOffset:CGPointMake(0.0, offset)];
    }];
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  if (object == self.masterContentScroller) {
    
    self.cloakView.alpha = self.masterContentScroller.contentOffset.y / self.basicTemplate.image1.frame.size.height;
    
    if (self.captionUp) {
      [self fadeCaption];
    }
    
    if (self.webContentLoader.containsTwitterEntries) {
      
      CGPoint initial = [[change objectForKey:@"initial"] CGPointValue];
      CGPoint new = [[change objectForKey:@"new"] CGPointValue];
      
      if (!self.twitterSynthesized) {
        if (abs(new.y - initial.y) > 10.0) {
          
          self.twitterSynthesized = YES;
          if (self.webContentLoader.twitterEmbeds) {
            while ([self.webContentLoader.twitterEmbeds count] > 0) {
              NSString *tid = [self.webContentLoader.twitterEmbeds objectAtIndex:0];
              [self.webContentLoader.twitterEmbeds removeObjectAtIndex:0];
              [[SocialManager shared] synthesizeTwitterTweet:tid
                                                   container:self.webContentLoader];
            }
          }
        }
      }
    }
    
  }
}

# pragma mark - ButtonTapped
- (IBAction)buttonTapped:(id)sender {

  // Queue Button
  if (sender == self.queueButton) {
    if (![[QueueManager shared] articleIsInQueue:self.relatedArticle]) {
      [[QueueManager shared] addToQueue:self.relatedArticle asset:nil];
      [self adjustUIForQueue:nil];
    } else {
      if ([[QueueManager shared] articleIsPlayingNow:self.relatedArticle]) {
        [[QueueManager shared] pop];
      } else {
        [[QueueManager shared] removeFromQueue:self.relatedArticle];
        [self adjustUIForQueue:nil];
      }
    }
  }

  // PlayAudio Button
  if (sender == self.playAudioButton) {
    if (![[QueueManager shared] articleIsInQueue:self.relatedArticle]) {
      [[QueueManager shared] addToQueue:self.relatedArticle
                                  asset:nil];
    }
    [[QueueManager shared] playSpecificArticle:self.relatedArticle];
    [self adjustUIForQueue:nil];
  }

  // RVSP Button
  if (sender == self.rsvpButton) {
    if ([self.relatedArticle objectForKey:@"rsvp_url"]) {
      NSString *rsvp = [self.relatedArticle objectForKey:@"rsvp_url"];
      NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:rsvp]];
      [self externalWebContentRequest:request];
    }
    [[AnalyticsManager shared] logEvent:@"user_rsvp_for_event" withParameters:@{}];
  }

  // Social Share Button
  if (sender == self.socialShareButton) {
    [self toggleShareModal];
  }

}

- (void)setRelatedArticle:(NSDictionary *)relatedArticle {
  _relatedArticle = relatedArticle;
  
  if ( [relatedArticle objectForKey:@"permalink"] ) {
    self.relatedURL = [relatedArticle objectForKey:@"permalink"];
  }
}

- (void)handleDelayedLoad {
  if (!self.initialLoadFinished) {
    if (self.webContentLoader.queuedContentString) {
      [self.webContentLoader setupWithArticle:self.relatedArticle
                                     delegate:self];
    }
  }
}


#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  self.relatedArticle = [content objectAtIndex:0];
  [self arrangeContent];
}

- (void)contentFinishedDisplaying {
  self.externalContent = nil;
}

- (void)arrangeContent {

  if (self.contentArranged) {
    return;
  }
  
  self.landscapeImageSheetView.clipsToBounds = YES;
  
  SCPRSingleArticleCollectionViewController *pc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
  if (pc.category == ContentCategoryEvents) {
    self.liveEvent = [[ScheduleManager shared] eventIsLive:self.relatedArticle];
  }
  
  if (pc.category == ContentCategoryNews || [self fromSnapshot]) {
    [self queryParse];  
  }

  
#ifdef DEBUG
  // -- Developer Note --
  // This is a way to override the contents of the article so you can look at specific use-cases of story content which is helpful for debugging.
  // Simply load an article as json through the API (http://scpr.org/api/v2/articles/by_url?url=http://scpr.org.etc.etc.) via your
  // web browser and then copy the contents into complicated3.json in order to view.
  //
  // WARNING: doing this will cause a crash once you try to scroll away from the article. Not sure why but it was crashing the last time
  // I was testing this override capability so once this fake article is loaded up
  // just observe it on its own and don't swipe left or right to get to another clone of the same article.
  
  // uncomment the following line to override the article contents
  // self.relatedArticle = (NSDictionary*)[Utilities loadJson:@"complicated3"];
#endif
  
  NSAssert(!self.workerThread,@"This is mistakenly a worker thread");

  self.view.alpha = 1.0;
  [self photoVideoTreatment];

  NSString *imgUrl = [Utilities extractImageURLFromBlob:self.relatedArticle
                                                quality:AssetQualityFull];
  
  NSString *ratio = [[DesignManager shared] aspectCodeForContentItem:self.relatedArticle
                                                             quality:AssetQualityFull];
  
  self.pushAssetIntoBody = NO;
  if ([ratio isEqualToString:@"23"] || [ratio isEqualToString:@"34"] || [ratio isEqualToString:@"Sq"]) {
    self.basicTemplate.image1.contentMode = UIViewContentModeScaleAspectFit;
    self.view.backgroundColor = [UIColor blackColor];
    self.pushAssetIntoBody = YES;
  }


  NSArray *assets = [self.relatedArticle objectForKey:@"assets"];

  if ([assets count] > 1) {
    self.pushAssetIntoBody = NO;
  }
  
#ifdef FAKE_INLINE_ASSETS
  //self.pushAssetIntoBody = YES;
#endif
  
  // -- Developer Note --
  // We've decided to load an image into the large/top template - do so here and observe scroller.
  //
  // self.shortPage indicates that we're not going to use the large template, so we push a
  // smaller image asset in to the actual body of the article.
  if (![Utilities pureNil:imgUrl] && !self.pushAssetIntoBody) {
    self.shortPage = NO;

    [self.basicTemplate.image1 loadImage:imgUrl quietly:YES];
    
    // When in portrait - observe the contentOffset of the masterContentScroller to fade out
    // the main image asset for the article.
    if (![Utilities isLandscape]) {
      [self.masterContentScroller addObserver:self
                                 forKeyPath:@"contentOffset"
                                    options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                                    context:nil];
    }
    
  } else { // Configure Article with no asset main asset.
    
    self.shortPage = YES;
    self.captionButton.alpha = 0.0;
    self.basicTemplate.backgroundColor = [UIColor whiteColor];

    if (![Utilities isLandscape]) { // Configure shortPage in Portrait
      [self.basicTemplate.image1 removeFromSuperview];
      self.basicTemplate.matteView.alpha = 0.0;
      
      self.articleDetailsAnchor.constant = 40.0;
      
      
    } else {
      
      [self.landscapeImageSheetView removeFromSuperview];
      if ( self.articleDetailsAnchor ) {
        [self.masterContentScroller removeConstraint:self.articleDetailsAnchor];
      }
      
      self.articleDetailsAnchor = [NSLayoutConstraint constraintWithItem:self.webContentLoader.webView
                                                               attribute:NSLayoutAttributeTopMargin
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.textSheetView
                                                               attribute:NSLayoutAttributeBottomMargin
                                                              multiplier:1.0
                                                                constant:0.0];
      [self.masterContentScroller addConstraint:self.articleDetailsAnchor];
      

      
    }


  } // end configure noAsset article


  // Set article Headline
  if ([self.relatedArticle objectForKey:@"title"]) {
    [self.basicTemplate.headLine sansifyTitleText:[self.relatedArticle objectForKey:@"title"]
                                           bold:YES
                                  respectHeight:YES];
  } else {
    [self.basicTemplate.headLine sansifyTitleText:[self.relatedArticle objectForKey:@"short_title"]
                                             bold:YES
                                    respectHeight:YES];
  }


  // Set article Byline
  NSString *bylineStr = [[self.relatedArticle objectForKey:@"byline"] uppercaseString];
  NSString *dateStr = [self.relatedArticle objectForKey:@"published_at"];
  NSDate *dateObj = [Utilities dateFromRFCString:dateStr];
  NSString *pretty = [NSDate stringFromDate:dateObj
                                 withFormat:@"MMM d, YYYY, h:mm a"];

  self.basicTemplate.byLine.textColor = [[DesignManager shared] burnedCharcoalColor];
  
  NSString *formatted = bylineStr ? [NSString stringWithFormat:@"%@\n%@",bylineStr,pretty] : pretty;
  [self.basicTemplate.byLine titleizeText:formatted
                                     bold:NO
                            respectHeight:YES];


  // Set article Category
  NSDictionary *category = [self.relatedArticle objectForKey:@"category"];
  if (category) {
    NSString *title = [category objectForKey:@"title"];
    if (![Utilities pureNil:title]) {
      [self.categoryLabel titleizeText:[title uppercaseString] bold:YES];
    } else {
      [self.categoryLabel titleizeText:@"MISCELLANEOUS" bold:YES];
    }
  } else {
    [self.categoryLabel titleizeText:@"MISCELLANEOUS" bold:YES];
  }
  
  // Handle article Audio
  NSArray *audio = [self.relatedArticle objectForKey:@"audio"];
  BOOL hasAudio = NO;
  if ( [audio count] > 0 ) {
    hasAudio = YES;
  }
  

  // Update UI for audioSeatView
  if (hasAudio) {
    
    self.audioDividerLine.vertical = YES;
    self.queueButton.alpha = 1.0;
    
    [[DesignManager shared] globalSetFontTo:[[DesignManager shared]
                                             latoRegular:self.queueButton.titleLabel.font.pointSize]
                                  forButton:self.queueButton];
    
    self.contentDividerLine.alpha = 0.0;
    self.audioSeatInternalView.layer.borderColor = [[DesignManager shared] periwinkleColor].CGColor;
    self.audioSeatInternalView.layer.borderWidth = 1.0;
    
    [self.playThisAudioLabel titleizeText:self.playThisAudioLabel.text
                                     bold:NO];
    
    NSDictionary *piece = [audio objectAtIndex:0];
    if ([piece objectForKey:@"duration"] != [NSNull null]) {
      [self.audioDurationLabel italicizeText:[Utilities formalStringFromSeconds:[[piece objectForKey:@"duration"] intValue]]
                                        bold:YES
                               respectHeight:YES];
    } else {
      [self.audioDurationLabel setHidden:YES];
    }
    
  } else {
    [self shortenForNoAudio];
  }
  
  [self adjustUIForQueue:nil];
  
  self.contentArranged = YES;
  self.textSheetView.alpha = 1.0;


  // On Portrait article with large image asset, send image to lowest seat in main view.
  if (![Utilities isLandscape]) {
    if (!self.shortPage) {
      [self.basicTemplate.image1 removeFromSuperview];
      [self.view addSubview:self.basicTemplate.image1];
      

      NSArray *hPosition = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[image]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{ @"image" : self.basicTemplate.image1 }];
      
      CGFloat height = self.basicTemplate.image1.frame.size.height;
      NSArray *vPosition = [NSLayoutConstraint
                            constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(40)-[image(%ld)]",(long)height]
                            options:0
                                                                   metrics:nil
                                                                     views:@{ @"image" : self.basicTemplate.image1 }];
      [self.view addConstraints:hPosition];
      [self.view addConstraints:vPosition];
      [self.view sendSubviewToBack:self.basicTemplate.image1];
      self.masterContentScroller.backgroundColor = [UIColor clearColor];
    }
    [[DesignManager shared] alignHorizontalCenterOf:self.basicTemplate.image1
                                           withView:self.masterContentScroller];
  }
  

  // -- Developer Note --
  // Restyle UI for Live Events pages. This can probably be optimized in the future, but it's
  // fine to place it here for now. We're talking about hundredths of a second.
  if (pc.category == ContentCategoryEvents) {
    [self eventTreatment];
  }

  // Store 'original' height of webView, prior to placing any article content inside of it.
  // Used later to calculate content size for masterScoller.
  self.originalWebViewHeight = self.webContentLoader.webView.frame;
  self.captionView.alpha = 0.0; 
  
  // Send article to the webcontentLoader - place HTML content inside webView body.
  [self.webContentLoader setupWithArticle:self.relatedArticle
                                 delegate:self
                                pushAsset:self.pushAssetIntoBody
                               completion:^{


                                 
                               }];
  
  if ( self.fromSnapshot ) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[Utilities del] uncloakUI];
    });
  }
}

- (void)shortenForNoAudio {
  
  [self.textSheetView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self.audioSeatView removeFromSuperview];
  
  if ( self.grayLineBottomAnchor ) {
    [self.textSheetView removeConstraint:self.grayLineBottomAnchor];
    self.grayLineBottomAnchor = nil;
  }

  if ( self.playerControlsByLineAnchor ) {
    [self.textSheetView removeConstraint:self.playerControlsByLineAnchor];
    self.playerControlsByLineAnchor = nil;
  }
  
  self.grayLineBottomAnchor = [NSLayoutConstraint constraintWithItem:self.contentDividerLine
                                                           attribute:NSLayoutAttributeTopMargin
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.basicTemplate.byLine
                                                           attribute:NSLayoutAttributeBottomMargin
                                                          multiplier:1.0
                                                            constant:28.0];
  
  [self.textSheetView addConstraint:self.grayLineBottomAnchor];
  
}

#pragma mark - UI Treatment for ContentCategoryEvents
- (void)eventTreatment {

  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.rsvpButton.titleLabel.font.pointSize]
                                forButton:self.rsvpButton];
  
  UIColor *labelColor = [[DesignManager shared] number3pencilColor];
  self.dateContentLabel.textColor = labelColor;
  self.dateCaptionLabel.textColor = labelColor;
  self.locationCaptionLabel.textColor = labelColor;
  self.locationContentLabel.textColor = labelColor;
  

  NSDictionary *location = [self.relatedArticle objectForKey:@"location"];
  NSString *locationTitle = @"TBA";
  if (location) {
    locationTitle = [location objectForKey:@"title"];
  }
  
  [self.locationContentLabel titleizeText:locationTitle
                                     bold:NO];
  [self.locationCaptionLabel titleizeText:self.locationCaptionLabel.text
                                     bold:YES];
  
  NSString *start = [self.relatedArticle objectForKey:@"starts_at"];
  NSDate *startTime = [Utilities dateFromRFCString:start];
  NSString *prettyDuration = @"";
  if ([[self.relatedArticle objectForKey:@"is_all_day"] boolValue]) {
    prettyDuration = @"All Day";
  } else {
    NSString *endTime = [self.relatedArticle objectForKey:@"ends_at"];
    NSDate *finish = [Utilities dateFromRFCString:endTime];
    NSString *formattedStart = [NSDate stringFromDate:startTime withFormat:@"h:mm a"];
    NSString *formattedEnd = [NSDate stringFromDate:finish withFormat:@"h:mm a"];
    
    prettyDuration = [NSString stringWithFormat:@"%@-%@",formattedStart,formattedEnd];
    
  }
  if (self.liveEvent) {
    [self.dateCaptionLabel titleizeText:@"EVENT TIME:"
                                   bold:YES];
    [self.dateContentLabel titleizeText:prettyDuration
                                   bold:NO];
    
  } else {
    [self.dateCaptionLabel titleizeText:@"DATE & TIME:"
                                   bold:YES];
    
    NSString *startDay = [NSDate stringFromDate:startTime withFormat:@"EEEE, MMM d"];
    prettyDuration = [NSString stringWithFormat:@"%@, %@",startDay,prettyDuration];
    
    [self.dateContentLabel titleizeText:prettyDuration
                                   bold:NO];
  }
  
  if (self.liveEvent || [Utilities pureNil:[self.relatedArticle objectForKey:@"rsvp_url"]] ) {
    
    if (self.shortPage || self.pushAssetIntoBody) {
      [[DesignManager shared] globalSetImageTo:@"" forButton:self.playOverlayButton];
    }
    
  } else {

    [self.textSheetView addSubview:self.rsvpSeatView];
    [self.rsvpSeatView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSArray *sizeLocks = [[DesignManager shared] sizeContraintsForView:self.rsvpSeatView];
    //[self.rsvpSeatView addConstraints:sizeLocks];
    
    NSArray *hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[rsvp]|"
                                                                options:0
                                                                metrics:nil
                                                                  views:@{ @"rsvp" : self.rsvpSeatView }];
    NSArray *vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[caption][rsvp]-(10)-[line]"]
                                                                options:0
                                                                metrics:nil
                                                                  views:@{ @"caption" : self.basicTemplate.headLine,
                                                                           @"rsvp" : self.rsvpSeatView,
                                                                           @"line" : self.contentDividerLine }];
    [self.textSheetView removeConstraint:self.bylineToCaptionAnchor];
    [self.textSheetView removeConstraint:self.grayLineBottomAnchor];
    
    [self.textSheetView addConstraints:hAnchors];
    [self.textSheetView addConstraints:vAnchors];

    [self.basicTemplate.byLine removeFromSuperview];
    [self.textSheetView setNeedsLayout];

    self.rsvpButtonSeatView.layer.cornerRadius = 5.0;
    self.rsvpButtonSeatView.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];

  }
  
  BOOL videoAsset = [[ContentManager shared] storyHasYouTubeAsset:self.relatedArticle];
  videoAsset = [[ScheduleManager shared] eventIsLive:self.relatedArticle];
  
  if (videoAsset) {
    self.categorySeat.backgroundColor = [[DesignManager shared] auburnColor];
    [self.categoryLabel titleizeText:@"LIVE VIDEO"
                                bold:YES];
    self.categorySeat.alpha = 1.0;
    
  } else {
    [self.categoryLabel titleizeText:@"LIVE EVENT"
                                bold:YES];
    self.categorySeat.alpha = 1.0;
  }
  
}


#pragma mark - UI Treatment for slideshow or video assets
- (void)photoVideoTreatment {
  NSArray *assets = [self.relatedArticle objectForKey:@"assets"];
  NSDictionary *primary = nil;
  if ([assets count] > 0) {
    primary = [assets objectAtIndex:0];
  }
  
  BOOL prime = NO;
  BOOL hasNative = [primary objectForKey:@"native"] != nil;
  
  SCPRSingleArticleCollectionViewController *pc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
  if (pc.category == ContentCategoryEvents) {
    hasNative = [[ScheduleManager shared] eventIsLive:self.relatedArticle];
  }

  
  if (hasNative) {
    self.playOverlayButton.alpha = 1.0;
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playButtonSmall.png"]];
    self.extraAssetsImage.frame = iv.frame;
    self.extraAssetsImage.image = [UIImage imageNamed:@"playButtonSmall.png"];
    
    
    NSString *videoText = pc.category == ContentCategoryEvents ? @"WATCH LIVE VIDEO" : @"PLAY VIDEO";
    [self.extraAssetsLabel titleizeText:videoText
                                   bold:NO];
    
    
    [self.basicTemplate.matteView layoutIfNeeded];
    
    self.extraAssetsSeat.alpha = 1.0;
    [self.playOverlayButton addTarget:self
                               action:@selector(playVideo:)
                     forControlEvents:UIControlEventTouchUpInside];
    prime = YES;
    
    
  } else {

    if ([assets count] > 1) { // Create slideshow when article has more than one asset.
      
      self.playOverlayButton.alpha = 1.0;
      self.extraAssetsImage.image = [UIImage imageNamed:@"slideshow-icon.png"];
      
      [self.extraAssetsLabel titleizeText:[NSString stringWithFormat:@"SLIDESHOW : %d PHOTOS",[assets count]]
                                     bold:NO];
      
      self.extraAssetsSeat.alpha = 1.0;
      [self.playOverlayButton addTarget:self
                                 action:@selector(presentSlideshow:)
                       forControlEvents:UIControlEventTouchUpInside];
      prime = YES;

    } else { // Set caption for article with only one asset.
      if (primary) {
        [self armCaption:primary];
      }
      self.extraAssetsSeat.alpha = 0.0;
      self.playOverlayButton.alpha = 0.0;
    }
  } // end-if for hasNative assets
  

}


#pragma mark - UI Treatment for Main Asset Caption
- (void)armCaption:(NSDictionary*)leadingAsset {
  
  if ([leadingAsset objectForKey:@"caption"] == [NSNull null] || [leadingAsset objectForKey:@"owner"] == [NSNull null]) {
    self.captionView.alpha = 0.0;
    return;
  }

  UIView *v2u = [Utilities isLandscape] ? self.landscapeImageSheetView : self.basicTemplate.matteView;
  self.captionButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.captionButton addTarget:self
                         action:@selector(showCaption:)
               forControlEvents:UIControlEventTouchUpInside];
  [v2u addSubview:self.captionButton];
  
  NSArray *typical = [[DesignManager shared] typicalConstraints:self.captionButton];
  [v2u addConstraints:typical];
  

  // Set, style, and arrange caption labels.
  [self.captionLabel titleizeText:[leadingAsset objectForKey:@"caption"] bold:NO respectHeight:YES];
  [self.captionCreditLabel titleizeText:[leadingAsset objectForKey:@"owner"] bold:NO respectHeight:YES];
  self.captionCreditLabel.textColor = [[DesignManager shared] charcoalColor];
  self.captionView.backgroundColor = [[DesignManager shared] frostedWindowColor:0.88];
  self.captionView.frame = CGRectMake(0.0, 0.0, self.captionView.frame.size.width,
                                      self.captionCreditLabel.frame.origin.y + self.captionCreditLabel.frame.size.height + self.captionLabel.frame.origin.y + 2.0);
  self.captionView.alpha = 0.0;

}

- (void)showCaption:(id)sender {
  
  if (self.captionUp) {
    [self fadeCaption];
    return;
  }
  
  [UIView animateWithDuration:0.22 animations:^{
    self.captionView.alpha = 1.0;
  } completion:^(BOOL finished) {
    self.captionUp = YES;
    self.captionFadeTapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(fadeCaption)];
    [self.view addGestureRecognizer:self.captionFadeTapper];
    self.captionFadeTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                             target:self
                                                           selector:@selector(fadeCaption)
                                                           userInfo:nil
                                                            repeats:NO];
  }];
}

- (void)fadeCaption {
  
  if (self.captionFadeTimer) {
    if ([self.captionFadeTimer isValid]) {
      [self.captionFadeTimer invalidate];
    }
    self.captionFadeTimer = nil;
  }
  
  if (self.captionFadeTapper) {
    [self.view removeGestureRecognizer:self.captionFadeTapper];
    self.captionFadeTapper = nil;
  }
  
  [UIView animateWithDuration:0.22 animations:^{
    self.captionView.alpha = 0.0;
  } completion:^(BOOL finished) {
    self.captionUp = NO;
  }];
}


#pragma mark - Extra Assets
- (void)playVideo:(id)sender {
  [self presentVideo];
}

- (void)presentSlideshow:(id)sender {
  [[Utilities del] cloakUIWithSlideshowFromArticle:self.relatedArticle];
}

- (void)presentVideo {
  self.floatingVideoController = [[SCPRFloatingEmbedViewController alloc]
                                  initWithNibName:[[DesignManager shared]
                                                   xibForPlatformWithName:@"SCPRFloatingEmbedViewController"]
                                  bundle:nil];

  self.floatingVideoController.fadeAudio = YES;
  [[Utilities del] cloakUIWithCustomView:self.floatingVideoController dismissible:YES];
  [self.floatingVideoController setupWithPVArticle:self.relatedArticle];
}


#pragma mark - UI Adjustment for Content Height Change
- (void)refreshHeight {
  [self snapToContentHeight];
}

- (void)snapToContentHeight {
  NSString *output = [self.webContentLoader.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"container\").offsetHeight;"];
  CGFloat webHeight = fmaxf([output floatValue],self.originalWebViewHeight.size.height);
  
  CGFloat totalHeight = webHeight;
  
  // Only increase height if we have a large, main image asset (not in the article body).
  if ([Utilities articleHasAsset:self.relatedArticle]) {
    if (!self.shortPage) {
      if ([Utilities isLandscape]) {
        totalHeight += self.landscapeImageSheetView.frame.size.height;
      } else {
        totalHeight += self.basicTemplate.matteView.frame.size.height;
      }
    }
  }
  totalHeight += self.textSheetView.frame.size.height;
  
  // Nudge for Short List and non-iOS7 devices
  if (![Utilities isIOS7]) {
    totalHeight += 60.0;
    webHeight += 60.0;
  }
  if (self.fromSnapshot) {
    totalHeight += 60.0;
    webHeight +=  60.0;
  }
  
  self.webContentHeightAnchor.constant = webHeight;
  
  
  if (self.hasSocialData) {
    // Place the social sheetview below the article's contents and embeds
    CGFloat socialSheetVertAdjust = 30.0;
    if (![Utilities isIOS7]) {
      socialSheetVertAdjust += 50.0;
    }
    if (self.fromSnapshot) {
      socialSheetVertAdjust += 70.0;
    }
    
    [self.socialSheetView setFrame:CGRectMake(self.socialSheetView.frame.origin.x,
                                              self.masterContentScroller.contentSize.height - self.socialSheetView.frame.size.height - socialSheetVertAdjust,
                                              self.socialSheetView.frame.size.width,
                                              self.socialSheetView.frame.size.height)];
    
    if (self.activity.alpha == 0.0 && self.socialSheetView.alpha == 0.0) {
      [UIView animateWithDuration: 0.0
                            delay:0.2 options:UIViewAnimationOptionCurveEaseInOut
                       animations:^{
                         self.socialSheetView.alpha = 1.0;
                       } completion:nil];
    }
  }
  
}


# pragma mark - UI Treatment for Queue
- (void)adjustUIForQueue:(NSNotification*)note {

  if ([[QueueManager shared] articleIsInQueue:self.relatedArticle]) {
    if ([[QueueManager shared] articleIsPlayingNow:self.relatedArticle]) {
      
      // PAUSED or PLAYING NOW
      [[DesignManager shared] globalSetImageTo:@"icon-audio-listening.png"
                                     forButton:self.playAudioButton];
      
      // IN QUEUE, NOT PLAYING
      [[DesignManager shared] globalSetImageTo:@"icon-queue-active.png"
                                     forButton:self.queueButton];
      self.queueButton.enabled = YES;
      
      NSString *text = [Utilities isIpad] ? @"In Queue" : @"";
      [[DesignManager shared] globalSetTitleTo:text
                                     forButton:self.queueButton];
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] kpccOrangeColor]
                                         forButton:self.queueButton];
      
      self.playAudioButton.enabled = NO;

    } else {
      
      [[DesignManager shared] globalSetImageTo:@"icon-audio-play.png"
                                     forButton:self.playAudioButton];
      
      self.playAudioButton.enabled = YES;
      
      // IN QUEUE, NOT PLAYING
      [[DesignManager shared] globalSetImageTo:@"icon-queue-active.png"
                                     forButton:self.queueButton];
      
      NSString *text = [Utilities isIpad] ? @"In Queue" : @"";
      [[DesignManager shared] globalSetTitleTo:text
                                     forButton:self.queueButton];
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] kpccOrangeColor]
                                         forButton:self.queueButton];
      
      self.queueButton.enabled = YES;

    }
  } else {
    if ([[QueueManager shared] articleIsPlayingNow:self.relatedArticle]) {
      
      // PLAYING NOW
      [[DesignManager shared] globalSetImageTo:@"icon-queue-active.png"
                                     forButton:self.queueButton];
      
      NSString *text = [Utilities isIpad] ? @"In Queue" : @"";
      [[DesignManager shared] globalSetTitleTo:text
                                     forButton:self.queueButton];
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] kpccOrangeColor]
                                         forButton:self.queueButton];
      
      self.queueButton.enabled = YES;
      
      [[DesignManager shared] globalSetImageTo:@"icon-audio-listening.png"
                                     forButton:self.playAudioButton];
      
      self.playAudioButton.enabled = NO;

    } else {
      
      // NOT IN QUEUE
      [[DesignManager shared] globalSetImageTo:@"icon-queue.png"
                                     forButton:self.queueButton];
      self.queueButton.enabled = YES;
      
      [[DesignManager shared] globalSetImageTo:@"icon-audio-play.png"
                                     forButton:self.playAudioButton];
      
      NSString *text = [Utilities isIpad] ? @"Add to Queue" : @"";
      [[DesignManager shared] globalSetTitleTo:text
                                     forButton:self.queueButton];
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] number3pencilColor]
                                         forButton:self.queueButton];
      
      self.playAudioButton.enabled = YES;
    }
  }
}


#pragma mark - Query to Parse for Article Share Counts
- (void)queryParse {
  // Make request to PCC social_data_no_constraints function and retrieve social share count for this article.
  if (![self.relatedArticle objectForKey:@"social_data"]) {
    NSString *articleId = [self.relatedArticle objectForKey:@"id"];
    if (articleId) {
      [PFCloud callFunctionInBackground:@"social_data_no_constraints"
                         withParameters:@{@"articleIds": @[articleId]}
                                  block:^(NSDictionary *results, NSError *error) {
                                    if (!error) {
                                      if ([results objectForKey:articleId]) {
                                        self.socialCountHash = [results objectForKey:articleId];
                                      }
                                      [self socialDataLoaded];
                                    }
                                  }];
    }
  }  else {
    // Social Data already exists for current article.
    self.socialCountHash = [self.relatedArticle objectForKey:@"social_data"];
    [self socialDataLoaded];
  }
}

- (void)socialDataLoaded {
  
  _hasSocialData = YES;
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.socialShareButton.titleLabel.font.pointSize]
                                forButton:self.socialShareButton];
  
  [[self.socialShareButton layer] setCornerRadius:3.0f];
  [[self.socialShareButton layer] setBorderWidth:1.0f];
  [[self.socialShareButton layer] setBorderColor:[UIColor colorWithRed:9.0/255.0 green:185.0/255.0 blue:243.0/255.0 alpha:1.0].CGColor];

  if (![self.masterContentScroller.subviews containsObject:self.socialSheetView]) {
    [self.masterContentScroller addSubview:self.socialSheetView];
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[social]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{ @"social" : self.socialSheetView }];
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.socialSheetView
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0
                                                              constant:self.socialSheetView.frame.size.height];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.socialSheetView
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:self.webContentLoader.webView.frame.size.width];
    
    NSLayoutConstraint *verticalAnchor1 = [NSLayoutConstraint constraintWithItem:self.socialSheetView
                                                                      attribute:NSLayoutAttributeBottomMargin
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.masterContentScroller
                                                                      attribute:NSLayoutAttributeBottomMargin
                                                                     multiplier:1.0
                                                                       constant:0.0];
    
    NSLayoutConstraint *verticalAnchor2 = [NSLayoutConstraint constraintWithItem:self.socialSheetView
                                                                       attribute:NSLayoutAttributeTopMargin
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.webContentLoader.webView
                                                                       attribute:NSLayoutAttributeBottomMargin
                                                                      multiplier:1.0
                                                                        constant:0.0];
    
    [self.socialSheetView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.webContentLoader.webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    

    
    [self.masterContentScroller removeConstraint:self.webViewBottomAnchor];
    [self.socialSheetView addConstraint:heightConstraint];
    [self.socialSheetView addConstraint:widthConstraint];
    [self.masterContentScroller addConstraints:constraints];
    [self.masterContentScroller addConstraint:verticalAnchor1];
    [self.masterContentScroller addConstraint:verticalAnchor2];

  }
  
  if (self.socialCountHash) {
    NSString *facebookCount = [self.socialCountHash objectForKey:@"facebook_count"];
    NSString *twitterCount = [self.socialCountHash objectForKey:@"twitter_count"];
  
    if (facebookCount && facebookCount.integerValue > 0) {
      [self.facebookCountLabel setFont:([[DesignManager shared] latoRegular: 13.0])];
      [self.facebookCountLabel setText:[NSString stringWithFormat:@"%@",  facebookCount]];
    } else {
      [self.facebookCountLabel setText:@""];
      [self.facebookLogoImage setImage:[UIImage imageNamed:@"icon-social-facebook-disabled"]];
    }
  
    if (twitterCount && twitterCount.integerValue > 0) {
      [self.twitterCountLabel setFont:([[DesignManager shared] latoRegular: 13.0])];
      [self.twitterCountLabel setText:[NSString stringWithFormat:@"%@",  twitterCount]];
    } else {
      [self.twitterCountLabel setText:@""];
      [self.twitterLogoImage setImage:[UIImage imageNamed:@"icon-social-twitter-disabled"]];
    }
  } else {
    [self.facebookCountLabel setText:@""];
    [self.twitterCountLabel setText:@""];
    [self.facebookLogoImage setImage:[UIImage imageNamed:@"icon-social-facebook-disabled"]];
    [self.twitterLogoImage setImage:[UIImage imageNamed:@"icon-social-twitter-disabled"]];
  }
  

  [self refreshHeight];
}


#pragma mark - Share Modal Handling
- (void)toggleShareModal {
  if ( self.shareModalOpen ) {
    [self closeShareModal];
  } else {
    [self openShareModal];
  }
}

- (void)closeShareModal {
  if (!self.shareModalOpen) {
    return;
  }
  self.shareModalOpen = NO;
  [self.shareModal dismissPopoverAnimated:YES];
}

- (void)openShareModal {
  if (self.shareModalOpen) {
    return;
  }
  self.shareModalOpen = YES;
  
  self.shareModal = [[UIPopoverController alloc]
                       initWithContentViewController:self.shareDrawer];
  
  self.shareModal.delegate = self;
  self.shareDrawer.singleArticleDelegate = self;
  
  CGRect raw = self.socialShareButton.frame;
  CGRect cooked = [self.view convertRect:raw fromView:self.socialSheetView];
  cooked = CGRectMake(cooked.origin.x, cooked.origin.y + 4, cooked.size.width, cooked.size.height);
  
  [self.shareDrawer.shareMethodTable reloadData];
  CGFloat s = [self.shareDrawer.shareCells count]*52.0+4.0;
  self.shareModal.popoverContentSize = CGSizeMake(self.shareDrawer.shareMethodTable.frame.size.width,s);
  [self.shareModal presentPopoverFromRect:cooked
                                     inView:self.view
                   permittedArrowDirections:UIPopoverArrowDirectionDown
                                   animated:YES];
}


#pragma mark - UIPopoverController
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  self.shareModalOpen = NO;
}


#pragma mark - Web Content Loader
- (BOOL)webContentReady {
  SCPRSingleArticleCollectionViewController *sacvc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
  if (sacvc) {
    NSLog(@"Parent Collection not actually nil!");
  }
  return !sacvc.contentLock;
}

- (void)webContentLoaded:(BOOL)firstTime {
  self.okToTrash = YES;
  
  if ( firstTime ) {
    
    NSAssert([NSThread isMainThread], @"Method called using a thread other than main! : webContentLoaded");
    [self snapToContentHeight];
    
    [UIView animateWithDuration:0.22 animations:^{
      
      self.webContentLoader.webView.alpha = 1.0;
    } completion:^(BOOL finished) {

      self.masterContentScroller.scrollEnabled = YES;

    }];
    
  } else {
    self.masterContentScroller.scrollEnabled = YES;
  }

  [self.activity stopAnimating];
  self.activity.alpha = 0.0;
  
  self.socialSheetView.alpha = 1.0;
}

- (void)webContentFailed {

}

- (void)externalWebContentRequest:(NSURLRequest*)request {
  SCPRExternalWebContentViewController *external = [[SCPRExternalWebContentViewController alloc]
                                                    initWithNibName:[[DesignManager shared]
                                                                     xibForPlatformWithName:@"SCPRExternalWebContentViewController"]
                                                    bundle:nil];
  external.fromEditions = self.fromSnapshot;
  external.supplementalContainer = self;
  
  [[[Utilities del] globalTitleBar] morph:BarTypeExternalWeb
                                container:external];
  
  if ([self.relatedArticle objectForKey:@"rsvp_url"]) {
    [[[Utilities del] globalTitleBar] applyBackButtonText:@"Live Events"];
  }
  
  if (self.parentCollection) {
    SCPRSingleArticleCollectionViewController *pc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
    [pc.navigationController pushViewController:external animated:YES];
    external.backContainer = pc;
  } else {
    [self.navigationController pushViewController:external animated:YES];
  }
  
  external.view.frame = external.view.frame;
  
  if ([Utilities isIOS7]) {
    external.webContentView.frame = CGRectMake(external.webContentView.frame.origin.x,
                                               external.webContentView.frame.origin.y + 40.0,
                                               external.webContentView.frame.size.width,
                                               external.webContentView.frame.size.height - 20.0);
  }
  
  [external prime:request];
  
  self.externalContent = external;
  
  external.bensOffbrandButton = [[[Utilities del] globalTitleBar] parserOrFullButton];
  
  [external.bensOffbrandButton addTarget:external
                                  action:@selector(buttonTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
  
  [[ContentManager shared] setUserIsViewingExpandedDetails:YES];
}

- (NSDictionary*)associatedArticleContent {
  return self.relatedArticle;
}


#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Rotatable
- (void)handleRotationPre {
  [UIView animateWithDuration:0.12 animations:^{
    self.masterContentScroller.alpha = 0.0;
  }];
}

- (void)handleRotationPost {
  
  [[Utilities del] blackoutCloak:^{
    SCPREditionAtomViewController *atom = self.parentEditionAtom;
    SCPREditionMoleculeViewController *molecule = [atom parentMolecule];
    [molecule setNeedsPush:YES];
    [self backTapped];
  }];

  /*
  [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                       xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                                owner:self
                              options:nil];
  self.contentArranged = NO;
  [self stretch];
  
  if (self.fromSnapshot) {
    SCPRViewController *svc = [[Utilities del] viewController];
    
    CGFloat offset = [Utilities isIOS7] ? -40.0 : -60.0;
    [UIView animateWithDuration:0.22 animations:^{
      [svc.mainPageScroller setContentOffset:CGPointMake(0.0, offset)];
    }];
  }
  
  [self arrangeContent];
  
  if ([Utilities isLandscape]) {
    @try {
      
      /*[self.masterContentScroller removeObserver:self
                                      forKeyPath:@"contentOffset"];
      
    } @catch (NSException *e) {
      
    }
  }
  
  [UIView animateWithDuration:0.12 animations:^{
    self.masterContentScroller.alpha = 1.0;
  }];
   */
}

- (BOOL)shouldAutorotate {
  return YES;
}


#pragma mark - Backable
- (UIScrollView*)titlebarTraversalScroller {
  return self.masterContentScroller;
}

- (CGFloat)traversableTitlebarArea {
  return self.basicTemplate.image1.frame.size.height;
}

- (void)backTapped {
  
  if ([[[Utilities del] viewController] shareDrawerOpen]) {
    [[[Utilities del] viewController] toggleShareDrawer];
  }
  
  if (self.fromSnapshot) {
    
    SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
    
    [tb pop];
    [tb.personalInfoButton setAlpha:0.0];
    
    
    SCPRViewController *svc = [[Utilities del] viewController];
    [UIView animateWithDuration:0.22 animations:^{
      [svc.mainPageScroller setContentOffset:CGPointMake(0.0, 0.0)];
    }];
    
    [[ContentManager shared] popFromResizeVector];
    
    [self.navigationController popViewControllerAnimated:YES];
    
  } else {
    if ( self.videoStarted ) {
      if ( ![[AudioManager shared] isPlayingAnyAudio] ) {
        [[AudioManager shared] startStream:nil];
      }
    }
    
    self.webContentLoader.webView.delegate = nil;
    SCPRSingleArticleCollectionViewController *savc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
    
    savc.trash = YES;
    [savc cleanup];
    [savc.navigationController popViewControllerAnimated:YES];
    [[DesignManager shared] setInSingleArticle:NO];
    [[ContentManager shared] popFromResizeVector];
    
    [[[Utilities del] globalTitleBar] pop];
    
    if ( self.supplementalContainer ) {
      if ( [self.supplementalContainer respondsToSelector:@selector(contentFinishedDisplaying)] ) {
        [self.supplementalContainer contentFinishedDisplaying];
      }
    }
  }
  
  @try {
    [self.masterContentScroller removeObserver:self
                                    forKeyPath:@"contentOffset"];
  } @catch (NSException *e) {
    
  }
  [[ContentManager shared] setUserIsViewingExpandedDetails:NO];
}


#pragma mark - Deactivatable
- (void)deactivationMethod {
  NSLog(@" ***** KILLING CONTENT ****** ");
  
  self.webContentLoader.cleaningUp = YES;
  [self.webContentLoader.webView stopLoading];
  self.webContentLoader.delegate = nil;
  [self.webContentLoader.webView loadHTMLString:@"" baseURL:nil];
  
  self.okToDelete = YES;
  
}

- (void)killContent {
  
  NSString *title = [self.relatedArticle objectForKey:@"short_title"] ? [self.relatedArticle objectForKey:@"short_title"] : [self.relatedArticle objectForKey:@"title"];
  NSString *code = [NSString stringWithFormat:@"%@%d",[Utilities sha1:title],
                    (NSInteger)[[NSDate date] timeIntervalSince1970]];
  self.deactivationToken = code;
  //[[ContentManager shared] queueDeactivation:self];
  
  @try {
    [self.masterContentScroller removeObserver:self
                                    forKeyPath:@"contentOffset"];
  } @catch (NSException *e) {
    //NSLog(@"Unnecessary observation removal...");
  }
  
  NSString *blank = [[FileManager shared] copyFromMainBundleToDocuments:@"blank.html"
                                                               destName:@"blank.html"];
  NSURL *url = [NSURL fileURLWithPath:blank];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [self.webContentLoader.webView stopLoading];
  self.webContentLoader.cleaningUp = YES;
  [self.webContentLoader.webView loadRequest:request];
}

- (void)safeKillContent {
  if ( ![Utilities isLandscape] ) {
    @try {
      [self.masterContentScroller removeObserver:self
                                      forKeyPath:@"contentOffset"];
    } @catch (NSException *e) {
      //NSLog(@"Unnecessary observation removal...");
    }
  }
}

- (void)cleanup {
  self.webContentLoader.webView.delegate = nil;
  [self.webContentLoader.webView removeFromSuperview];
  self.webContentLoader.webView = nil;
  self.webContentLoader = nil;
  self.webView = nil;
  
  if ( self.extraAssetsController ) {
    [self.extraAssetsController deactivate];
  }
  
  self.basicTemplate.image1.image = nil;
  self.basicTemplate.image1 = nil;
  [self.basicTemplate.image1 removeFromSuperview];
  
  self.basicTemplate = nil;
  self.webContentLoader.webView = nil;
  self.extraAssetsController = nil;
  self.parentCollection = nil;
  
  [self.view removeFromSuperview];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  self.okToDelete = YES;
  [[ContentManager shared] popDeactivation:self.deactivationToken];
}


- (void)dealloc {
  
  NSLog(@"DEALLOCATING SINGLE ARTICLE VIEW CONTROLLER...");
  [self safeKillContent];
  
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  [[NSURLCache sharedURLCache] removeAllCachedResponses];

}

@end
