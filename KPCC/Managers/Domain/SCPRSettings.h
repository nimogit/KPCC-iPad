//
//  SCPRSettings.h
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCPRSettings : NSObject<NSCoding> {
  CGFloat _playerVolume;
  BOOL _playerMinimized;
  NSDate *_lastCacheCleanDate;
  NSString *_deviceID;
  NSString *_lastKnownConnectionType;
  NSString *_userFacebookInformation;
  NSArray *_cachedFetch;
}

@property CGFloat playerVolume;
@property BOOL playerMinimized;
@property (nonatomic,strong) NSDate *lastCompositeNewsSync;
@property (nonatomic,strong) NSDate *lastCacheCleanDate;
@property (nonatomic,strong) NSString *deviceID;
@property (nonatomic,strong) NSString *lastKnownConnectionType;
@property (nonatomic,strong) NSArray *cachedFetch;
@property (nonatomic,strong) NSString *currentlyPlaying;
@property (nonatomic,strong) NSString *userFacebookInformation;
@property (nonatomic,strong) NSString *profileImageURL;
@property (nonatomic,strong) NSString *twitterInformation;
@property (nonatomic,strong) NSString *linkedInToken;
@property (nonatomic,strong) NSDate *linkedInTokenExpire;
@property (nonatomic,strong) NSString *linkedInInformation;
@property (nonatomic,strong) NSString *memberInformation;
@property (nonatomic,strong) NSString *favoriteProgramsAsJson;
@property (nonatomic) double totalListeningTime;
@property BOOL singleSignOnWithLinkedIn;
@property BOOL parseInitiated;
@property BOOL onboardingShown;
@property (nonatomic,strong) NSString *parseId;
@property (nonatomic,strong) NSString *parseDeviceId;
@property (nonatomic,strong) NSString *pushToken;
@property (nonatomic,strong) NSString *remindersString;
@property (nonatomic,strong) NSDate *lastReminderSync;
@property (nonatomic,strong) NSDate *lastProgramSync;
@property (nonatomic,strong) NSDate *leftAppAt;
@property (nonatomic,strong) NSString *deskToken;
@property (nonatomic,strong) NSString *userEmail;
@property (nonatomic,strong) NSString *editionsJson;
@property (nonatomic,strong) NSDate *lastEditionsSync;
@property (nonatomic,strong) NSString *lastAlertPayload;
@property (nonatomic,strong) NSDate *lastAlertPayloadReceived;
@property (nonatomic,strong) NSString *rom;
@property (nonatomic,strong) NSString *twitterBearerToken;
@property (nonatomic,strong) NSDate *lastLatestEpisodesSync;
@property (nonatomic,strong) NSString *promotionalContent;


@end
