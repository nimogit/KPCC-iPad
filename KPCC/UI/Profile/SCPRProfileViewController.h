//
//  SCPRProfileViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRCircleView.h"
#import "SCPRFlatShadedButton.h"
#import "SCPRModalListPickerViewController.h"
#import "global.h"
#import "SCPRExternalWebContentViewController.h"
#import "SCPRGrayLineView.h"

@interface SCPRProfileViewController : UIViewController<Twitterable,UITableViewDelegate,UITableViewDataSource,ContentProcessor,ExternalWebContentDelegate,Rotatable>

- (void)prepHeader;
- (IBAction)buttonTapped:(id)sender;
- (IBAction)switchTurned:(id)sender;
- (void)respin;

- (void)twitterIdentity;
- (void)facebookIdentity;
- (void)linkedInIdentity;
- (void)membershipIdentity;
- (void)anonymousIdentity;
- (void)commonIdentity;
- (void)calculateListeningTime;
- (void)sourceWithListenedSegments:(NSArray*)segments;
- (void)resetAllButtons;
- (void)doPastListens;
- (void)doPastReads;
- (void)doNotifications;
- (void)arrangeSocialVisuals;

@property (nonatomic,strong) NSArray *segments;
@property (nonatomic,strong) IBOutlet UITableView *pastListensTable;
@property (nonatomic,strong) IBOutlet UILabel *nameLabel;
@property (nonatomic,strong) IBOutlet UILabel *memberSinceLabel;
@property (nonatomic,strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic,strong) IBOutlet SCPRCircleView *circleFrameView;
@property (nonatomic,strong) SCPRCircleView *circleMaskView;
@property (nonatomic,strong) IBOutlet UIButton *facebookButton;
@property (nonatomic,strong) IBOutlet UIButton *twitterButton;
@property (nonatomic,strong) IBOutlet UIButton *logoutButton;
@property (nonatomic,strong) IBOutlet UIButton *linkedInButton;
@property (nonatomic,strong) IBOutlet UIImageView *socialIcon;
@property (nonatomic,strong) IBOutlet UILabel *socialTitle;
@property (nonatomic,strong) IBOutlet UILabel *totalListeningTime;
@property (nonatomic,strong) IBOutlet UIView *expandedInfoView;
@property (nonatomic,strong) IBOutlet UISwitch *breakingNewsSwitch;
@property (nonatomic,strong) IBOutlet UISwitch *kpccEventsSwitch;
@property (nonatomic,strong) IBOutlet UILabel *breakingNewsLabel;
@property (nonatomic,strong) IBOutlet UILabel *kpccEventsLabel;
@property (nonatomic,strong) IBOutlet SCPRFlatShadedButton *expandButton;
@property (nonatomic,strong) IBOutlet UITableView *remindersTable;
@property (nonatomic,strong) IBOutlet UIView *controlSeat;
@property (nonatomic,strong) IBOutlet UIImageView *bigSplashImage;
@property (nonatomic,strong) IBOutlet UIImageView *bigSplashImageBlurry;
@property (nonatomic,strong) IBOutlet UILabel *versionLabel;
@property (nonatomic,strong) IBOutlet UIView *circleSeat;

@property BOOL notificationsTabSelected;


// Movable
@property (nonatomic,strong) IBOutlet UIScrollView *contentScroller;
@property (nonatomic,strong) IBOutlet UIView *pastListensSeat;
@property (nonatomic,strong) IBOutlet UIView *notificationsSeat;
@property (nonatomic,strong) IBOutlet UIView *pastReadsSeat;
@property (nonatomic,strong) IBOutlet UITableView *pastReadsTable;
@property (nonatomic,strong) IBOutlet UIButton *pastListensButton;
@property (nonatomic,strong) IBOutlet UIButton *pastReadsButton;
@property (nonatomic,strong) IBOutlet UIButton *notificationsButton;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *grayLine;
@property (nonatomic,strong) IBOutlet UIImageView *arrowSelector;

@property (nonatomic,strong) IBOutlet UIButton *signInButton;

@property (nonatomic,strong) IBOutlet UIView *headerView;
@end
