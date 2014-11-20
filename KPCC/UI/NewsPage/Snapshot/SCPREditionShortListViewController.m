//
//  SCPREditionShortListViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 10/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREditionShortListViewController.h"
#import "global.h"
#import "SCPREditionMoleculeViewController.h"
#import "SCPRTitlebarViewController.h"
#import "SCPREditionMineralViewController.h"

@interface SCPREditionShortListViewController ()

@end

@implementation SCPREditionShortListViewController

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
  
  [self.view setAccessibilityLabel:@"The Short List Table of Contents"];
  [self.drillDownButton setAccessibilityLabel:@"Go to The Short List"];
  [self.readMoreButton setAccessibilityLabel:@"Go to The Short List"];
  
    // Do any additional setup after loading the view from its nib.
}

- (void)prime {
  
  self.spinner.alpha = 0.0;
  

  
  if ( !self.numberOfStoriesSeat ) {
    self.view.frame = self.view.frame;
  }
  
  self.numberOfStoriesSeat.backgroundColor = [[DesignManager shared] kpccOrangeColor];
  
  [self.shortListTitleLabel sansifyTitleText:@"THE SHORT LIST"
                                        bold:YES
                               respectHeight:YES
                                    centered:![Utilities isLandscape]];
  
  [self.plusLabel italicizeText:@"Plus:"
                           bold:YES
                  respectHeight:NO];
  self.plusLabel.textColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.readMoreButton.titleLabel.font.pointSize]
                                forButton:self.readMoreButton];
  
  self.readMoreSeat.layer.cornerRadius = 2.0;
  self.readMoreSeat.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  self.dividerLine.strokeColor = [[DesignManager shared] transparentWhiteColor];
  
  self.leadAssetImage.clipsToBounds = YES;
  

}

- (void)shrink {
  self.leadAssetImage.frame = CGRectMake(self.leadAssetImage.frame.origin.x,
                                                             self.leadAssetImage.frame.origin.y,
                                                             self.leadAssetImage.frame.size.width,
                                                             self.cruxView.frame.size.height);
}

- (void)pushTitleUp {
  self.shortListTitleLabel.center = CGPointMake(self.shortListTitleLabel.center.x,
                                                self.shortListTitleLabel.center.y-30.0);
}

- (void)setupWithEdition:(NSDictionary *)edition {
  
  [self prime];
  
  self.readMoreSeat.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:0.8];
  self.edition = edition;
  NSArray *abstracts = [self.edition objectForKey:@"abstracts"];
  NSDictionary *lead = [abstracts objectAtIndex:0];
  
  NSString *asset = [Utilities extractImageURLFromBlob:lead
                                               quality:AssetQualityFull
                                          forceQuality:YES];
  [self.leadAssetImage loadImage:asset];
  [self.numberOfStoriesLabel titleizeText:[NSString stringWithFormat:@"%d STORIES",[abstracts count]]
                                     bold:YES];
  [self.leadStoryHeadlineLabel sansifyTitleText:[lead objectForKey:@"headline"]
                                           bold:YES
                                  respectHeight:YES];
  
  [[DesignManager shared] avoidNeighbor:self.shortListTitleLabel
                               withView:self.timestampLabel
                              direction:NeighborDirectionAbove
                                padding:3.0];
  
  
  NSString *pa = [self.edition objectForKey:@"published_at"];
  NSDate *published = [Utilities dateFromRFCString:pa];
  NSString *slKey = @"edition_type";
  
  
  NSString *shortListSpecificTitle = @"";

  
  if ( [self.edition objectForKey:slKey] && ![Utilities pureNil:[self.edition objectForKey:slKey]] ) {
    shortListSpecificTitle = [NSString stringWithFormat:@"%@",[self.edition objectForKey:slKey]];
  } else {
    NSString *tod = [[ScheduleManager shared] determineTypeByDate:published];
    shortListSpecificTitle = [NSString stringWithFormat:@"%@",tod];
  }
  
  NSString *timeString = [Utilities specialMonthDayFormatFromDate:published];
  
  NSString *finishedTimeString = [NSString stringWithFormat:@"%@ • %@",shortListSpecificTitle,timeString];
  if ( self.fromNews ) {
    finishedTimeString = shortListSpecificTitle;
  }
  
  [self.timestampLabel titleizeText:[finishedTimeString uppercaseString]
                               bold:NO];
  
  self.timestampLabel.textAlignment = [Utilities isLandscape] ? NSTextAlignmentLeft : NSTextAlignmentCenter;
  
  CGFloat squeeze = [Utilities isIpad] ? 1.0 : 0.25;
  if ( ![Utilities isLandscape] ) {
    [[DesignManager shared] alignHorizontalCenterOf:self.timestampLabel
                                           withView:self.leadAssetImage];
    [[DesignManager shared] alignHorizontalCenterOf:self.shortListTitleLabel
                                           withView:self.leadAssetImage];
    
    CGFloat push = self.fromNews ? 139.0 : 209.0;
    push = [Utilities isIpad] ? push : push*squeeze;
    
    [[DesignManager shared] avoidNeighbor:self.timestampLabel
                                 withView:self.leadStorySeatView
                                direction:NeighborDirectionAbove
                                  padding:push];
      
  } else {
    
    CGFloat push = self.fromNews ? 2.0 : 10.0;
    UIView *toUse = self.fromNews ? self.timestampLabel : self.timestampLabel;
    [[DesignManager shared] avoidNeighbor:toUse
                                 withView:self.leadStorySeatView
                                direction:NeighborDirectionAbove
                                  padding:push];
    
    [[DesignManager shared] avoidNeighbor:self.leadStorySeatView
                                 withView:self.additionalSeat
                                direction:NeighborDirectionAbove
                                  padding:0.0];
    
    [[DesignManager shared] alignLeftOf:self.timestampLabel
                               withView:self.numberOfStoriesSeat];
    [[DesignManager shared] alignLeftOf:self.shortListTitleLabel
                               withView:self.numberOfStoriesSeat];
  }
  
  
  CGFloat s1 = [Utilities isIpad] ? 16.0 : 4.0;
  [[DesignManager shared] avoidNeighbor:self.numberOfStoriesSeat
                               withView:self.leadStoryHeadlineLabel
                              direction:NeighborDirectionAbove
                                padding:s1];
  
  CGFloat s2 = [Utilities isIpad] ? 12.0: 5.0;
  [[DesignManager shared] avoidNeighbor:self.leadStoryHeadlineLabel
                               withView:self.dividerLine
                              direction:NeighborDirectionAbove
                                padding:s2];
  
  CGFloat adPush = [Utilities isLandscape] ? 10.0 : 5.0;
  adPush = [Utilities isIpad] ? adPush : adPush*squeeze;
  [[DesignManager shared] avoidNeighbor:self.leadStorySeatView
                               withView:self.additionalSeat
                              direction:NeighborDirectionAbove
                                padding:adPush];
  
#ifdef DEBUG
  //self.additionalSeat.backgroundColor = [UIColor magentaColor];
  //self.leadStorySeatView.backgroundColor = [UIColor purpleColor];
#endif
  
  if ( !self.fromNews ) {
    
    CGFloat workableSpace = self.view.frame.size.height-(self.leadStorySeatView.frame.origin.y+self.leadStorySeatView.frame.size.height);
    self.additionalSeat.frame = CGRectMake(self.additionalSeat.frame.origin.x,
                                           self.additionalSeat.frame.origin.y,
                                           self.additionalSeat.frame.size.width,
                                           workableSpace);
    
    CGFloat pull = [Utilities isIOS7] ? 50.0 : 60.0;
    
    self.readMoreSeat.frame = CGRectMake(self.readMoreSeat.frame.origin.x,
                                         self.additionalSeat.frame.size.height-pull-self.readMoreSeat.frame.size.height,
                                         self.readMoreSeat.frame.size.width,
                                         self.readMoreSeat.frame.size.height);
    
    CGFloat revisedWorkableSpace = self.readMoreSeat.frame.origin.y-(self.plusLabel.frame.origin.y+self.plusLabel.frame.size.height+20.0);
    
    self.moreStoriesListLabel.frame = CGRectMake(self.moreStoriesListLabel.frame.origin.x,
                                                 self.moreStoriesListLabel.frame.origin.y,
                                                 self.moreStoriesListLabel.frame.size.width,
                                                 revisedWorkableSpace);
    
    
    
  } else {
    
    CGFloat pushDown = [Utilities isLandscape] ? 10.0 : 40.0;
    pushDown = [Utilities isIpad] ? pushDown : pushDown*squeeze;
    
    if ( ![Utilities isIOS7] ) {
      pushDown = 20.0;
    }
    
    [[DesignManager shared] avoidNeighbor:self.moreStoriesListLabel
                                 withView:self.readMoreSeat
                                direction:NeighborDirectionAbove
                                  padding:pushDown];
  }
  
  self.leadStorySeatView.frame = CGRectMake(self.leadStorySeatView.frame.origin.x,
                                            self.leadStorySeatView.frame.origin.y,
                                            self.leadStorySeatView.frame.size.width,
                                            self.dividerLine.frame.origin.y+self.dividerLine.frame.size.height+10.0);
  

  
  [[DesignManager shared] alignLeftOf:self.readMoreSeat
                             withView:self.plusLabel];
  
  [[DesignManager shared] avoidNeighbor:self.leadStorySeatView
                               withView:self.additionalSeat
                              direction:NeighborDirectionAbove
                                padding:12.0];
  
  
  if ( !self.fromNews ) {
    [self.drillDownButton addTarget:self
                             action:@selector(proxyPush)
                   forControlEvents:UIControlEventTouchUpInside];
    
    [self.readMoreButton addTarget:self
                            action:@selector(proxyPush)
                  forControlEvents:UIControlEventTouchUpInside];
  }
  
  NSString *combo = [self buildList:self.edition];
  [self.moreStoriesListLabel titleizeText:combo
                                     bold:NO
                            respectHeight:YES];
  
  if ( ![Utilities isIOS7] ) {
    self.moreStoriesListLabel.frame = CGRectInset(self.moreStoriesListLabel.frame,
                                                  0.0, -3.0);
  }
  
  CGFloat avoidPlur = [Utilities isIOS7] ? 2.0 : 6.0;
  [[DesignManager shared] avoidNeighbor:self.plusLabel
                               withView:self.moreStoriesListLabel
                              direction:NeighborDirectionAbove
                                padding:avoidPlur];
  
  [self shrinkStoriesBox];
  
  if ( ![Utilities isIOS7] ) {
    if ( self.fromNews ) {
      self.leadAssetImage.frame = CGRectMake(0.0, 0.0, self.leadAssetImage.frame.size.width, self.cruxView.frame.size.height);
    }
  }
  
  [[DesignManager shared] alignVerticalCenterOf:self.spinner
                                       withView:self.readMoreSeat];
  
  [[DesignManager shared] avoidNeighbor:self.readMoreSeat
                               withView:self.spinner
                              direction:NeighborDirectionToLeft
                                padding:10.0];
  
}

- (void)shrinkStoriesBox {
  
  CGFloat padding = 4.0;
  CGSize s = [self.numberOfStoriesLabel.text sizeOfStringWithFont:self.numberOfStoriesLabel.font
                                                constrainedToSize:CGSizeMake(MAXFLOAT,self.numberOfStoriesLabel.frame.size.height)];
  self.numberOfStoriesLabel.frame = CGRectMake(padding,self.numberOfStoriesLabel.frame.origin.y,
                                               s.width+2.0,
                                               self.numberOfStoriesLabel.frame.size.height);
  self.numberOfStoriesSeat.frame = CGRectMake(self.numberOfStoriesSeat.frame.origin.x,
                                              self.numberOfStoriesSeat.frame.origin.y,
                                              padding+self.numberOfStoriesLabel.frame.size.width+padding,
                                              self.numberOfStoriesSeat.frame.size.height);
}

- (void)proxyPush {
  [self.spinner startAnimating];
  [UIView animateWithDuration:0.22 animations:^{
    self.spinner.alpha = 1.0;
  } completion:^(BOOL finished) {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(hideSpinner)
                                                name:@"editions_finished_building"
                                              object:nil];
    [self pushToMolecule:0];
  }];
}

- (void)hideSpinner {
  
  [[NSNotificationCenter defaultCenter]
   removeObserver:self
   name:@"editions_finished_building"
   object:nil];
  
  self.spinner.alpha = 0.0;
}

- (void)pushToMolecule:(NSInteger)atomIndex {
  SCPREditionMoleculeViewController *emvc = [[SCPREditionMoleculeViewController alloc]
                                             initWithNibName:[[DesignManager shared]
                                                              xibForPlatformWithName:@"SCPREditionMoleculeViewController"]
                                             bundle:nil];
  
  emvc.view.frame = emvc.view.frame;
  emvc.parentEditionContentViewController = self;
  
  
  [[[Utilities del] globalTitleBar] morph:BarTypeEditions
                                container:emvc];
  
  [emvc setupWithEdition:self.edition
                andIndex:atomIndex];
  
  self.pushedContent = emvc;
  self.pushedAtomIndex = atomIndex;
  
  UIViewController *mineral = (UIViewController*)self.parentMineral;
  [(SCPREditionMineralViewController*)mineral setMoleculePushed:YES];
  
  [mineral.navigationController pushViewController:emvc
                                          animated:YES];
  
  [[ContentManager shared] pushToResizeVector:emvc];
}

- (NSString*)buildList:(NSDictionary *)edition {
  
  NSArray *abstracts = [self.edition objectForKey:@"abstracts"];
  NSString *finished = @"";
  
  int max = [Utilities isLandscape] ? 7 : 5;
  if ( !self.fromNews ) {
    if ( ![Utilities isLandscape] ) {
      max = 7;
    }
  } else {
    if ( [Utilities isLandscape] ) {
      max = 6;
    }
  }
  
  
  if ( !self.fromNews ) {
    if ( ![Utilities isIpad] ) {
      max = 3;
    }
  }
  
  for ( unsigned i = 0; i < [abstracts count]; i++ ) {
    if ( i == 0 ) {
      continue;
    }
    
    if ( i == max ) {
      NSInteger diff = [abstracts count] - max;
      
      NSString *suffix = diff == 1 ? @"y" : @"ies";
      NSString *append = [NSString stringWithFormat:@"\n\n• %d more stor%@...",diff,suffix];
      finished = [finished stringByAppendingString:append];
      return finished;
    }
    
    if ( i > 1 ) {
      finished = [finished stringByAppendingString:@"\n\n"];
    }
    
    NSDictionary *abstract = [abstracts objectAtIndex:i];
    NSString *append = [NSString stringWithFormat:@"• %@",[abstract objectForKey:@"headline"]];
    finished = [finished stringByAppendingString:append];

  }
  
  return finished;
  
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"**** DEALLOCATING SHORT LIST ****");
  
  [[NSNotificationCenter defaultCenter]
   removeObserver:self];
}
#endif


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
