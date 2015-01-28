//
//  ContentManager.h
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SCPRSettings.h"
#import "domain.h"
#import "SCPRAppDelegate.h"
#import "NetworkManager.h"
#import <Parse/Parse.h>
#import <Google-Mobile-Ads-SDK/GADInterstitial.h>

#define kPushKeyBreakingNews @"breakingNews"
#define kPushKeyEvents @"events"
#define kPushKeySandbox @"sandbox_beta"
#define kFavoritesMacro @"||_FAVORITES_YIELD_||"

typedef void (^NetworkCompletionCallback)(void);

typedef enum {
  ScreenContentTypeUnknown = 0,
  ScreenContentTypeNewsPage,
  ScreenContentTypeDynamicPage,
  ScreenContentTypeProgramPage,
  ScreenContentTypeSnapshotPage,
  ScreenContentTypeCompositePage,
  ScreenContentTypeEventsPage,
  ScreenContentTypeProfilePage,
  ScreenContentTypeProgramAZPage,
  ScreenContentTypeVideoPhotoPage,
  ScreenContentTypeUnderConstruction,
  ScreenContentTypeFeedback,
  ScreenContentTypeOnboarding
} ScreenContentType;

typedef enum {
  CollectionTypeUnknown = 0,
  CollectionTypeStation = 1,
  CollectionTypeUserPlaylist = 2,
  CollectionTypeCuratedPlaylist = 3
} CollectionType;

typedef enum {
  ModelTypeUnknown = 0,
  ModelTypeSegment = 1,
  ModelTypeCollection = 2,
  ModelTypeKeyword = 3
} ModelType;

@protocol Pageable <NSObject>

- (NSInteger)index;

@end

@protocol VersionCheckable <NSObject>

- (void)currentVersionCallback:(PFObject*)cvDetails;

@end

@protocol Deactivatable <NSObject>

- (NSString*)deactivationToken;

@optional
- (void)deactivationMethod;
- (BOOL)okToDelete;

@end


@interface ContentManager : NSObject<ContentProcessor,GADInterstitialDelegate> {
  NSManagedObjectModel *_managedObjectModel;
  NSPersistentStoreCoordinator *_persistentStoreCoordinator;
  NSManagedObjectContext *_managedObjectContext;
  NSManagedObjectContext *_backgroundThreadObjectContext;
  
  SCPRSettings *_settings;
  BOOL _threadLock;
  
  // Caching
  NSMutableDictionary *_imageCache;
  NSOperationQueue *_imageViewQueue;
}




- (NSDictionary*)buildDeviceObject;
- (void)systemClean;

// Global
- (id)findModelByName:(NSString*)name andType:(ModelType)type;

// Segments
- (NSSet*)findSegmentsWithKeyword:(id)keyword;
- (Segment*)segmentFromArticle:(NSDictionary*)article;
- (NSArray*)orderedSegmentsForCollection:(Collection*)collection;
- (Segment*)findSegmentBySlug:(NSString*)slug;
- (NSArray*)findAllSegments;
- (void)destroySegment:(Segment*)segment;

// Schedulers
- (Scheduler*)findSchedulerForProgram:(NSString*)slug;
- (Scheduler*)createSchedulerForProgram:(NSString*)slug;
- (void)destroySchedulerForProgram:(NSString*)slug;

// Queue
- (void)removeSegment:(id)segment fromCollection:(id)collection;
- (void)removeSegment:(id)segment fromCollection:(id)collection suspendCommit:(BOOL)suspendCommit;
- (void)addSegment:(id)segment toCollection:(id)collection;
- (void)pushSegment:(id)segment toCollection:(id)collection;
- (Collection*)createQueue;
- (BOOL)articleExists:(id)segment inCollection:(id)collection;

// ArticleStub
- (void)persistStubForArticle:(NSDictionary*)article treatedBody:(NSString*)body links:(NSDictionary*)links;
- (void)threadedStubForArticle:(NSPersistentStoreCoordinator*)mainThreadPSC article:(NSDictionary*)article treatedBody:(NSString*)body links:(NSDictionary*)links;
- (ArticleStub*)stubForArticle:(NSDictionary*)article;
- (ArticleStub*)stubForBreakingNews:(NSString*)payload;

- (void)displayPushMessageWithPayload:(NSDictionary*)userInfo;

@property (atomic) BOOL threadLock;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic,strong) NSManagedObjectContext *backgroundThreadObjectContext;

@property (strong, nonatomic) SCPRSettings *settings;
@property (nonatomic,strong) NSMutableDictionary *imageCache;
@property (nonatomic,strong) NSMutableDictionary *contentCache;
@property (nonatomic,strong) NSMutableDictionary *programCache;
@property (nonatomic,strong) NSMutableDictionary *masterProgramList;
@property (nonatomic,strong) NSOperationQueue *imageViewQueue;
@property (nonatomic, strong) id focusedContentObject;
@property (nonatomic, strong) id focusedEditionObject;
@property (atomic) BOOL skipParse;
@property (atomic) BOOL parseReady;
@property (atomic) BOOL userIsViewingExpandedDetails;
@property BOOL passiveProgramCheck;
@property BOOL adIsLoaded;
@property (nonatomic,strong) NSOperationQueue *globalImageQueue;
@property (nonatomic,strong) NSTimer *synthesisTimer;
@property (nonatomic,strong) NSMutableArray *mutableTrendingStories;
@property (nonatomic,strong) NSMutableArray *mutableGeneralStories;
@property (nonatomic,weak) NSMutableArray *operatingOnStories;
@property (nonatomic,strong) NSDictionary *audioMetaData;
@property (nonatomic,strong) UIImageView *loader;
@property (nonatomic,weak) id<Rotatable> focusedScreen;
@property (nonatomic,strong) NSMutableArray *resizeVector;
@property (nonatomic,strong) NSMutableArray *patchList;
@property (nonatomic,strong) NSMutableArray *sortedProgramsCache;
@property (nonatomic,strong) NSMutableDictionary *globalCompositeNews;
@property (nonatomic,strong) NSMutableDictionary *compositeNewsLookupHash;
@property (nonatomic,strong) NSMutableDictionary *deactivationQueue;
@property (nonatomic,strong) NSMutableDictionary *pendingNotification;

@property (nonatomic,strong) NSMutableArray *garbageCan;

@property (nonatomic,strong) GADInterstitial *loadedAd;

@property NSInteger swipeCount;
@property NSInteger adCount;

@property (atomic) BOOL contextLock;
@property BOOL flipBackToPageOne;
@property BOOL performWriteOnMainThread;
@property BOOL adReadyOffscreen;
@property BOOL adIsDisplayingOnScreen;
@property UISwipeGestureRecognizerDirection observeForSwipe;

// Ads
@property BOOL adFailure;
@property (nonatomic,strong) NSTimer *adFailureTimer;
- (void)resetAdTracking;
- (void)tickSwipe:(UISwipeGestureRecognizerDirection)direction
           inView:(UIView*)hopefullyAScroller
      penultimate:(BOOL)penultimate
    silenceVector:(NSMutableArray*)silenceVector;
- (void)adDeliveredSuccessfully;

@property NSInteger currentNewsPage;

- (void)pushToResizeVector:(id<Rotatable>)rotatable;
- (void)popFromResizeVector;



- (void)resetNewsContent;

+ (ContentManager*)shared;

- (void)saveContext;
- (void)threadedSaveContext:(NSPersistentStoreCoordinator*)mainThreadPSC;
- (void)saveContextOnMainThread;
- (void)saveContextInBackground;
- (void)queueDeactivation:(id<Deactivatable>)articleKey;
- (void)popDeactivation:(NSString*)token;

- (NSString*)modelBase;

// Parse push to cloud
- (void)writeToParse;
- (void)checkCurrentVersion:(id)delegate;
- (void)checkForPromotionalMaterial;
- (void)patch:(NSString*)version;
- (void)writePatch:(NSString*)patch;
- (BOOL)userIsMissingPatch:(NSString*)patch;

- (BOOL)adIsReady;

// Programs
- (NSDictionary*)programCacheForProgram:(NSDictionary*)programObject;
- (void)addProgramToCache:(NSDictionary*)programObject data:(NSArray*)data;
- (NSMutableArray*)minimizedProgramFavorites:(NSString*)json;
- (NSDictionary*)maximizedProgramForMinimized:(NSDictionary*)program;
- (NSDictionary*)fullProgramObjectForTitle:(NSString*)title;
- (NSArray*)favoritedProgramsList;
- (NSMutableArray*)filterPrograms:(NSArray*)programs;
- (NSMutableArray*)sortedProgramList;
- (NSDictionary*)bakeInIDForArticle:(NSDictionary*)article;
- (NSDictionary*)bakeInShortTitleForArticle:(NSDictionary*)article;
- (NSDictionary*)bakeInBylineForArticle:(NSDictionary*)article;
- (NSDictionary*)bakeInThumbnailForArticle:(NSDictionary*)article thumb:(NSString*)thumbUrl;
- (NSDictionary*)bakeInProgramToSegment:(NSDictionary*)segment program:(NSDictionary*)program oid:(NSString*)oid;
- (NSString*)imageNameForProgram:(NSDictionary*)program;
- (void)loadAudioMetaDataForAudio:(id)audio;


// Drawer Schema
- (NSDictionary*)drawerSchema;

- (BOOL)maxPagesReached;

// Utility functions
- (NSString*)nameForModelType:(ModelType)type;
- (NSString*)nameForScreenContentType:(NSInteger)contentType;
- (NSString*)prettyNameForScreenContentType:(NSInteger)contentType;

// Settings
- (void)loadSettings;
- (void)writeSettings;
- (void)threadedSettings;
- (void)syncSettingsWithParse;
- (void)forceSettingsWithParse;
- (void)sweepUnsavedSettings;

// Cache
- (void)initDataStores;
- (void)sanitizeSettings;

// Image caching
- (UIImage*)retrieveImageFromCache:(NSString*)link;
- (NSString*)writeImageToDisk:(NSData*)img forHash:(NSString*)hash;
- (NSString*)writeImageToDisk:(NSData *)img forHash:(NSString *)hash sandbox:(BOOL)sandbox;
- (NSString*)writeImageToDisk:(NSData *)img forHash:(NSString *)hash sandbox:(BOOL)sandbox atomically:(BOOL)atomically;
- (void)writeImageDirectlyIntoCache:(id)image;
- (void)writeImage:(UIImage*)image forHash:(NSString*)hash;

- (UIImage*)retrieveSandboxedImageFromDisk:(NSString*)link;
- (void)sweepDiskAndMemory;
- (void)destroyDiskAndMemoryCache;
- (void)sweepMemory;
- (CGFloat)imageCacheSizeInMB;
- (void)printCacheUsage;

// Push
- (void)editPushForBreakingNews:(BOOL)on;
- (void)editPushForEvents:(BOOL)on;
- (BOOL)isRegisteredForPushKey:(NSString*)key;
- (void)unregisterPushNotifications;

- (void)empty;

- (BOOL)storyHasVideoAsset:(NSDictionary*)story;
- (BOOL)storyHasYouTubeAsset:(NSDictionary*)story;

- (void)convertBreakingNewsToArticle:(NSString*)alertID;
- (BOOL)isKPCCArticle:(NSDictionary*)sourceArticle;
- (BOOL)isKPCCURL:(NSString*)url;

- (void)disposeOfObject:(id<Deactivatable>)object protect:(BOOL)protect;
- (void)emptyTrash;
- (void)manuallyRemoveFromTrash:(id<Deactivatable>)object;

@end
