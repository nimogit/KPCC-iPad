//
//  SCPREventDetailViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRBCVideoContentViewController.h"
#import "global.h"
#import "SCPRFlatShadedButton.h"
#import "SCPRReloadViewController.h"
typedef enum {
  TwitterIntentUnknown = 0,
  TwitterIntentTweet,
  TwitterIntentConnect
} TwitterIntent;

@interface SCPREventDetailViewController : UIViewController<UITextViewDelegate,Backable,Twitterable,Reloadable,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) NSDictionary *event;

@property (nonatomic,strong) IBOutlet SCPRBCVideoContentViewController *videoController;
@property (nonatomic,strong) IBOutlet UIView *eventDetailsView;
@property (nonatomic,strong) IBOutlet UIView *liveTweetView;
@property (nonatomic,strong) IBOutlet UITextView *tweetContentTextView;
@property (nonatomic,strong) IBOutlet UIButton *tweetButton;
@property (nonatomic,strong) IBOutlet UILabel *hashtagLabel;
@property (nonatomic,strong) IBOutlet UILabel *eventDateLabel;
@property (nonatomic,strong) IBOutlet UILabel *eventTitleLabel;
@property (nonatomic,strong) IBOutlet UILabel *eventDescriptionLabel;
@property (nonatomic,strong) IBOutlet UITableView *twitterFeedTable;
@property (nonatomic,strong) IBOutlet UIImageView *eventImageView;
@property (nonatomic,strong) IBOutlet UILabel *remainingCharactersLabel;
@property (nonatomic,strong) IBOutlet UIScrollView *mainScroller;
@property (nonatomic,strong) IBOutlet UILabel *twitterAccountLabel;
@property (nonatomic,strong) IBOutlet UIView *noTwitterView;
@property (nonatomic,strong) IBOutlet UILabel *noTwitterLabel;
@property (nonatomic,strong) IBOutlet SCPRFlatShadedButton *connectWithTwitterButton;
@property (nonatomic,strong) ACAccount *twitterAccount;
@property (nonatomic,strong) NSArray *tweets;
@property (nonatomic,strong) SCPRReloadViewController *reloader;
@property (nonatomic,strong) IBOutlet UIToolbar *fauxBar;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *twitterSpinner;
@property (nonatomic,strong) IBOutlet UIWebView *videoWebView;

@property BOOL maxLength;
@property BOOL resumeAudioOnExit;
@property BOOL twitterTurnedOn;
@property TwitterIntent twitterIntent;

- (IBAction)tweetTapped:(id)sender;
- (IBAction)connectTapped:(id)sender;
- (IBAction)doneTapped:(id)sender;

- (NSInteger)countRemainingCharacters;
- (void)twitterize;
- (void)untwitterize;

@end
