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

  
  [self.timestampLabel titleizeText:[finishedTimeString uppercaseString]
                               bold:NO];
  
  if ( !self.fromNews ) {
    [self.drillDownButton addTarget:self
                             action:@selector(proxyPush)
                   forControlEvents:UIControlEventTouchUpInside];
    
    [self.readMoreButton addTarget:self
                            action:@selector(proxyPush)
                  forControlEvents:UIControlEventTouchUpInside];
  } else {
    finishedTimeString = shortListSpecificTitle;
  }
  
  [self refresh];
  
  NSString *combo = [self buildList:self.edition];
  [self.moreStoriesListLabel titleizeText:combo
                                     bold:NO
                            respectHeight:YES];
  
}

- (void)refresh {
  self.headlineLabelAnchor.constant = 30.0;
  self.timestampLabel.textAlignment = [Utilities isLandscape] ? NSTextAlignmentLeft : NSTextAlignmentCenter;
  self.shortListTitleLabel.textAlignment = [Utilities isLandscape] ? NSTextAlignmentLeft : NSTextAlignmentCenter;
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
