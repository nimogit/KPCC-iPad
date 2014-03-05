//
//  SCPRDrawerViewController.h
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRTopicSchema.h"
#import "SCPRCircleView.h"
#import "SCPRModalListPickerViewController.h"
#import "SCPRExternalWebContentViewController.h"
#import "SCPRFlatShadedButton.h"



@interface SCPRDrawerViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,Twitterable,ExternalWebContentDelegate> {
  UITableView *_internalTable;
  NSMutableDictionary *_expandedCells;
  NSMutableDictionary *_allCells;
}

- (CGFloat)calculateTableHeight;
- (void)prepHeader;
- (IBAction)buttonTapped:(id)sender;
- (IBAction)switchTurned:(id)sender;
- (void)respin;
- (void)expand;
- (void)contract;

- (void)twitterIdentity;
- (void)facebookIdentity;
- (void)linkedInIdentity;
- (void)anonymousIdentity;
- (void)memberIdentity;

@property (nonatomic,strong) id modalTable;
@property (nonatomic,strong) IBOutlet UITableView *internalTable;
@property (nonatomic,strong) NSMutableDictionary *expandedCells;
@property (nonatomic,strong) NSDictionary *schema;
@property (nonatomic,strong) NSMutableDictionary *allCells;
@property (nonatomic,strong) NSString *menuTitle;
@property (nonatomic,strong) IBOutlet UIView *personalInfoHeader;
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
@property (nonatomic,strong) IBOutlet UIButton *tapToSignInButton;
@property (nonatomic,strong) IBOutlet UILabel *tapToSignInLabel;

@property BOOL expanded;
@property CGRect originalHeaderFrame;

@end
