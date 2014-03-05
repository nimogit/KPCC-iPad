//
//  SCPREventsOverviewViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREventsOverviewViewController.h"
#import "SCPREventsHeaderViewController.h"
#import "SCPREventDetailViewController.h"
#import "SCPREventCell.h"
#import "global.h"

#define kCarouselRefreshRate 10.0

@interface SCPREventsOverviewViewController ()

@end

@implementation SCPREventsOverviewViewController

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
  

  
}

- (void)viewDidAppear:(BOOL)animated {
  
  [self disarmCarousel];
  
  self.carouselTimer = [NSTimer scheduledTimerWithTimeInterval:kCarouselRefreshRate
                                                        target:self
                                                      selector:@selector(cycleCarousel)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)disarmCarousel {
  if ( self.carouselTimer ) {
    if ( [self.carouselTimer isValid] ) {
      [self.carouselTimer invalidate];
    }
  }
  self.carouselTimer = nil;
}

- (void)cycleCarousel {
  [UIView animateWithDuration:0.25 animations:^{
    self.featuredHeaderView.alpha = 0.0;
  } completion:^(BOOL finished) {
    [self cycle];
  }];
}

- (void)cycle {
  [self primeHeader];
}

#pragma mark - UI
- (void)unplug {
  [self disarmCarousel];
  self.pushedEvent = nil;
}

- (void)sourceWithList:(NSArray *)eventsContent {
  self.eventsList = [eventsContent mutableCopy];
  
  NSMutableArray *kpccEvents = [[NSMutableArray alloc] init];
  
  for ( NSDictionary *event in self.eventsList ) {
    if ( [[event objectForKey:@"is_kpcc_event"] boolValue] ) {
      [kpccEvents addObject:event];
    }
  }
  
  self.eventsList = kpccEvents;
  
  self.futureEvents = [[NSMutableArray alloc] init];
  
  NSDate *now = [NSDate date];
  NSMutableArray *diff = [[NSMutableArray alloc] init];
  
  for ( NSDictionary *event in self.eventsList ) {
    
    
    NSDate *eventDate = [Utilities dateFromRFCString:[event objectForKey:@"starts_at"]];
    if ( [eventDate earlierDate:now] == now ) {
      [self.futureEvents addObject:event];
    } else {
      [diff addObject:event];
    }
  }
  
  self.eventsList = diff;
  
  [self.eventsList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    
    NSDictionary *d1 = (NSDictionary*)obj1;
    NSDictionary *d2 = (NSDictionary*)obj2;
    
    NSString *rfc1 = [d1 objectForKey:@"starts_at"];
    NSString *rfc2 = [d2 objectForKey:@"starts_at"];
    
    NSDate *date1 = [Utilities dateFromRFCString:rfc1];
    NSDate *date2 = [Utilities dateFromRFCString:rfc2];
    
    return (NSComparisonResult)[date2 compare:date1];
    
  }];
  
  [self.futureEvents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    
    NSDictionary *d1 = (NSDictionary*)obj1;
    NSDictionary *d2 = (NSDictionary*)obj2;
    
    NSString *rfc1 = [d1 objectForKey:@"starts_at"];
    NSString *rfc2 = [d2 objectForKey:@"starts_at"];
    
    NSDate *date1 = [Utilities dateFromRFCString:rfc1];
    NSDate *date2 = [Utilities dateFromRFCString:rfc2];
    
    return (NSComparisonResult)[date1 compare:date2];
    
  }];
  
  [self primeHeader];
}

- (void)primeHeader {
  self.featuredEvent = [self.futureEvents objectAtIndex:self.carouselPointer];
  self.carouselPointer++;
  
  if ( self.carouselPointer >= [self.futureEvents count] ) {
    self.carouselPointer = 0;
  }
  
  self.featuredSplashImageView.clipsToBounds = YES;
  [self.featuredSplashImageView loadImage:[Utilities extractImageURLFromBlob:self.featuredEvent
                                           quality:AssetQualityFull]];
  
  [self.featuredTitleLabel snapText:[self.featuredEvent objectForKey:@"title"]
                               bold:YES
                      respectHeight:NO];
  
  [self.featuredDateLabel snapText:[Utilities prettyStringFromRFCDateString:[self.featuredEvent objectForKey:@"starts_at"]]
                           bold:NO
                  respectHeight:YES];
  
  
  [self.featuredTeaserLabel snapText:[self.featuredEvent objectForKey:@"teaser"]
                                  bold:NO
                         respectHeight:NO];
  
  self.featuredInformationView.layer.cornerRadius = 4.0;
  self.featuredInformationView.clipsToBounds = YES;
  
  [self.featuredCaptionLabel snapText:@"Featured Event"
                                 bold:YES
                        respectHeight:YES];
  
 
  
  self.eventsTable.tableHeaderView = self.featuredHeaderView;
  
  [[DesignManager shared] avoidNeighbor:self.featuredTitleLabel
                               withView:self.featuredTeaserLabel
                              direction:NeighborDirectionAbove
                                padding:4.0];
  
  self.featuredInformationView.frame = CGRectMake(self.featuredInformationView.frame.origin.x,
                                             self.featuredInformationView.frame.origin.y,
                                             self.featuredInformationView.frame.size.width,
                                             self.featuredTeaserLabel.frame.origin.y+self.featuredTeaserLabel.frame.size.height+17.0);
  
  [UIView animateWithDuration:0.25 animations:^{
    self.featuredHeaderView.alpha = 0.0;
  } completion:^(BOOL finished) {

  }];
  
}



#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  if ( self.futureEvents ) {
    return 2;
  }
  
  self.futureEvents = [[NSMutableArray alloc] init];
  BOOL atLeastOneFutureEvent = NO;
  NSDate *now = [NSDate date];
  for ( NSDictionary *event in self.eventsList ) {
    NSDate *eventDate = (NSDate*)[event objectForKey:@"starts_at"];
    if ( [eventDate earlierDate:now] == now ) {
      atLeastOneFutureEvent = YES;
      break;
    }
  }
  
  if ( atLeastOneFutureEvent ) {
    return 2;
  }
  
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  if ( section == 0 ) {
    return [self.futureEvents count];
  }
  
  return [self.eventsList count];
  
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSArray *eventObjects = [[NSBundle mainBundle] loadNibNamed:@"SCPREventCell"
                                                        owner:nil
                                                      options:nil];
  SCPREventCell *cell = (SCPREventCell*)[eventObjects objectAtIndex:0];
  
  if ( indexPath.section == 0 ) {
    NSDictionary *event = [self.futureEvents objectAtIndex:indexPath.row];
    [cell primeCell:event];
  }
  if ( indexPath.section == 1 ) {
    NSDictionary *event = [self.eventsList objectAtIndex:indexPath.row];
    [cell primeCell:event];
  }
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
  
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 120.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ( indexPath.section == 0 ) {
    
    [self disarmCarousel];
    
    NSDictionary *event = [self.futureEvents objectAtIndex:indexPath.row];
    SCPREventDetailViewController *eventDetail = [[SCPREventDetailViewController alloc]
                                                  initWithNibName:[[DesignManager shared]
                                                                   xibForPlatformWithName:@"SCPREventDetailViewController"]
                                                  bundle:nil];
    eventDetail.event = event;
    self.pushedEvent = eventDetail;
    [self.navigationController pushViewController:eventDetail animated:YES];
    
    
  }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  SCPREventsHeaderViewController *header = [[SCPREventsHeaderViewController alloc]
                                            initWithNibName:[[DesignManager shared]
                                                             xibForPlatformWithName:@"SCPREventsHeaderViewController"]
                                            bundle:nil];
  if ( section == 0 ) {
    header.headerTitle = @"Upcoming Events";
  } else {
    header.headerTitle = @"Past Events";
  }
  
  return header.view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 26.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.backgroundColor = [[DesignManager shared] number1pencilColor];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  
  NSLog(@"DEALLOCATING EVENTS VIEW CONTROLLER...");
  
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
