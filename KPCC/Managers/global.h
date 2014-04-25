//
//  global.h
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//


#ifndef KPCC_global_h
#define KPCC_global_h

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


#define kGlobalResize UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

#ifdef TURN_OFF_LOGGING
#define NSLog //
#endif

#define TICK   NSDate *startTime = [NSDate date]
#define TOCK   NSLog(@"Execution Time: %f  -- [ %s ]=[ Line %d ]", -[startTime timeIntervalSinceNow], __PRETTY_FUNCTION__, __LINE__)

#import "ContentManager.h"
#import "DesignManager.h"
#import "Utilities.h"
#import "NetworkManager.h"
#import "AudioManager.h"
#import "AnalyticsManager.h"
#import "FileManager.h"
#import "QueueManager.h"
#import "SocialManager.h"
#import "ScheduleManager.h"
#import "FeedbackManager.h"
#import "AlarmManager.h"
#import "UIViewController+iOS7Helper.h"

// Utilities
#import "NSDate+Helper.h"
#import "NSTimer+Disarm.h"
#import "UIImageView+ImageProcessor.h"
#import "UILabel+Adjustments.h"
#import "UIImage+StackBlur.h"
#import "SBJson.h"
#import "NSString+sizeWithFont.h"

// Modify these per project
#import "SCPRAppDelegate.h"

#define kAdSwipeThreshold 5
#define kMaxAdsPerSession 5

#pragma mark - Gobal view tags
#define kVolumeWidgetTag 894749

#pragma mark - Global environment settings
#define kFadeTime 0.8
#ifndef PRODUCTION
#define kCacheCleaningThreshold 0
#else
#define kCacheCleaningThreshold 2
#endif

#define kPlaceHolderString @"Add your comments..."
#define kCacheObjectThreshold 50
#define kNewsCacheThreshold 4
#define kHeaderLabelTag 1122


#define kBreakingNewsThresholdInHours 3
#define kNumberOfStoriesPerPage 3

#define kDonateURL @"https://scprcontribute.publicradio.org"

#pragma mark - Global protocols


#endif
