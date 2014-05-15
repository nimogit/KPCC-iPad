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

@interface SCPRSingleArticleViewController() <UIPopoverControllerDelegate>

@end

@implementation SCPRSingleArticleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  [self stretch];
  [self.activity startAnimating];
  
  self.webContentLoader.webView.alpha = 0.0;
  self.webContentLoader.webView.frame = self.webContentLoader.webView.frame;

  
  self.textSheetView.alpha = 0.0;
  self.cloakView.alpha = 0.0;
  self.queueButton.alpha = 0.0;
  self.socialSheetView.alpha = 0.0;
  self.basicTemplate.headLine.textColor = [UIColor blackColor]/*[[DesignManager shared] darkoalColor]*/;
  self.basicTemplate.byLine.textColor = [UIColor blackColor]/*[[DesignManager shared] darkoalColor]*/;
  self.view.backgroundColor = [UIColor whiteColor];/*[[DesignManager shared] charcoalColor];*/
  
  if ( !self.relatedArticle ) {
    [[NetworkManager shared] fetchContentForSingleArticle:self.relatedURL
                                                display:self];
  }
  
  self.basicTemplate.aspectCode = @"SingleArticle";
  self.basicTemplate.backgroundColor = [UIColor whiteColor];
  self.basicTemplate.templateStyle = NewsPageTemplateSingleArticle;
  self.backButton.alpha = 0.0;
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.socialShareButton.titleLabel.font.pointSize]
                                forButton:self.socialShareButton];
  
  [[self.socialShareButton layer] setCornerRadius:3.0f];
  [[self.socialShareButton layer] setBorderWidth:1.0f];
  [[self.socialShareButton layer] setBorderColor:[UIColor colorWithRed:9.0/255.0 green:185.0/255.0 blue:243.0/255.0 alpha:1.0].CGColor];
  
  self.shareDrawer = [[Utilities del] viewController].globalShareDrawer;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(adjustUIForQueue:)
                                               name:@"notify_listeners_of_queue_change"
                                             object:nil];
}

- (UIView*)bendableView {
  return self.view;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  if ( object == self.masterContentScroller ) {
    
    self.cloakView.alpha = self.masterContentScroller.contentOffset.y / self.basicTemplate.image1.frame.size.height;
    
    if ( self.webContentLoader.containsTwitterEntries ) {
      
      CGPoint initial = [[change objectForKey:@"initial"] CGPointValue];
      CGPoint new = [[change objectForKey:@"new"] CGPointValue];
      
      if ( !self.twitterSynthesized ) {
        if ( abs(new.y - initial.y) > 10.0 ) {
          
          self.twitterSynthesized = YES;
          if ( self.webContentLoader.twitterEmbeds ) {
            while ( [self.webContentLoader.twitterEmbeds count] > 0 ) {
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

- (void)arm {

}

- (void)viewDidAppear:(BOOL)animated {
  [[[Utilities del] globalTitleBar] applyKpccLogo];
}

- (void)viewWillAppear:(BOOL)animated {
  if ( self.fromSnapshot ) {
    SCPRViewController *svc = [[Utilities del] viewController];
    
    CGFloat offset = [Utilities isIOS7] ? -40.0 : -60.0;
    [UIView animateWithDuration:0.22 animations:^{
      [svc.mainPageScroller setContentOffset:CGPointMake(0.0, offset)];
    }];
  }
}

- (void)activate {
  [self arrangeContent];
  self.backButton.alpha = 1.0;
}

- (IBAction)buttonTapped:(id)sender {
  if ( sender == self.queueButton ) {
    if ( ![[QueueManager shared] articleIsInQueue:self.relatedArticle] ) {
      [[QueueManager shared] addToQueue:self.relatedArticle
                                asset:nil];
      [self adjustUIForQueue:nil];
    } else {
      if ( [[QueueManager shared] articleIsPlayingNow:self.relatedArticle] ) {
        [[QueueManager shared] pop];
      } else {
        [[QueueManager shared] removeFromQueue:self.relatedArticle];
        [self adjustUIForQueue:nil];
      }
    }
  }
  if ( sender == self.playAudioButton ) {
    if ( ![[QueueManager shared] articleIsInQueue:self.relatedArticle] ) {
      [[QueueManager shared] addToQueue:self.relatedArticle
                                  asset:nil];
    }
    [[QueueManager shared] playSpecificArticle:self.relatedArticle];
    [self adjustUIForQueue:nil];
  }
  if ( sender == self.rsvpButton ) {
    if ( [self.relatedArticle objectForKey:@"rsvp_url"] ) {
      
      NSString *rsvp = [self.relatedArticle objectForKey:@"rsvp_url"];
      NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:rsvp]];
      [self externalWebContentRequest:request];
      
    }
    
    [[AnalyticsManager shared] logEvent:@"user_rsvp_for_event"
                         withParameters:@{}];
  }
  if (sender == self.socialShareButton) {
    [self toggleShareModal];
  }
}

- (void)killContent {

  NSString *title = [self.relatedArticle objectForKey:@"short_title"] ? [self.relatedArticle objectForKey:@"short_title"] : [self.relatedArticle objectForKey:@"title"];
  NSString *code = [NSString stringWithFormat:@"%@%d",[Utilities sha1:title],
                    (NSInteger)[[NSDate date] timeIntervalSince1970]];
  self.deactivationToken = code;
  [[ContentManager shared] queueDeactivation:self];
  
  @try {
    [self.masterContentScroller removeObserver:self
                                    forKeyPath:@"contentOffset"];
  } @catch (NSException *e) {
    //NSLog(@"Unnecessary observation removal...");
  }
  
  NSString *blank = [[FileManager shared] copyFromMainBundleToDocuments:@"blank.html"
                                                               destName:@"blank.html"];
  NSURL *url = [NSURL fileURLWithPath:blank];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                         cachePolicy:NSURLCacheStorageAllowed
                                                     timeoutInterval:10.0];

  [self.webContentLoader.webView stopLoading];
  self.webContentLoader.cleaningUp = YES;
  [self.webContentLoader.webView loadRequest:request];
}

- (void)safeKillContent {
  @try {
    [self.masterContentScroller removeObserver:self
                                    forKeyPath:@"contentOffset"];
  } @catch (NSException *e) {
    //NSLog(@"Unnecessary observation removal...");
  }
}

- (void)setRelatedArticle:(NSDictionary *)relatedArticle {
  _relatedArticle = relatedArticle;
  
  if ( [relatedArticle objectForKey:@"permalink"] ) {
    self.relatedURL = [relatedArticle objectForKey:@"permalink"];
  }
}

- (void)handleMultipleAssets {
  self.assetsHandled = YES;
}

- (void)partialWash {
  self.matteCloak.alpha = 0.8;
  self.sheetCloak.alpha = 0.8;
}

- (void)unwash {
  self.matteCloak.alpha = 0.0;
  self.sheetCloak.alpha = 0.0;
}

#pragma mark - Rotatable
- (void)handleRotationPre {
  [UIView animateWithDuration:0.12 animations:^{
    self.masterContentScroller.alpha = 0.0;
  }];
}

- (void)handleRotationPost {

  [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                       xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                                owner:self
                              options:nil];
  self.contentArranged = NO;
  [self stretch];
  
  if ( self.fromSnapshot ) {
    SCPRViewController *svc = [[Utilities del] viewController];
    
    CGFloat offset = [Utilities isIOS7] ? -40.0 : -60.0;
    [UIView animateWithDuration:0.22 animations:^{
      [svc.mainPageScroller setContentOffset:CGPointMake(0.0, offset)];
    }];
  }
  
  [self arrangeContent];
  
  if ( [Utilities isLandscape] ) {
    @try {
      
      [self.masterContentScroller removeObserver:self
                                      forKeyPath:@"contentOffset"];
      
    } @catch (NSException *e) {
      
    }
  }
  
  [UIView animateWithDuration:0.12 animations:^{
    self.masterContentScroller.alpha = 1.0;
  }];
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

#pragma mark - Backable
- (UIScrollView*)titlebarTraversalScroller {
  return self.masterContentScroller;
}

- (CGFloat)traversableTitlebarArea {
  return self.basicTemplate.image1.frame.size.height;
}

- (void)backTapped {

  if ( [[[Utilities del] viewController] shareDrawerOpen] ) {
    [[[Utilities del] viewController] toggleShareDrawer];
  }
  
  if ( self.fromSnapshot ) {
      
    SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
      
    [tb pop];
    [tb.personalInfoButton removeFromSuperview];
      
    
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

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  self.relatedArticle = [content objectAtIndex:0];
  [self arrangeContent];
}

- (void)contentFinishedDisplaying {
  self.externalContent = nil;
}

- (void)arrangeContent {
  if ( self.contentArranged ) {
    return;
  }

  self.categorySeat.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  
  SCPRSingleArticleCollectionViewController *pc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
  if ( pc.category == ContentCategoryEvents ) {
    self.liveEvent = [[ScheduleManager shared] eventIsLive:self.relatedArticle];
  }
  
  if (pc.category == ContentCategoryNews || [self fromSnapshot]) {
    [self queryParse];  
  }
  
  NSArray *assets = [self.relatedArticle objectForKey:@"assets"];
  NSDictionary *primary = nil;
  if ( [assets count] > 0 ) {
    primary = [assets objectAtIndex:0];
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
  
  BOOL pushAssetIntoBody = NO;
  if ( [ratio isEqualToString:@"23"] || [ratio isEqualToString:@"34"] || [ratio isEqualToString:@"Sq"] ) {
    self.basicTemplate.image1.contentMode = UIViewContentModeScaleAspectFit;
    self.view.backgroundColor = [UIColor blackColor];
    pushAssetIntoBody = YES;
  }
  
  if ( [assets count] > 1 ) {
    pushAssetIntoBody = NO;
  }
  
#ifdef FAKE_INLINE_ASSETS
  pushAssetIntoBody = YES;
#endif
  
  BOOL noAsset = NO;
  if ( ![Utilities pureNil:imgUrl] && !pushAssetIntoBody ) {
    [self.basicTemplate.image1 loadImage:imgUrl quietly:YES];
    if ( ![Utilities isLandscape] ) {
      
      [self.masterContentScroller addObserver:self
                                 forKeyPath:@"contentOffset"
                                    options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                                    context:nil];
    }
    
  } else {
    
    noAsset = YES;
    self.shortPage = YES;
    
    self.captionButton.alpha = 0.0;
    if ( ![Utilities isLandscape] ) {
      
      self.basicTemplate.matteView.alpha = 0.0;
      self.basicTemplate.backgroundColor = [UIColor whiteColor];
      
      CGFloat yOffset = [Utilities isIOS7] ? 0.0 : 20.0;
      self.textSheetView.frame = CGRectMake(self.basicTemplate.matteView.frame.origin.x,
                                            self.basicTemplate.matteView.frame.origin.y+yOffset,
                                            self.textSheetView.frame.size.width,
                                            self.textSheetView.frame.size.height);
      CGFloat heightDiff = self.masterContentScroller.frame.size.height - (self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height);
      self.webContentLoader.webView.frame = CGRectMake(self.webContentLoader.webView.frame.origin.x,
                                                       self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height,
                                                       self.webContentLoader.webView.frame.size.width,
                                                       heightDiff);
      
    } else {

      self.landscapeImageSheetView.alpha = 0.0;
      CGFloat heightDiff = self.masterContentScroller.frame.size.height - (self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height);
      self.webContentLoader.webView.frame = CGRectMake(self.webContentLoader.webView.frame.origin.x,
                                                       self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height,
                                                       self.webContentLoader.webView.frame.size.width,
                                                       heightDiff);
      
      [[DesignManager shared] avoidNeighbor:self.textSheetView
                                   withView:self.webContentLoader.webView
                                  direction:NeighborDirectionAbove
                                    padding:0.0];
      
    }
  }

  CGSize actual = [self.basicTemplate.image1 frameForImage].size;
  CGFloat actualWidth = self.basicTemplate.image1.image.size.width*actual.width;
  CGFloat widthToUse = fminf(actualWidth, self.basicTemplate.image1.frame.size.width);
  CGFloat diff = widthToUse - actualWidth;
  if ( diff > 0.0 ) {
    self.basicTemplate.blurb1.center = CGPointMake(self.basicTemplate.blurb1.center.x-diff,
                                                   self.basicTemplate.blurb1.center.y);
  }
  
  if ( [self.relatedArticle objectForKey:@"title"] ) {
    [self.basicTemplate.headLine sansifyTitleText:[self.relatedArticle objectForKey:@"title"]
                                           bold:YES
                                  respectHeight:YES];
  } else {
    [self.basicTemplate.headLine sansifyTitleText:[self.relatedArticle objectForKey:@"short_title"]
                                             bold:YES
                                    respectHeight:YES];
  }
  
  NSString *bylineStr = [self.relatedArticle objectForKey:@"byline"];
  bylineStr = [bylineStr uppercaseString];
  NSString *dateStr = [self.relatedArticle objectForKey:@"published_at"];
  NSDate *dateObj = [Utilities dateFromRFCString:dateStr];
  NSString *pretty = [NSDate stringFromDate:dateObj
                                 withFormat:@"MMM d, YYYY, h:mm a"];
  
  [self.basicTemplate.byLine titleizeText:[NSString stringWithFormat:@"%@\n%@",bylineStr,pretty]
                                     bold:NO
   respectHeight:YES];
  
  self.basicTemplate.byLine.textColor = [[DesignManager shared] burnedCharcoalColor];
  
  
  [[DesignManager shared] avoidNeighbor:self.basicTemplate.headLine
                               withView:self.basicTemplate.byLine
                              direction:NeighborDirectionAbove
                                padding:3.0];
  
  self.textSheetView.backgroundColor = [UIColor whiteColor];
  
  NSDictionary *category = [self.relatedArticle objectForKey:@"category"];
  if ( category ) {
    NSString *title = [category objectForKey:@"title"];
    if ( ![Utilities pureNil:title] ) {
      [self.categoryLabel titleizeText:[title uppercaseString]
                                  bold:YES];
    } else {
      [self.categoryLabel titleizeText:@"MISCELLANEOUS"
                                  bold:YES];
    }
  } else {
    [self.categoryLabel titleizeText:@"MISCELLANEOUS"
                                bold:YES];
  }
  
  [[DesignManager shared] avoidNeighbor:self.categorySeat
                                 withView:self.basicTemplate.headLine
                                direction:NeighborDirectionAbove
                                  padding:20.0];
    
  [[DesignManager shared] avoidNeighbor:self.basicTemplate.headLine
                                 withView:self.basicTemplate.byLine
                                direction:NeighborDirectionAbove
                                  padding:12.0];
    
  [[DesignManager shared] avoidNeighbor:self.basicTemplate.byLine
                                 withView:self.contentDividerLine
                                direction:NeighborDirectionAbove
                                  padding:30.0];
  
  NSArray *audio = [self.relatedArticle objectForKey:@"audio"];
  BOOL hasAudio = NO;
  CGFloat accountForAudio = 0.0;
  if ( [audio count] > 0 ) {
    hasAudio = YES;
    accountForAudio = self.audioSeatView.frame.size.height;
  }
  
  self.textSheetView.frame = CGRectMake(self.textSheetView.frame.origin.x,
                                          self.textSheetView.frame.origin.y,
                                          self.textSheetView.frame.size.width,
                                          self.contentDividerLine.frame.origin.y+self.contentDividerLine.frame.size.height-1.0+accountForAudio);
  
  if ( hasAudio ) {
    
    [self.textSheetView addSubview:self.audioSeatView];
    
    if ( [Utilities isLandscape] ) {
      
      
      self.audioSeatView.frame = CGRectMake(self.basicTemplate.headLine.frame.origin.x,self.textSheetView.frame.size.height-self.audioSeatView.frame.size.height-10.0,
                                          self.basicTemplate.image1.frame.size.width,
                                          self.audioSeatView.frame.size.height);
      
      self.basicTemplate.matteView.frame = CGRectMake(self.basicTemplate.matteView.frame.origin.x,
                                                      self.basicTemplate.matteView.frame.origin.y,
                                                      self.basicTemplate.matteView.frame.size.width,
                                                      self.textSheetView.frame.size.height);
      
      [self.captionButton removeFromSuperview];
      self.captionButton.frame = CGRectMake(0.0, 0.0,
                                            self.landscapeImageSheetView.frame.size.width,
                                            self.landscapeImageSheetView.frame.size.height);
      [self.landscapeImageSheetView addSubview:self.captionButton];

    } else {
      self.audioSeatView.frame = CGRectMake(0.0,self.textSheetView.frame.size.height-self.audioSeatView.frame.size.height-10.0,
                                            self.audioSeatView.frame.size.width,
                                            self.audioSeatView.frame.size.height);
    }
    
    self.audioDividerLine.vertical = YES;
    self.queueButton.alpha = 1.0;
    
    [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.queueButton.titleLabel.font.pointSize]
                                  forButton:self.queueButton];
    
    self.contentDividerLine.alpha = 0.0;
    self.audioSeatInternalView.layer.borderColor = [[DesignManager shared] periwinkleColor].CGColor;
    self.audioSeatInternalView.layer.borderWidth = 1.0;
    
    [self.playThisAudioLabel titleizeText:self.playThisAudioLabel.text bold:NO];
    NSDictionary *piece = [audio objectAtIndex:0];
    if ([piece objectForKey:@"duration"] != [NSNull null]) {
      [self.audioDurationLabel italicizeText:[Utilities formalStringFromSeconds:[[piece objectForKey:@"duration"] intValue]]
                                        bold:YES
                               respectHeight:YES];
    } else {
      [self.audioDurationLabel setHidden:YES];
    }
  }
  
  if ( ![Utilities isLandscape] || ( pushAssetIntoBody && [Utilities isLandscape] )) {
    self.webContentLoader.webView.frame = CGRectMake(self.webContentLoader.webView.frame.origin.x,
                                                     self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height,
                                                     self.webContentLoader.webView.frame.size.width,
                                                     self.webContentLoader.webView.frame.size.height);
  } else {
    
    if ( !noAsset  ) {
      [[DesignManager shared] avoidNeighbor:self.textSheetView
                                   withView:self.landscapeImageSheetView
                                  direction:NeighborDirectionAbove
                                    padding:0.0];
      
      [[DesignManager shared] avoidNeighbor:self.landscapeImageSheetView
                                   withView:self.webContentLoader.webView
                                  direction:NeighborDirectionAbove
                                    padding:0.0];
    }
  }
  
  [[DesignManager shared] alignHorizontalCenterOf:self.textSheetView
                                         withView:self.webContentLoader.webView];
  
  [self adjustUIForQueue:nil];
  self.contentArranged = YES;
  
  self.textSheetView.alpha = 1.0;
  
#ifdef FILL_BOUNDARIES
  self.playOverlayButton.backgroundColor = [UIColor greenColor];
#endif
  
  [self.extraAssetsSeat removeFromSuperview];
  if ( [assets count] > 1 && pushAssetIntoBody ) {
    
    if ( ![Utilities isLandscape] ) {
      [self.textSheetView addSubview:self.extraAssetsSeat];
      [[DesignManager shared] avoidNeighbor:self.contentDividerLine
                                   withView:self.extraAssetsSeat
                                  direction:NeighborDirectionBelow padding:10.0];
      
      [[DesignManager shared] alignRightOf:self.extraAssetsSeat
                                  withView:self.contentDividerLine];
      
      [self.playOverlayButton removeFromSuperview];
      [self.textSheetView addSubview:self.playOverlayButton];
      self.playOverlayButton.frame = self.extraAssetsSeat.frame;
    }
    
  } else {
  
    if ( ![Utilities isLandscape] ) {
      [self.view addSubview:self.extraAssetsSeat];
      [self.view sendSubviewToBack:self.extraAssetsSeat];
      [[DesignManager shared] alignHorizontalCenterOf:self.extraAssetsSeat
                                           withView:self.masterContentScroller];
    } else {
      [self.landscapeImageSheetView addSubview:self.extraAssetsSeat];
      [self.landscapeImageSheetView bringSubviewToFront:self.playOverlayButton];
    }
    
  }

  if ( ![Utilities isLandscape] ) {
    [self.basicTemplate.image1 removeFromSuperview];
    [self.view addSubview:self.basicTemplate.image1];
    [self.view sendSubviewToBack:self.basicTemplate.image1];

    [[DesignManager shared] alignHorizontalCenterOf:self.basicTemplate.image1
                                         withView:self.masterContentScroller];
  }

  // -- Developer Note -- //
  // This is what I referred to in RefactoringProposals.md about only now addressing the case of it being a Live Event context. All of this work
  // is done prior to set the article up a certain way and now it's finally checking the category for Live Event. A simple enough hack to make this better
  // immediately would be to wrap everything above this line in an if ( pc.category != ContentCategoryEvents ) { condition, and then make the rest
  // of the code the else case. I would do that right now but if I'm going to ever touch this method again it would be to completely rewrite it,
  // not to improve it slightly. Luckily, the UI arranging and setup here is relatively inexpensive, and for all I know Apple does some optimizations in order
  // to "work backward", meaning it looks at what a certain view is going to look like by the end of
  // the method and simply constructs the view based on that before doing any intermediary calculations. Wishful thinking?
  //
  // ... probably.
  //
  if ( pc.category == ContentCategoryEvents ) {
    
    [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.rsvpButton.titleLabel.font.pointSize]
                                  forButton:self.rsvpButton];
    
    UIColor *labelColor = [[DesignManager shared] number3pencilColor];
    self.dateContentLabel.textColor = labelColor;
    self.dateCaptionLabel.textColor = labelColor;
    self.locationCaptionLabel.textColor = labelColor;
    self.locationContentLabel.textColor = labelColor;
    
    [[DesignManager shared] avoidNeighbor:self.dateCaptionLabel
                                 withView:self.dateContentLabel
                                direction:NeighborDirectionToLeft
                                  padding:3.0];
    
    [[DesignManager shared] avoidNeighbor:self.locationCaptionLabel
                                 withView:self.locationContentLabel
                                direction:NeighborDirectionToLeft
                                  padding:3.0];
    
    NSDictionary *location = [self.relatedArticle objectForKey:@"location"];
    NSString *locationTitle = @"TBA";
    if ( location ) {
      locationTitle = [location objectForKey:@"title"];
    }
    
    [self.locationContentLabel titleizeText:locationTitle
                                       bold:NO];
    [self.locationCaptionLabel titleizeText:self.locationCaptionLabel.text
                                       bold:YES];
    
    NSString *start = [self.relatedArticle objectForKey:@"starts_at"];
    NSDate *startTime = [Utilities dateFromRFCString:start];
    NSString *prettyDuration = @"";
    if ( [[self.relatedArticle objectForKey:@"is_all_day"] boolValue] ) {
      prettyDuration = @"All Day";
    } else {
      NSString *endTime = [self.relatedArticle objectForKey:@"ends_at"];
      NSDate *finish = [Utilities dateFromRFCString:endTime];
      NSString *formattedStart = [NSDate stringFromDate:startTime withFormat:@"h:mm a"];
      NSString *formattedEnd = [NSDate stringFromDate:finish withFormat:@"h:mm a"];
      
      formattedStart = [Utilities stripLeadingZero:formattedStart];
      formattedEnd = [Utilities stripLeadingZero:formattedEnd];
      
      prettyDuration = [NSString stringWithFormat:@"%@-%@",formattedStart,formattedEnd];
      
    }
    if ( self.liveEvent ) {
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
    
    [self.basicTemplate.byLine removeFromSuperview];
    [self.textSheetView addSubview:self.rsvpSeatView];
    
    self.rsvpButtonSeatView.layer.cornerRadius = 5.0;
    self.rsvpButtonSeatView.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
    
    BOOL videoAsset = [[ContentManager shared] storyHasYouTubeAsset:self.relatedArticle];
    if ( pc.category == ContentCategoryEvents ) {
      videoAsset = [[ScheduleManager shared] eventIsLive:self.relatedArticle];
    }
    
    if ( videoAsset ) {
      self.categorySeat.backgroundColor = [[DesignManager shared] auburnColor];
      [self.categoryLabel titleizeText:@"LIVE VIDEO"
                                 bold:YES];
      self.categorySeat.alpha = 1.0;
      
    } else {
      self.categorySeat.alpha = 0.0;
      
      self.basicTemplate.headLine.frame = CGRectMake(self.basicTemplate.headLine.frame.origin.x,
                                                     self.categorySeat.frame.origin.y,
                                                     self.basicTemplate.headLine.frame.size.width,
                                                     self.basicTemplate.headLine.frame.size.height);
    }
    
    if ( self.liveEvent || [Utilities pureNil:[self.relatedArticle objectForKey:@"rsvp_url"]]  ) {
      
      self.rsvpSeatView.frame = CGRectMake(0.0,self.basicTemplate.headLine.frame.origin.y+self.basicTemplate.headLine.frame.size.height,
                                           self.rsvpSeatView.frame.size.width,
                                           self.dateCaptionLabel.frame.origin.y+self.locationCaptionLabel.frame.origin.y+self.locationCaptionLabel.frame.size.height+self.dateCaptionLabel.frame.origin.y);
      
      self.rsvpButtonSeatView.alpha = 0.0;
      
      if ( noAsset || pushAssetIntoBody ) {
        [self.extraAssetsSeat removeFromSuperview];
        [self.textSheetView addSubview:self.extraAssetsSeat];
        
        [[DesignManager shared] alignRightOf:self.extraAssetsSeat
                                    withView:self.contentDividerLine];
        
        [[DesignManager shared] avoidNeighbor:self.contentDividerLine
                                     withView:self.extraAssetsSeat
                                    direction:NeighborDirectionBelow
                                      padding:10.0];
        
        [self.playOverlayButton removeFromSuperview];
        self.playOverlayButton.frame = CGRectMake(0.0, 0.0, self.extraAssetsSeat.frame.size.width,
                                                  self.extraAssetsSeat.frame.size.height);
        
        [self.extraAssetsSeat addSubview:self.playOverlayButton];
        [[DesignManager shared] globalSetImageTo:@"" forButton:self.playOverlayButton];
      }

    } else {
      
      self.rsvpSeatView.frame = CGRectMake(0.0,self.basicTemplate.headLine.frame.origin.y+self.basicTemplate.headLine.frame.size.height,
                 self.rsvpSeatView.frame.size.width,
                 self.rsvpSeatView.frame.size.height);
      

    }
    
    if ( [Utilities isLandscape] && !noAsset ) {
   
      [[DesignManager shared] avoidNeighbor:self.landscapeImageSheetView
                                     withView:self.webContentLoader.webView
                                    direction:NeighborDirectionAbove
                                      padding:0.0];
      CGFloat heightDiff = self.masterContentScroller.frame.size.height - (self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height)-self.landscapeImageSheetView.frame.size.height;
        
      self.webContentLoader.webView.frame = CGRectMake(self.webContentLoader.webView.frame.origin.x,
                                                         self.webContentLoader.webView.frame.origin.y,
                                                         self.webContentLoader.webView.frame.size.width,
                                                         heightDiff);
      
 
    } else {
    
      [[DesignManager shared] avoidNeighbor:self.rsvpSeatView
                                   withView:self.contentDividerLine
                                  direction:NeighborDirectionAbove
                                    padding:0.0];
      
      self.textSheetView.frame = CGRectMake(self.textSheetView.frame.origin.x,
                                            self.textSheetView.frame.origin.y,
                                            self.textSheetView.frame.size.width,
                                            self.contentDividerLine.frame.origin.y+self.contentDividerLine.frame.size.height);
      
      CGFloat heightDiff = self.masterContentScroller.frame.size.height - (self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height);
      self.webContentLoader.webView.frame = CGRectMake(self.webContentLoader.webView.frame.origin.x,
                                                       self.textSheetView.frame.origin.y+self.textSheetView.frame.size.height,
                                                       self.webContentLoader.webView.frame.size.width,
                                                       heightDiff);
    }
  }

  CGSize categorySize = [self.categoryLabel.text sizeOfStringWithFont:self.categoryLabel.font
                                                    constrainedToSize:CGSizeMake(self.categoryLabel.frame.size.width,self.categoryLabel.frame.size.height)];
  
  CGFloat anchor = noAsset ? 10.0 : self.categorySeat.frame.origin.y;
  self.categorySeat.frame = CGRectMake(self.categorySeat.frame.origin.x,
                                       anchor,
                                       self.categoryLabel.frame.origin.x+categorySize.width+self.categoryLabel.frame.origin.x,
                                       self.categorySeat.frame.size.height);
  
  self.originalWebViewHeight = self.webContentLoader.webView.frame;
  
  [self.webContentLoader setupWithArticle:self.relatedArticle
                                 delegate:self
                                pushAsset:pushAssetIntoBody
                               completion:^{

                               }];
}

- (void)photoVideoTreatment {
  SCPRSingleArticleCollectionViewController *pc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
  NSArray *assets = [self.relatedArticle objectForKey:@"assets"];
  NSDictionary *primary = nil;
  if ( [assets count] > 0 ) {
    primary = [assets objectAtIndex:0];
  }
  
  BOOL prime = NO;
  BOOL hasNative = [primary objectForKey:@"native"] != nil;
  
  if ( pc.category == ContentCategoryEvents ) {
    hasNative = [[ScheduleManager shared] eventIsLive:self.relatedArticle];
  }

  
  if ( hasNative ) {
    self.playOverlayButton.alpha = 1.0;
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playButtonSmall.png"]];
    self.extraAssetsImage.frame = iv.frame;
    self.extraAssetsImage.image = [UIImage imageNamed:@"playButtonSmall.png"];
    
    [[DesignManager shared] alignVerticalCenterOf:self.extraAssetsImage
                                         withView:self.extraAssetsLabel];
    
    [[DesignManager shared] avoidNeighbor:self.extraAssetsLabel
                                 withView:self.extraAssetsImage
                                direction:NeighborDirectionToRight
                                  padding:8.0];
    
    SCPRSingleArticleCollectionViewController *pc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
    NSString *videoText = pc.category == ContentCategoryEvents ? @"WATCH LIVE VIDEO" : @"PLAY VIDEO";
    [self.extraAssetsLabel titleizeText:videoText
                                   bold:NO];
    
    self.extraAssetsSeat.alpha = 1.0;
    [self.playOverlayButton addTarget:self
                               action:@selector(playVideo:)
                     forControlEvents:UIControlEventTouchUpInside];
    prime = YES;
    
    self.extraAssetsSeat.center = CGPointMake(self.basicTemplate.image1.frame.size.width/2.0,
                                              self.basicTemplate.image1.frame.size.height/2.0);
    
  } else {
    
    if ( [assets count] > 1 ) {
      
      self.playOverlayButton.alpha = 1.0;
      self.extraAssetsImage.image = [UIImage imageNamed:@"slideshow-icon.png"];
      
      [self.extraAssetsLabel titleizeText:[NSString stringWithFormat:@"SLIDESHOW : %d PHOTOS",[assets count]]
                                     bold:NO];
      
      self.extraAssetsSeat.alpha = 1.0;
      [self.playOverlayButton addTarget:self
                                 action:@selector(presentSlideshow:)
                       forControlEvents:UIControlEventTouchUpInside];
      prime = YES;
      
      CGFloat push = [Utilities isIpad] ? 170.0 : 60.0;
      self.extraAssetsSeat.center = CGPointMake(self.basicTemplate.image1.frame.size.width/2.0,
                                                self.basicTemplate.image1.frame.size.height/2.0+push);
      
      if ( [Utilities isLandscape] ) {
        [self.playOverlayButton removeFromSuperview];
        self.playOverlayButton.frame = CGRectMake(0.0,
                                                  0.0,
                                                  self.landscapeImageSheetView.frame.size.width,
                                                  self.landscapeImageSheetView.frame.size.height);
        [self.landscapeImageSheetView addSubview:self.playOverlayButton];
      }
    } else {
      if ( primary ) {
        [self armCaption:primary];
      }
      self.extraAssetsSeat.alpha = 0.0;
      self.playOverlayButton.alpha = 0.0;
    }
  }
  
  if ( prime ) {
    
    if ( [Utilities isLandscape] ) {
      [self.extraAssetsSeat removeFromSuperview];
      [self.landscapeImageSheetView addSubview:self.extraAssetsSeat];
    }
    
    CGSize tl = [self.extraAssetsLabel.text sizeOfStringWithFont:self.extraAssetsLabel.font
                 constrainedToSize:CGSizeMake(self.extraAssetsLabel.frame.size.width,
                                              self.extraAssetsLabel.frame.size.height)];
    
    CGFloat candidate = 3.0;
    if ( (int)(tl.width + 3.0) % 2 != 0 ) {
      candidate = 4.0;
    }
    
    self.extraAssetsLabel.frame = CGRectMake(self.extraAssetsLabel.frame.origin.x,
                                             self.extraAssetsLabel.frame.origin.y,
                                             ceilf(tl.width+candidate),
                                             self.extraAssetsLabel.frame.size.height);
    
    self.extraAssetsSeat.frame = CGRectMake(self.extraAssetsSeat.frame.origin.x,
                                            self.extraAssetsSeat.frame.origin.y,
                                            self.extraAssetsLabel.frame.origin.x+self.extraAssetsLabel.frame.size.width+self.extraAssetsImage.frame.origin.x,
                                            self.extraAssetsSeat.frame.size.height);
    
    if ( ![Utilities isLandscape] ) {
      [[DesignManager shared] alignHorizontalCenterOf:self.extraAssetsSeat
                                           withView:self.basicTemplate.image1];
    } else {
      self.extraAssetsSeat.center = CGPointMake(self.landscapeImageSheetView.frame.size.width/2.0,
                                                self.extraAssetsSeat.center.y);
      [self.landscapeImageSheetView bringSubviewToFront:self.playOverlayButton];
    }
    
  }
  
}

#pragma mark - Caption stuff
- (void)armCaption:(NSDictionary*)leadingAsset {

  self.captionButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.captionButton.frame = self.playOverlayButton.frame;
  [self.captionButton addTarget:self
                         action:@selector(showCaption:)
               forControlEvents:UIControlEventTouchUpInside];
  [self.masterContentScroller addSubview:self.captionButton];
  

  self.captionView.backgroundColor = [[DesignManager shared] frostedWindowColor:0.88];
  
  
  NSString *caption = [leadingAsset objectForKey:@"caption"];
  NSString *owner = [leadingAsset objectForKey:@"owner"];
  
  [self.captionCreditLabel titleizeText:owner
                                   bold:NO
   respectHeight:YES];
  
  self.captionCreditLabel.textColor = [[DesignManager shared] charcoalColor];
  
  [self.captionLabel titleizeText:caption
                             bold:NO
                    respectHeight:YES];
  
  [[DesignManager shared] avoidNeighbor:self.captionLabel
                               withView:self.captionCreditLabel
                              direction:NeighborDirectionAbove
                                padding:2.0];
  
  self.captionView.frame = CGRectMake(0.0, 0.0, self.captionView.frame.size.width,
                                      self.captionCreditLabel.frame.origin.y+self.captionCreditLabel.frame.size.height+self.captionLabel.frame.origin.y+2.0);
  
  self.captionView.alpha = 0.0;
  [self.masterContentScroller addSubview:self.captionView];
  
  [[DesignManager shared] avoidNeighbor:self.textSheetView
                               withView:self.captionView
                              direction:NeighborDirectionBelow
                                padding:20.0];
  
  [[DesignManager shared] alignHorizontalCenterOf:self.captionView
                                         withView:self.textSheetView];
}

- (void)showCaption:(id)sender {
  
  if ( self.captionUp ) {
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
    self.captionFadeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                             target:self
                                                           selector:@selector(fadeCaption)
                                                           userInfo:nil
                                                            repeats:NO];
  }];
}

- (void)fadeCaption {
  
  if ( self.captionFadeTimer ) {
    if ( [self.captionFadeTimer isValid] ) {
      [self.captionFadeTimer invalidate];
    }
    self.captionFadeTimer = nil;
  }
  
  if ( self.captionFadeTapper ) {
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
  SCPRAppDelegate *del = [Utilities del];
  self.floatingVideoController = [[SCPRFloatingEmbedViewController alloc]
                                  initWithNibName:[[DesignManager shared]
                                                   xibForPlatformWithName:@"SCPRFloatingEmbedViewController"]
                                  bundle:nil];
  
  
  self.floatingVideoController.fadeAudio = YES;
  [del cloakUIWithCustomView:self.floatingVideoController
                 dismissible:YES];
  [self.floatingVideoController setupWithPVArticle:self.relatedArticle];
}

- (void)postProcess {
  
  if ( self.postProcessed )
    return;

  [self handleMultipleAssets];
  self.postProcessed = YES;
}

- (void)adjustUIForQueue:(NSNotification*)note {

  if ( [[QueueManager shared] articleIsInQueue:self.relatedArticle] ) {
    if ( [[QueueManager shared] articleIsPlayingNow:self.relatedArticle] ) {
      
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
    if ( [[QueueManager shared] articleIsPlayingNow:self.relatedArticle] ) {
      
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

#pragma mark - Web Content Loader
- (BOOL)webContentReady {
  
  SCPRSingleArticleCollectionViewController *sacvc = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
  if ( sacvc ) {
    NSLog(@"Parent Collection not actually nil!");
  }
  return !sacvc.contentLock;
}

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

  if (![self.masterContentScroller.subviews containsObject:self.socialSheetView]) {
    [self.masterContentScroller addSubview:self.socialSheetView];
    [self.socialSheetView setFrame:CGRectMake(self.socialSheetView.frame.origin.x,
                                              self.masterContentScroller.contentSize.height - self.socialSheetView.frame.size.height,
                                              self.socialSheetView.frame.size.width,
                                              self.socialSheetView.frame.size.height)];
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
  
  // Resize Facebook count frame to fit its contents.
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
  
  // Space the twitter Logo 8px to right of vertical line divider.
  self.twitterLogoImage.frame = CGRectMake(self.socialLineDivider.frame.origin.x + 8,
                                           self.twitterLogoImage.frame.origin.y,
                                           self.twitterLogoImage.frame.size.width,
                                           self.twitterLogoImage.frame.size.height);
  
  // Position the twitter count label 20px to right of twitter logo.
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

  [self refreshHeight];
}

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
  
  if ( [self.relatedArticle objectForKey:@"rsvp_url"] ) {
    [[[Utilities del] globalTitleBar] applyBackButtonText:@"Live Events"];
  }
  
  if ( self.parentCollection ) {
    SCPRSingleArticleCollectionViewController *collection = (SCPRSingleArticleCollectionViewController*)self.parentCollection;
    [collection.navigationController pushViewController:external animated:YES];
    external.backContainer = collection;
  } else {
    [self.navigationController pushViewController:external animated:YES];
  }
  
  external.view.frame = external.view.frame;
  
  if ( [Utilities isIOS7] ) {
    external.webContentView.frame = CGRectMake(external.webContentView.frame.origin.x,
                                               external.webContentView.frame.origin.y+40.0,
                                               external.webContentView.frame.size.width,
                                               external.webContentView.frame.size.height-20.0);
  }
  
  [external prime:request];
  
  self.externalContent = external;
  
  external.bensOffbrandButton = [[[Utilities del] globalTitleBar] parserOrFullButton];
  
  [external.bensOffbrandButton addTarget:external
                                  action:@selector(buttonTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
  
  [[ContentManager shared] setUserIsViewingExpandedDetails:YES];
  
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
  self.armoireController = nil;
  self.extraAssetsController = nil;
  self.parentCollection = nil;
  self.leftFlap = nil;
  self.rightFlap = nil;

  [self.view removeFromSuperview];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  self.okToDelete = YES;
  [[ContentManager shared] popDeactivation:self.deactivationToken];
  
}

- (NSDictionary*)associatedArticleContent {
  return self.relatedArticle;
}

- (void)refreshHeight {
  [self snapToContentHeight];
}

- (void)snapToContentHeight {
  NSString *output = [self.webContentLoader.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"container\").offsetHeight;"];
  CGFloat webHeight = fmaxf([output floatValue],self.originalWebViewHeight.size.height);
  
  CGFloat totalHeight = webHeight;
  if ( [Utilities articleHasAsset:self.relatedArticle] ) {
    if ( [Utilities isLandscape] ) {
      if ( !self.shortPage ) {
        totalHeight += self.landscapeImageSheetView.frame.size.height;
      }
    } else {
      // Only increase totalHeight if article has an image loaded in the top template.
      if ([self.basicTemplate.image1 frameForImage].size.height > 0) {
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
    totalHeight += 80.0;
    webHeight +=  80.0;
  }

  self.webContentLoader.webView.frame = CGRectMake(self.webContentLoader.webView.frame.origin.x,
                                                   self.webContentLoader.webView.frame.origin.y,
                                                   self.webContentLoader.webView.frame.size.width,
                                                   webHeight + 150.0);
  
  self.webContentLoader.webView.scrollView.scrollEnabled = NO;

  self.masterContentScroller.contentSize = CGSizeMake(self.masterContentScroller.frame.size.width,
                                                      totalHeight + 150.0);
  
  self.masterContentScroller.frame = CGRectMake(self.masterContentScroller.frame.origin.x,
                                                self.masterContentScroller.frame.origin.y,
                                                self.masterContentScroller.frame.size.width,
                                                self.masterContentScroller.frame.size.height);
  
  if (self.hasSocialData) {
    // Place the social sheetview below the article's contents and embeds
    CGFloat socialSheetVertAdjust = 30.0;
    if (![Utilities isIOS7]) {
      socialSheetVertAdjust += 30.0;
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

- (void)handleDelayedLoad {
  if ( !self.initialLoadFinished ) {
    if ( self.webContentLoader.queuedContentString ) {
      [self.webContentLoader setupWithArticle:self.relatedArticle
                                   delegate:self];
    }
  }
}

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  [self.navigationController popViewControllerAnimated:YES];
}

- (NSString*)smartSplit:(NSString *)fullString givenLabel:(UILabel *)label {
  
  CGSize s = [fullString sizeOfStringWithFont:label.font
                     constrainedToSize:CGSizeMake(label.frame.size.width,
                                                  MAXFLOAT)];
  
  CGFloat ratio = label.frame.size.height / s.height;
  
  if ( ratio >= 1.0 ) {
    return fullString;
  }
  
  NSInteger count = [fullString length];
  NSInteger splitIndex = ceil(count*ratio);
  unichar whitespace = 'z';
  while ( ![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[fullString characterAtIndex:splitIndex]] && splitIndex >= 0 && splitIndex != count-1 ) {
    whitespace = [fullString characterAtIndex:splitIndex];
    splitIndex--;
  }
  
  NSString *properCut = [fullString substringToIndex:splitIndex];
  return properCut;
  
}

- (BOOL)shouldAutorotate {
  return YES;
}


#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  
  NSLog(@"DEALLOCATING SINGLE ARTICLE VIEW CONTROLLER...");
  
}
#endif

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

@end
