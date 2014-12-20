//
//  DesignManager.h
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define kBaselinePadding 20.0

@class SCPRNewsPageContainerController;
@class SCPRNewsPageViewController;
@class SCPRFlapViewController;

typedef enum {
  AssetQualityUnknown = 0,
  AssetQualityThumb,
  AssetQualitySmall,
  AssetQualityLarge,
  AssetQualityFull
} AssetQuality;

typedef enum {
  ButtonStyleUnknown = 0,
  ButtonStyleKPCCBlue = 1
} ButtonStyle;

typedef enum {
  NeighborDirectionUnknown = 0,
  NeighborDirectionAbove,
  NeighborDirectionBelow,
  NeighborDirectionToLeft,
  NeighborDirectionToRight
} NeighborDirection;

@protocol Arrangeable <NSObject>

@required
- (void)arrange;
@property NSUInteger templateStyle;
@property (nonatomic,strong) NSString *aspectCode;

@end

@protocol Turnable <NSObject>

- (SCPRFlapViewController*)leftFlap;
- (SCPRFlapViewController*)rightFlap;
- (NSInteger)ghostIndex;
- (CGRect)ghostFrame;
- (UIView*)bendableView;
- (UIView*)shadowView;

@end

@interface DesignManager : NSObject

+ (DesignManager*)shared;
- (void)applyBaseShadowTo:(UIView*)view;
- (void)applyPerimeterShadowTo:(UIView*)view;
- (void)applyWhitePerimeterShadowTo:(UIView*)view;
- (void)applyTopShadowTo:(UIView*)view;
- (void)applyLeftShadowTo:(UIView*)view;
- (void)applyLeftOrangeShadowTo:(UIView*)view;

// Button styling
- (void)globalSetTitleTo:(NSString*)title forButton:(UIButton*)button;
- (void)globalSetImageTo:(NSString*)image forButton:(UIButton*)button;
- (void)globalSetTextColorTo:(UIColor*)color forButton:(UIButton*)button;
- (void)globalSetFontTo:(UIFont*)font forButton:(UIButton*)button;

- (NSString*)xibForPlatformWithName:(NSString*)root;
- (NSString*)xibit:(NSString*)root style:(NSInteger)style;
- (void)treatButton:(UIButton*)button withStyle:(ButtonStyle)style;
- (UIImage*)imageForProgram:(NSDictionary*)program;

// Fonts
- (UIFont*)bodyFontRegular:(CGFloat)size;
- (UIFont*)bodyFontBold:(CGFloat)size;
- (UIFont*)headlineFontRegular:(CGFloat)size;
- (UIFont*)headlineFontBold:(CGFloat)size;
- (UIFont*)latoRegular:(CGFloat)size;
- (UIFont*)sansRegular:(CGFloat)size;
- (UIFont*)latoBold:(CGFloat)size;
- (UIFont*)sansBold:(CGFloat)size;
- (UIFont*)latoItalic:(CGFloat)size;
- (UIFont*)latoBoldItalic:(CGFloat)size;
- (UIFont*)latoLight:(CGFloat)size;

// Colors
- (UIColor*)color:(NSArray*)rgb;
- (UIColor*)charcoalColor;
- (UIColor*)darkoalColor;
- (UIColor*)burnedCharcoalColor;
- (UIColor*)number1pencilColor;
- (UIColor*)number2pencilColor;
- (UIColor*)number3pencilColor;
- (UIColor*)peachColor;
- (UIColor*)kpccOrangeColor;
- (UIColor*)kpccDarkOrangeColor;
- (UIColor*)kpccButtonBlueTopRange;
- (UIColor*)kpccButtonBlueBtmRange;
- (UIColor*)shadowColor;
- (UIColor*)touchOfGrayColor;
- (UIColor*)deepCharcoalColor;
- (UIColor*)uncorkedOrangeColor;
- (UIColor*)uncorkedGreenColor;
- (UIColor*)uncorkedPowderedBlueColor;
- (UIColor*)vinylColor:(CGFloat)alpha;
- (UIColor*)oliveColor:(CGFloat)alpha;
- (UIColor*)salmonColor:(CGFloat)alpha;
- (UIColor*)lavendarColor:(CGFloat)alpha;
- (UIColor*)slateColor:(CGFloat)alpha;
- (UIColor*)aquaColor:(CGFloat)alpha;
- (UIColor*)obsidianColor:(CGFloat)alpha;
- (UIColor*)turquoiseCrystalColor:(CGFloat)alpha;
- (UIColor*)frostedWindowColor:(CGFloat)alpha;
- (UIColor*)translucentSlateColor:(CGFloat)alpha;
- (UIColor*)headlineTextColor;
- (UIColor*)bodyTextColor;
- (UIColor*)blockQuoteTextColor;
- (UIColor*)queueCellIdleColor;
- (UIColor*)queueCellPlayingColor;
- (UIColor*)offwhiteColor;
- (UIColor*)steamColor;
- (UIColor*)puttingGreenColor:(CGFloat)alpha;
- (UIColor*)softBlueColor;
- (UIColor*)twitterBlueColor;
- (UIColor*)stratusCloudColor:(CGFloat)alpha;
- (UIColor*)deepOnyxColor;
- (UIColor*)onyxColor;
- (UIColor*)deepTranslucentOnyxColor;
- (UIColor*)gloomyCloudColor;
- (UIColor*)periwinkleColor;
- (UIColor*)translucentPeriwinkleColor;
- (UIColor*)translucentCharcoalColor;
- (UIColor*)tireColor;
- (UIColor*)pumpkinColor;
- (UIColor*)polishedOnyxColor;
- (UIColor*)barelyThereColor;
- (UIColor*)silverliningColor;
- (UIColor*)silverCurtainsColor;
- (UIColor*)silverTextColor;
- (UIColor*)consistentCharcolColor;
- (UIColor*)clayColor;
- (UIColor*)lightClayColor;
- (UIColor*)auburnColor;
- (UIColor*)kingCrimsonColor;
- (UIColor*)transparentWhiteColor;
- (UIColor*)sectionsBlueColor;

// Queue colors
- (UIColor*)doneGreenColor;
- (UIColor*)removeAllRedColor;
- (UIColor*)cancelBlackColor;

// Color functions
- (UIColor*)rainbowForIndex:(NSInteger)index;
- (void)applyHeadlineStyling:(UILabel*)label;

// View factory
- (UIView*)orangeTextHeaderWithText:(NSString*)text;
- (UIView*)deluxeHeaderWithText:(NSString*)text;
- (UIView*)textHeaderWithText:(NSString *)text textColor:(UIColor*)color backgroundColor:(UIColor*)backgroundColor;
- (UIView*)textHeaderWithText:(NSString *)text textColor:(UIColor *)color backgroundColor:(UIColor *)backgroundColor divider:(BOOL)divider;

// Layout functions
- (void)avoidNeighbor:(UIView*)neighbor withView:(UIView*)view direction:(NeighborDirection)direction padding:(CGFloat)padding;
- (NSString*)aspectCodeForContentItem:(NSDictionary*)item quality:(AssetQuality)quality;
- (void)alignTopOf:(UIView*)thisView withView:(UIView*)thatView;
- (void)alignBottomOf:(UIView*)floatingView withView:(UIView*)anchoredView;
- (void)alignLeftOf:(UIView*)floatingView withView:(UIView*)anchoredView;
- (void)alignRightOf:(UIView*)floatingView withView:(UIView*)anchoredView;
- (void)avoidNeighborFrame:(CGRect)frame withView:(UIView*)floatingView direction:(NeighborDirection)direction padding:(CGFloat)padding;
- (void)alignHorizontalCenterOf:(UIView*)floatingView withView:(UIView*)anchoredView;
- (void)alignVerticalCenterOf:(UIView*)floatingView withView:(UIView*)anchoredView;
- (void)turn:(id<Turnable>)turnable withValues:(NSDictionary*)changes;
- (void)nudge:(UIView*)view direction:(NeighborDirection)direction amount:(CGFloat)amount;

- (NSArray*)typicalConstraints:(UIView*)view;

@property BOOL inSingleArticle;
@property BOOL hasBeenInFullscreen;
@property CGSize predictedWindowSize;

@end
