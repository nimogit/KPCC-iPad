//
//  SCPRModalListPickerViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRModalListPickerViewController.h"
#import "Utilities.h"
#import "global.h"

@interface SCPRModalListPickerViewController ()

@end

@implementation SCPRModalListPickerViewController

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
  
  self.listTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.listTable.frame.size.width,
                                                                            1.0)];
  self.listTable.tableFooterView.backgroundColor = [UIColor clearColor];
  
  self.listTable.tableHeaderView = self.dismissHeader;
  
    // Do any additional setup after loading the view from its nib.
}

- (void)sourceWithList:(NSArray *)list fromOrigin:(CGPoint)origin andMessage:(NSString *)message {
  

  
  self.view.alpha = 0.0;
  self.masterList = list;
  self.listTable.dataSource = self;
  self.listTable.delegate = self;
  
  [[DesignManager shared] applyPerimeterShadowTo:self.view];
  
  [self.listTable reloadData];
  
  self.view.frame = CGRectMake(origin.x,origin.y,
                               self.view.frame.size.width,
                               self.view.frame.size.height);
  
  UIViewController *vc = (UIViewController*)[[Utilities del] masterRootController];
  [vc.view addSubview:self.view];
  
  [self.messageLabel italicizeText:message
                              bold:NO
                     respectHeight:YES];
  
  self.messageLabel.textColor = [[DesignManager shared] charcoalColor];
  
  [UIView animateWithDuration:0.25 animations:^{
    self.view.alpha = 1.0;
  } completion:^(BOOL finished) {
    [self presented];
  }];
  
}

- (void)sourceWithList:(NSArray *)list fromOrigin:(CGPoint)origin {
  [self sourceWithList:list
            fromOrigin:origin
            andMessage:@"Select a Twitter account..."];
}

- (void)presented {
  
  
}

- (IBAction)dismissTapped:(id)sender {
  [self killSelf];
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.masterList count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:@"no"];
  
  id<Listable> obj = [self.masterList objectAtIndex:indexPath.row];
  cell.textLabel.text = [obj stringRepresentation];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  id<Listable> obj = [self.masterList objectAtIndex:indexPath.row];
  [self.delegate itemPickedFromTable:[obj item]];
  [self killSelf];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  /*if ( indexPath.row == [self.masterList count]-1 ) {
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                 self.view.frame.origin.y,
                                 self.view.frame.size.width,
                                 44.0*[self.masterList count]);
    tableView.frame = CGRectMake(tableView.frame.origin.x,
                                 tableView.frame.origin.y,
                                 tableView.frame.size.width,
                                 44.0*[self.masterList count]);

  }*/
}



- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)killSelf {
  [UIView animateWithDuration:0.25 animations:^{
    self.view.alpha = 0.0;
  } completion:^(BOOL finished) {
    [self finish];
  }];
}

- (void)finish {
  
  [self.view removeFromSuperview];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"kill_floating_picker"
                                                object:nil];
  [self.delegate unhook];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
