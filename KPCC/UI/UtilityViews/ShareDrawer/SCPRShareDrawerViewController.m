//
//  SCPRShareDrawerViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/31/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRShareDrawerViewController.h"
#import "SCPRShareCellViewController.h"
#import "global.h"
#import "SBJson.h"
#import "SCPRViewController.h"
#import "SCPRSingleArticleViewController.h"
#import <MessageUI/MessageUI.h>

@interface SCPRShareDrawerViewController ()

@end

@implementation SCPRShareDrawerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - External Web Content
- (void)requestURILoaded:(NSString*)complete {
  NSArray *comps = [complete componentsSeparatedByString:@"="];
  if ( [comps count] > 1 ) {
    NSString *candidate = [comps objectAtIndex:1];
    if ( [candidate rangeOfString:@"access_denied"].location != NSNotFound ) {
      [[Utilities del] uncloakUI];
      return;
    } else {
      [[Utilities del] uncloakUI];
      [[SocialManager shared] linkedInTradeCodeForToken:candidate];
    }
  }
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.shareCells count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SCPRShareCellViewController *cell = [self.shareCells objectAtIndex:indexPath.row];
  return (UITableViewCell*)cell.view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 52.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UIColor *c2u = [Utilities isIpad] ? [UIColor clearColor] : [[DesignManager shared] silverCurtainsColor];
  cell.backgroundColor = c2u;
  cell.backgroundView.backgroundColor = c2u;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  SCPRShareCellViewController *asDrawerCell = [self.shareCells objectAtIndex:indexPath.row];

  [asDrawerCell.grayLine setNeedsDisplay];
  asDrawerCell.logoImage.image = asDrawerCell.repImage;
  //asDrawerCell.logoImage.alpha = 0.87;
  
  if ( [asDrawerCell.shareType isEqualToString:@"email"] ) {
    if ( ![MFMailComposeViewController canSendMail] ) {
      asDrawerCell.disabled = YES;
    }
  }
  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SCPRShareCellViewController *cell = [self.shareCells objectAtIndex:indexPath.row];
  
  if ( cell.disabled ) {
    return;
  }
  
  SCPRViewController *svc = [[Utilities del] viewController];
  [svc closeShareDrawer];
  
  if (self.singleArticleDelegate) {
    if ([self.singleArticleDelegate isKindOfClass:[SCPRSingleArticleViewController class]]) {
      SCPRSingleArticleViewController *savc = (SCPRSingleArticleViewController*) self.singleArticleDelegate;
      [savc closeShareModal];
    }
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sharingFinished)
                                               name:@"sharing_finished"
                                             object:nil];
  
  [[SocialManager shared] shareDispatcher:[[SocialManager shared] intentForString:cell.shareType]
                                  article:[[ContentManager shared] focusedContentObject]
   delegate:self];
  
}


- (void)sharingFinished {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                               name:@"sharing_finished"
                                             object:nil];
  

  
  SCPRViewController *svc = [[Utilities del] viewController];
  [svc closeShareDrawer];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
  
  /*self.view.layer.borderColor = [[DesignManager shared] translucentPeriwinkleColor].CGColor;
  self.view.layer.borderWidth = 1.0;*/
  
  if ( ![Utilities isIOS7] ) {
    self.shareMethodTable.backgroundColor = [UIColor whiteColor];
  }
  
  self.shareMethodTable.scrollEnabled = NO;
  self.shareMethodTable.separatorColor = [UIColor clearColor];
  self.shareMethodTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0,0.0,self.shareMethodTable.frame.size.width,1.0)];
  self.dismissSwiper = [[UISwipeGestureRecognizer alloc]
                        initWithTarget:self
                        action:@selector(dismissSelf)];
  self.dismissSwiper.direction = UISwipeGestureRecognizerDirectionUp;
  [self.view addGestureRecognizer:self.dismissSwiper];
}

- (void)dismissSelf {
  SCPRViewController *vc = [[Utilities del] viewController];
  [vc closeShareDrawer];
}

- (void)buildCells {
  
  self.shareCells = [[NSMutableArray alloc] init];
  
  NSString *supported = @"supported_sharetypes";
  
  if ( ![MFMailComposeViewController canSendMail] ) {
    supported = @"supported_sharetypes_nomail";
  }
  
#ifndef PRODUCTION
  supported = [supported stringByAppendingString:@"_debug"];
#endif

  
  NSDictionary *types = (NSDictionary*)[Utilities loadJson:supported];
  NSArray *list = [types objectForKey:@"supported-share-types"];
  
  CGSize dummySize;
  for ( NSString *type in list ) {
    SCPRShareCellViewController *twtr = [[SCPRShareCellViewController alloc]
                                       initWithNibName:[[DesignManager shared]
                                                        xibForPlatformWithName:@"SCPRShareCellViewController"]
                                       bundle:nil];
    twtr.view.frame = twtr.view.frame;
    dummySize = twtr.view.frame.size;
    twtr.view.frame = twtr.view.frame;
    twtr.logoImage.contentMode = UIViewContentModeCenter;
    twtr.repImage = [UIImage imageNamed:[NSString stringWithFormat:@"icon-share-%@.png",type]];
    twtr.shareType = type;
    twtr.cellView.selectionStyle = UITableViewCellSelectionStyleNone;
    if ( [Utilities isIpad] ) {
      [twtr.captionLabel titleizeText:[type capitalizedString]
                                 bold:NO];
    }
    [self.shareCells addObject:twtr];
  }
 

  /*self.view.frame = CGRectMake(self.view.frame.origin.x,
                               self.view.frame.origin.y,
                               self.view.frame.size.width,
                               dummySize.height*[self.shareCells count]);
  
  self.shareMethodTable.frame = CGRectMake(self.shareMethodTable.frame.origin.x,
                                           self.shareMethodTable.frame.origin.y,
                                           self.shareMethodTable.frame.size.width,
                                           dummySize.height*[self.shareCells count]);*/
  self.shareMethodTable.dataSource = self;
  self.shareMethodTable.delegate = self;
  [self.shareMethodTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
