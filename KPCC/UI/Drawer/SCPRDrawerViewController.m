//
//  SCPRDrawerViewController.m
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRDrawerViewController.h"
#import "SCPRDrawerCell.h"
#import "global.h"
#import "SCPRViewController.h"
#import <Accounts/Accounts.h>
#import "SCPRModalListPickerViewController.h"
#import "SCPRListableObject.h"
#import "SCPRDrawerSectionHeaderView.h"

@interface SCPRDrawerViewController ()

@end

@implementation SCPRDrawerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
      // Custom initialization
  }
  return self;
}

#pragma mark - External Web Content Delegate
- (void)requestURILoaded:(NSString *)complete {
  
}

#pragma mark - UITableView Delegation
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [self.schema count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRDrawerCell"]
                                                   owner:nil
                                                 options:nil];
  SCPRDrawerCell *cell = [objects objectAtIndex:0];
  return cell.frame.size.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSString *key = [NSString stringWithFormat:@"section%d",section];
  NSDictionary *sectionBlock = [self.schema objectForKey:key];
  NSArray *content = [sectionBlock objectForKey:@"content"];
  
  NSInteger modifier = section == 1 ? 1 : 0;
  return [content count]+modifier;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *key = [NSString stringWithFormat:@"section%d",indexPath.section];
  SCPRDrawerCell *cell = nil;
  NSArray *objs = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared] xibForPlatformWithName:@"SCPRDrawerCell"]
                                                  owner:nil
                                                options:nil];
  cell = (SCPRDrawerCell*)[objs objectAtIndex:0];
  NSDictionary *sectionBlock = [self.schema objectForKey:key];
  NSArray *contents = [sectionBlock objectForKey:@"content"];
  
  if ( indexPath.section == 1 ) {
    if ( indexPath.row == [contents count] ) {
      // Edit programs
      cell.leftAccessoryIcon.alpha = 1.0;
      [[DesignManager shared] avoidNeighbor:cell.leftAccessoryIcon withView:cell.headingLabel
                                  direction:NeighborDirectionToLeft
                                    padding:4.0];
      
      
      NSString *copy = @"All Programs";
      [cell.headingLabel titleizeText:copy
                                 bold:YES];
      cell.accessoryIcon.alpha = 0.0;
      return cell;
    }
    if ( indexPath.row == [contents count]+1 ) {
      // All programs
      cell.leftAccessoryIcon.alpha = 0.0;
      cell.accessoryIcon.alpha = 1.0;
      [cell.headingLabel titleizeText:@"All Programs"
                                 bold:YES];
      cell.menuTitle = @"All Programs";
      cell.parentMenuController = self;
      [cell placeObservers];
      
      return cell;
    }
  }
  
  cell.indexHint = indexPath.row;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.leftAccessoryIcon.alpha = 0.0;
  cell.accessoryIcon.alpha = 1.0;

  NSString *heading = [contents objectAtIndex:indexPath.row];
  [cell.headingLabel titleizeText:heading
                              bold:YES
                    respectHeight:YES];
  cell.menuTitle = heading;
  cell.parentMenuController = self;

  [cell placeObservers];

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Atomic top-level page
  [[[Utilities del] viewController] handleDrawerCommand:[NSString stringWithFormat:@"%d|%d",indexPath.section,indexPath.row]];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  SCPRDrawerCell *asDrawerCell = (SCPRDrawerCell*)cell;
  asDrawerCell.headingLabel.textColor = [[DesignManager shared] gloomyCloudColor];
  [asDrawerCell.headingLabel titleizeText:asDrawerCell.headingLabel.text bold:NO];
  asDrawerCell.backgroundColor = [[DesignManager shared] onyxColor];
}

- (CGFloat)calculateTableHeight {
  CGFloat standard = [self.schema count]*50.0;
  for ( NSString *key in [self.expandedCells allKeys] ) {
    SCPRDrawerCell *cell = [self.allCells objectForKey:key];
    standard += [cell determineHeightForDatasource];
  }
  return standard;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared] xibForPlatformWithName:@"SCPRDrawerSectionHeaderView"]
                                                   owner:nil
                                                 options:nil];
  
  SCPRDrawerSectionHeaderView *sHead = (SCPRDrawerSectionHeaderView*)[objects objectAtIndex:0];
  
  NSString *key = [NSString stringWithFormat:@"section%d",section];

  NSDictionary *sectionBlock = [self.schema objectForKey:key];
  [sHead.sectionCaptionLabel titleizeText:[sectionBlock objectForKey:@"title"]
                                     bold:YES];
  
  NSString *imageKey = [NSString stringWithFormat:@"section_%d_header_icon.png",section];
  UIImage *icon = [UIImage imageNamed:imageKey];
  UIImageView *iconImage = [[UIImageView alloc] initWithImage:icon];
  iconImage.contentMode = UIViewContentModeScaleAspectFit;
  [sHead addSubview:iconImage];
  iconImage.center = sHead.sectionIconImageView.center;
  [sHead.sectionIconImageView removeFromSuperview];
  iconImage.layer.shouldRasterize = YES;
  
  sHead.backgroundColor = [[DesignManager shared] deepOnyxColor];
  sHead.topLine.strokeColor = [[DesignManager shared] headlineTextColor];
  sHead.bottomLine.strokeColor = [[DesignManager shared] headlineTextColor];
  
  return sHead;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared] xibForPlatformWithName:@"SCPRDrawerSectionHeaderView"]
                                                   owner:nil
                                                 options:nil];
  
  SCPRDrawerSectionHeaderView *sHead = (SCPRDrawerSectionHeaderView*)[objects objectAtIndex:0];
  return sHead.frame.size.height;
  
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return 0.0;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( indexPath.row == [self.schema count]-1 ) {
    [self.expandedInfoView removeFromSuperview];
    if ( self.expanded ) {
      
      self.expandedInfoView.backgroundColor = [[DesignManager shared] number1pencilColor];
      self.expandedInfoView.frame = CGRectMake(0.0,self.originalHeaderFrame.size.height,
                                               self.expandedInfoView.frame.size.width,
                                               self.expandedInfoView.frame.size.height);
      [self.personalInfoHeader addSubview:self.expandedInfoView];
    } else {
      
    }
  }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section {

}

#pragma mark - Standard handling
- (void)viewDidLoad
{
    [super viewDidLoad];
  
  if ( [Utilities isIOS7] ) {
    self.personalInfoHeader.frame = CGRectMake(self.personalInfoHeader.frame.origin.x, self.personalInfoHeader.frame.origin.y,
                                               self.personalInfoHeader.frame.size.width,
                                               self.personalInfoHeader.frame.size.height+20.0);
    
    for ( UIView *v in [self.personalInfoHeader subviews] ) {
      v.center = CGPointMake(v.center.x,
                             v.center.y+20.0);
    }
    self.internalTable.frame = CGRectMake(self.internalTable.frame.origin.x,
                                          self.personalInfoHeader.frame.origin.y+self.personalInfoHeader.frame.size.height,
                                          self.internalTable.frame.size.width,
                                          self.internalTable.frame.size.height-20.0);
  }
  self.originalHeaderFrame = self.personalInfoHeader.frame;
  self.expandedCells = [[NSMutableDictionary alloc] init];
  self.internalTable.backgroundColor = [[DesignManager shared] onyxColor];
  [self.nameLabel titleizeText:self.nameLabel.text bold:YES];
  
  self.tapToSignInLabel.textColor = [[DesignManager shared] periwinkleColor];
  
  [self.tapToSignInLabel titleizeText:self.tapToSignInLabel.text
                                             bold:NO];
  
  self.schema = [[ContentManager shared] drawerSchema];
  
  self.internalTable.separatorColor = [[DesignManager shared] deepCharcoalColor];
  self.allCells = [[NSMutableDictionary alloc] init];
  [[DesignManager shared] applyBaseShadowTo:self.internalTable];
  self.view.backgroundColor = [[DesignManager shared] darkoalColor];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(respin)
                                               name:@"logged_out"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(respin)
                                               name:@"logged_in"
                                             object:nil];
  
  /*
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(respin)
                                               name:@"notify_listeners_of_queue_change"
                                             object:nil];*/
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(respin)
                                               name:@"favorites_modified"
                                             object:nil];
  
  [self prepHeader];
  
  UIView *foot = [[UIView alloc] initWithFrame:CGRectMake(0.0,0.0,self.internalTable.frame.size.width,
                                                          1.0)];
  foot.backgroundColor = [UIColor clearColor];
  
  self.internalTable.tableFooterView = foot;
  
    // Do any additional setup after loading the view from its nib.
}

- (void)respin {

  
  // Try to eliminate as much loading as possible until the app is finished launching
  if ( [[Utilities del] firstLaunchAndDisplayFinished] ) {
    NSLog(@"Respinning drawer...");
    [self.expandedCells removeAllObjects];
    [self prepHeader];
    self.schema = [[ContentManager shared] drawerSchema];
    
    NSString *promo = [[ContentManager shared].settings promotionalContent];
    if ( ![Utilities pureNil:promo] ) {
      NSMutableDictionary *newSchema = [self.schema mutableCopy];
      NSDictionary *pDict = [promo JSONValue];
      NSInteger count = [newSchema count];
      count--;
      
      NSString *token = [NSString stringWithFormat:@"section%d",count];
      NSMutableDictionary *lastSection = [[newSchema objectForKey:token] mutableCopy];
      NSMutableArray *titles = [[lastSection objectForKey:@"content"] mutableCopy];
      [titles addObject:[pDict objectForKey:@"contentTitle"]];
      [lastSection setObject:titles
                      forKey:@"content"];
      [newSchema setObject:lastSection
                    forKey:token];
      
      self.schema = [NSDictionary dictionaryWithDictionary:newSchema];
    }

    [self.internalTable reloadData];
    
  } else {
    
    [[Utilities del] setDrawerIsDirty:YES];
    [self prepHeader];
    
  }
}

- (void)prepHeader {
  

  self.personalInfoHeader.backgroundColor = [[DesignManager shared] onyxColor];
  self.memberSinceLabel.textColor = [[DesignManager shared] charcoalColor];
  self.nameLabel.textColor = [[DesignManager shared] gloomyCloudColor];
  self.socialTitle.textColor = [[DesignManager shared] gloomyCloudColor];
  
  self.circleFrameView.fillColor = [[DesignManager shared] offwhiteColor];
  self.circleFrameView.clipsToBounds = YES;
  self.circleFrameView.layer.cornerRadius = self.circleFrameView.frame.size.height/2.0;
  self.circleMaskView = [[SCPRCircleView alloc] initWithFrame:CGRectMake(0.0,0.0,
                                                                         self.avatarImage.frame.size.width,
                                                                         self.avatarImage.frame.size.height)];
  self.circleMaskView.fillColor = [[DesignManager shared] obsidianColor:1.0];
  self.personalInfoHeader.clipsToBounds = YES;
  
  [self.circleMaskView setNeedsDisplay];
  [self.circleFrameView setNeedsDisplay];
  
  BOOL anonymous = NO;
  
  // Facebook
  if ( [[SocialManager shared] isAuthenticatedWithMembership] ) {
    [self memberIdentity];
  } else if ( [[SocialManager shared] isAuthenticatedWithFacebook] ) {
    [self facebookIdentity];
  } else if ( [[SocialManager shared] isAuthenticatedWithTwitter] ) {
    [self twitterIdentity];
  } else if ( [[SocialManager shared] isAuthenticatedWithLinkedIn] ) {
    [self linkedInIdentity];
  } else {
    anonymous = YES;
    [self anonymousIdentity];
  }


  CGFloat push = [Utilities isIOS7] ? -12.0 : 2.0;
  push = [Utilities isIpad] ? push : 2.0;
  
  
  self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.height/2.0;
  self.avatarImage.clipsToBounds = YES;
  
  
  [self.expandButton setShadeColor:[[DesignManager shared] deepCharcoalColor]];
  
  
  self.nameLabel.text = [self.nameLabel.text capitalizedString];
  
  
}

- (void)facebookIdentity {
  [[SocialManager shared] facebookImageTo:self.avatarImage];
  [[SocialManager shared] facebookNameTo:self.nameLabel];
  [[SocialManager shared] facebookNameTo:self.socialTitle];
  self.socialTitle.alpha = 1.0;
  //self.socialIcon.image = [UIImage imageNamed:@"facebook_share_logo.png"];
  [self.socialIcon loadLocalImage:@"facebook-icon-small.png"
                          quietly:NO];
  self.socialIcon.alpha = 1.0;
  self.logoutButton.alpha = 1.0;
  self.facebookButton.alpha = 0.0;
  self.twitterButton.alpha = 0.0;
  self.linkedInButton.alpha = 0.0;
  self.circleFrameView.backgroundColor = [UIColor whiteColor];
  //self.tapToSignInButton.alpha = 0.0;
  self.tapToSignInLabel.alpha = 0.0;
  self.circleFrameView.fillColor = [[DesignManager shared] offwhiteColor];
}

- (void)linkedInIdentity {
  [[SocialManager shared] linkedInNameTo:self.nameLabel];
  [[SocialManager shared] linkedInNameTo:self.socialTitle];
  [[SocialManager shared] linkedInImageTo:self.avatarImage];
  self.socialTitle.alpha = 1.0;
  //self.socialIcon.image = [UIImage imageNamed:@"linkedin_share_logo.png"];
  [self.socialIcon loadLocalImage:@"linkedin-icon-small.png"
                          quietly:NO];
  self.socialIcon.alpha = 1.0;
  self.logoutButton.alpha = 1.0;
  self.facebookButton.alpha = 0.0;
  self.twitterButton.alpha = 0.0;
  self.linkedInButton.alpha = 0.0;
  self.circleFrameView.backgroundColor = [UIColor whiteColor];
  //self.tapToSignInButton.alpha = 0.0;
  self.tapToSignInLabel.alpha = 0.0;
  self.circleFrameView.fillColor = [[DesignManager shared] offwhiteColor];
}

- (void)twitterIdentity {
  [[SocialManager shared] twitterImageTo:self.avatarImage];
  [[SocialManager shared] twitterNameTo:self.nameLabel];
  [[SocialManager shared] twitterScreenNameTo:self.socialTitle];
  //self.socialIcon.image = [UIImage imageNamed:@"twitter_share_logo.png"];
  [self.socialIcon loadLocalImage:@"twitter-icon-small.png"
                          quietly:NO];
  self.socialTitle.alpha = 1.0;
  self.socialIcon.alpha = 1.0;
  self.logoutButton.alpha = 1.0;
  self.facebookButton.alpha = 0.0;
  self.twitterButton.alpha = 0.0;
  self.linkedInButton.alpha = 0.0;
  self.circleFrameView.backgroundColor = [UIColor whiteColor];
  //self.tapToSignInButton.alpha = 0.0;
  self.tapToSignInLabel.alpha = 0.0;
  self.circleFrameView.fillColor = [[DesignManager shared] offwhiteColor];
}

- (void)memberIdentity {
  [self.socialIcon loadLocalImage:@"member-icon.png"
                          quietly:NO];
  self.socialTitle.alpha = 1.0;
  self.socialIcon.alpha = 1.0;
  self.circleFrameView.backgroundColor = [UIColor whiteColor];
  self.tapToSignInLabel.alpha = 0.0;
  self.circleFrameView.fillColor = [[DesignManager shared] offwhiteColor];
  [[SocialManager shared] memberNameTo:self.nameLabel];
  [[SocialManager shared] memberImageTo:self.avatarImage];
  [[SocialManager shared] memberDonorClassTo:self.socialTitle];
}

- (void)anonymousIdentity {
  self.nameLabel.text = @"Not Signed In";
  self.avatarImage.image = [UIImage imageNamed:@"anonymous-mask.png"];
  self.logoutButton.alpha = 0.0;
  self.socialIcon.alpha = 0.0;
  self.socialTitle.alpha = 0.0;
  self.facebookButton.alpha = 1.0;
  self.twitterButton.alpha = 1.0;
  self.linkedInButton.alpha = 1.0;
  self.circleFrameView.fillColor = [UIColor clearColor];
  self.tapToSignInButton.alpha = 1.0;
  self.tapToSignInLabel.alpha = 1.0;
}

- (void)expand {
  [self setExpanded:YES];
  
  [[DesignManager shared] globalSetTitleTo:@"Less..."
                                 forButton:self.expandButton];
  
  [self.internalTable reloadData];
}

- (void)contract {
  [self setExpanded:NO];
  
  
  [[DesignManager shared] globalSetTitleTo:@"More..."
                                 forButton:self.expandButton];
  
  [self.internalTable reloadData];
}

- (IBAction)buttonTapped:(id)sender {
  if ( sender == self.tapToSignInButton ) {
    SCPRViewController *scpr = [[Utilities del] viewController];
    
    if ( [[SocialManager shared] isConnected] ) {
      [scpr primeUI:ScreenContentTypeProfilePage newsPath:@""];
    } else {
      [scpr primeUI:ScreenContentTypeOnboarding newsPath:@""];
    }
  }
  
  if ( sender == self.facebookButton ) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(facebookLoginComplete)
                                               name:@"logged_in"
                                             object:nil];
  
    [[SocialManager shared] authenticateWithFacebook];
  }
  if ( sender == self.twitterButton ) {
    [[SocialManager shared] handleTwitterInteraction:self
                                    displayedInFrame:self.twitterButton.frame];
  }
  if ( sender == self.logoutButton ) {
    if ( [[SocialManager shared] isAuthenticatedWithFacebook] ) {
      [[SocialManager shared] logoutOfFacebook];
    } else {
      if ( [[SocialManager shared] isAuthenticatedWithTwitter] ) {
        [[SocialManager shared] logoutOfTwitter];
      } else {
        if ( [[SocialManager shared] isAuthenticatedWithLinkedIn] ) {
          [[SocialManager shared] logoutOfLinkedIn];
        }
      }
    }
  }
  if ( sender == self.linkedInButton ) {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkedInLoginComplete)
                                                 name:@"logged_in"
                                               object:nil];
    
    [[SocialManager shared] loginWithLinkedIn:self
                                       silent:NO];
    
  }
  if ( sender == self.expandButton ) {
    
    if ( self.expanded ) {
      [self contract];
    } else {
      [self expand];
    }
    
  }

}

- (IBAction)switchTurned:(id)sender {
#if !TARGET_IPHONE_SIMULATOR
  if ( sender == self.kpccEventsSwitch ) {
    [[ContentManager shared] editPushForEvents:self.kpccEventsSwitch.on];
  }
  if ( sender == self.breakingNewsSwitch ) {
    [[ContentManager shared] editPushForBreakingNews:self.breakingNewsSwitch.on];
  }
#endif
}


#pragma mark - Twitterable
- (void)finishWithAccount:(ACAccount *)account {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(twitterLoginComplete)
                                               name:@"logged_in"
                                             object:nil];
  
  [[SocialManager shared] loginWithTwitter:account];
}

- (UIView*)twitterableView {
  return self.view;
}

- (void)currentAccountIdentified:(ACAccount *)account {
  
}

- (void)twitterAuthenticationFailed {
  
}

#pragma mark - Login completions
- (void)facebookLoginComplete {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in"
                                                object:nil];
  [self respin];
}

- (void)twitterLoginComplete {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in"
                                                object:nil];
  [self respin];
}

- (void)linkedInLoginComplete {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in"
                                                object:nil];
  [self respin];
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
