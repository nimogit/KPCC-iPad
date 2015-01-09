//
//  SCPRDeluxeNewsViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 7/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRDeluxeNewsViewController.h"
#import "global.h"
#import "SCPRDeluxeNewsCell.h"
#import "SCPRTitlebarViewController.h"
#import "SCPRSingleArticleCollectionViewController.h"
#import "SCPRViewController.h"
#import "SCPRSingleArticleViewController.h"
#import "SCPRDeluxeEditionsCell.h"
#import "SCPREditionMoleculeViewController.h"
#import "SCPRMasterRootViewController.h"
#import "SCPRBlankCell.h"
#import "SCPRControllerOverlayAnimator.h"
#import <AFNetworking/AFNetworking.h>
#import "MBProgressHud.h"

#define kPreemptivePrimeThreshold 25

@interface SCPRDeluxeNewsViewController ()

@property (strong, nonatomic) NSDate *startTime;

@end

@implementation SCPRDeluxeNewsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      // Custom initialization
      [self supportedInterfaceOrientations];
    }
    return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[Utilities del] globalTitleBar].delegate = self;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(processEditions)
                                               name:@"update_news_feed_ui"
                                             object:nil];

  
  // Config table background colors, scroll appearance, and bottom loading spinner.
  self.view.backgroundColor = [UIColor blackColor];
  self.view.clipsToBounds = NO;
  self.photoVideoTable.showsVerticalScrollIndicator = NO;
  self.photoVideoTable.showsHorizontalScrollIndicator = NO;
  self.photoVideoTable.separatorColor = [UIColor clearColor];
  self.photoVideoTable.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  self.photoVideoTable.tableFooterView = self.emptyFooter;
  self.photoVideoTable.allowsSelection = NO;
  self.emptyFooter.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  self.loadingMoreNewsSpinner.color = [[DesignManager shared] periwinkleColor];
  self.dummyHeader = [[DesignManager shared] deluxeHeaderWithText:@"EDITIONS: 123"];
  
  self.lookupForDuplicates = [@{} mutableCopy];
  self.masterCellHash = [[NSMutableDictionary alloc] init];
  self.editionCellHash = [[NSMutableDictionary alloc] init];
  self.numberOfRegularStoriesPerRow = kNumberOfRegularStoriesPerRow;

  if (self.contentType == ScreenContentTypeVideoPhotoPage) {

    [self sanitizeBigPosts];
    [self buildCells];
    
  } else if (self.contentType == ScreenContentTypeCompositePage) {

    // For 'Home' page, set bottom loading spinner to tableFooterView and add pull-to-refresh control.
    [self loadDummies];
    
    self.currentNewsCategorySlug = @"home";
    self.currentNewsCategoryLongTitle = nil;

    self.photoVideoTable.tableFooterView = self.spinnerFooter;
    self.spinnerFooter.backgroundColor = [[DesignManager shared] silverCurtainsColor];
    self.loadingMoreNewsSpinner.alpha = 0.0;
    
    self.tableController.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableController.refreshControl addTarget:self
                                            action:@selector(pullToRefreshTriggered)
                                  forControlEvents:UIControlEventValueChanged];

  } else if (self.contentType == ScreenContentTypeEventsPage) {
    [self loadDummies:NO];
    [self buildCells];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  SCPRTitlebarViewController *tvc = [[Utilities del] globalTitleBar];
  tvc.view.layer.backgroundColor = [[DesignManager shared] deepOnyxColor].CGColor;
}


- (void)viewDidAppear:(BOOL)animated {
  if (self.contentType == ScreenContentTypeVideoPhotoPage) {
    [Utilities primeTitlebarWithText:@"PHOTO & VIDEO"
                        shareEnabled:NO
                           container:nil];
    
  } else {
    [[[Utilities del] globalTitleBar] applyKpccLogo];
  }
  
  if (self.contentType != ScreenContentTypeCompositePage) {
    [[[Utilities del] globalTitleBar] eraseDonateButton];
  }
  
  if (self.armToKill) {
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(killCollection)
                                   userInfo:nil
                                    repeats:NO];
  }
}

#pragma mark - Load dummy cells from nibs 
- (void)loadDummies {
  [self loadDummies:YES];
}
- (void)loadDummies:(BOOL)editions {
  if (editions) {
    self.dummyEditions = [self editionCellFromEdition:@{} forceLoad:NO];
  }
  self.dummySingleSquare = [Utilities loadNib:@"SCPRDeluxeNewsCellSingleSq"];
  self.dummySingleRectangle = [Utilities loadNib:@"SCPRDeluxeNewsCellSingle43"];
  self.dummyDouble = [Utilities loadNib:@"SCPRDeluxeNewsCellDouble"];
}


// -- Developer Note --
// Here, fetchAllContent refers to fetching the Short List, individual articles, mobile-featured articles, and then social data counts
// from Parse for all of these pieces of content. The FetchContentCallback is primarily used to handle a refresh within an
// SCPRSingleArticleCollectionViewController (ie. when scrolling left right between individual articles). Otherwise, the FetchContentCallback
// can be set to nil - as used from within this class .
# pragma mark - Network Calls
- (void)fetchAllContent:(NSString *)categorySlug withCallback:(FetchContentCallback)callback {

  self.articleMapPerDate = [@{} mutableCopy];
  
  NSString *editionsRequestStr = [NSString stringWithFormat:@"%@/editions?limit=1", kServerBase];
  
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager GET:editionsRequestStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

    if (responseObject) {

      if ([responseObject isKindOfClass:[NSArray class]]) {
        self.editionsData = (NSArray*)responseObject;
      }
      
      dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setHasAShortList:YES];
        
        if ([[ContentManager shared] currentNewsPage] == 1) {
          [self prepTableTransition];
          [self.photoVideoTable reloadData];
        }
        
        [UIView animateWithDuration:0.22 animations:^{
          self.loadingMoreNewsSpinner.alpha = 1.0;
          self.photoVideoTable.scrollEnabled = NO;
        } completion:^(BOOL finished) {
          
          [self.loadingMoreNewsSpinner startAnimating];

          // Fetch content from Articles endpoint
          [self fetchArticleContent:categorySlug withCallback:callback];
        }];
      });
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
    [[AnalyticsManager shared] failureFetchingContent:editionsRequestStr];
    return;
  }];
}

- (void)fetchArticleContent:(NSString *)categorySlug withCallback:(FetchContentCallback)callback {
  
  NSString *requestStr;
  if (categorySlug && ![categorySlug isEqualToString:@"home"]) {
    requestStr = [NSString stringWithFormat:@"%@/articles?types=news,blogs&limit=18&page=%d&categories=%@",kServerBase,[[ContentManager shared] currentNewsPage], categorySlug];
  } else {
    requestStr = [NSString stringWithFormat:@"%@/articles?types=news,blogs&limit=18&page=%d",kServerBase,[[ContentManager shared] currentNewsPage]];
  }
  
  // -- Developer Note --
  // If loading a Category, show progress HUD on the first news page
  if (categorySlug && [[ContentManager shared] currentNewsPage] < 2) {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    hud.labelFont = [[DesignManager shared] latoLight:19.0f];
    hud.labelText = [NSString stringWithFormat:@"Loading %@ stories...", [categorySlug isEqualToString:@"home"] ? @"all" : categorySlug.capitalizedString];
  }
  
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];
  [manager GET:requestStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
    
    if (responseObject && [responseObject isKindOfClass:[NSArray class]]) {
      
      __block NSArray *allChunk = (NSMutableArray*)responseObject;
      NSMutableArray *currentFetchedArticles = [[NSMutableArray alloc] initWithArray:allChunk];
      
      // -- Developer Note --
      // If scrolling past the first news page
      // 1) Grab old articles from rawArticleHash and append new articles to it
      // 2) Match content offset of the tableView to the previous one
      if ([[ContentManager shared] currentNewsPage] > 1) {
        NSMutableArray *composite = [[self.rawArticleHash objectForKey:@"general"] mutableCopy];
        [composite addObjectsFromArray:allChunk];
        allChunk = [NSArray arrayWithArray:composite];
        if (!callback) {
          self.photoVideoTable.contentOffset = self.previousOffset;
        }
      }
      
      // If filtering news by Category, save previous content offset the tableView
      if (categorySlug && self.contentType == ScreenContentTypeCompositePage) {
        _performingSectionFilter = YES;
        if (!callback) {
          self.photoVideoTable.contentOffset = self.previousOffset;
        }
      }
      
      // Check if this is part of a pull to refresh
      if (self.hardReset) {
        self.hardReset = NO;
        self.currentNewsCategorySlug = @"home";
        self.currentNewsCategoryLongTitle = nil;
        [self.tableController.refreshControl endRefreshing];
      }
      
      self.rawArticleHash = [@{ @"general" : allChunk,
                                @"lookup" : @{} } mutableCopy];
      
      // -- Developer Note --
      // Give the QueueManager a reference to the latest news so if the user
      // launches the queue and asks for 5 stories there are articles to work with
      [[QueueManager shared] setStories:self.rawArticleHash];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.lockPageCount) {
          self.lockPageCount = NO;
        } else {
          NSInteger cp = [[ContentManager shared] currentNewsPage];
          cp++;
          [[ContentManager shared] setCurrentNewsPage:cp];
        }
        
        // -- Developer Note --
        // Skip fetch from Mobile-Featured bucket when scrolling farther down through news content.
        // This sends the currently-fetched-articles directly to post-processing and queries Parse
        // to grab their Social Data counts. It seemed beneficial to cut out an necessary network call
        // here, but this should definitely be tweaked in the future if we produce a higher volume of
        // mobile-featured content.
        if ([[ContentManager shared] currentNewsPage] > 2) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.22 animations:^{
              self.loadingMoreNewsSpinner.alpha = 0.0;
              self.photoVideoTable.scrollEnabled = YES;
            } completion:^(BOOL finished) {
              [self applyEmbiggening:nil withCallback:callback];
              [self fetchSocialDataForArticles:currentFetchedArticles];
            }];
          });

        } else {

          // Network call to Mobile-Featured endpoint
          NSString *mobileFeaturedUrl = [NSString stringWithFormat:@"%@/buckets/mobile-featured?limit=8",kServerBase];
          [manager GET:mobileFeaturedUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (responseObject) {
            
              NSDictionary *bucket = (NSDictionary*)responseObject;
              NSMutableArray *articles = [[bucket objectForKey:@"articles"] mutableCopy];
              if ([articles count] >= 8) {
                articles = [[articles subarrayWithRange:NSMakeRange(0, 6)] mutableCopy];
              }
            
#ifdef DEBUG
              // -- Developer Note --
              // In debug, always embiggen 1 article for testing purposes
              /*NSDictionary *realArticle = [[self.rawArticleHash objectForKey:@"general"] objectAtIndex:5];
              BOOL okToAdd = YES;
              for (NSDictionary *article in articles) {
                if ([Utilities article:article isSameAs:realArticle]) {
                  okToAdd = NO;
                  break;
                }
              }
              if (okToAdd) {
                [articles addObject:realArticle];
              }*/
#endif
              dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.22 animations:^{
                  self.loadingMoreNewsSpinner.alpha = 0.0;
                  self.photoVideoTable.scrollEnabled = YES;
                } completion:^(BOOL finished) {
                  [self applyEmbiggening:articles withCallback:callback];
                  
                  // Grab the most recent article from the Mobile Featured bucket so we can scan Parse for it
                  if ([articles count] >= 1) {
                    [currentFetchedArticles addObject:[articles objectAtIndex:0]];
                  }
                  
                  // Make a call to Parse and fetch social data for the current set of fetched articles
                  [self fetchSocialDataForArticles:currentFetchedArticles];
                }];

              }); // Dispatch in background closure
            }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          
            [[AnalyticsManager shared] failureFetchingContent:mobileFeaturedUrl];
            return;
          
          }]; // Fetch from Mobile-Featured endpoint

        } // if-else for skipping Mobile-Featured

      }); // Dispatch in background closure
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    [[AnalyticsManager shared] failureFetchingContent:requestStr];
    return;

  }]; // Fetch from Articles endpoint
}

- (void)fetchSocialDataForArticles:(NSArray *)articles{
  
  // Construct an array of ids from articles.
  NSMutableArray *articleIdArray = [[NSMutableArray alloc]init];
  for (NSDictionary *article  in articles) {
    if ([article objectForKey:@"id"]) {
      [articleIdArray addObject:[article objectForKey:@"id"]];
    }
  }
  
  // Make request to our Parse Cloud Code function and retrieve social share counts for given articles.
  [PFCloud callFunctionInBackground:@"social_data"
                     withParameters:@{@"articleIds": articleIdArray}
                              block:^(NSDictionary *results, NSError *error) {
                                
                                if (!error) {
                                  if (!self.socialShareCountHash) {
                                    self.socialShareCountHash = [[NSMutableDictionary alloc] init];
                                  }
                                  
                                  for (NSDictionary *eachArticle in results) {
                                    if ([[results objectForKey:eachArticle] objectForKey:@"facebook_count"] && [[results objectForKey:eachArticle] objectForKey:@"twitter_count"]){
                                      [self.socialShareCountHash setObject:[results objectForKey:eachArticle] forKey:eachArticle];
                                    }
                                  }
                                  [self.photoVideoTable reloadData];
                                }
                              }];
}


#pragma mark - Process News Content
- (void)applyEmbiggening:(NSMutableArray *)mobileFeatured withCallback:(FetchContentCallback)callback {
  
  [self setHasAerticles:YES];
  
  NSMutableDictionary *newLookup = [@{} mutableCopy];
  NSArray *incumbent = [self.rawArticleHash objectForKey:@"general"];
  NSMutableDictionary *incumbentHash = [@{} mutableCopy];
  
  for (NSDictionary *incArticle in incumbent) {
    [incumbentHash setObject:@1 forKey:[incArticle objectForKey:@"id"]];
  }
  
  for (NSDictionary *article in mobileFeatured) {
    if ([incumbentHash objectForKey:[article objectForKey:@"id"]]) {
      [newLookup setObject:@1 forKey:[article objectForKey:@"id"]];
    }
  }
  
  NSMutableDictionary *bhM = [self.rawArticleHash mutableCopy];
  [bhM setObject:newLookup forKey:@"lookup"];
  self.rawArticleHash = [[NSDictionary dictionaryWithDictionary:bhM] mutableCopy];
  [self sortNewsData:callback];
}


- (void)sortNewsData:(FetchContentCallback)callback {
  
  self.numberOfRegularStoriesPerRow = kNumberOfRegularStoriesPerRow;
  
  self.dateCells = [[NSMutableDictionary alloc] init];
  self.cacheMutex = YES;
  
  [self setupBigHash:callback];
  
  NSDictionary *lookup = [self.bigHash objectForKey:@"lookup"];
  NSDictionary *temporal = [self.bigHash objectForKey:@"general"];
  
  self.regularStoriesPerDate = [[NSMutableDictionary alloc] init];
  self.editionsStoriesPerDate = [[NSMutableDictionary alloc] init];
  self.embiggenedStoriesPerDate = [[NSMutableDictionary alloc] init];
  self.articleMapPerDate = [[NSMutableDictionary alloc] init];
  
  dispatch_queue_t queueToUse = [[ContentManager shared] currentNewsPage] > 2 ? dispatch_get_main_queue() : (dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
                                                                                                             
  dispatch_async(queueToUse, ^{
  
    __block BOOL postProcess = YES;
    if ( [NSThread isMainThread] ) {
      postProcess = NO;
    }
    
    NSArray *dates = [temporal allKeys];
    dates = [dates sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      NSString *ds1 = (NSString*)obj1;
      NSString *ds2 = (NSString*)obj2;
      
      NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
      [fmt setDateFormat:@"YYYY-MM-dd"];
      
      NSDate *d1 = [fmt dateFromString:ds1];
      NSDate *d2 = [fmt dateFromString:ds2];
      
      if ( [d1 earlierDate:d2] == d1 ) {
        return NSOrderedDescending;
      } else {
        return NSOrderedAscending;
      }
    }];

    self.sortedKeyArrayCache = dates;
    
    for ( unsigned i = 0; i < [self.sortedKeyArrayCache count]; i++ ) {
      NSString *dateKey = [self.sortedKeyArrayCache objectAtIndex:i];
      NSMutableArray *day = [temporal objectForKey:dateKey];
      for ( unsigned j = 0; j < [day count]; j++ ) {
        NSDictionary *article = [day objectAtIndex:j];
        

        NSString *hash = [article objectForKey:@"id"];
        
        // Look for editions
        if ( [article objectForKey:@"abstracts"] ) {
          NSMutableArray *dateVector = [self.editionsStoriesPerDate objectForKey:dateKey];
          if ( !dateVector ) {
            dateVector = [[NSMutableArray alloc] init];
          }
          [dateVector addObject:article];
          [self.editionsStoriesPerDate setObject:dateVector
                                          forKey:dateKey];
          continue;
        }
        
        // Look for embiggened
        
        if ( [lookup objectForKey:hash] && self.numberOfRegularStoriesPerRow > 1 ) {
          NSMutableArray *dateVector = [self.embiggenedStoriesPerDate objectForKey:dateKey];
          if ( !dateVector ) {
            dateVector = [[NSMutableArray alloc] init];
          }
          [dateVector addObject:article];
          [self.embiggenedStoriesPerDate setObject:dateVector
                                          forKey:dateKey];
          continue;
        }
        
        NSMutableArray *dateVector = [self.regularStoriesPerDate objectForKey:dateKey];
        if ( !dateVector ) {
          dateVector = [[NSMutableArray alloc] init];
        }
    
        [dateVector addObject:article];
      
        
        [self.regularStoriesPerDate setObject:dateVector
                                       forKey:dateKey];
      }
      
      NSMutableArray *articleMap = [[NSMutableArray alloc] init];
      int embigPtr = 0;
      int editPtr = 0;
      int regPtr = 0;
      BOOL embigDone = NO;
      BOOL editDone = NO;
      BOOL regDone = NO;
      
      NSMutableArray *regDay = [self.regularStoriesPerDate objectForKey:dateKey];
      if ( !regDay ) {
        regDay = [[NSMutableArray alloc] init];
      }
      NSMutableArray *embigDay = [self.embiggenedStoriesPerDate objectForKey:dateKey];
      if ( !embigDay ) {
        embigDay = [[NSMutableArray alloc] init];
      }
      NSMutableArray *editDay = [self.editionsStoriesPerDate objectForKey:dateKey];
      if ( !editDay ) {
        editDay = [[NSMutableArray alloc] init];
      }
      while ( !embigDone || !editDone || !regDone ) {
        
        if ( regPtr >= [regDay count] ) {
          regDone = YES;
        }
        if ( editPtr >= [editDay count] ) {
          editDone = YES;
        }
        if ( embigPtr >= [embigDay count] ) {
          embigDone = YES;
        }
        
        NSDictionary *regularCandidate = nil;
        NSDictionary *embiggenedCandidate = nil;
        NSDictionary *editionsCandidate = nil;
        NSMutableArray *dates = [[NSMutableArray alloc] init];
        NSMutableArray *identifier = [[NSMutableArray alloc] init];
        if ( !regDone ) {
          regularCandidate = [regDay objectAtIndex:regPtr];
          NSDate *d = [Utilities dateFromRFCString:[regularCandidate objectForKey:@"published_at"]];
          [identifier addObject:@"regular"];
          [dates addObject:d];
        }
        if ( !editDone ) {
          editionsCandidate = [editDay objectAtIndex:editPtr];
          NSDate *d = [Utilities dateFromRFCString:[editionsCandidate objectForKey:@"published_at"]];
          [dates addObject:d];
          [identifier addObject:@"editions"];
        }
        if ( !embigDone ) {
          embiggenedCandidate = [embigDay objectAtIndex:embigPtr];
          NSDate *d = [Utilities dateFromRFCString:[embiggenedCandidate objectForKey:@"published_at"]];
          [dates addObject:d];
          [identifier addObject:@"embiggened"];
        }
        
        
        if ( [dates count] > 0 ) {
          NSInteger winner = [Utilities latestDate:dates];
          if ( winner < 0 ) {
            continue;
          }
          NSString *ident = [identifier objectAtIndex:winner];
          if ( [ident isEqualToString:@"regular"] ) {
            
            NSMutableArray *map = [[NSMutableArray alloc] init];
            if ( (regPtr+1 < [regDay count]) && self.numberOfRegularStoriesPerRow > 1 ) {
              [map addObject:[regDay objectAtIndex:regPtr]];
              [map addObject:[regDay objectAtIndex:regPtr+1]];
              regPtr += 2;
            } else {
              [map addObject:[regDay objectAtIndex:regPtr]];
              regPtr++;
            }
            
            NSDictionary *meta = @{ @"type" : @"regular",
                                    @"posts" : map };
            
            [articleMap addObject:meta];
          }
          
          if ( [ident isEqualToString:@"editions"] ) {
            
            NSDictionary *meta = @{ @"type" : @"editions",
                                    @"posts" : @[[editDay objectAtIndex:editPtr]] };
            
            [articleMap addObject:meta];
            editPtr++;
            
          }
          
          if ( [ident isEqualToString:@"embiggened"] ) {
            
            NSDictionary *meta = @{ @"type" : @"embiggened",
                                    @"posts" : @[[embigDay objectAtIndex:embigPtr]] };
            [articleMap addObject:meta];
            embigPtr++;
            
          }
        }
      }
      [self.articleMapPerDate setObject:articleMap
                                 forKey:dateKey];
      
      dispatch_async(dispatch_get_main_queue(), ^{

        self.cacheMutex = NO;
        [self prepTableTransition];
        [self.photoVideoTable reloadData];
        
        // If filtering by Section, adjust content offset of tableView to proper location
        if (self.performingSectionFilter) {
          _performingSectionFilter = NO;
          
          [MBProgressHUD hideHUDForView:self.view animated:YES];
          
          if ([[ContentManager shared] currentNewsPage] <= 2) {
            
            if ([Utilities isIOS7]) {
              [UIView animateWithDuration:0.56
                                    delay:0.0
                   usingSpringWithDamping:0.65
                    initialSpringVelocity:0.0
                                  options:UIViewAnimationOptionBeginFromCurrentState
                               animations:^{
                                 self.photoVideoTable.contentOffset = CGPointMake(0.0, self.dummyEditions.frame.size.height);
                               } completion:^(BOOL finished) {
                                 
                               }];
            } else {
              [UIView animateWithDuration:0.56
                                    delay:0.0
                                  options:UIViewAnimationOptionCurveEaseInOut
                               animations:^{
                                 self.photoVideoTable.contentOffset = CGPointMake(0.0, self.dummyEditions.frame.size.height);
                               } completion:^(BOOL finished) {

                               }];
            }
          } else {
            if (!callback) {
              self.photoVideoTable.contentOffset = self.previousOffset;
            }
          }
        } // if self.performingSectionFilter
        
      }); // dispatch_async
      
    }
  });
}

- (void)setupBigHash:(FetchContentCallback)callback {

  self.bigHash = @{};
  self.lookupForDuplicates = [@{} mutableCopy];
  
  if ( self.rawArticleHash && [self.rawArticleHash count] > 0 ) {
    self.bigHash = [NSMutableDictionary dictionaryWithDictionary:self.rawArticleHash];
  } else {
    if ( !self.bigHash ) {
      NSDictionary *part = @{ @"general" : @[], @"lookup" : @[] };
      self.bigHash = [part mutableCopy];
    }
  }
  
  NSArray *general = [self.bigHash objectForKey:@"general"];
  self.monolithicNewsVector = [general mutableCopy];
  
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    NSDictionary *d = (NSDictionary*)evaluatedObject;
    return ( [d objectForKey:@"abstracts"] == nil && [d objectForKey:@"summary"] == nil );
  }];
  
  [self.monolithicNewsVector filterUsingPredicate:predicate];
  
  
  NSMutableDictionary *dateHash = [[NSMutableDictionary alloc] init];
  for ( NSDictionary *generalArticle in general ) {
    
    if ( [generalArticle objectForKey:@"id"] ) {
      NSString *sID = [generalArticle objectForKey:@"id"];
      if ( [self.lookupForDuplicates objectForKey:sID] ) {
        NSLog(@"Duplicate article : %@",[generalArticle objectForKey:@"short_title"]);
        continue;
      } else {
        [self.lookupForDuplicates setObject:@1 forKey:sID];
      }
    }
    
    NSString *dateString = [generalArticle objectForKey:@"published_at"];
    NSDate *dateObj = [Utilities dateFromRFCString:dateString];
    NSString *pretty = [NSDate stringFromDate:dateObj
                                   withFormat:@"YYYY-MM-dd"];
    
    NSMutableArray *day = [dateHash objectForKey:pretty];
    if ( !day ) {
      day = [[NSMutableArray alloc] init];
    }
    [day addObject:generalArticle];
    [dateHash setObject:day
                 forKey:pretty];
    
  }

  self.bigHash = @{ @"lookup" : [self.bigHash objectForKey:@"lookup"],
                    @"general" : dateHash };
  
  if (callback) {
    callback(YES);
  }
}

- (void)processEditions {
  self.bigHash = [[ContentManager shared] globalCompositeNews];
  [self sortNewsData:nil];
  
  [self.photoVideoTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0
                                                                    inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)buildCells {
  self.cells = [[NSMutableArray alloc] init];

  for ( unsigned i = 0; i < [self.posts count]; i++ ) {
    NSString *baseFormat = @"SCPRDeluxeNewsCellDouble";
    NSString *aspectCode = @"";
    NSDictionary *post = [self.posts objectAtIndex:i];
    BOOL grabTwo = YES;
    BOOL composite = self.contentType == ScreenContentTypeCompositePage;
    
    if (((i == 0 && composite) || [self.bigHash objectForKey:[post objectForKey:@"id"]]) && [Utilities isIpad]) {
      // BIG
      aspectCode = [[DesignManager shared] aspectCodeForContentItem:post
                                                            quality:AssetQualityFull];
      baseFormat = @"SCPRDeluxeNewsCellSingle";
      grabTwo = NO;
    } else {
      // SMALL
      aspectCode = @"";
    }
    
    // Do some cooking
    aspectCode = [aspectCode stringByReplacingOccurrencesOfString:@"_clip" withString:@""];
    NSString *template = [NSString stringWithFormat:@"%@%@",baseFormat,aspectCode];

    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared] xibForPlatformWithName:template]
                                                     owner:nil
                                                   options:nil];
    SCPRDeluxeNewsCell *vpc = (SCPRDeluxeNewsCell*)[objects objectAtIndex:0];
  
    if (grabTwo) {
      if (i+1 >= [self.posts count]) {
        vpc.posts = @[post];
        vpc.facade1.view.alpha = 0.0;
      } else {
        NSDictionary *secondary = [self.posts objectAtIndex:i+1];
        i++;
        vpc.posts = @[post,secondary];
      }
    } else {
      vpc.posts = @[post];
      vpc.facade0.embiggened = [Utilities isIpad];
    }
    
    vpc.facade0.parentPVController = self;
    vpc.facade1.parentPVController = self;
    vpc.facade0.contentType = self.contentType;
    vpc.facade1.contentType = self.contentType;
    vpc.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.cells addObject:vpc];
  }
}

- (void)sanitizeBigPosts {
  
  NSMutableDictionary *fresh = [[NSMutableDictionary alloc] init];
  NSLog(@"Number of big Video/Photo stories before filter : %d",[self.bigHash count]);
  for (NSString *key in [self.bigHash allKeys]) {
    BOOL present = NO;
    for (NSDictionary *vpData in self.posts) {
      NSString *candidate = [vpData objectForKey:@"id"];
      if ([candidate isEqualToString:key]) {
        present = YES;
        break;
      }
    }
    if (present) {
      [fresh setObject:@1 forKey:key];
    }
  }
  self.bigHash = fresh;
   NSLog(@"Number of big Video/Photo stories after filter : %d",[self.bigHash count]);
}


- (void)killCollection {
  NSLog(@"Killing pushed content...");
  self.armToKill = NO;
  self.pushedContent = nil;
}


# pragma mark - Handling Cell Selection

- (void)handleDrillDown:(NSDictionary *)story {

  if ( [story objectForKey:@"summary"] ) {
    
    NSArray *abstracts = nil;
    NSInteger index = 0;
    NSDictionary *dict = nil;
    for ( NSString *key in self.editionCellHash ) {
      NSDictionary *d = [self.editionCellHash objectForKey:key];
      abstracts = [d objectForKey:@"abstracts"];
      BOOL found = NO;
      for ( unsigned i = 0; i < [abstracts count]; i++ ) {
        NSDictionary *absCandidate = [abstracts objectAtIndex:i];
        if ( absCandidate == story ) {
          index = i;
          found = YES;
          
          SCPRDeluxeEditionsCell *cell = [d objectForKey:@"editionCell"];
          dict = cell.mainEdition;
          
          break;
        }
      }
      if ( found ) {
        break;
      }
    }
    
    // This is an edition
    SCPREditionMoleculeViewController *emvc = [[SCPREditionMoleculeViewController alloc]
                                               initWithNibName:[[DesignManager shared]
                                                                xibForPlatformWithName:@"SCPREditionMoleculeViewController"]
                                               bundle:nil];
    

    emvc.view.frame = emvc.view.frame;
    emvc.fromNewsPage = YES;
    emvc.parentEditionContentViewController = self;
    
    [[ContentManager shared] pushToResizeVector:emvc];
    
    [[[Utilities del] globalTitleBar] morph:BarTypeEditions
                                  container:emvc];
    
    [[[Utilities del] globalTitleBar] applyBackButtonText:@"NEWS"];

    [emvc setupWithEdition:dict
                   andIndex:index];
    
    self.pushedContent = emvc;

    SCPRViewController *vc = [[Utilities del] viewController];
    if ( vc.currentAnchors ) {
      if ( vc.currentAnchors[@"top"] ) {
        NSLayoutConstraint *top = vc.currentAnchors[@"top"];
        [UIView animateWithDuration:1.33 animations:^{
          
          [top setConstant:-40.0];
          [self.view.superview layoutIfNeeded];
          
        } completion:^(BOOL finished) {
          [self.navigationController pushViewController:emvc
                                               animated:YES];
        }];
      }
    }
    
  } else {
    if (self.contentType == ScreenContentTypeCompositePage || self.contentType == ScreenContentTypeVideoPhotoPage) {
      SCPRSingleArticleCollectionViewController *collection = [[SCPRSingleArticleCollectionViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                                            options:@{ UIPageViewControllerOptionSpineLocationKey : @( UIPageViewControllerSpineLocationMin)}];
    
      NSArray *collectionType = nil;
      if ( self.contentType == ScreenContentTypeVideoPhotoPage ) {
        collectionType = self.posts;
        collection.category = ContentCategoryPhotoVideo;
      } else {
        collection.category = ContentCategoryNews;
        NSString *pa = [story objectForKey:@"published_at"];
        NSDate *d = [Utilities dateFromRFCString:pa];
        NSString *key = [NSDate stringFromDate:d withFormat:@"YYYY-MM-dd"];
        NSArray *dayStories = [[self.bigHash objectForKey:@"general"] objectForKey:key];
        collectionType = dayStories;
      }
      
      // Remove editions because they F-up the scroller
      NSMutableArray *clean = [[NSMutableArray alloc] init];
      for ( NSDictionary *d in collectionType ) {
        if ( [d objectForKey:@"abstracts"] ) {
          continue;
        }
        [clean addObject:d];
      }
      
      collectionType = [NSArray arrayWithArray:clean];
      
      self.pushedCollection = collection;
      SCPRAppDelegate *del = [Utilities del];
      SCPRViewController *mvc = (SCPRViewController*)del.viewController;
    
      collection.view.frame = collection.view.frame;
    
      NSUInteger index = 0;
      for ( unsigned i = 0; i < [collectionType count]; i++ ) {
        NSDictionary *article = [collectionType objectAtIndex:i];
        if ( story == article || [[story objectForKey:@"id"] isEqualToString:[article objectForKey:@"id"]] ) {
          index = i;
          break;
        }
      }
    
      [self.navigationController
       pushViewController:collection animated:YES];
    
      mvc.mainPageScroller.scrollEnabled = NO;
      collection.parentDeluxeNewsPage = self;
      
      NSDictionary *marshalled = [self marshalledIndex:[collectionType objectAtIndex:index]];
      NSNumber *n = [marshalled objectForKey:@"index"];
      NSArray *arrayToUse = nil;
      if ( n ) {
        NSLog(@"Using world context...");
        index = [n intValue];
        arrayToUse = [NSMutableArray arrayWithArray:self.monolithicNewsVector];
      } else {
        NSLog(@"Using per-date context...");
        arrayToUse = [NSMutableArray arrayWithArray:collectionType];
      }
      
      [collection setupWithCollection:arrayToUse
                   beginningAtIndex:index
                       processIndex:YES];
    
      [[[Utilities del] globalTitleBar] morph:BarTypeModal
                                  container:collection];
    
      NSString *title = [[ContentManager shared] prettyNameForScreenContentType:self.contentType];

      
      [[[Utilities del] globalTitleBar] applyBackButtonText:[title uppercaseString]];
      
      collection.collectionType = [[ContentManager shared] prettyNameForScreenContentType:self.contentType];
      [[ContentManager shared] pushToResizeVector:collection];
      
      if ( self.contentType == ScreenContentTypeVideoPhotoPage ) {
        if ( [[ContentManager shared] storyHasVideoAsset:story] ) {
          SCPRSingleArticleViewController *single = (SCPRSingleArticleViewController*)[collection currentPage];
          [single presentVideo];
        }
      }
      
      NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:[NSMutableDictionary dictionaryWithDictionary:story]] mutableCopy];
      NSDictionary *newParams = @{ @"article_id" : [story objectForKey:@"id"],
                                 @"date" : [NSDate stringFromDate:[NSDate date]
                                                       withFormat:@"MMM dd, YYYY HH:mm"],
                                   @"accessed_from" : [[ContentManager shared] prettyNameForScreenContentType:self.contentType],
                                   @"audio_on" : ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO"};
    
      for ( NSString *key in newParams ) {
        [params setObject:[newParams objectForKey:key]
                 forKey:key];
      }
    
      [[AnalyticsManager shared] logEvent:@"story_read"
                         withParameters:params];
      
    } else if ( self.contentType == ScreenContentTypeEventsPage ) {

      NSInteger index = 0;
      for ( unsigned i = 0; i < [self.posts count]; i++ ) {
        NSDictionary *d = [self.posts objectAtIndex:i];
        if ( [Utilities article:d isSameAs:story] ) {
          index = i;
          break;
        }
      }
      
      SCPRSingleArticleCollectionViewController *collection = [[SCPRSingleArticleCollectionViewController alloc]
                                                             initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRSingleArticleCollectionViewController"]
                                                             bundle:nil];
    
      collection.category = ContentCategoryEvents;
      collection.view.frame = collection.view.frame;
      NSMutableArray *arrayToUse = [NSMutableArray arrayWithArray:self.posts];
      self.pushedCollection = collection;
      
      [collection setupWithCollection:arrayToUse
                   beginningAtIndex:index
                       processIndex:YES];
      
      [[ContentManager shared] pushToResizeVector:collection];
    
      collection.parentDeluxeNewsPage = self;
      
      [self.navigationController
       pushViewController:collection animated:YES];
      
      [[[Utilities del] globalTitleBar] morph:BarTypeModal
                                  container:collection];
      
      NSString *title = [[ContentManager shared] prettyNameForScreenContentType:self.contentType];

      [[[Utilities del] globalTitleBar] applyBackButtonText:[title uppercaseString]];
    }
  }


}

- (NSMutableArray*)dateSort:(NSMutableArray *)articles {
  return [[articles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    
    
    NSDictionary *ds1 = (NSDictionary*)obj1;
    NSDictionary *ds2 = (NSDictionary*)obj2;
    
    NSString *dateS1 = [ds1 objectForKey:@"published_at"];
    NSString *dateS2 = [ds2 objectForKey:@"published_at"];
    
    NSDate *d1 = [Utilities dateFromRFCString:dateS1];
    NSDate *d2 = [Utilities dateFromRFCString:dateS2];
    
    if ( [d1 earlierDate:d2] == d1 ) {
      return (NSComparisonResult)NSOrderedDescending;
    } else {
      return (NSComparisonResult)NSOrderedAscending;
    }
  }] mutableCopy];
}

- (NSDictionary*)marshalledIndex:(NSDictionary *)article {
  [[AnalyticsManager shared] tS];
  
  for ( unsigned i = 0; i < [self.monolithicNewsVector count]; i++ ) {
    NSDictionary *incumbent = [self.monolithicNewsVector objectAtIndex:i];
    if ( article == incumbent || [Utilities article:incumbent
                                           isSameAs:article] ) {
      return @{ @"index" : [NSNumber numberWithInt:i] };
    }
  }
  
  [[AnalyticsManager shared] tF:@"Placing article in world context..."];
  
  return @{};
  
}

- (NSArray*)newsForDayReferencedBySection:(NSInteger)section {
  NSArray *sortedKeys = [self sortedKeysForCellDates];
  if ( sortedKeys.count == 0 ) {
    return 0;
  }
  
  NSArray *a1 = [self.dateCells objectForKey:[sortedKeys objectAtIndex:section-1]];
  return a1;
}

- (NSArray*)sortedKeysForCellDates {
  
  return self.sortedKeyArrayCache;
  
}

- (SCPRDeluxeEditionsCell*)editionCellFromEdition:(NSDictionary *)edition forceLoad:(BOOL)forceLoad {

  NSString *editionPD = [edition objectForKey:@"published_at"];
  if ( !editionPD ) {
    editionPD = @"DUMMY";
  }
  NSDictionary *meta = [self.editionCellHash objectForKey:[Utilities sha1:editionPD]];
  SCPRDeluxeEditionsCell *cell = nil;
  if ( meta ) {
    cell = [meta objectForKey:@"editionCell"];
    [cell prime:self];
    return cell;
  }
  
  
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRDeluxeEditionsCell"]
                                                   owner:nil
                                                 options:nil];
  cell = [objects objectAtIndex:0];
  cell.parentController = self;
  
  
  NSDictionary *latestEdition = edition;
  cell.mainEdition = latestEdition;
  
  NSArray *abstracts = [latestEdition objectForKey:@"abstracts"];
  if ( !abstracts ) {
    abstracts = @[];
  }
  
  [self.editionCellHash setObject:@{ @"abstracts" : abstracts,
                                     @"editionCell" : cell }
                           forKey:[Utilities sha1:editionPD]];
  return cell;
}


#pragma mark - SCPRTitlebarDelegate

- (void)openSectionsTapped {

  if (self.sectionsTableOpen) {
    return;
  }

  [[[Utilities del] globalTitleBar] applyCategoriesUI];
  
  // Force scrolling on the news table to hard stop
  CGPoint offset = self.photoVideoTable.contentOffset;
  [self.photoVideoTable setContentOffset:offset animated:NO];

  self.categoriesTableViewController = [[SCPRNewsSectionTableViewController alloc] init];
  self.categoriesTableViewController.currentSectionSlug = self.currentNewsCategorySlug;
  self.categoriesTableViewController.sectionsDelegate = self;

  self.categoriesBlurView = [[FXBlurView alloc] initWithFrame:self.view.frame];
  self.categoriesBlurView.blurRadius = 5;
  self.categoriesBlurView.tintColor = [UIColor clearColor];
  self.categoriesBlurView.dynamic = NO;
  
  self.categoriesDarkView = [[UIView alloc] initWithFrame:self.categoriesBlurView.frame];
  self.categoriesDarkView.backgroundColor = [UIColor blackColor];
  
  self.categoriesBlurView.alpha = 0.0;
  self.categoriesDarkView.alpha = 0.0;
  
  [self.view addSubview:self.categoriesBlurView];
  [self.view addSubview:self.categoriesDarkView];

  self.categoriesTableViewController.view.layer.cornerRadius = 5;
  self.categoriesTableViewController.view.layer.masksToBounds = YES;

  self.categoriesTableViewController.view.transform = CGAffineTransformMakeScale(1.8, 1.8);
  [self.view addSubview:self.categoriesTableViewController.view];

  // Hide the player widget
  [[[Utilities del] viewController] hidePlayer];
  
  if ([Utilities isIOS7]) {
    [UIView animateWithDuration:0.45
                          delay:0.0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.categoriesTableViewController.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
                       self.categoriesDarkView.alpha = 0.7;
                       self.categoriesBlurView.alpha = 1.0;
                       self.categoriesBlurView.blurRadius = 30;
                     } completion:^(BOOL finished){
                       _sectionsTableOpen = YES;
                       [[AnalyticsManager shared] logEvent:@"menu_open_topics" withParameters:@{}];
                     }];
  } else {
    [UIView animateWithDuration:0.3f animations: ^{
     self.categoriesTableViewController.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
     self.categoriesDarkView.alpha = 0.7;
     self.categoriesBlurView.alpha = 1.0;
     self.categoriesBlurView.blurRadius = 30;
     } completion:^(BOOL finished) {
       _sectionsTableOpen = YES;
       [[AnalyticsManager shared] logEvent:@"menu_open_topics" withParameters:@{}];
     }];
  }
}

- (void)closeSectionsTapped {
  
  if (!self.sectionsTableOpen) {
    return;
  }

  [[[Utilities del] globalTitleBar] removeCategoriesUI];
  
  // Show the player widget
  [[[Utilities del] viewController] displayPlayer];

  [UIView animateWithDuration:0.4f animations: ^{
    self.categoriesTableViewController.view.transform = CGAffineTransformMakeScale(1.75f, 1.75f);
    self.categoriesTableViewController.view.alpha = 0.0;

    if (self.categoriesBlurView) {
      self.categoriesBlurView.alpha = 0.0;
    }
    if (self.categoriesDarkView) {
      [self.categoriesDarkView setBackgroundColor:[UIColor clearColor]];
    }
    
  } completion: ^(BOOL finished) {
    [self.categoriesTableViewController.view removeFromSuperview];
    if (self.categoriesBlurView) {
      [self.categoriesBlurView removeFromSuperview];
    }
    if (self.categoriesDarkView) {
      [self.categoriesDarkView removeFromSuperview];
    }

    _sectionsTableOpen = NO;
  }];
}


#pragma mark - SCPRNewsSectionDelegate
- (void)sectionSelected:(NSDictionary *)section {
  [self closeSectionsTapped];

  self.currentNewsCategorySlug = [section objectForKey:@"slug"];
  self.currentNewsCategoryLongTitle = [[section objectForKey:@"title"] isEqualToString:@"Home"] ? nil : [section objectForKey:@"title"];

  // Hold off the news fetch for a split-second to let the Sections-close animation go smoothly.
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self refreshTableContents:self.currentNewsCategorySlug];
  });
  
  [[AnalyticsManager shared] logEvent:@"menu_select_topic" withParameters:@{ @"topic" : self.currentNewsCategorySlug }];
}


#pragma mark - Pull to Refresh
- (void)pullToRefreshTriggered {
  self.hardReset = YES;
  [self.tableController.refreshControl beginRefreshing];
  [self refreshTableContents:nil];
  [[AnalyticsManager shared] logEvent: @"load_pulldown_refresh" withParameters:@{}];
}


#pragma mark - Refresh table contents
- (void)refreshTableContents:(NSString *)categorySlug {
  
  self.lookupForDuplicates = [@{} mutableCopy];
  [[ContentManager shared] resetNewsContent];
  [[ContentManager shared] setCurrentNewsPage:1];
  
  if (categorySlug) {
    self.previousOffset = self.photoVideoTable.contentOffset;
    [self fetchArticleContent:categorySlug withCallback:nil];
  } else {
    [self fetchAllContent:nil withCallback:nil];
  }
}

- (void)updateTableContents {
  
  if ( self.failoverTimer ) {
    if ( [self.failoverTimer isValid] ) {
      [self.failoverTimer invalidate];
    }
    self.failoverTimer = nil;
  }
  
  NSLog(@"Editions finished loading after initial delay ****************************************** ");
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"editions_complete"
                                                object:nil];
  [self prepTableTransition];
  [self.photoVideoTable reloadData];
}

- (void)handleCompositeNews:(NSDictionary *)content {
  [self.loadingMoreNewsSpinner stopAnimating];
  [UIView animateWithDuration:0.22 animations:^{
    self.loadingMoreNewsSpinner.alpha = 0.0;
  } completion:^(BOOL finished) {
    
    [[QueueManager shared] setStories:content];
    [[ContentManager shared] setGlobalCompositeNews:[content mutableCopy]];
    
    self.photoVideoTable.scrollEnabled = YES;
    self.rawArticleHash = [content mutableCopy];
    
    [self sortNewsData:nil];
    
    if (self.hardReset) {
      self.hardReset = NO;
      [self.photoVideoTable reloadData];
      [self.tableController.refreshControl endRefreshing];
    } else {
      if (self.lockScrollUpdates) {
        self.lockScrollUpdates = NO;
      }
    }
    
  }];
}


# pragma mark - AnimationDelegate
- (void)finalizeAnimation {
  
  
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

  if ( [anim isKindOfClass:[SCPRUsefulTransition class]] ) {
    [UIView animateWithDuration:0.12 animations:^{
      self.photoVideoTable.alpha = 1.0;
    } completion:^(BOOL finished) {
      
      // Force the category blur view to redraw its background contents
      if (self.contentType == ScreenContentTypeCompositePage) {
        if ([self.view.subviews containsObject:self.categoriesBlurView]) {
          [self.categoriesBlurView updateAsynchronously:NO completion:nil];
        }
      }
    }];
  }
}

#pragma mark - Rotatable
- (void)handleRotationPre {
  self.reorienting = YES;
  
  [UIView animateWithDuration:0.12 animations:^{

    // Fade out the categories table and associated views
    if (self.contentType == ScreenContentTypeCompositePage) {
      if ([self.view.subviews containsObject:self.categoriesBlurView]) {
          self.categoriesBlurView.alpha = 0.0;
      }
      if ([self.view.subviews containsObject: self.categoriesDarkView]) {
        self.categoriesDarkView.alpha = 0.0;
      }
      if ([self.view.subviews containsObject: self.categoriesTableViewController.view]) {
        self.categoriesTableViewController.view.alpha = 0.0;
      }
    }
    
    //self.photoVideoTable.alpha = 0.0;
  }];
}

- (void)handleRotationPost {
  
  [self.masterCellHash removeAllObjects];
  [self.editionCellHash removeAllObjects];
  
  [self loadDummies];
  [self buildCells];

  [self.photoVideoTable reloadData];
  
  /*if (self.contentType == ScreenContentTypeCompositePage || self.contentType == ScreenContentTypeEventsPage) {
    
    CGFloat width = [Utilities isLandscape] ? 1024.0 : 768.0;
    CGFloat height = [Utilities isLandscape] ? 673.0 : 926.0;
    self.view.frame = CGRectMake(0.0, 0.0, width, [Utilities isLandscape] ? 768.0 : 1024.0);
    
    self.photoVideoTable.frame = CGRectMake(0.0,
                                            self.photoVideoTable.frame.origin.y,
                                            width,
                                            height);
    self.photoVideoTable.center = CGPointMake(self.view.frame.size.width / 2.0,
                                              self.photoVideoTable.center.y);
    
    if (self.contentType == ScreenContentTypeCompositePage) {

      self.categoriesDarkView.frame = CGRectMake(0.0,
                                                  0.0,
                                                  [Utilities isLandscape] ? 1024.0 : 768.0,
                                                  [Utilities isLandscape] ? 768.0 : 1024.0);
      
      self.categoriesBlurView.frame = CGRectMake(0.0,
                                                 0.0,
                                                 [Utilities isLandscape] ? 1024.0 : 768.0,
                                                 [Utilities isLandscape] ? 768.0 : 1024.0);
      
      // Unfade the Sections table and associated views if they are present
      [UIView animateWithDuration:0.12 animations:^{
        if ([self.view.subviews containsObject:self.categoriesBlurView]) {
          self.categoriesBlurView.alpha = 1.0;
        }
        if ([self.view.subviews containsObject: self.categoriesDarkView]) {
          self.categoriesDarkView.alpha = 0.7;
        }
        if ([self.view.subviews containsObject: self.categoriesTableViewController.view]) {
          self.categoriesTableViewController.view.alpha = 1.0;
        }
      }];
      
      [self.masterCellHash removeAllObjects];
      [self.editionCellHash removeAllObjects];
      [self loadDummies];
      [self prepTableTransition];
      [self.photoVideoTable reloadData];

    } else {
      [self buildCells];
      [self prepTableTransition];
      [self.photoVideoTable reloadData];
    }
  } else  {
    [self buildCells];
    [self prepTableTransition];
    [self.photoVideoTable reloadData];
  }

  [[[Utilities del] masterRootController] uncloak];
  self.reorienting = NO;
   */
}

- (void)prepTableTransition {
  self.tableFadeCAT = [SCPRUsefulTransition animation];
  SCPRUsefulTransition *transition = self.tableFadeCAT;
  transition.animDelegate = self;
  transition.type = kCATransitionFade;
  transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  transition.fillMode = kCAFillModeBoth;
  transition.duration = 0.12;
  transition.subtype = kCATransitionFromTop;
  transition.delegate = self;
  transition.key = @"TableFade";
  [[self.photoVideoTable layer] addAnimation:transition
                                      forKey:@"UITableViewReloadDataAnimationKey"];
}

- (void)unplug {
  self.tableFadeCAT.delegate = nil;
  self.tableFadeCAT.animDelegate = nil;
}

- (void)viewWillLayoutSubviews {
  
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  if (self.contentType == ScreenContentTypeVideoPhotoPage) {
    return 1;
  }
  if (self.contentType == ScreenContentTypeCompositePage) {
    if (self.hasAerticles) {
      if (self.articleMapPerDate) {
        return [[self.articleMapPerDate allValues] count]+1;
      }
    } else if (self.hasAShortList) {
      return 1;
    } else {
      return 0;
    }
  }
  if (self.contentType == ScreenContentTypeEventsPage) {
    if ([self.bigHash count] > 0) {
      return 2;
    }
    return 1;
  }
  return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  if (self.contentType == ScreenContentTypeVideoPhotoPage) {
    return [self.cells count];
  }

  if (self.contentType == ScreenContentTypeCompositePage) {
    if (section == 0) {
      return 1;
    } else {
      NSInteger offset = section - 1;
      if ([self.sortedKeyArrayCache count] == 0) {
        return 0;
      }
      NSString *dateKey = [self.sortedKeyArrayCache objectAtIndex:offset];
      NSMutableArray *map = [self.articleMapPerDate objectForKey:dateKey];
      return [map count];
    }
  }

  if (self.contentType == ScreenContentTypeEventsPage) {
    if ([self.bigHash count] > 0) {
      if (section == 0) {
        return 1;
      } else {
        return [self.cells count]-1;
      }
    }
    return [self.cells count];
  }
  
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (self.contentType == ScreenContentTypeVideoPhotoPage) {
    return [self.cells objectAtIndex:indexPath.row];
  }
  
  if (self.contentType == ScreenContentTypeEventsPage) {
    if ([self.bigHash count] > 0) {
      if (indexPath.section == 0) {
        return [self.cells objectAtIndex:0];
      } else {
        return [self.cells objectAtIndex:indexPath.row+1];
      }
    } else {
      return [self.cells objectAtIndex:indexPath.row];
    }
  }
  
  if (indexPath.section == 0) {
    if (!self.editionsData) {
      self.editionsData = (NSArray*)[[[ContentManager shared].settings editionsJson] JSONValue];
      if (!self.editionsData) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateTableContents)
                                                     name:@"editions_complete"
                                                   object:nil];
        
        [[NetworkManager shared] setCompletionListenerEnabled:YES];
        
        SCPRBlankCell *cell = (SCPRBlankCell*)[Utilities loadNib:@"SCPRBlankCell"];
        cell.spinner.color = [[DesignManager shared] pumpkinColor];
        [cell.spinner startAnimating];
        
        self.failoverTimer = [NSTimer scheduledTimerWithTimeInterval:1.3
                                                              target:self
                                                            selector:@selector(updateTableContents)
                                                            userInfo:nil
                                                             repeats:NO];
        return cell;
      }
    }
    
    NSDictionary *edition = [self.editionsData objectAtIndex:0];
    SCPRDeluxeEditionsCell *cell = [self editionCellFromEdition:edition forceLoad:NO];
    [cell squish];
    return cell;
  }
  
  NSString *cellKey = [NSString stringWithFormat:@"%d%d",indexPath.section,indexPath.row];
  UITableViewCell *c = [self.masterCellHash objectForKey:cellKey];
  if (c) {
    return c;
  }
  
  NSString *orientation = [Utilities isLandscape] ? @"LND" : @"PT";
  NSInteger offset = indexPath.section - 1;
  NSString *key = [self.sortedKeyArrayCache objectAtIndex:offset];
  NSMutableArray *map = [self.articleMapPerDate objectForKey:key];
  NSDictionary *info = [map objectAtIndex:indexPath.row];
  
  NSString *type = [info objectForKey:@"type"];
  if ([type isEqualToString:@"regular"]) {
    
    NSMutableArray *posts = [info objectForKey:@"posts"];
    NSDictionary *article = [posts objectAtIndex:0];
    NSString *aspect = [[DesignManager shared] aspectCodeForContentItem:article
                                                                    quality:AssetQualityFull];
    aspect = [aspect stringByReplacingOccurrencesOfString:@"_clip"
                                               withString:@""];
    
    if ([posts count] == 2) {
      aspect = @"";
    }
    
    NSString *reuse = [NSString stringWithFormat:@"vpc%d%@",[posts count],orientation];

    SCPRDeluxeNewsCell *cell = nil;
    if (!self.reorienting) {
      cell = [self.photoVideoTable dequeueReusableCellWithIdentifier:reuse];
    } else {
      NSLog(@"Reorientation lock successful .... ");
    }
    
    if (cell.facade0.noAsset || cell.facade1.noAsset) {
      cell = nil;
    }
    if (!cell /*|| [self.masterCellHash objectForKey:lookup]*/) {
      NSString *template = [NSString stringWithFormat:@"%@",@"SCPRDeluxeNewsCellDouble"];
      NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                              xibForPlatformWithName:template]
                                                       owner:nil
                                                     options:nil];

      cell = (SCPRDeluxeNewsCell*)[objects objectAtIndex:0];
    }

    // Set social share counts for each post in the current cell row.
    if (self.socialShareCountHash) {
      for (NSMutableDictionary *post in posts) {
        if ([self.socialShareCountHash objectForKey:[post objectForKey:@"id"]]) {
          @try {
            [post setObject:[self.socialShareCountHash objectForKey:[post objectForKey:@"id"]] forKey:@"social_data"];
          } @catch(NSException *e) {
            NSLog(@"%@",e);
          }
        }
      }
    }
    
    cell.posts = posts;
    if ([posts count] == 1) {
      cell.facade1.view.alpha = 0.0;
    }
    
    cell.facade0.contentType = self.contentType;
    cell.facade1.contentType = self.contentType;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.currentIndexPath = indexPath;
    cell.landscape = [Utilities isLandscape];

    return cell;
  }
  
  if ([type isEqualToString:@"editions"]) {
    
    NSMutableArray *posts = [info objectForKey:@"posts"];
    SCPRDeluxeEditionsCell *cell = [self editionCellFromEdition:[posts lastObject]
                              forceLoad:NO];
    
    return cell;
  }
  if ([type isEqualToString:@"embiggened"]) {
    
    NSMutableArray *posts = [info objectForKey:@"posts"];
    NSDictionary *article = [posts objectAtIndex:0];

    NSString *aspect = [[DesignManager shared] aspectCodeForContentItem:article
                                                                quality:AssetQualityFull];
    aspect = [aspect stringByReplacingOccurrencesOfString:@"_clip"
                                               withString:@""];
    
    // Set social share counts for post in the current embiggened cell.
    if (self.socialShareCountHash) {
      for (NSMutableDictionary *post in posts) {
        if ([self.socialShareCountHash objectForKey:[post objectForKey:@"id"]]) {
          @try {
            [post setObject:[self.socialShareCountHash objectForKey:[post objectForKey:@"id"]] forKey:@"social_data"];
          } @catch (NSException *e) {
            NSLog(@"%@",e);
          }
        }
      }
    }
    
    NSString *reuse = [NSString stringWithFormat:@"vpcbig%@1%@",aspect,orientation];
    SCPRDeluxeNewsCell *cell = [self.photoVideoTable dequeueReusableCellWithIdentifier:reuse];
    NSString *lookup = [NSString stringWithFormat:@"%d%d",cell.currentIndexPath.section,cell.currentIndexPath.row];

    if (!cell || [self.masterCellHash objectForKey:lookup]) {
      NSString *template = [NSString stringWithFormat:@"%@%@",@"SCPRDeluxeNewsCellSingle",aspect];
      NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                              xibForPlatformWithName:template]
                                                       owner:nil
                                                     options:nil];
      
      cell = (SCPRDeluxeNewsCell*)[objects objectAtIndex:0];
    }

    cell.facade0.embiggened = YES;
    cell.facade0.contentType = self.contentType;
    cell.posts = posts;
    cell.currentIndexPath = indexPath;
    cell.landscape = [Utilities isLandscape];

    return cell;
  }

  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:@""];
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (self.contentType == ScreenContentTypeCompositePage) {
    if (section == 0) {
      return nil;
    } else {
      
      NSArray *keys = [self sortedKeysForCellDates];
      if ([keys count] == 0) {
        return nil;
      }
      
      NSString *funnyDate = [keys objectAtIndex:section-1];
      
      NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
      [fmt setDateFormat:@"YYYY-MM-dd"];
      
      NSDate *d = [fmt dateFromString:funnyDate];
      NSString *pretty = [NSDate stringFromDate:d
                                     withFormat:@"MMM d"];
      
      if (section == 1) {
        if (self.currentNewsCategoryLongTitle) {
          pretty = [NSString stringWithFormat:@"LATEST HEADLINES: %@",self.currentNewsCategoryLongTitle];
        } else {
          pretty = [NSString stringWithFormat:@"LATEST NEWS: %@",pretty];
        }
      } else {
        pretty = [NSString stringWithFormat:@"NEWS FROM %@",pretty];
      }
      return [[DesignManager shared] deluxeHeaderWithText:pretty];
    }
  }
  
  if ( self.contentType == ScreenContentTypeEventsPage ) {
    if ( section == 0 ) {
      if ( [self.bigHash count] > 0 ) {
        return [[DesignManager shared] deluxeHeaderWithText:@"HAPPENING NOW"];
      } else {
        return [[DesignManager shared] deluxeHeaderWithText:@"UPCOMING EVENTS"];
      }
    } else {
      return [[DesignManager shared] deluxeHeaderWithText:@"UPCOMING EVENTS"];
    }
  }
  
  return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

  if (self.contentType == ScreenContentTypeCompositePage) {
    if (section > 0) {
      return self.dummyHeader.frame.size.height;
    }
  }

  if (self.contentType == ScreenContentTypeEventsPage) {
    return self.dummyHeader.frame.size.height;
  }

  return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.contentType == ScreenContentTypeVideoPhotoPage ) {
    SCPRDeluxeNewsCell *cell = [self.cells objectAtIndex:indexPath.row];
    return cell.frame.size.height;
  } else if (self.contentType == ScreenContentTypeCompositePage) {
    
    if (indexPath.section > 0) {
      NSInteger offset = indexPath.section - 1;
      if ([self.sortedKeyArrayCache count] == 0) {
        return 0;
      }

      NSString *dateKey = [self.sortedKeyArrayCache objectAtIndex:offset];
      NSMutableArray *map = [self.articleMapPerDate objectForKey:dateKey];
      NSDictionary *meta = [map objectAtIndex:indexPath.row];
      NSString *type = [meta objectForKey:@"type"];
      NSMutableArray *posts = [meta objectForKey:@"posts"];
      CGFloat squish = indexPath.row == 0 ? 23.0 : 0.0;

      if ([type isEqualToString:@"editions"]) {
        CGFloat mod = [Utilities isLandscape] ? 100.0 : 0.0;
        return self.dummyEditions.frame.size.height + mod;
      }

      if ([type isEqualToString:@"regular"]) {
        return self.dummyDouble.frame.size.height;
      }

      if ([type isEqualToString:@"embiggened"]) {
        NSString *aspect = [[DesignManager shared]
                            aspectCodeForContentItem:[posts lastObject]
                            quality:AssetQualityFull];
        aspect = [aspect stringByReplacingOccurrencesOfString:@"_clip"
                                                   withString:@""];
        
        if ([aspect isEqualToString:@"23"] ||
            [aspect isEqualToString:@"34"] ||
            [aspect isEqualToString:@"Sq"]) {
          return self.dummySingleSquare.frame.size.height-squish;
        } else {
          return self.dummySingleRectangle.frame.size.height-squish;
        }
      }
    } else {
      CGFloat mod = [Utilities isLandscape] ? 120.0 : 0.0;
      return self.dummyEditions.frame.size.height + mod;
    }

  } else if (self.contentType == ScreenContentTypeEventsPage) {
  
    SCPRDeluxeNewsCell *cell = nil;
    if ([self.bigHash count] > 0) {
      if (indexPath.section == 0) {
        cell = [self.cells objectAtIndex:0];
        return cell.frame.size.height;
      }
      
      cell = [self.cells objectAtIndex:indexPath.row+1];
      CGFloat squish = indexPath.row == 0 ? 23.0 : 0.0;
      return cell.frame.size.height-squish;
    } else {
      CGFloat squish = indexPath.row == 0 ? 23.0 : 0.0;
      cell = [self.cells objectAtIndex:indexPath.row];
      return cell.frame.size.height-squish;
    }
  }
  return 0.0;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  // Configure the cell...
  if ( self.contentType == ScreenContentTypeCompositePage && indexPath.section == 0 ) {
    cell.backgroundColor = [[DesignManager shared] silverCurtainsColor];
    if ( [cell isKindOfClass:[SCPRDeluxeEditionsCell class]] ) {
      [(SCPRDeluxeEditionsCell*)cell prime:self];
    }
    return;
  }
  
  if ( [(id)cell respondsToSelector:@selector(prime:)] ) {
    if ( [cell isKindOfClass:[SCPRDeluxeEditionsCell class]] ) {
      NSLog(@"Priming editions cell separately...");
      [(SCPRDeluxeEditionsCell*)cell prime:self];
    } else {
      SCPRDeluxeNewsCell *vpc = (SCPRDeluxeNewsCell*)cell;
      if ( self.contentType == ScreenContentTypeEventsPage || self.contentType == ScreenContentTypeCompositePage ) {
        if ( indexPath.row == 0 ) {
          [vpc squish];
        }
      }
      if ( !vpc.primed ) {
        [vpc prime:self];
      }
    }
  }
}

#pragma mark - ScrollView

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  
  if (self.contentType == ScreenContentTypeVideoPhotoPage || self.contentType == ScreenContentTypeEventsPage) {
    return;
  }
  
  if ([[ContentManager shared] maxPagesReached]) {
    return;
  }
  
  CGRect frm = self.spinnerFooter.frame;
  if (!scrollView.scrollEnabled) {
    return;
  }

  // Scrolled to end of articles -- load more news.
  if (scrollView.contentOffset.y + scrollView.frame.size.height >= frm.origin.y) {
    [UIView animateWithDuration:0.22 animations:^{
      self.previousOffset = scrollView.contentOffset;
      self.loadingMoreNewsSpinner.alpha = 1.0;
      self.photoVideoTable.scrollEnabled = NO;
    } completion:^(BOOL finished) {
      
      [self.loadingMoreNewsSpinner startAnimating];
      [self fetchArticleContent:self.currentNewsCategorySlug withCallback:nil];

      [[AnalyticsManager shared] logEvent: @"load_more_news"
                           withParameters:@{ @"active_topic" : !self.currentNewsCategorySlug || [self.currentNewsCategorySlug isEqualToString:@"home"]? @"NO" : @"YES" }];
      
    }];
  }
}

- (void)scrollViewDidScroll:(UITableView *)tableView {

  if (self.contentType == ScreenContentTypeVideoPhotoPage || self.contentType == ScreenContentTypeEventsPage) {
    return;
  }
  
  if (!tableView.scrollEnabled) {
    return;
  }

  CGRect row = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
  
  // Scrolled past Short List -- hide Donate button in nav bar and show Sections button.
  if (tableView.contentOffset.y > CGRectGetMaxY(row)) {
    
    if ([[[Utilities del] globalTitleBar] isCategoriesButtonShown]) {
      return;
    }
 
    [[[Utilities del] globalTitleBar] applyCategoriesButton];

  } else if (tableView.contentOffset.y - 20.0 < CGRectGetMinY(row)) {
    
    if ([[[Utilities del] globalTitleBar] isDonateButtonShown] || _sectionsTableOpen) {
      return;
    }
    
    [[[Utilities del] globalTitleBar] applyDonateButton];
  }
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING DELUXE NEWS VIEW CONTROLLER");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
  
  if ( self.contentType == ScreenContentTypeCompositePage ) {
    [self.masterCellHash removeAllObjects];
    [[ContentManager shared] setCurrentNewsPage:1];
    [[ContentManager shared] resetNewsContent];
  }
  
    // Dispose of any resources that can be recreated.
}

@end
