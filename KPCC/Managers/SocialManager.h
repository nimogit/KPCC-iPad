//
//  SocialManager.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import <Social/Social.h>
#import "SCPRExternalWebContentViewController.h"
#import <MessageUI/MessageUI.h>
#import "SCPRModalListPickerViewController.h"
#import "UIImageView+ImageProcessor.h"

#define kFBStateChangeToken @"fb_state_change"

typedef void (^MemberValidationBlock)(void);

typedef enum {
  FB_THREAD_IDLE = 0,
  FB_THREAD_BUSY
} FB_THREAD;

typedef enum {
  ShareIntentUnknown = 0,
  ShareIntentFacebook,
  ShareIntentTwitter,
  ShareIntentEmail,
  ShareIntentTumblr,
  ShareIntentLinkedIn,
  ShareIntentDebug
} ShareIntent;

@protocol Twitterable <NSObject>

@optional
- (void)tweetsReceived:(NSDictionary*)data;
- (void)currentAccountIdentified:(ACAccount*)account;

@required
- (UIView*)twitterableView;
- (void)finishWithAccount:(ACAccount*)account;
- (void)twitterAuthenticationFailed;

@end

@protocol MemberStatusable <NSObject>

- (void)processMemberData:(NSArray*)meta;

@end

@interface SocialManager : NSObject<MFMailComposeViewControllerDelegate,ModalListPickerDelegate>

+ (SocialManager*)shared;
- (void)checkForLoginCredentials;
- (NSString*)userName;
- (void)shareDispatcher:(ShareIntent)shareIntent article:(id)article delegate:(id)delegate;
- (void)shareDisabled;
- (ShareIntent)intentForString:(NSString*)str;
- (NSString*)stringForIntent:(ShareIntent)intent;
- (NSString*)signInInformation;
- (BOOL)isConnected;

// Facebook
- (void)facebookImageTo:(UIImageView*)imgView;
- (void)facebookImageTo:(UIImageView *)imgView completion:(ImageAppearedCallback)completion;
- (void)facebookNameTo:(UILabel*)nameLabel;
- (void)threadedImageFetch:(id)result;
- (void)threadedNameFetch:(id)result;
- (void)logoutOfFacebook;
- (void)shareWithFacebook:(id)article;
- (void)getPublished;
- (BOOL)checkForFacebookCredentials;
- (BOOL)isAuthenticatedWithFacebook;
- (BOOL)authenticateWithFacebook;
- (NSString*)facebookName;

// Twitter
- (void)discreteInlineTwitterAuth;
- (void)synthesizeTwitterTweet:(NSString*)twId container:(id)container;

- (void)shareWithTwitter:(NSDictionary*)article;
- (void)loginWithTwitter:(ACAccount*)twitter;
- (BOOL)isAuthenticatedWithTwitter;
- (void)twitterImageTo:(UIImageView*)imgView;
- (void)twitterImageTo:(UIImageView *)imgView completion:(ImageAppearedCallback)block;

- (void)twitterNameTo:(UILabel*)nameLabel;
- (void)twitterScreenNameTo:(UILabel*)titleLabel;
- (void)storeTwitterInformation:(NSString*)twitterInfo;
- (void)logoutOfTwitter;
- (void)queryTweetsWithHashtag:(NSString*)hashtag respondTo:(id<Twitterable>)twitterable withAccount:(ACAccount*)account;
- (void)processBasicLinkedInProfile:(NSData*)xml;
- (void)handleTwitterInteraction:(id<Twitterable>)delegate displayedInFrame:(CGRect)frame;
- (void)updateTwitterStatus:(NSString*)text;
- (NSString*)twitterName;
- (void)accountObjectForScreenName:(NSString*)name delegate:(id<Twitterable>)twitterable;
- (void)twitterAuthFailed:(NSError*)error delegate:(id<Twitterable>)delegate;

// LinkedIn
- (void)loginWithLinkedIn:(id)delegate silent:(BOOL)silent;
- (void)loginWithLinkedIn:(id)delegate silent:(BOOL)silent webcontent:(id)webcontent;
- (NSString*)linkedInApiBase;
- (NSString*)linkedInAppKey;
- (NSString*)linkedInRedirectPrefix;
- (NSString*)linkedInRedirectBase;
- (NSString*)linkedInClientSecret;
- (void)linkedInTradeCodeForToken:(NSString*)code;
- (void)storeLinkedInInformation:(NSDictionary*)info;
- (void)linkedInFail;
- (BOOL)isAuthenticatedWithLinkedIn;
- (BOOL)isSilentlyAuthenticatedWithLinkedIn;
- (void)retrieveLinkedInInfo;
- (void)linkedInImageTo:(UIImageView*)imgView;
- (void)linkedInImageTo:(UIImageView *)imgView completion:(ImageAppearedCallback)completion;
- (void)linkedInNameTo:(UILabel*)nameLabel;
- (void)logoutOfLinkedIn;
- (void)shareWithLinkedIn:(id)article delegate:(id)delegate;
- (void)completeLinkedInShare:(NSString*)comments;
- (void)linkedInLoginComplete;
- (NSString*)linkedInName;

// Membership
- (void)validateMembershipWithKeys:(NSDictionary*)keys delegate:(id<MemberStatusable>)delegate;
- (void)loginWithMembershipInfo:(NSDictionary*)info;
- (BOOL)isAuthenticatedWithMembership;
- (void)memberNameTo:(UILabel*)label;
- (void)memberImageTo:(UIImageView*)imageView;
- (void)memberDonorClassTo:(UILabel*)label;
- (void)logoutOfMembership;

// Email
- (void)shareWithEmail:(NSDictionary*)article delegate:(id)delegate;
- (void)shareWithEmail:(NSDictionary *)article delegate:(id)delegate debug:(BOOL)debug;


- (void)circumscribeImageWithURL:(NSString*)image toImage:(UIImageView*)imgView completion:(ImageAppearedCallback)completion;

@property (nonatomic,strong) id linkedInWebView;
@property BOOL leavingForFacebookAuthRead;
@property BOOL leavingForFacebookAuthPub;
@property BOOL linkedInSilence;
@property ShareIntent shareIntent;
@property (nonatomic,strong) id materialToShare;
@property (nonatomic,strong) ACAccount *activeTwitterAccount;
@property (nonatomic,strong) id designatedDelegate;
@property (nonatomic,strong) id genericRetainer;
@property NSInteger failoverCount;
@property SEL methodForTwitter;
@property (nonatomic,strong) id<Twitterable> twitterDelegate;
@property (nonatomic,strong) NSString *memberEmailCandidate;

// Threaded
@property (nonatomic,strong) NSConditionLock *userImageFetchLock;

@end
