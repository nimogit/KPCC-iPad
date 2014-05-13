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

  self.categories = [Utilities loadJson:@"categories"];
  
  CGFloat height = [Utilities isLandscape] ? 748.0 : 1004.0;

  self.tableView.backgroundColor = [UIColor clearColor];
  self.tableView.separatorColor = [UIColor clearColor];
  self.tableView.rowHeight = 72.0f;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.showsVerticalScrollIndicator = NO;
  self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y + 20.0, self.tableView.frame.size.width, height);
}

- (BOOL)shouldAutorotate {
  return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.categories count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsSectionTableViewCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc]init];
  }
  cell.backgroundColor = [UIColor clearColor];
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.text = [[self.categories objectAtIndex:indexPath.row] objectForKey:@"title"];
  
  if (self.currentSectionSlug && [self.currentSectionSlug isEqualToString:[[self.categories objectAtIndex:indexPath.row] objectForKey:@"slug"]]) {
    cell.textLabel.font = [[DesignManager shared] latoRegular:29.0f];
    UIView *verticalBlueDiv = [[UIView alloc] initWithFrame:CGRectMake(4.0, 20.0, 2.0, cell.frame.size.height - 10.0)];
    verticalBlueDiv.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:185.0/255.0 blue:242.0/255.0 alpha:1.0];
    [cell addSubview:verticalBlueDiv];
  } else {
    cell.textLabel.font = [[DesignManager shared] latoLight:29.0f];
  }
  
  if (![Utilities isIOS7]) {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  return cell;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  // Send Category slug to DeluxeNewsViewController
  [self.sectionsDelegate sectionSelected:[self.categories objectAtIndex:indexPath.row]];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
