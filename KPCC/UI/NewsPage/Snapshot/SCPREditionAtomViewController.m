//
//  SCPREditionAtomViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 7/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREditionAtomViewController.h"
#import "SCPRTitlebarViewController.h"
#import "SCPRSingleArticleViewController.h"
#import "global.h"
#import "SCPREditionMoleculeViewController.h"
#import "SCPRPlayerWidgetViewController.h"

@interface SCPREditionAtomViewController ()

@end

@implementation SCPREditionAtomViewController

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
  
  self.view.backgroundColor = [UIColor blackColor];
  self.photoCaptionSeat.alpha = 0.0;
  self.photoCaptionSeat.backgroundColor = [[DesignManager shared] frostedWindowColor:0.88];
  self.photoCaptionLabel.textColor = [[DesignManager shared] deepOnyxColor];
  self.blueStripeView.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  
    // Do any additional setup after loading the view from its nib.
}



- (void)mergeWithArticle {
  
  NSString *source = [self.relatedArticle objectForKey:@"source"];
  CGFloat iconPadding = 0.0;
  if ( [self isKPCCArticle] ) {
    
    iconPadding = 10.0;
    self.trustedSource = YES;
    [[DesignManager shared] globalSetTitleTo:[NSString stringWithFormat:@"READ FULL STORY"]
                                   forButton:self.expandButton];


    
    /*[[DesignManager shared] globalSetImageTo:@"icon-abstract-view-kpccarticle.png"
                                   forButton:self.expandButton];*/
    
    self.buttonIcon.image = [UIImage imageNamed:@"icon-abstract-view-kpccarticle.png"];
  } else {
    
    iconPadding = 8.0;
    self.trustedSource = NO;
    
    NSString *dynamic = [NSString stringWithFormat:@"READ FULL STORY AT %@",[source uppercaseString]];
    [[DesignManager shared] globalSetTitleTo:dynamic
                                 forButton:self.expandButton];
    

    /*[[DesignManager shared] globalSetImageTo:@"icon-abstract-view-externalarticle.png"
                                   forButton:self.expandButton];*/
    self.buttonIcon.image = [UIImage imageNamed:@"icon-abstract-view-externalarticle.png"];
  }
  
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] turquoiseCrystalColor:1.0]
                                     forButton:self.expandButton];
  

  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared]
                                           latoLight:self.expandButton.titleLabel.font.pointSize]
                                forButton:self.expandButton];
  
  iconPadding = [Utilities isIpad] ? iconPadding : 18.0;
  if ( !self.trustedSource ) {
    if ( ![Utilities isIpad] ) {
      iconPadding = 10.0;
    }
  }

  
  self.view.frame = self.view.frame;
  
  self.splashImageView.clipsToBounds = YES;
  NSString *imageURL = [Utilities extractImageURLFromBlob:self.relatedArticle
                                                  quality:AssetQualityFull
                        forceQuality:YES];
  [self.splashImageView loadImage:imageURL];
  
  self.suppressCaption = YES;
  NSArray *assets = [self.relatedArticle objectForKey:@"assets"];
  if ( assets && [assets count] > 0 ) {
    NSDictionary *leadImage = [assets objectAtIndex:0];
    if ( leadImage ) {
      NSString *caption = [leadImage objectForKey:@"caption"];
      NSString *title = [leadImage objectForKey:@"title"];
      NSString *owner = [leadImage objectForKey:@"owner"];
      
      if ( [Utilities pureNil:caption] ) {
        if ( ![Utilities pureNil:title] ) {
          caption = title;
        } else {
          if ( ![Utilities pureNil:owner] ) {
            caption = owner;
          }
        }
      } else {
        if ( ![Utilities pureNil:title] ) {
          caption = [NSString stringWithFormat:@"%@: %@",title,caption];
        }
        if ( ![Utilities pureNil:owner] ) {
          caption = [NSString stringWithFormat:@"%@ - %@",caption,owner];
        }
      }
      
      if ( ![Utilities pureNil:owner] ) {
        [self.photoCaptionLabel titleizeText:owner
                                        bold:YES
         respectHeight:YES];
        
        self.photoCaptionSeat.frame = CGRectMake(self.photoCaptionSeat.frame.origin.x,
                                                 self.photoCaptionSeat.frame.origin.y,
                                                 self.photoCaptionSeat.frame.size.width,
                                                 self.photoCaptionLabel.frame.origin.y+self.photoCaptionLabel.frame.size.height+self.photoCaptionLabel.frame.origin.y);
        
        if ( [Utilities isIpad] ) {

          [[DesignManager shared] avoidNeighbor:self.detailsSeatView
                                       withView:self.photoCaptionSeat
                                      direction:NeighborDirectionBelow
                                        padding:10.0];
        } else {
          [[DesignManager shared] avoidNeighbor:self.bottomGradient
                                       withView:self.photoCaptionSeat
                                      direction:NeighborDirectionBelow
                                        padding:10.0];
          
        }
        
        self.suppressCaption = NO;
      }
    }
  }
  
  
  [self.headlineLabel sansifyTitleText:[Utilities unwebbifyString:[self.relatedArticle objectForKey:@"headline"] respectLinebreaks:YES]
                                  bold:YES
                         respectHeight:YES
                              centered:NO];
  
  CGFloat bottomIndex = self.headlineLabel.frame.origin.y+self.headlineLabel.frame.size.height;
  CGFloat diff = self.edgeDivider.frame.origin.y-bottomIndex-10.0;
  self.blurbLabel.frame = CGRectMake(self.blurbLabel.frame.origin.x,
                                     bottomIndex,
                                     self.blurbLabel.frame.size.width,
                                     diff);

  
  NSString *blurbText = [Utilities unwebbifyString:[self.relatedArticle objectForKey:@"summary"]
                                 respectLinebreaks:YES];
  
  [self.blurbLabel standardizeText:blurbText
                              bold:NO
                     respectHeight:YES
                          withFont:@"PTSerif-Regular"
                   verticalFanning:3.0
                    clipParagraphs:YES];
  
  CGFloat avg = (diff + self.blurbLabel.frame.size.height)/2.0;
  self.blurbLabel.frame = CGRectMake(self.blurbLabel.frame.origin.x,
                                     bottomIndex,
                                     self.blurbLabel.frame.size.width,
                                     avg);
  
  [self.blurbLabel setTextColor:[[DesignManager shared] color:@[ @58.0, @59.0, @61.0]]];
  
  self.detailsSeatView.backgroundColor = [UIColor whiteColor];
 
  
  if ( UIDeviceOrientationIsLandscape(self.interfaceOrientation) ) {
    /*self.detailsSeatView.center = CGPointMake(self.detailsSeatView.center.x,
                                              self.detailsSeatView.center.y-200.0);*/
  }
  
  if ( ![Utilities isIpad] ) {
    self.iphoneScroller.contentSize = CGSizeMake(self.iphoneScroller.frame.size.width,
                                                 self.detailsSeatView.frame.size.height);
  }
}

- (BOOL)isKPCCArticle {
  return [[ContentManager shared] isKPCCArticle:self.relatedArticle];
}

- (IBAction)buttonTapped:(id)sender {
  
  if (sender == self.expandButton || sender == self.altTriggerButton || sender == self.secondaryExpandButton ) {

    if (![self isKPCCArticle]) {
      NSString *url = [self.relatedArticle objectForKey:@"url"];
      NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
      SCPRExternalWebContentViewController *external = [[SCPRExternalWebContentViewController alloc]
                                                      initWithNibName:[[DesignManager shared]
                                                                       xibForPlatformWithName:@"SCPRExternalWebContentViewController"]
                                                      bundle:nil];
      SCPREditionMoleculeViewController *molecule = (SCPREditionMoleculeViewController*)self.parentMolecule;
      external.fromEditions = !molecule.fromNewsPage;
      external.view.frame = external.view.frame;
      external.supplementalContainer = self;
      
      if ([Utilities isIOS7]) {
        CGFloat adjuster = [Utilities isLandscape] ? 20.0 : 20.0;
        external.webContentView.frame = CGRectMake(external.webContentView.frame.origin.x,
                                                   external.webContentView.frame.origin.y + 40.0,
                                                   external.webContentView.frame.size.width,
                                                   external.webContentView.frame.size.height - adjuster);
      }
      
      [[[Utilities del] globalTitleBar] morph:BarTypeExternalWeb container:external];
      [molecule.navigationController pushViewController:external animated:YES];
      [external prime:request];
      
      if (self.externalContent) {
        SCPRExternalWebContentViewController *prev = (SCPRExternalWebContentViewController*)self.externalContent;
        [prev.bensOffbrandButton removeTarget:prev
                                       action:@selector(buttonTapped:)
                             forControlEvents:UIControlEventTouchUpInside];
        self.externalContent = nil;
      }
      
      self.externalContent = external;
      external.bensOffbrandButton = [[[Utilities del] globalTitleBar] parserOrFullButton];
      [external.bensOffbrandButton addTarget:external
                                    action:@selector(buttonTapped:)
                          forControlEvents:UIControlEventTouchUpInside];
    } else {
      [[NetworkManager shared] fetchContentForSingleArticle:[self.relatedArticle objectForKey:@"url"]
                                                    display:self];
      NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:self.relatedArticle] mutableCopy];      
      [[AnalyticsManager shared] logEvent:@"tap_abstract"
                           withParameters:params];
    }
  
    [[ContentManager shared] setUserIsViewingExpandedDetails:YES];
    
    NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:self.relatedArticle] mutableCopy];
    [params setObject:[NSDate stringFromDate:[NSDate date]
                                  withFormat:@"MMM dd, YYYY HH:mm"]
               forKey:@"date"];
    [params setObject:@"Editions" forKey:@"accessed_from"];
    [params setObject: ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO" forKey:@"audio_on"];
    [[AnalyticsManager shared] logEvent:@"story_read" withParameters:params];
  }

  if ( sender == self.captionButton ) {
    if ( self.suppressCaption ) {
      return;
    }
    
    if ( self.captionShowing ) {
      [self fadePhotoCaption];
    } else {
    
      [UIView animateWithDuration:0.5 animations:^{
        self.photoCaptionSeat.alpha = 1.0;
        if ( ![Utilities isIpad] ) {
          SCPREditionMoleculeViewController *m = (SCPREditionMoleculeViewController*)self.parentMolecule;
          [m.infoSeatView setAlpha:0.0];
          self.detailsSeatView.alpha = 0.0;
          SCPRTitlebarViewController *tbvc = [[Utilities del] globalTitleBar];
          tbvc.view.alpha = 0.0;
          self.iphoneScroller.alpha = 0.0;
          self.topGradient.alpha = 0.0;
          SCPRPlayerWidgetViewController *pvc = [[Utilities del] globalPlayer];
          pvc.view.alpha = 0.0;
          
        }
      } completion:^(BOOL finished) {
        SCPREditionMoleculeViewController *m = (SCPREditionMoleculeViewController*)self.parentMolecule;
        m.scroller.scrollEnabled = NO;
        
        self.captionTapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(fadePhotoCaption)];
        self.captionShowing = YES;
        [self.view addGestureRecognizer:self.captionTapper];
        self.photoCaptionTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                                target:self
                                                              selector:@selector(fadePhotoCaption)
                                                              userInfo:nil
                                                               repeats:NO];
      }];
      
    }
  }
}

- (void)fadePhotoCaption {
  
  if ( self.photoCaptionTimer ) {
    if ( [self.photoCaptionTimer isValid] ) {
      [self.photoCaptionTimer invalidate];
    }
    self.photoCaptionTimer = nil;
  }
  
  [UIView animateWithDuration:0.5 animations:^{
    self.photoCaptionSeat.alpha = 0.0;
    if ( ![Utilities isIpad] ) {
      SCPREditionMoleculeViewController *m = (SCPREditionMoleculeViewController*)self.parentMolecule;
      [m.infoSeatView setAlpha:1.0];
      self.detailsSeatView.alpha = 1.0;
      SCPRTitlebarViewController *tbvc = [[Utilities del] globalTitleBar];
      tbvc.view.alpha = 1.0;
      self.topGradient.alpha = 1.0;
      self.iphoneScroller.alpha = 1.0;
      SCPRPlayerWidgetViewController *pvc = [[Utilities del] globalPlayer];
      pvc.view.alpha = 1.0;
    }
  } completion:^(BOOL finished) {
    [self.view removeGestureRecognizer:self.captionTapper];
    self.captionTapper = nil;
    self.captionShowing = NO;
    SCPREditionMoleculeViewController *m = (SCPREditionMoleculeViewController*)self.parentMolecule;
    m.scroller.scrollEnabled = YES;
  }];
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  if ( [content count] > 0 ) {
    self.nativeArticle = [content objectAtIndex:0];
    NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");
    
    SCPRSingleArticleViewController *sac = [[SCPRSingleArticleViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                     xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                                                                                             bundle:nil];
    sac.fromSnapshot = YES;
    sac.relatedArticle = self.nativeArticle;
    sac.wantsFullScreenLayout = YES;
    sac.parentEditionAtom = self;
    self.internalContent = sac;
    
    SCPREditionMoleculeViewController *molecule = (SCPREditionMoleculeViewController*)self.parentMolecule;
    BOOL animated = YES;
    if ( [molecule intermediaryAppearance] ) {
      animated = NO;
      [molecule setIntermediaryAppearance:NO];
    }
    [molecule.navigationController pushViewController:sac animated:animated];
    [sac arrangeContent];

    [[ContentManager shared] pushToResizeVector:sac];
    [[ContentManager shared] setFocusedContentObject:self.nativeArticle];
  
    [[[Utilities del] globalTitleBar] morph:BarTypeModal container:sac];
    
    [[[Utilities del] globalTitleBar] applyBackButtonText:@"Summary"];
  }
}

- (void)contentFinishedDisplaying {
  self.externalContent = nil;
  self.internalContent = nil;
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING EDITION ATOM...");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
