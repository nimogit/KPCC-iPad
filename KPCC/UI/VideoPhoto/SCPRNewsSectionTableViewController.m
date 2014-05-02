//
//  SCPRNewsSectionTableViewController.m
//  KPCC
//
//  Created by John Meeker on 4/28/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import "SCPRNewsSectionTableViewController.h"
#import "SCPRDeluxeNewsViewController.h"

@interface SCPRNewsSectionTableViewController ()

@end

@implementation SCPRNewsSectionTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.sections = [[NSMutableArray alloc] initWithArray:@[@"Home", @"Politics", @"Business", @"Crime & Justice", @"Health", @"Education", @"Arts & Entertainment", @"Emerging Communities", @"Local", @"US & World", @"Science"]];
  
  self.tableView.scrollEnabled = NO;
  self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width - 72.0, self.tableView.frame.size.height);
  self.tableView.sizeToFit;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self.tableView.frame = CGRectMake(self.tableView.frame.origin.x + 36.0, self.tableView.frame.origin.y + 40.0, self.tableView.frame.size.width, self.tableView.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated  {
  [super viewDidAppear:animated];

  [Utilities primeTitlebarWithText:@"SECTIONS"
                      shareEnabled:NO
                         container:nil];
  [[[Utilities del] globalTitleBar] eraseCategoriesButton];
  [[[Utilities del] globalTitleBar] applyCloseCategoriesButton];
}

- (void) viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [Utilities primeTitlebarWithText:@""
                      shareEnabled:NO
                         container:nil];

  [[[Utilities del] globalTitleBar] applyKpccLogo];
  [[[Utilities del] globalTitleBar] eraseCloseCategoriesButton];
  [[[Utilities del] globalTitleBar] applyCategoriesButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.sections count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsSectionTableViewCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc]init];
  }
  cell.backgroundColor = [UIColor clearColor];
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.text = [self.sections objectAtIndex:indexPath.row];
  cell.textLabel.font = [[DesignManager shared] latoLight:29.0f];
  return cell;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  // Send Category slug to DeluxeNewsViewController
  [self.sectionsDelegate sectionSelected:[self.sections objectAtIndex:indexPath.row]];
  
  [self dismissViewControllerAnimated:YES completion:nil];
  [[[Utilities del] globalTitleBar] eraseCloseCategoriesButton];
  [[[Utilities del] globalTitleBar] applyCategoriesButton];
}


# pragma mark - Rotatable
- (void)handleRotationPre {
  
}

- (void)handleRotationPost {
  
}


# pragma mark - Cloakable
- (void)deactivate {
  [Utilities primeTitlebarWithText:@"" shareEnabled:NO container:nil];
  [[[Utilities del] globalTitleBar] applyKpccLogo];
  [[[Utilities del] globalTitleBar] eraseCloseCategoriesButton];
  [[[Utilities del] globalTitleBar] applyCategoriesButton];
}

@end
