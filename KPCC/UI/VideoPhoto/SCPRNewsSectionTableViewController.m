//
//  SCPRNewsSectionTableViewController.m
//  KPCC
//
//  Created by John Meeker on 4/28/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import "SCPRNewsSectionTableViewController.h"
#import "SCPRDeluxeNewsViewController.h"
#import "SCPRNewsSectionNavigationControllerDelegate.h"

@interface SCPRNewsSectionTableViewController ()

@end

@implementation SCPRNewsSectionTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.sections = [[NSMutableArray alloc] initWithArray:@[@"Home", @"Politics", @"Business", @"Crime & Justice", @"Health", @"Education", @"Arts & Entertainment", @"Emerging Communities", @"Local", @"US & World", @"Science"]];

}

- (void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 40.0, self.view.frame.size.width, self.view.frame.size.height);
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
    return [self.sections count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsSectionTableViewCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc]init];
  }
  cell.backgroundColor = [UIColor clearColor];
  cell.textLabel.text = [self.sections objectAtIndex:indexPath.row];
  return cell;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  [self dismissViewControllerAnimated:YES completion:nil];
  [[[Utilities del] globalTitleBar] eraseCloseCategoriesButton];
  [[[Utilities del] globalTitleBar] applyCategoriesButton];
}


# pragma mark - Rotatable
- (void)handleRotationPre {
  
}

- (void)handleRotationPost {
  
}


@end
