//
//  Utilities.h
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCPRAppDelegate.h"
#import "DesignManager.h"
#import "UIColor+Additions.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@class SCPRViewController;

@interface Utilities : NSObject

+ (NSString*)urlize:(NSString*)dirty;
+ (BOOL)isIpad;
+ (BOOL)isIOS7;
+ (BOOL)isRetina;
+ (BOOL)isLandscape;
+ (NSString*)sha1:(NSString*)input;
+ (NSString*)base64:(NSData*)input;
+ (NSString*)stripBadCharacters:(NSString*)dirty;
+ (NSString*)generateSlug:(NSString*)name;
+ (CGFloat)degreesToRadians:(CGFloat) degrees;
+ (CGFloat)radiansToDegrees:(CGFloat)radians;
+ (SCPRAppDelegate*)del;
+ (SCPRViewController*)mainContainer;
+ (BOOL)pureNil:(id)object;
+ (NSString*)extractImageURLFromBlob:(NSString*)imgTag;
+ (NSString*)extractImageURLFromBlob:(NSDictionary*)object quality:(AssetQuality)quality;
+ (NSString*)extractImageURLFromBlob:(NSDictionary*)object quality:(AssetQuality)quality forceQuality:(BOOL)forceQuality;
+ (NSString*)unwebbifyString:(NSString*)dirty;
+ (NSString*)unwebbifyString:(NSString*)dirty respectLinebreaks:(BOOL)respectLinebreaks;
+ (NSDictionary*)imageObjectFromBlob:(NSDictionary*)object quality:(AssetQuality)quality;
+ (NSUInteger)snapshotEditionForTimeOfDay;
+ (NSDate*)dateFromRFCString:(NSString *)dateString;
+ (NSString*)stringFromRFCDate:(NSDate*)date;
+ (NSString*)webstyledSlug:(NSDictionary*)article;
+ (NSString*)locateFirstParagraph:(NSString*)body;
+ (NSString*)getValueForHTMLTag:(NSString*)tag inBody:(NSString*)body;
+ (NSDictionary*)collectTappableLinks:(NSString*)body;
+ (void)animStart:(id)del sel:(SEL)sel;
+ (void)animEnd;
+ (NSString*)prettyStringFromSeconds:(NSInteger)seconds;
+ (NSString*)prettyStringFromSocialCount:(NSInteger)seconds;
+ (NSString*)formalStringFromSeconds:(NSInteger)seconds;
+ (NSString*)prettyStringFromRFCDateString:(NSString*)rawDate;
+ (NSString*)prettyLongStringFromRFCDateString:(NSString*)rawDate;
+ (NSString*)isoDateStringFromDate:(NSDate*)date;
+ (CGFloat)easeIn:(CGFloat)value;
+ (NSDictionary*)reverseHash:(NSDictionary*)hash;
+ (BOOL)article:(NSDictionary*)article isSameAs:(NSDictionary*)thisArticle;
+ (BOOL)validLink:(NSString*)link;
+ (NSString*)titleize:(NSString*)title;
+ (id)loadJson:(NSString*)filename;
+ (id)loadNib:(NSString*)rawNibName objIndex:(NSInteger)objIndex;
+ (id)loadNib:(NSString *)rawNibName;
+ (NSString*)loadHtmlAsString:(NSString*)htmlFileName;
+ (NSDictionary*)convertToArticle:(NSDictionary*)episodeOrSegment;
+ (BOOL)isDigit:(unichar)candidate;
+ (BOOL)validateEmail:(NSString *)string;
+ (NSString*)prettyVersion;
+ (NSString*)prettyShortVersion;
+ (NSDictionary*)overrideTopicForArticle:(NSDictionary*)article newTopic:(NSString*)topic;
+ (void)primeTitlebarWithText:(NSString*)text shareEnabled:(BOOL)shareEnabled container:(id<Backable>)container;
+ (void)manuallyStretchView:(UIView*)view;
+ (NSString*)higherVersionBetween:(NSString*)thisVersion thatVersion:(NSString*)thatVersion;
+ (BOOL)articleHasAsset:(NSDictionary*)article;
+ (NSInteger)earliestDate:(NSArray*)dates;
+ (NSInteger)latestDate:(NSArray*)dates;
+ (NSString*)stripLeadingZero:(NSString*)dirty;
+ (NSString*)specialMonthDayFormatFromDate:(NSDate*)date;
+ (NSString*)clipOutYouTubeID:(NSString*)fullLink;
+ (NSString*)stripTrailingNewline:(NSString*)text;

@end
