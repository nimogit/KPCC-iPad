//
//  SCPRSingleArticleCollectionViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 5/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

typedef enum {
  ContentCategoryUnknown = 0,
  ContentCategoryNews = 1,
  ContentCategoryEditions = 2,
  ContentCategoryPhotoVideo = 3,
  ContentCategoryEvents = 4
  
} ContentCategory;

@interface SCPRSingleArticleCollectionViewController : UIViewController<UIScrollViewDelegate,Backable,Rotatable>

@property (nonatomic,strong) IBOutlet UIScrollView *articleScroller;
@property (nonatomic,strong) NSMutableDictionary *wingArticles;
@property (nonatomic,strong) NSMutableArray *articles;
@property (nonatomic,strong) NSMutableArray *visualComponents;
@property (nonatomic,strong) NSMutableDictionary *queuedForTrash;
@property (nonatomic,weak) id parentContainer;
@property (nonatomic,weak) id parentDeluxeNewsPage;
@property (nonatomic,strong) NSString *protect;
@property (nonatomic,strong) id currentPage;
@property (nonatomic,strong) IBOutlet UIView *maskingView;
@property (nonatomic,strong) NSString *collectionType;
@property ContentCategory category;

@property NSInteger waitingForLoad;
@property NSInteger loadCount;
@property NSInteger currentIndex;
@property CGPoint currentOffset;
@property BOOL gateOpen;
@property BOOL trash;
@property (atomic) BOOL contentLock;
@property (atomic) BOOL fetchLock;
@property CGFloat targetX;

@property (nonatomic,strong) NSTimer *contentTimer;
@property (nonatomic,strong) NSOperationQueue *webcontentQueue;

- (void)setupWithCollection:(NSArray*)articles beginningAtIndex:(NSInteger)index processIndex:(BOOL)processIndex;
- (void)cleanup;
- (void)brandWithCategory:(ContentCategory)category;


@end
