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

  self.sections = [Utilities loadJson:@"categories"];
  
  //CGFloat width = [Utilities isLandscape] ? 1024.0 : 768.0;
  //self.view.frame = CGRectMake(0.0, 20.0, width, ([Utilities isLandscape] ? 768.0 : 1024.0) - 20.0);

  
  //self.tableView.scrollEnabled = NO;
  self.tableView.backgroundColor = [UIColor clearColor];
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.showsVerticalScrollIndicator = NO;
  self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width - 72.0, self.tableView.frame.size.height);
  self.tableView.sizeToFit;
}

/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSLog(@"HEREE!!");
  return YES;
}*/

/*- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
}*/

- (BOOL)shouldAutorotate {
  return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  NSLog(@"WILL ANIMATE!!! ROTAETEA");
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSLog(@"viewWillAppear news section");
  
  
  [self.view convertRect:self.tableView.frame fromView:self.view];
  
  self.tableView.frame = CGRectMake(self.tableView.frame.origin.x + 36.0, self.tableView.frame.origin.y + 20.0, self.tableView.frame.size.width, self.tableView.frame.size.height);
  
  
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
  cell.textLabel.text = [[self.sections objectAtIndex:indexPath.row] objectForKey:@"title"];
  cell.textLabel.font = [[DesignManager shared] latoLight:29.0f];
  return cell;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  // Send Category slug to DeluxeNewsViewController
  [self.sectionsDelegate sectionSelected:[self.sections objectAtIndex:indexPath.row]];
}


# pragma mark - Rotatable
- (void)handleRotationPre {
  NSLog(@"handleRotationPRE");
}

- (void)handleRotationPost {
  NSLog(@"handleRotationPOST");
}


@end
