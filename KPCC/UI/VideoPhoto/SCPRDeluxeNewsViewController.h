//
//  SCPRDeluxeNewsViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 7/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRDeluxeNewsCell.h"
#import "SCPRDeluxeEditionsCell.h"
#import "SCPRViewController.h"
#import "global.h"
#import "SCPRUsefulTransition.h"
#import "SCPRNewsSectionTableViewController.h"
#import "FXBlurView.h"

#define kNumberOfRegularStoriesPerRow 2

typedef void (^FetchContentCallback)(BOOL);


@interface SCPRDeluxeNewsViewController : UIViewController<ContentProcessor,UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate,Rotatable,AnimationDelegate,SCPRTitlebarDelegate,SCPRNewsSectionDelegate>

// UI
@property (nonatomic,strong) IBOutlet UITableView *photoVideoTable;
@property (nonatomic,strong) IBOutlet UITableViewController *tableController;
@property (nonatomic,strong) IBOutlet UIView *emptyFooter;
@property (nonatomic,strong) IBOutlet UIView *spinnerFooter;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *loadingMoreNewsSpinner;

// For Sections UI and data handling - only used on ScreenContentTypeCompositePage.
@property (nonatomic,strong) UITableView *categoriesTableView;
@property (nonatomic,strong) SCPRNewsSectionTableViewController *categoriesTableViewController;
@property (nonatomic,strong) FXBlurView *categoriesBlurView;
@property (nonatomic,strong) UIView *categoriesDarkView;
@property (nonatomic,strong) NSString *currentNewsCategory;


// Article, cell, social, short list data stores
@property (nonatomic,strong) NSArray *posts;
@property (nonatomic,strong) NSMutableDictionary *rawArticleHash;
@property (nonatomic,strong) NSMutableDictionary *socialShareCountHash;
@property (nonatomic,strong) NSDictionary *bigHash;
@property (nonatomic,strong) NSArray *sortedKeyArrayCache;
@property (nonatomic,strong) NSMutableArray *monolithicNewsVector;

@property (nonatomic,weak) id pushedContent;
@property (nonatomic,strong) id pushedCollection;
@property (nonatomic,strong) NSMutableArray *cells;
@property (nonatomic,strong) NSMutableDictionary *dateCells;
@property (nonatomic,strong) NSArray *editionsData;
@property (nonatomic,strong) NSMutableDictionary *editionCellHash;

@property (nonatomic,strong) NSMutableDictionary *regularStoriesPerDate;
@property (nonatomic,strong) NSMutableDictionary *editionsStoriesPerDate;
@property (nonatomic,strong) NSMutableDictionary *embiggenedStoriesPerDate;
@property (nonatomic,strong) NSMutableDictionary *articleMapPerDate;
@property (nonatomic,strong) NSMutableDictionary *masterCellHash;
@property (nonatomic,strong) NSMutableDictionary *lookupForDuplicates;

// Class properties & vars
@property ScreenContentType contentType;
@property NSInteger numberOfRegularStoriesPerRow;
@property BOOL armToKill;
@property BOOL cacheMutex;
@property BOOL hardReset;
@property BOOL lockScrollUpdates;
@property BOOL reorienting;
@property (nonatomic,strong) NSIndexPath *previousFinalRow;
@property CGPoint previousOffset;
@property (nonatomic,strong) NSTimer *failoverTimer;

// Dummy cells and UI
@property (nonatomic,strong) SCPRDeluxeNewsCell *dummySingleSquare;
@property (nonatomic,strong) SCPRDeluxeNewsCell *dummySingleRectangle;
@property (nonatomic,strong) SCPRDeluxeNewsCell *dummyDouble;
@property (nonatomic,strong) SCPRDeluxeEditionsCell *dummyEditions;
@property (nonatomic,strong) UIView *dummyHeader;

// Table fade animation
@property (nonatomic,strong) SCPRUsefulTransition *tableFadeCAT;

// Methods
- (void)handleDrillDown:(NSDictionary*)story;
- (void)sanitizeBigPosts;
- (void)buildCells;
- (void)sortNewsData:(FetchContentCallback)callback;
- (void)setupBigHash:(FetchContentCallback)callback;
- (void)processEditions;
- (void)loadDummies;
- (void)loadDummies:(BOOL)editions;
- (void)prepTableTransition;

- (NSArray*)newsForDayReferencedBySection:(NSInteger)section;
- (NSArray*)sortedKeysForCellDates;
- (NSMutableArray*)dateSort:(NSMutableArray*)articles;

- (SCPRDeluxeEditionsCell*)editionCellFromEdition:(NSDictionary*)edition forceLoad:(BOOL)forceLoad;
- (void)refreshTableContents:(NSString*)categorySlug;
- (NSDictionary*)marshalledIndex:(NSDictionary*)article;

// COMPOSITE PAGE REFACTOR
@property BOOL hasAShortList;
@property BOOL hasAerticles;
@property (nonatomic,strong) NSMutableDictionary *embiggenedHash;
@property BOOL lockPageCount;

- (void)fetchContent:(NSString*)categorySlug withCallback:(FetchContentCallback)callback;
- (void)applyEmbiggening:(NSArray*)mobileFeatured withCallback:(FetchContentCallback)callback;


@end
