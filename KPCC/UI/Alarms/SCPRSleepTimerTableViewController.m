//
//  SCPRSleepTimerTableViewController.m
//  KPCC
//
//  Created by John Meeker on 3/3/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import "SCPRSleepTimerTableViewController.h"
#import "SCPRQueueViewController.h"

#define kTimerDuration15Minute 15
#define kTimerDuration30Minute 30
#define kTimerDuration45Minute 45
#define kTimerDuration90Minute 90

@interface SCPRSleepTimerTableViewController ()

@end

@implementation SCPRSleepTimerTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Fix table row separator left-inset spacing.
  if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
  }
  
  self.tableView.scrollEnabled = NO;
  self.tableView.dataSource = self;

  self.sleepTimerData = [[NSMutableArray alloc] initWithObjects:
   [NSNumber numberWithInt:kTimerDuration15Minute],
   [NSNumber numberWithInt:kTimerDuration30Minute],
   [NSNumber numberWithInt:kTimerDuration45Minute],
   [NSNumber numberWithInt:kTimerDuration90Minute],
   nil];
  
  [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  return [self.sleepTimerData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"SleepTimerTableViewCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  [[cell textLabel] setText:[NSString stringWithFormat:@"%@ minutes", [self.sleepTimerData objectAtIndex:indexPath.row] ]];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.textLabel.textAlignment = NSTextAlignmentCenter;
  cell.textLabel.textColor = [[DesignManager shared] periwinkleColor];
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSNumber *sleepTimerDurationMinutes = [self.sleepTimerData objectAtIndex:indexPath.row];
  [[AlarmManager shared] startTimer:sleepTimerDurationMinutes.integerValue * 60];
  
  if (self.queueViewControllerDelegate) {
    if ([self.queueViewControllerDelegate isKindOfClass:[SCPRQueueViewController class]]) {
      SCPRQueueViewController *qvc = (SCPRQueueViewController*) self.queueViewControllerDelegate;
      [qvc updateSleepTimeLeft];
      [qvc closeSleepTimerModal];
      [UIView animateWithDuration:0.22 animations:^{
        qvc.sleepTimerActiveView.alpha = 1.0;
        qvc.sleepTimerInactiveView.alpha = 0.0;
      }];
    }
  }
}


@end
