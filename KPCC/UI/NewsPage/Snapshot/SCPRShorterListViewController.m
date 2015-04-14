//
//  SCPRShorterListViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 4/7/15.
//  Copyright (c) 2015 scpr. All rights reserved.
//

#import "SCPRShorterListViewController.h"
#import "SCPRGrayLineView.h"
#import "SCPRStoryTableViewCell.h"
#import "DesignManager.h"
#import "UILabel+Adjustments.h"
#import "SCPRExternalWebContentViewController.h"
#import "SCPRTitlebarViewController.h"
#import "Utilities.h"
#import "SCPRSingleArticleViewController.h"

static CGFloat kEstimatedRowHeight = 124.0f;

@interface SCPRShorterListViewController ()

@end

@implementation SCPRShorterListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
  [self.shortListLabel titleizeText:@"THE SHORT LIST"
                               bold:YES
                      respectHeight:NO
                            lighten:NO];
  
  [self.dateTimeLabel italicizeText:self.dateTimeLabel.text
                               bold:NO
                      respectHeight:YES];
  
  self.dateTimeLabel.textColor = [[DesignManager shared] seventiesJacketColor];
  
  self.splashImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.splashImageView.clipsToBounds = YES;
  
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  NSLog(@"View did appear");
}

- (void)viewDidLayoutSubviews {
  
  NSLog(@"View did layout subviews");
  
  [self setupScrollingDimensionsWithStories:self.stories];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupWithEdition:(NSDictionary *)edition {
  
  [self.contentScroller layoutIfNeeded];
  
  NSArray *abstracts = [edition objectForKey:@"abstracts"];
  self.stories = [abstracts mutableCopy];
  
  NSDictionary *story = self.stories.firstObject;
  
  [self.contentsTable addObserver:self
                         forKeyPath:@"contentOffset"
                            options:NSKeyValueObservingOptionNew
                            context:nil];
  
  self.contentsTable.delegate = self;
  self.contentsTable.dataSource = self;
  self.contentsTable.backgroundColor = [UIColor clearColor];
  
  self.headlineSeatView.backgroundColor = [UIColor whiteColor];
  self.scrollingContentView.backgroundColor = [UIColor clearColor];
  self.contentsTable.separatorColor = [UIColor clearColor];
  self.contentsTable.translatesAutoresizingMaskIntoConstraints = NO;
  self.contentScroller.delegate = self;
  
  
  [self.dateTimeLabel setText:[self formattedTimestampForEdition:edition]];
  
  NSString *imageURL = [Utilities extractImageURLFromBlob:story
                                                  quality:AssetQualityFull
                                             forceQuality:YES];
  [self.splashImageView loadImage:imageURL];
  
  [self setupScrollingDimensionsWithStories:self.stories];
  
}

- (void)setupScrollingDimensionsWithStories:(NSMutableArray *)stories {
  
  [self.splashImageView printDimensionsWithIdentifier:@"Splash Image"];
  
  self.contentsTable.contentInset = UIEdgeInsetsMake(self.splashImageView.frame.size.height,
                                                     0.0f,
                                                     0.0f,
                                                     0.0f);
  
  self.contentsTable.contentOffset = CGPointMake(0.0,-1.0*self.splashImageView.frame.size.height);
  
  NSLog(@"Content Offset : %1.1f",self.contentsTable.contentOffset.y);
  
  [self.view layoutIfNeeded];
  [self.contentScroller layoutIfNeeded];
  [self.scrollingContentView updateConstraintsIfNeeded];
  

  
  [self.contentScroller printDimensionsWithIdentifier:@"Short List Scroller"];
  [self.scrollingContentView printDimensionsWithIdentifier:@"Scrolling Content View"];
  [self.contentsTable printDimensionsWithIdentifier:@"Actual Content Table"];
  
}

- (NSString*)formattedTimestampForEdition:(NSDictionary *)edition {
  
  NSString *dateString = edition[@"published_at"];
  NSString *formatted = [Utilities prettyLongStringFromRFCDateString:dateString];
  return [NSString stringWithFormat:@"Your morning digest for %@",formatted];
  
}

- (void)pushToStoryAtIndex:(NSInteger)index {
  
  NSDictionary *story = self.stories[index];
  [[ContentManager shared] setFocusedContentObject:story];
  
  if ( ![[ContentManager shared] isKPCCArticle:story] ) {
    NSString *url = [story objectForKey:@"url"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    SCPRExternalWebContentViewController *external = [[SCPRExternalWebContentViewController alloc]
                                                      initWithNibName:[[DesignManager shared]
                                                                       xibForPlatformWithName:@"SCPRExternalWebContentViewController"]
                                                      bundle:nil];
    
    external.fromEditions = !self.fromNews;
    external.view.frame = external.view.frame;
 
    
    if ([Utilities isIOS7]) {
      CGFloat adjuster = [Utilities isLandscape] ? 20.0 : 20.0;
      external.webContentView.frame = CGRectMake(external.webContentView.frame.origin.x,
                                                 external.webContentView.frame.origin.y + 40.0,
                                                 external.webContentView.frame.size.width,
                                                 external.webContentView.frame.size.height - adjuster);
    }
    
    [[[Utilities del] globalTitleBar] morph:BarTypeExternalWeb container:external];
    [self.navigationController pushViewController:external animated:YES];
    [external prime:request];
    
    /*if (self.externalContent) {
      SCPRExternalWebContentViewController *prev = (SCPRExternalWebContentViewController*)self.externalContent;
      [prev.bensOffbrandButton removeTarget:prev
                                     action:@selector(buttonTapped:)
                           forControlEvents:UIControlEventTouchUpInside];
      self.externalContent = nil;
    }
    
    self.externalContent = external;*/
    
    external.bensOffbrandButton = [[[Utilities del] globalTitleBar] parserOrFullButton];
    [external.bensOffbrandButton addTarget:external
                                    action:@selector(buttonTapped:)
                          forControlEvents:UIControlEventTouchUpInside];
    
    
    [[[Utilities del] globalTitleBar] applyBackButtonText:@"THE SHORT LIST"];
    
    
  } else {
    [[NetworkManager shared] fetchContentForSingleArticle:[story objectForKey:@"url"]
                                                  completion:^(id returnedObject) {
                                                    
                                                    SCPRSingleArticleViewController *sac = [[SCPRSingleArticleViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                                                                     xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                                                                                                                                             bundle:nil];
                                                    sac.fromSnapshot = YES;
                                                    sac.view.frame = sac.view.frame;
                                                    sac.relatedArticle = returnedObject;
                                                    [sac arrangeContent];
                                                    
                                                    [[[Utilities del] globalTitleBar] morph:BarTypeModal container:sac];
                                                    
                                                    [[[Utilities del] globalTitleBar] applyBackButtonText:@"THE SHORT LIST"];
                                                    
                                                    [self.navigationController pushViewController:sac animated:YES];
                                                    
                                                    [[ContentManager shared] pushToResizeVector:sac];
                                                    
                                                    NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:story] mutableCopy];
                                                    [[AnalyticsManager shared] logEvent:@"tap_abstract"
                                                                         withParameters:params];
                                                    
                                                  }];

  }
  
  [[ContentManager shared] setUserIsViewingExpandedDetails:YES];
  
  NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:story] mutableCopy];
  [params setObject:[NSDate stringFromDate:[NSDate date]
                                withFormat:@"MMM dd, YYYY HH:mm"]
             forKey:@"date"];
  [params setObject:@"Editions" forKey:@"accessed_from"];
  [params setObject: ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO" forKey:@"audio_on"];
  [[AnalyticsManager shared] logEvent:@"story_read" withParameters:params];
  
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  CGPoint offset = [change[@"new"] CGPointValue];
  CGFloat ratio = fabs(offset.y) / self.splashImageView.frame.size.height;
  self.curtainView.alpha = 1.0f - ratio;
}

#pragma mark - Rotatable
- (void)handleRotationPost {
  [self setupScrollingDimensionsWithStories:self.stories];
}

#pragma mark - UIScrollView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if ( scrollView == self.contentScroller ) {
    [self.contentsTable becomeFirstResponder];
  }
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  if ( section == 0 ) {
    return 1;
  }
  
  return self.stories.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ( indexPath.section == 0 ) {
    return self.shortListHeaderCell;
  }
  
  SCPRStoryTableViewCell *cell = nil/*[self.contentsTable dequeueReusableCellWithIdentifier:@"story-cell"]*/;
  //if ( !cell ) {
    NSArray *objects = [[NSBundle mainBundle]
                        loadNibNamed:[[DesignManager shared]
                                      xibForPlatformWithName:@"SCPRStoryTableViewCell"]
                        owner:nil
                        options:nil];
    cell = (SCPRStoryTableViewCell*)objects[0];
  //}
  
  NSDictionary *story = self.stories[indexPath.row];
  [cell setupWithStory:story];
  
  if ( indexPath.row == 0 ) {
    [cell applyQuantity:self.stories.count];
    cell.quantityView.alpha = 1.0f;
  } else {
    cell.quantityView.alpha = 0.0f;
  }
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  return cell;
  
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ( indexPath.section == 0 ) {
    return self.shortListHeaderCell.frame.size.height;
  }
  
  return kEstimatedRowHeight;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  if ( section == 1 ) {
    return [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, [[UIScreen mainScreen] bounds].size.width,
                                                    64.0f)];
  }
  
  return nil;
}
            
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  
  if ( section == 1 ) {
    return 64.0f;
  }
  
  return 0.0f;
  
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( indexPath.section > 0 ) {
    [[(SCPRStoryTableViewCell*)cell contentSeatView] layoutIfNeeded];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self pushToStoryAtIndex:indexPath.row];
}

- (void)dealloc {
  @try {
    [self.contentsTable removeObserver:self
                              forKeyPath:@"contentOffset"];
  } @catch (NSException *exception) {
    
  } @finally {
    
  }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
