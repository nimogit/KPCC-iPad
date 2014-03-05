//
//  SCPRProfileViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRProfileViewController.h"
#import "global.h"
#import "SCPRProfileListenedCell.h"
#import <Parse/Parse.h>
#import "SCPRProfileReminderCell.h"
#import "SCPRViewController.h"

#define kEventsReminderSwitchTag 23849
#define kBreakingNewsSwitchTag 11938

@interface SCPRProfileViewController ()

@end

@implementation SCPRProfileViewController

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
  
  [self stretch];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(respin)
                                               name:@"logged_out"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(respin)
                                               name:@"logged_in"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refreshTable)
                                               name:@"segment_tracked"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(calculateListeningTime)
                                               name:@"notify_listeners_of_queue_change"
                                             object:nil];
  [self prepHeader];
  
  if ( [Utilities isIOS7] ) {
    [Utilities manuallyStretchView:self.pastListensSeat];
    [Utilities manuallyStretchView:self.pastReadsSeat];
    [Utilities manuallyStretchView:self.contentScroller];
  }
  
  self.contentScroller.contentSize = CGSizeMake(self.pastListensSeat.frame.size.width*2,
                                                self.contentScroller.frame.size.height);
  
  self.pastListensSeat.frame = CGRectMake(0.0,0.0,
                                          self.contentScroller.frame.size.width,
                                          self.contentScroller.frame.size.height);
  

  self.notificationsSeat.frame = CGRectMake(self.pastReadsSeat.frame.size.width,0.0,
                                            self.contentScroller.frame.size.width,
                                            self.contentScroller.frame.size.height);
  
  [self.contentScroller addSubview:self.pastListensSeat];
  [self.contentScroller addSubview:self.notificationsSeat];
  self.contentScroller.scrollEnabled = NO;
  
  self.controlSeat.backgroundColor = [UIColor whiteColor];
  self.pastReadsSeat.backgroundColor = [UIColor whiteColor];
  self.notificationsSeat.backgroundColor = [UIColor whiteColor];
  self.pastListensSeat.backgroundColor = [UIColor whiteColor];
  self.remindersTable.backgroundColor = [UIColor whiteColor];
  self.pastListensTable.backgroundColor = [UIColor whiteColor];
  self.pastReadsTable.backgroundColor = [UIColor whiteColor];

  self.view.backgroundColor = [[DesignManager shared] onyxColor];
  self.headerView.backgroundColor = [[DesignManager shared] onyxColor];
  self.grayLine.strokeColor = [[DesignManager shared] turquoiseCrystalColor:0.45];
  
  [self resetAllButtons];
  [self doNotifications];
  [self doPastListens];
  
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  
  [[[Utilities del] globalTitleBar] applySignoutButton];
  [[[Utilities del] globalTitleBar] applyKpccLogo];
  [[[Utilities del] globalTitleBar] applyOnyxBackground];
  
  self.logoutButton = [[[Utilities del] globalTitleBar] signoutButton];
  

  
  [self.logoutButton addTarget:self
                        action:@selector(buttonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
}

- (void)respin {
  NSLog(@"Respinning profile...");
  [self prepHeader];
}

- (void)refreshTable {
  [[NetworkManager shared] fetchContentForUserProfile:self];
}

- (void)sourceWithListenedSegments:(NSArray *)segments {
  
  self.segments = segments;
  self.pastListensTable.dataSource = self;
  self.pastListensTable.delegate = self;
  [self prepHeader];
  
}

- (void)prepHeader {
  
  self.circleSeat.backgroundColor = [[DesignManager shared] gloomyCloudColor];
  self.circleSeat.layer.cornerRadius = self.circleSeat.frame.size.height/2.0;
  
  self.memberSinceLabel.textColor = [UIColor whiteColor];
  self.nameLabel.textColor = [UIColor whiteColor];
  UIImageView *circle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"circleMask.png"]];
  circle.frame = CGRectMake(0.0,0.0,self.avatarImage.frame.size.width,self.avatarImage.frame.size.height);
  [self.avatarImage.layer setMask:circle.layer];
  

  
#ifndef PRODUCTION
  self.versionLabel.alpha = 1.0;
  [self.versionLabel titleizeText:[Utilities prettyVersion] bold:YES];
#else
  self.versionLabel.alpha = 0.0;
#endif
  
  BOOL anonymous = NO;
  
  // Facebook
  if ( [[SocialManager shared] isAuthenticatedWithFacebook] ) {
    [self facebookIdentity];
  } else {
    // Twitter
    if ( [[SocialManager shared] isAuthenticatedWithTwitter] ) {
      [self twitterIdentity];
    } else {
      // LinkedIn
      if ( [[SocialManager shared] isAuthenticatedWithLinkedIn] ) {
        [self linkedInIdentity];
      } else {
        // Member
        if ( [[SocialManager shared] isAuthenticatedWithMembership] ) {
          [self membershipIdentity];
        } else {
          anonymous = YES;
          [self anonymousIdentity];
        }
      }
    }
  }
  
  
  [self calculateListeningTime];
  
  self.totalListeningTime.layer.cornerRadius = 4.0;
  self.totalListeningTime.layer.borderColor = [[DesignManager shared] offwhiteColor].CGColor;
  self.totalListeningTime.layer.borderWidth = 1.0;
  

  //NSString *text = self.nameLabel.text;
  //self.nameLabel.text = [text lowercaseString];
  
  [self.expandButton setShadeColor:[[DesignManager shared] deepCharcoalColor]];
  

  
}

- (void)calculateListeningTime {
  NSString *prettyTime = [Utilities prettyStringFromSeconds:[[ContentManager shared].settings totalListeningTime]];
  NSString *formatted = [NSString stringWithFormat:@"Total Listening Time:\n%@",prettyTime];
  [self.totalListeningTime snapText:formatted bold:NO];
}

#pragma mark - Rotatable

- (void)handleRotationPre {
  [UIView animateWithDuration:0.18 animations:^{
    self.view.alpha = 0.0;
  }];
}

- (void)handleRotationPost {
  
  [self.logoutButton removeTarget:self
                           action:@selector(buttonTapped:)
                 forControlEvents:UIControlEventTouchUpInside];
  
  [[[Utilities del] viewController] primeUI:ScreenContentTypeProfilePage newsPath:@""];
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

#pragma mark - Identity
- (void)commonIdentity {
  self.socialIcon.alpha = 1.0;
  self.socialTitle.alpha = 1.0;
  self.logoutButton.alpha = 1.0;
  self.signInButton.alpha = 0.0;
  [UIView animateWithDuration:0.33 animations:^{
    self.bigSplashImage.alpha = 1.0;
    self.bigSplashImageBlurry.alpha = 0.0;
  }];
  
  self.nameLabel.text = [self.nameLabel.text lowercaseString];
  
  [self.nameLabel titleizeText:[self.nameLabel.text capitalizedString]
                          bold:NO];
  [self.socialTitle titleizeText:self.socialTitle.text
                            bold:NO];
  
  /*[[DesignManager shared] alignHorizontalCenterOf:self.socialTitle
                                         withView:self.avatarImage];
  [[DesignManager shared] avoidNeighbor:self.socialTitle
                               withView:self.socialIcon
                              direction:NeighborDirectionToRight
                                padding:2.0];*/
}

- (void)facebookIdentity {
  [[SocialManager shared] facebookImageTo:self.avatarImage completion:^{
    [[SocialManager shared] facebookNameTo:self.nameLabel];
    
    [self commonIdentity];
    
    self.socialIcon.image = [UIImage imageNamed:@"facebook-icon-small.png"];
    self.socialIcon.alpha = 1.0;
    self.socialTitle.alpha = 0.0;
    
    self.facebookButton.alpha = 0.0;
    self.twitterButton.alpha = 0.0;
    self.linkedInButton.alpha = 0.0;
    
    [self arrangeSocialVisuals];
    
    [[DesignManager shared] alignVerticalCenterOf:self.socialIcon
                                         withView:self.nameLabel];
    
  }];

  
}

- (void)linkedInIdentity {

  [[SocialManager shared] linkedInImageTo:self.avatarImage completion:^{
    [[SocialManager shared] linkedInNameTo:self.nameLabel];
    [self commonIdentity];
    
    self.socialIcon.image = [UIImage imageNamed:@"linkedin-icon-small.png"];
    self.socialIcon.alpha = 1.0;
    self.socialTitle.alpha = 0.0;
    
    self.facebookButton.alpha = 0.0;
    self.twitterButton.alpha = 0.0;
    self.linkedInButton.alpha = 0.0;
    
    [self arrangeSocialVisuals];
    
    [[DesignManager shared] alignVerticalCenterOf:self.socialIcon
                                         withView:self.nameLabel];
    

  }];
  

}

- (void)twitterIdentity {
  [[SocialManager shared] twitterImageTo:self.avatarImage completion:^{
    [[SocialManager shared] twitterNameTo:self.nameLabel];
    
    [self commonIdentity];
    
    self.facebookButton.alpha = 0.0;
    self.twitterButton.alpha = 0.0;
    self.linkedInButton.alpha = 0.0;
    
    self.socialIcon.alpha = 1.0;
    self.socialIcon.image = [UIImage imageNamed:@"twitter-icon-small.png"];
    self.socialTitle.textColor = [[DesignManager shared] twitterBlueColor];
    [[SocialManager shared] twitterScreenNameTo:self.socialTitle];
    [[DesignManager shared] alignVerticalCenterOf:self.socialIcon
                                         withView:self.socialTitle];
    
    
    [self arrangeSocialVisuals];
  }];
  
}

- (void)membershipIdentity {
  [[SocialManager shared] memberImageTo:self.avatarImage];
  [[SocialManager shared] memberNameTo:self.nameLabel];
  
  [self commonIdentity];
  
  self.facebookButton.alpha = 0.0;
  self.twitterButton.alpha = 0.0;
  self.linkedInButton.alpha = 0.0;
  self.socialIcon.alpha = 1.0;
  self.socialIcon.image = [UIImage imageNamed:@"member-icon.png"];
  self.socialTitle.textColor = [[DesignManager shared] kpccOrangeColor];
  [[SocialManager shared] memberDonorClassTo:self.socialTitle];
  [self arrangeSocialVisuals];
}

- (void)anonymousIdentity {
  self.nameLabel.text = @"Sign In";
  self.avatarImage.image = [UIImage imageNamed:@"avatar-default.png"];
  self.logoutButton.alpha = 0.0;
  self.socialIcon.alpha = 0.0;
  self.socialTitle.alpha = 0.0;
  self.facebookButton.alpha = 1.0;
  self.twitterButton.alpha = 1.0;
  self.linkedInButton.alpha = 1.0;
  [UIView animateWithDuration:0.33 animations:^{
    self.bigSplashImage.alpha = 0.0;
    self.bigSplashImageBlurry.alpha = 1.0;
  }];
  self.signInButton.alpha = 1.0;
}

- (void)arrangeSocialVisuals {
  CGSize s = [self.socialTitle.text sizeOfStringWithFont:self.socialTitle.font
                                       constrainedToSize:CGSizeMake(MAXFLOAT,self.socialTitle.frame.size.height)];
  self.socialTitle.frame = CGRectMake(self.socialTitle.frame.origin.x,
                                      self.socialTitle.frame.origin.y,
                                      s.width+2.0,
                                      self.socialTitle.frame.size.height);
  
  CGSize sx = [self.nameLabel.text sizeOfStringWithFont:self.nameLabel.font
                                       constrainedToSize:CGSizeMake(MAXFLOAT,self.nameLabel.frame.size.height)];
  
  if ( ![[SocialManager shared] isAuthenticatedWithMembership] ) {
    self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x,
                                      self.nameLabel.frame.origin.y,
                                      sx.width+3.0,
                                      self.nameLabel.frame.size.height);

  }

  
  self.circleSeat.center = CGPointMake(self.headerView.frame.size.width/2.0,
                                        self.headerView.frame.size.height/2.0);
  
  [[DesignManager shared] alignHorizontalCenterOf:self.socialTitle withView:self.circleSeat];

  
  [[DesignManager shared] alignHorizontalCenterOf:self.nameLabel withView:self.circleSeat];
  
  CGSize iconSize = self.socialIcon.image.size;
  self.socialIcon.frame = CGRectMake(self.socialIcon.frame.origin.x,
                                     self.socialIcon.frame.origin.y,
                                     iconSize.width,iconSize.height);
  
  if ( [[SocialManager shared] isAuthenticatedWithMembership] ||
      [[SocialManager shared] isAuthenticatedWithTwitter] ) {
    
    [[DesignManager shared] alignVerticalCenterOf:self.socialIcon withView:self.socialTitle];
    [[DesignManager shared] avoidNeighbor:self.socialTitle
                                 withView:self.socialIcon
                                direction:NeighborDirectionToRight
                                  padding:1.0];
    
  } else {
    [[DesignManager shared] alignVerticalCenterOf:self.socialIcon withView:self.nameLabel];
    [[DesignManager shared] avoidNeighbor:self.nameLabel
                                 withView:self.socialIcon
                                direction:NeighborDirectionToRight
                                  padding:5.0];
  }
  
  [[DesignManager shared] avoidNeighbor:self.circleSeat
                               withView:self.nameLabel
                              direction:NeighborDirectionAbove
                                padding:10.0];
  
  [[DesignManager shared] avoidNeighbor:self.nameLabel
                               withView:self.socialTitle
                              direction:NeighborDirectionAbove
                                padding:0.0];
  

  
  if ( ![[SocialManager shared] isAuthenticatedWithMembership] ) {
    
  } else {
    self.circleSeat.backgroundColor = [UIColor clearColor];
  }

  
}

- (IBAction)buttonTapped:(id)sender {
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
    
    NSString *type = @"";
    if ( [[SocialManager shared] isAuthenticatedWithFacebook] ) {
      [[SocialManager shared] logoutOfFacebook];
      type = @"Facebook";
    } else {
      if ( [[SocialManager shared] isAuthenticatedWithTwitter] ) {
        [[SocialManager shared] logoutOfTwitter];
        type = @"Twitter";
      } else {
        if ( [[SocialManager shared] isAuthenticatedWithLinkedIn] ) {
          [[SocialManager shared] logoutOfLinkedIn];
          type = @"LinkedIn";
        } else {
          [[SocialManager shared] logoutOfMembership];
          type = @"Membership";
        }
      }
    }
    
    [[AnalyticsManager shared] logEvent:@"logged_out_social"
                         withParameters:@{ @"type" : type }];
    
    [self.logoutButton removeTarget:self
                             action:@selector(buttonTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
    
    [[[Utilities del] viewController] primeUI:ScreenContentTypeOnboarding newsPath:@""];
    
  }
  if ( sender == self.linkedInButton ) {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkedInLoginComplete)
                                                 name:@"logged_in"
                                               object:nil];
    
    [[SocialManager shared] loginWithLinkedIn:self silent:NO];
  }
  if ( sender == self.notificationsButton ) {
    [self doNotifications];
  }
  if ( sender == self.pastReadsButton ) {
    [self doPastReads];
  }
  if ( sender == self.pastListensButton ) {
    [self doPastListens];
  }
  if ( sender == self.signInButton ) {
    [[[Utilities del] viewController] primeUI:ScreenContentTypeOnboarding newsPath:@""];
  }
}

- (void)resetAllButtons {
  
  [[DesignManager shared] globalSetImageTo:@"icon-notifications.png"
                                 forButton:self.notificationsButton];
  [[DesignManager shared] globalSetImageTo:@"icon-listenhistory.png"
                                 forButton:self.pastListensButton];

  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] charcoalColor]
                                     forButton:self.notificationsButton];

  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] charcoalColor]
                                     forButton:self.pastListensButton];
  
}

- (void)doNotifications {
  [self resetAllButtons];
  [[DesignManager shared] globalSetImageTo:@"icon-notifications-active.png"
                                 forButton:self.notificationsButton];
  [self.notificationsButton.titleLabel titleizeText:self.notificationsButton.titleLabel.text
                                               bold:NO];
  
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] turquoiseCrystalColor:1.0]
                                     forButton:self.notificationsButton];
  
  [UIView animateWithDuration:0.44 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    [self.contentScroller setContentOffset:self.notificationsSeat.frame.origin
                                  animated:NO];
    self.arrowSelector.center = CGPointMake(self.notificationsButton.center.x,
                                            self.arrowSelector.center.y);
    
    
  } completion:^(BOOL finished) {
    
  }];
 
}

- (void)doPastListens {
  [self resetAllButtons];
  [[DesignManager shared] globalSetImageTo:@"icon-listenhistory-active.png"
                                 forButton:self.pastListensButton];
  [self.pastListensButton.titleLabel titleizeText:self.pastListensButton.titleLabel.text
                                               bold:NO];
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] turquoiseCrystalColor:1.0]
                                     forButton:self.pastListensButton];
  [UIView animateWithDuration:0.44 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    [self.contentScroller setContentOffset:self.pastListensSeat.frame.origin
                                  animated:NO];
    self.arrowSelector.center = CGPointMake(self.pastListensButton.center.x,
                                            self.arrowSelector.center.y);
    
    
  } completion:^(BOOL finished) {
    
  }];
}

- (void)doPastReads {
  [self resetAllButtons];
  [[DesignManager shared] globalSetImageTo:@"reading-history-icon-on.png"
                                 forButton:self.pastReadsButton];
  [self.pastReadsButton.titleLabel titleizeText:self.pastReadsButton.titleLabel.text
                                             bold:NO];
  [[DesignManager shared] globalSetTextColorTo:[UIColor whiteColor]
                                     forButton:self.pastReadsButton];
  [UIView animateWithDuration:0.44 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    [self.contentScroller setContentOffset:self.pastReadsSeat.frame.origin
                                  animated:NO];
    self.arrowSelector.center = CGPointMake(self.pastReadsButton.center.x,
                                            self.arrowSelector.center.y);
    
    
  } completion:^(BOOL finished) {
    
  }];
}

- (IBAction)switchTurned:(id)sender {
#if !TARGET_IPHONE_SIMULATOR
  if ( sender == self.kpccEventsSwitch || sender == self.breakingNewsSwitch ) {
    [[ContentManager shared] editPushForBreakingNews:self.breakingNewsSwitch.on];
    return;
  }
#endif
  
  // Reminder
  UISwitch *switcheroo = (UISwitch*)sender;
  NSString *json = [[ContentManager shared].settings favoriteProgramsAsJson];
  NSArray *programs = [json JSONValue];
  NSDictionary *program = [programs objectAtIndex:switcheroo.tag];
  
  if ( switcheroo.on ) {
    [[ScheduleManager shared] addReminder:program reminderType:ReminderTypeBeginningOfProgram];
  } else {
    [[ScheduleManager shared] removeReminder:program];
  }
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  self.segments = content;
  [self.pastListensTable reloadData];
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

- (void)twitterAuthenticationFailed {
  
}

- (void)currentAccountIdentified:(ACAccount *)account {
  
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

#pragma mark - UITableView
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if ( tableView == self.remindersTable ) {
    if ( section == 0 ) {
      return [[DesignManager shared] orangeTextHeaderWithText:@"PUSH NOTIFICATIONS"];
    } else {
      return [[DesignManager shared] orangeTextHeaderWithText:@"PROGRAM SCHEDULE REMINDERS"];
    }
  }
  
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if ( tableView == self.remindersTable ) {
    return [[[DesignManager shared] orangeTextHeaderWithText:@""] frame].size.height;
  }
  
  return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  if ( tableView == self.pastListensTable ) {
    return 1;
  }
  if ( tableView == self.remindersTable ) {
    return 2;
  }
  
  return 1;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  if ( tableView == self.pastListensTable ) {
    return [self.segments count];
  }
  
  if ( tableView == self.remindersTable ) {
    if ( section == 1 ) {
      NSString *json = [[ContentManager shared].settings favoriteProgramsAsJson];
      NSArray *programs = [json JSONValue];
      return [programs count];
    } else {
      return 1;
    }
  }

  return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ( tableView == self.pastListensTable ) {
    SCPRProfileListenedCell *cell = [self.pastListensTable dequeueReusableCellWithIdentifier:@"listened_cell"];
    if ( !cell ) {
      NSArray *cellObjects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                                xibForPlatformWithName:@"SCPRProfileListenedCell"]
                                                         owner:nil
                                                       options:nil];
      cell = (SCPRProfileListenedCell*)[cellObjects objectAtIndex:0];
      cell.frame = cell.frame;
      cell.originalFrame = cell.headlineLabel.frame;
    }
  
    
  
    PFObject *container = [self.segments objectAtIndex:indexPath.row];
    NSString *json = [container objectForKey:@"json"];
    NSDictionary *article = (NSDictionary*)[json JSONValue];

    [cell.headlineLabel titleizeText:[article objectForKey:@"short_title"]
                          bold:NO
     respectHeight:YES];
  
    NSDate *completed = [container objectForKey:@"completed_at"];
    NSString *pretty = [NSDate stringFromDate:completed withFormat:@"MMM d, YYYY"];
    NSString *concat = [NSString stringWithFormat:@"Listened on %@",pretty];
    
    NSString *program = [container objectForKey:@"program_name"];
    if ( ![Utilities pureNil:program] ) {
      concat = [NSString stringWithFormat:@"%@ : %@",program,concat];
    }
    
    cell.headlineLabel.textColor = [[DesignManager shared] deepOnyxColor];
    cell.bylineLabel.textColor = [[DesignManager shared] charcoalColor];
    cell.grayLine.strokeColor = [[DesignManager shared] barelyThereColor];
    
    [cell.bylineLabel titleizeText:concat bold:NO];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
  }
  
  SCPRProfileReminderCell *cell = [self.remindersTable dequeueReusableCellWithIdentifier:@"reminder_cell"];
  if ( !cell ) {
    NSArray *cellObjects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                              xibForPlatformWithName:@"SCPRProfileReminderCell"]
                                                       owner:nil
                                                     options:nil];
    cell = (SCPRProfileReminderCell*)[cellObjects objectAtIndex:0];
  }

  if ( tableView == self.remindersTable ) {
    if ( indexPath.section == 0 ) {
      if ( indexPath.row == 0 ) {
        
        NSString *pushKey = kPushKeyBreakingNews;
#ifdef SANDBOX_PUSHES
        pushKey = kPushKeySandbox;
#endif
        NSString *pk = [[ContentManager shared].settings pushToken];
        cell.remindMeSwitch.on = ![Utilities pureNil:pk];
        if ( !cell.remindMeSwitch.on ) {
          cell.remindMeSwitch.on = [[ContentManager shared] isRegisteredForPushKey:kPushKeyBreakingNews];
        }
        cell.tag = kBreakingNewsSwitchTag;
        [cell.programTitleLabel titleizeText:@"Notify me of news, events, and updates"
                                      bold:NO];
        self.breakingNewsSwitch = cell.remindMeSwitch;
        
      } else {
        cell.remindMeSwitch.on = [[ContentManager shared] isRegisteredForPushKey:kPushKeyEvents];
        [cell.programTitleLabel titleizeText:@"Notify me when CFF Live is showcasing an event"
                                      bold:NO];
        cell.tag = kEventsReminderSwitchTag;
      }
    
      cell.programTitleLabel.textColor = [[DesignManager shared] darkoalColor];
      
      [cell.remindMeSwitch removeTarget:self
                               action:@selector(switchTurned:)
                     forControlEvents:UIControlEventValueChanged];
    
      [cell.remindMeSwitch addTarget:self
                            action:@selector(switchTurned:)
                  forControlEvents:UIControlEventValueChanged];
    
    }
    if ( indexPath.section == 1 ) {
      NSString *json = [[ContentManager shared].settings favoriteProgramsAsJson];
      NSArray *programs = [json JSONValue];
      NSDictionary *program = [programs objectAtIndex:indexPath.row];
  
      //UIImage *img = [[DesignManager shared] imageForProgram:program];
      [cell.programTitleLabel titleizeText:[program objectForKey:@"title"]
                                  bold:NO];
      /*cell.programImageView.image = img;
       cell.programImageView.clipsToBounds = YES;
       cell.programImageView.layer.cornerRadius = 8.0;*/
      NSString *currentReminders = [[ContentManager shared].settings remindersString];
      NSDictionary *remindersHash = [currentReminders JSONValue];
      NSString *key = [Utilities sha1:[program objectForKey:@"title"]];
      if ( [remindersHash objectForKey:key] ) {
        cell.remindMeSwitch.on = YES;
      } else {
        cell.remindMeSwitch.on = NO;
      }
  
      [cell.remindMeSwitch removeTarget:self
                             action:@selector(switchTurned:)
                   forControlEvents:UIControlEventValueChanged];
  
      [cell.remindMeSwitch addTarget:self
                          action:@selector(switchTurned:)
                forControlEvents:UIControlEventValueChanged];
      cell.remindMeSwitch.tag = indexPath.row;
      
      cell.programTitleLabel.textColor = [[DesignManager shared] darkoalColor];
    }
  }
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  SCPRProfileListenedCell *cell;
  NSArray *cellObjects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                                xibForPlatformWithName:@"SCPRProfileListenedCell"]
                                                         owner:nil
                                                       options:nil];
    cell = (SCPRProfileListenedCell*)[cellObjects objectAtIndex:0];
  
  return cell.frame.size.height;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
