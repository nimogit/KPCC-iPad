//
//  SCPREditionCrystalViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 4/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREditionCrystalViewController.h"
#import "global.h"
#import "SCPRViewController.h"
#import "NSDate+Helper.h"
#import "SCPRExternalWebContentViewController.h"
#import "SCPRSingleArticleViewController.h"
#import "SCPRLogoGeneratorViewController.h"
#import "SCPREditionAtomViewController.h"
#import "SCPREditionMoleculeViewController.h"
#import "SCPRGrayLineView.h"

@interface SCPREditionCrystalViewController ()

@end

@implementation SCPREditionCrystalViewController

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
    // Do any additional setup after loading the view from its nib.
  
  self.cellHash = [[NSMutableDictionary alloc] init];
  self.featureContent.aspectCode = @"SingleArticle";
  self.featureContent.image1.clipsToBounds = YES;
  //self.summaryTableView.scrollEnabled = NO;
  
  self.summaryTableView.backgroundColor = [UIColor clearColor];
  self.summaryTableView.backgroundView.backgroundColor = [UIColor clearColor];
  
  self.masterContent = [self.snapshotContent objectAtIndex:0];
  self.snapshotDate = [Utilities dateFromRFCString:[self.masterContent objectForKey:@"published_at"]];
  self.snapshotContent = [[self.snapshotContent objectAtIndex:0] objectForKey:@"abstracts"];

  
  self.featureContent.relatedArticle = [self.snapshotContent objectAtIndex:0];
  self.splashBannerImageView.clipsToBounds = YES;
  
  [self attachDate];
  [self attachEdition:self.edition];
  [self primeStyle];
  [self buildCells];

  self.summaryTableView.dataSource = self;
  self.summaryTableView.delegate = self;
  
}

- (void)viewWillAppear:(BOOL)animated {
  //[self prime];
}

- (void)viewDidAppear:(BOOL)animated {

}



#pragma mark - Turnable

- (UIView*)bendableView {
  return self.view;
}

- (NSInteger)ghostIndex {
  return self.editionIndex;
}

- (CGRect)ghostFrame {
  return self.originalFrame;
}


#pragma mark - WebContentLoader
- (void)webContentLoaded:(BOOL)firstTime {
  
}

- (void)webContentFailed {
  
}

- (void)externalWebContentRequest:(NSURLRequest *)request {
  
}

- (void)refreshHeight {
  
}

- (void)cleanup {
  
}


#pragma mark - UI
- (void)buttonTapped:(id)sender {
  SCPREditionMoleculeViewController *emvc = [[SCPREditionMoleculeViewController alloc]
                                             initWithNibName:[[DesignManager shared]
                                                              xibForPlatformWithName:@"SCPREditionMoleculeViewController"]
                                             bundle:nil];
  
  emvc.view.frame = emvc.view.frame;
  emvc.parentEditionContentViewController = self;
  
  
  [[[Utilities del] globalTitleBar] morph:BarTypeEditions
                                container:emvc]; 
  [emvc setupWithEdition:self.masterContent
                andIndex:0];
  
  self.pushedContent = emvc;
  
  UIViewController *mineral = (UIViewController*)self.parentMineral;
  [mineral.navigationController pushViewController:emvc
                                          animated:YES];

}

- (void)primeStyle {
  //self.headerBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientPattern2.png"]];
  
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRSnapshotCell"]
                                                   owner:nil options:nil];
  self.dummyCell = (SCPRSnapshotCell*)[objects objectAtIndex:0];
  
  self.dateContainer.backgroundColor = [[DesignManager shared] periwinkleColor];
  
  self.summaryTableView.separatorColor = [UIColor clearColor];  
  self.summaryTableView.backgroundColor = [UIColor whiteColor];
  self.view.backgroundColor = [[DesignManager shared] polishedOnyxColor];
  self.featureContent.snapshotContent = YES;
  [self.featureContent mergeWithArticle:YES];
  

  [self.launchEditionButton.titleLabel titleizeText:@"READ THIS EDITION"
                                               bold:NO];
  
  NSString *url = [Utilities extractImageURLFromBlob:self.featureContent.relatedArticle
                                             quality:AssetQualityFull];
  
  [self.featuredSourceImage loadImage:url
                              quietly:NO];
  self.featuredSourceImage.clipsToBounds = YES;
  self.featuredSourceImage.contentMode = UIViewContentModeScaleAspectFill;
  
  if ( [self.snapshotContent count] > 4 ) {
    NSInteger diff = [self.snapshotContent count] - 4;
    NSString *noun = diff == 1 ? @"STORY" : @"STORIES";
    NSString *moreStories = [NSString stringWithFormat:@"+ %d MORE %@",diff,noun];
    self.moreStoriesLabel.textColor = [[DesignManager shared] number2pencilColor];
    self.summaryTableView.tableFooterView = self.moreStoriesFooter;
    [self.moreStoriesLabel titleizeText:moreStories bold:NO];
  }
  
  [self.storyMetricsLabel titleizeText:[NSString stringWithFormat:@"%d STORIES",[self.snapshotContent count]]
                                  bold:NO
                         respectHeight:YES];
  self.storyMetricsLabel.textColor = [[DesignManager shared] burnedCharcoalColor];
  
  
  [self prime];
}

- (void)silencePage:(NSInteger)index {
  self.dateContainer.alpha = 0.0;
  self.featureContent.alpha = 0.0;
  self.featureContent.image1.alpha = 0.0;
  self.detailContainer.alpha = 0.0;
  for ( SCPRSnapshotCell *v in [self.cellHash allValues] ) {
    if ( v.index == index ) {
      v.headlineLabel.alpha = 0.0;
      v.sourceImage.alpha = 0.0;
      continue;
    }
    v.alpha = 0.0;
  }
  
}

- (void)awakenPage {
  //self.dateContainer.alpha = 1.0;
  //self.featureContent.alpha = 1.0;
  //self.featureContent.image1.alpha = 1.0;
  //self.detailContainer.alpha = 1.0;
}

- (UIImage*)imageForSourceString:(NSString *)source {
  NSString *sourceCpy = [source mutableCopy];
  source = [source stringByReplacingOccurrencesOfString:@" " withString:@"_"];
  source = [source lowercaseString];
  NSString *full = [NSString stringWithFormat:@"%@_editions_logo.png",source];
  
  UIImage *targetImage = [UIImage imageNamed:full];
  if ( !targetImage ) {
    SCPRLogoGeneratorViewController *generator = [[SCPRLogoGeneratorViewController alloc]
                                                  initWithNibName:[[DesignManager shared]
                                                                   xibForPlatformWithName:@"SCPRLogoGeneratorViewController"]
                                                  bundle:nil];
    targetImage = [generator renderWithText:sourceCpy];
  }
  
  return targetImage;
}

- (void)prime {
  

  
}

#pragma mark - Attachments
- (void)attachEdition:(NSUInteger)edition {
  
  
  NSString *base = @"";
  switch (edition) {
    case SnapshotEditionMorning:
      base = @"Morning Edition";
      break;
    case SnapshotEditionAfternoon:
      base = @"Afternoon Edition";
      break;
    case SnapshotEditionEvening:
      base = @"Evening Edition";
      break;
    case SnapshotEditionUnknown:
      default:
      break;
  }
  
  [self.dateNotesLabel titleizeText:base bold:YES];
}

- (void)attachDate {
  NSDate *date = self.snapshotDate;
  
  NSString *timeString = [NSDate stringFromDate:date
                                     withFormat:@"hh:mm a"];
  
  if ( [timeString characterAtIndex:0] == '0' ) {
    timeString = [timeString substringFromIndex:1];
  }
  
  NSString *dateString = [NSDate stringFromDate:date
                                     withFormat:@"MMM d, YYYY"];
  dateString = [NSString stringWithFormat:@"THE SHORT LIST: %@ %@",dateString,timeString];
  [self.dateLabel titleizeText:[dateString uppercaseString]
                          bold:YES];
  self.dateLabel.backgroundColor = [UIColor clearColor];
}

- (void)buildCells {
  
  for ( unsigned i = 0; i < [self.snapshotContent count]; i++ ) {
  
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
    NSString *key = [NSString stringWithFormat:@"%d%d",0,indexPath.row];
    SCPRSnapshotCell *ssc = [self.cellHash objectForKey:key];
    if ( !ssc ) {
    
      NSString *xibToUse = indexPath.row == 0 ? @"SCPRSnapshotCell" : @"SCPRSnapshotCellShort";
      NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                            xibForPlatformWithName:xibToUse]
                                                     owner:nil options:nil];
      ssc = (SCPRSnapshotCell*)[objects objectAtIndex:0];
    
    }
  
    NSDictionary *thing = [self.snapshotContent objectAtIndex:indexPath.row];
  
    ssc.divider.strokeColor = [[DesignManager shared] barelyThereColor];
    ssc.headlineLabel.textColor = [[DesignManager shared] deepOnyxColor];
    ssc.index = indexPath.row;
    ssc.selectionStyle = UITableViewCellSelectionStyleNone;
  
    BOOL bold = YES;
    if ( indexPath.row == 0 ) {
      bold = NO;
    }
    
    [ssc.headlineLabel titleizeText:[thing objectForKey:@"headline"]
                             bold:NO
                    respectHeight:YES
                            lighten:(indexPath.row == 0)];
  
    if ( indexPath.row != 0 ) {
      ssc.headlineLabel.center = CGPointMake(ssc.frame.size.width/2.0,
                                           ssc.frame.size.height/2.0);
    }
    
    [self.cellHash setObject:ssc forKey:key];
  }
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
  
  [emvc setupWithEdition:self.masterContent
                 andIndex:atomIndex];
  
  self.pushedContent = emvc;
  self.pushedAtomIndex = atomIndex;
  
  UIViewController *mineral = (UIViewController*)self.parentMineral;
  [(SCPREditionMineralViewController*)mineral setMoleculePushed:YES];
  
  [mineral.navigationController pushViewController:emvc
                                          animated:YES];
  
  [[ContentManager shared] pushToResizeVector:emvc];
  
  /*if ( [[ContentManager shared] userIsViewingExpandedDetails] ) {
    [emvc pushToAtomDetails:atomIndex];
  }*/
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if ( [self.snapshotContent count] < 4 ) {
    return [self.snapshotContent count];
  }
  
  return 4;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  SCPRSnapshotCell *ssc = nil;
  
  NSString *key = [NSString stringWithFormat:@"%d%d",indexPath.section,indexPath.row];
  ssc = [self.cellHash objectForKey:key];
  
  
  return ssc;

  
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  //SCPRSnapshotCell *cellSnap = (SCPRSnapshotCell*)cell;
  //[cellSnap animateCard];
  
  //[self popLoad];
  
}

- (void)popLoad {
  
  CGFloat yOffset = self.summaryTableView.contentOffset.y;
  NSInteger index = (NSInteger)floorf(yOffset/[self tableView:self.summaryTableView
                                      heightForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]);
  UIImageView *newImage = [self.splashImages objectAtIndex:index];
  [UIView animateWithDuration:0.1 animations:^{
    newImage.alpha = 1.0;
    self.currentImageView.alpha = 0.0;
  } completion:^(BOOL finished) {
    self.currentImageView = newImage;
  }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  SCPRSnapshotCell *ssc = nil;
  
  __block NSString *key = [NSString stringWithFormat:@"%d%d",indexPath.section,indexPath.row];
  ssc = [self.cellHash objectForKey:key];
  ssc.articleImage.contentMode = UIViewContentModeScaleAspectFill;
  
    
  [self pushToMolecule:indexPath.row];
  

  
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ( indexPath.row == 0 ) {
    NSDictionary *thing = [self.snapshotContent objectAtIndex:indexPath.row];
    NSString *headline = [thing objectForKey:@"headline"];
    

    SCPRSnapshotCell *cell = [self.cellHash objectForKey:[NSString stringWithFormat:@"%d%d",indexPath.section,indexPath.row]];
    [cell.headlineLabel titleizeText:headline bold:NO respectHeight:YES];
    
    CGSize s = cell.headlineLabel.frame.size;
    
    if ( [Utilities isIOS7] ) {
      s = CGSizeMake(ceilf(s.width), ceilf(s.height));
    }
    

    CGFloat total = s.height + cell.headlineLabel.frame.origin.y + cell.headlineLabel.frame.origin.y;
    if ( (int)total % 2 != 0 ) {
      return total+1.0;
    } else {
      return total;
    }
  }
  
  return 90.0;
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING EDITION CRYSTAL...");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
