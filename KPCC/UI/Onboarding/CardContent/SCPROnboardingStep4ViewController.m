//
//  SCPROnboardingStep2ViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingStep4ViewController.h"
#import "global.h"
#import "SCPRCandidateCell.h"

@interface SCPROnboardingStep4ViewController ()

@end

@implementation SCPROnboardingStep4ViewController

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
  

    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Cardable
- (void)prepUI {
  
  NSArray *meta = (NSArray*) [(SCPROnboardingFlowViewController*)self.master cardMetaData];
  self.memberMetaKeys = meta;
  
  self.candidateTable.delegate = self;
  self.candidateTable.dataSource = self;
  
  [self.verifyIdentityLabel titleizeText:self.verifyIdentityLabel.text
                              bold:NO
                     respectHeight:YES];
  self.verifyIdentityLabel.textColor = [[DesignManager shared] kpccOrangeColor];
  
  
  [self.blurbLabel titleizeText:self.blurbLabel.text
                           bold:NO
                  respectHeight:YES];
  
  self.blurbLabel.textColor = [[DesignManager shared] darkoalColor];
  
  [self.whichIsYouLabel titleizeText:self.whichIsYouLabel.text
                              bold:YES
                     respectHeight:YES];
  
  self.whichIsYouLabel.textColor = [[DesignManager shared] deepOnyxColor];
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.nopeButton.titleLabel.font.pointSize]
                                forButton:self.nopeButton];
  
}

- (NSInteger)myStepIndex {
  return FlowStepMemberValidateMultiple;
}

- (void)backTapped {
  
}


- (IBAction)buttonTapped:(id)sender {
  if ( sender == self.nopeButton ) {
    SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
    [flow popCard];
  }
}

- (void)thatsMeTapped:(id)sender {
  UIButton *tmb = (UIButton*)sender;
  NSDictionary *d = [self.memberMetaKeys objectAtIndex:tmb.tag];
  [[SocialManager shared] loginWithMembershipInfo:d];
  
  SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
  [flow finish];
}

#pragma mark - UITableView Junk
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.memberMetaKeys count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRCandidateCell"]
                                                   owner:nil
                                                 options:nil];
  SCPRCandidateCell *cell = [objects objectAtIndex:0];
  
  NSDictionary *d = [self.memberMetaKeys objectAtIndex:indexPath.row];
  NSString *upperCase = [(NSString*)[d objectForKey:@"member_name"] uppercaseString];
  [cell.nameLabel titleizeText:upperCase
                          bold:NO];
  cell.nameLabel.textColor = [[DesignManager shared] deepOnyxColor];
  
  NSString *complete = [NSString stringWithFormat:@"Member ID: %@",[d objectForKey:@"member_id"]];
  [cell.IDLabel titleizeText:complete bold:NO];
  cell.IDLabel.textColor = [[DesignManager shared] number3pencilColor];
  
  [cell.thatsMeButton addTarget:self
                         action:@selector(thatsMeTapped:)
               forControlEvents:UIControlEventTouchUpInside];
  cell.thatsMeButton.tag = indexPath.row;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  return cell;
  
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  // TODO: Make this based off a dummy-load of the cell
  return 90.0;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
