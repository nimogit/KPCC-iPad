//
//  FileManager.h
//  KPCC
//
//  Created by Ben Hochberg on 4/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kYieldMacro @"||_YIELD_||"
#define kWidthMacro @"||_WIDTH_||"
#define kHeightMacro @"||_HEIGHT_||"
#define kEmbedMacro @"||_EMBED_||"
#define kFrameWidthMacro @"||_FRAMEWIDTH_||"
#define kTopMarginMacro @"||_TOPMARGIN_||"
#define kLeftPaddingMacro @"||_LEFTPADDING_||"
#define kRightPaddingMacro @"||_RIGHTPADDING_||"
#define kYouTubeYieldMacro @"||_YOUTUBE_YIELD_||"
#define kYouTubeIDMacro @"||_YT_PLAYER_ID_||"
#define kYouTubeHashMacro @"||_YOUTUBE_HASH_YIELD_||"
#define kStylingMacro @"||_CSS_YIELD_||"
#define kBodyMacro @"||_BODY_YIELD_||"
#define kHeadlineMacro @"||_HEADLINE_YIELD_||"
#define kImageMacro @"||_IMG_YIELD_||"
#define kBylineMacro @"||_BYLINE_YIELD_||"
#define kAdVendorMacro @"||_ADVENDOR_ID_||"
#define kAdUnitMacro @"||_ADUNIT_ID_||"
#define kAdGTPIdMacro @"||_ADGTP_ID_||"

#define kYouTubeWidthAlignmentThreshold 600

typedef enum VideoType {
  VideoTypeUnknown = 0,
  VideoTypeYouTube = 1,
  VideoTypeVimeo = 2,
  VideoTypeBrightcove = 3
} VideoType;

typedef enum StyleType {
  StyleTypeBasic = 0,
  StyleTypeNone,
  StyleTypeSingleVideo,
} StyleType;

@protocol ParsingListener <NSObject>

@optional
- (void)parserFoundItemOfInterest:(NSString*)item;

@end


@interface FileManager : NSObject


@property (nonatomic,weak) id<ParsingListener> listener;

@property (nonatomic, strong) NSDictionary *globalConfig;

+ (FileManager*)shared;
- (NSString*)copyFromMainBundleToDocuments:(NSString*)sourceName destName:(NSString*)destName;
- (NSString*)copyFromMainBundleToDocuments:(NSString*)sourceName destName:(NSString*)destName root:(BOOL)root;
- (NSString*)writeContents:(NSString*)data toFilename:(NSString*)filename;
- (NSString*)writeFileFromData:(NSString*)string toFilename:(NSString*)filename;
- (NSString*)htmlContentFromFile:(NSString*)file;
- (NSArray*)loadVideoPages:(NSArray*)links options:(NSDictionary*)options;
- (NSString*)htmlPageFromBody:(NSString*)body;
- (NSString*)htmlPageFromBody:(NSString *)body article:(NSDictionary*)article;
- (NSString*)htmlPageFromBody:(NSString *)body article:(NSDictionary*)article style:(StyleType)styleType;
- (NSString*)bodyWithInlineAsset:(NSString*)body image:(NSDictionary*)image;

- (NSArray*)collectEmbedded:(NSString*)body type:(VideoType)type;
- (NSString*)embedYouTubeInBody:(NSArray*)embeds body:(NSString*)body;
- (NSString*)applyEmbeds:(NSArray*)embeds body:(NSString*)body;
- (NSString*)modifyJavascriptInContainer:(NSArray*)embeds container:(NSString*)container;
- (NSString*)replaceBadAssetLinks:(NSString*)source;
- (NSString*)formattedEmailForArticle:(NSDictionary*)article;
- (NSString*)basicPlaceholderTemplate:(NSString*)body;
- (NSString*)finalCleanup:(NSString*)content;
- (NSString*)standardExternalContentForReducedArticle:(NSDictionary*)reduced;
- (NSString*)flatYouTubeWithId:(NSString*)ytid width:(CGFloat)width height:(CGFloat)height;
- (NSString*)flatVimeoEmbedWithId:(NSString*)vid width:(CGFloat)width height:(CGFloat)height;
- (NSString*)flatEmbedWithReplacementData:(NSString*)vid width:(CGFloat)width height:(CGFloat)height service:(NSString*)service;

- (void)cleanupTemporaryFiles;

@end
