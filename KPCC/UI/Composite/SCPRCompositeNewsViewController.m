//
//  SCPRCompositeNewsViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRCompositeNewsViewController.h"
#import "SCPRCompSingleCell.h"
#import "SCPRCompDoubleCell.h"
#import "global.h"
#import "SCPRSingleArticleCollectionViewController.h"
#import "SCPRViewController.h"
#import "SCPRTitlebarViewController.h"

@interface SCPRCompositeNewsViewController ()

@end

@implementation SCPRCompositeNewsViewController

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
  
  self.compositeNewsTable.delegate = self;
  self.compositeNewsTable.dataSource = self;
 
  self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
  self.compositeNewsTable.backgroundColor = [[DesignManager shared] deepOnyxColor];
  //self.compositeNewsTable.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tableBackground.png"]];
  NSArray *objects = [[NSBundle mainBundle]
                      loadNibNamed:[[DesignManager shared]
                                    xibForPlatformWithName:@"SCPRCompSingleCell"]
                      owner:nil
                      options:nil];
  
  self.dummySingle = [objects objectAtIndex:0];
  
   objects = [[NSBundle mainBundle]
                      loadNibNamed:[[DesignManager shared]
                                    xibForPlatformWithName:@"SCPRCompDoubleCell"]
                      owner:nil
                      options:nil];
  
  self.dummyDouble = [objects objectAtIndex:0];
  
  /*self.spinner = [[SCPRSpinnerViewController alloc] initWithNibName:[[DesignManager shared]
                                                                     xibForPlatformWithName:@"SCPRAltSpinnerViewController"]
                                                             bundle:nil];
  [self.spinner spinWithFinishedToken:@"news_loaded"
                               inView:self.view];*/
  
    // Do any additional setup after loading the view from its nib.
  
  
  
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)unplug {
  NSLog(@"Unplugging composite news controller...");
  self.pushed = nil;
  self.compositeNews = nil;
  [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)focusArticle:(NSDictionary *)article {
  SCPRSingleArticleCollectionViewController *collection = [[SCPRSingleArticleCollectionViewController alloc]
                                                           initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRSingleArticleCollectionViewController"]
                                                           bundle:nil];
  
  self.pushed = collection;
  SCPRAppDelegate *del = [Utilities del];
  SCPRViewController *mvc = (SCPRViewController*)del.viewController;
  
  collection.view.frame = collection.view.frame;
  
  
  NSMutableArray *media = [[NSMutableArray alloc] init];
  NSArray *trending = [self.compositeNews objectForKey:@"trending"];
  NSArray *general = [self.compositeNews objectForKey:@"general"];
  
  NSInteger marker = 0;
  for ( unsigned i = 0; i < [trending count]; i++ ) {
    NSDictionary *t1 = [trending objectAtIndex:i];
    [media addObject:t1];
    for ( unsigned j = 0; j < 6; j++ ) {
      if ( marker >= [general count] ) {
        break;
      }
      NSDictionary *g1 = [general objectAtIndex:marker];
      [media addObject:g1];
      marker++;
    }
  }
  
  NSUInteger index = 0;
  for ( unsigned i = 0; i < [media count]; i++ ) {
    NSDictionary *story = [media objectAtIndex:i];
    if ( story == article ) {
      index = i;
      break;
    }
  }
  
  [self.navigationController
   pushViewController:collection animated:YES];
  
  mvc.mainPageScroller.scrollEnabled = NO;
  
  collection.parentContainer = nil;
  collection.category = ContentCategoryNews;
  [collection setupWithCollection:media
                 beginningAtIndex:index
                     processIndex:YES];
  
  [[[Utilities del] globalTitleBar] morph:BarTypeModal
                                container:collection.currentPage];
  
  collection.collectionType = @"Tile View";
  
  NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:[NSMutableDictionary dictionaryWithDictionary:article]] mutableCopy];
  NSDictionary *newParams = @{ @"article_id" : [article objectForKey:@"id"],
                               @"date" : [NSDate stringFromDate:[NSDate date]
                                                     withFormat:@"MMM dd, YYYY HH:mm"],
                               @"accessed_from" : @"Tile View",
                               @"audio_on" : ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO"};
  
  for ( NSString *key in newParams ) {
    [params setObject:[newParams objectForKey:key]
               forKey:key];
  }

  [[AnalyticsManager shared] logEvent:@"story_read"
                       withParameters:params];

}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSArray *trends = [self.compositeNews objectForKey:@"trending"];
  NSArray *general = [self.compositeNews objectForKey:@"general"];
  
  NSLog(@"Trends : %d",(int)[trends count]);
  NSLog(@"General : %d",(int)[general count]);
  
  return (([trends count]-1)*3);
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ( indexPath.row == 0 || indexPath.row % 4 == 0 ) {
    
    SCPRCompSingleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"comp_single"];
    if ( !cell || [cell isLocked] ) {
      NSArray *objects = [[NSBundle mainBundle]
                          loadNibNamed:[[DesignManager shared]
                                        xibForPlatformWithName:@"SCPRCompSingleCell"]
                          owner:nil
                          options:nil];
      cell = (SCPRCompSingleCell*)[objects objectAtIndex:0];
      [cell.articleCell0 arm];
      
    }
    
    NSInteger index = 0;
    if ( indexPath.row % 4 == 0 ) {
      index = indexPath.row / 4;
    }
    
    cell.articleCell0.parentCompositeNews = self;
    cell.articleCell0.circleGradient.alpha = 0.0;
    cell.index = index;
    NSArray *trending = [self.compositeNews objectForKey:@"trending"];
    NSDictionary *story = [trending objectAtIndex:index];
    [cell mergeWithArticles:@[story]];
    
    
    return cell;
    
  }
  
  SCPRCompDoubleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"comp_double"];
  if ( !cell ) {
    NSArray *objects = [[NSBundle mainBundle]
                        loadNibNamed:[[DesignManager shared]
                                      xibForPlatformWithName:@"SCPRCompDoubleCell"]
                        owner:nil
                        options:nil];
    cell = (SCPRCompDoubleCell*)[objects objectAtIndex:0];
    [cell.articleCell0 arm];
    [cell.articleCell1 arm];
  }
  
  NSInteger offset = ((NSInteger)floorf(indexPath.row / 4.0))+1;

  NSInteger baseIndex = (indexPath.row-offset)*2;
  
 
  NSArray *general = [self.compositeNews objectForKey:@"general"];
  NSDictionary *story = [general objectAtIndex:baseIndex];
  NSDictionary *secondStory = nil;
  if ( baseIndex+1 < [general count] ) {
    secondStory = [general objectAtIndex:baseIndex+1];
  }
  
  cell.articleCell0.parentCompositeNews = self;
  cell.articleCell1.parentCompositeNews = self;
  cell.articleCell0.circleGradient.alpha = 0.0;
  cell.articleCell1.circleGradient.alpha = 0.0;
  
  if ( secondStory ) {
    [cell mergeWithArticles:@[story,secondStory]];

  } else {
    [cell mergeWithArticles:@[story]];

  }
  

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  return cell;
  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( indexPath.row % 4 == 0 ) {
    return self.dummySingle.frame.size.height;
  }
  
  return self.dummyDouble.frame.size.height;
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  [[ContentManager shared] printCacheUsage];
  NSLog(@"DEALLOCATING COMPOSITE NEWS CONTROLLER...");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
