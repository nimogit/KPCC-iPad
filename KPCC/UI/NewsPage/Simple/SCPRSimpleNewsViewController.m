//
//  SCPRSimpleNewsViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 5/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSimpleNewsViewController.h"
#import "DesignManager.h"
#import "SCPRSingleArticleCollectionViewController.h"

#define kSpinTimerInterval 15
#define kBounceSize 64.0
#define kScrollerTopPadding 23.0

@interface SCPRSimpleNewsViewController ()

@end

@implementation SCPRSimpleNewsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
  
  self.paddingHash = [[NSMutableDictionary alloc] init];
  self.view.backgroundColor = [[DesignManager shared] vinylColor:1.0];
  self.scrollLocks = [[NSMutableDictionary alloc] init];
  self.bounceQueue = [[NSMutableArray alloc] init];
  
  NSError *err = nil;
  NSString *json = [NSString stringWithContentsOfFile:[[NSBundle mainBundle]
                                                       pathForResource:@"category_groups"
                                                       ofType:@"json"] encoding:NSUTF8StringEncoding
                                                error:&err];
  NSDictionary *groups = [json JSONValue];
  self.schema = [groups allKeys];
  
  self.quad1.tag = 1;
  self.quad2.tag = 2;
  self.quad3.tag = 3;
  self.quad4.tag = 4;
  
  self.stackPointer = 4;
  
#ifdef USE_WEB_SPINNER
  self.spinner = [[SCPRSpinnerViewController alloc]
                  initWithNibName:[[DesignManager shared]
                                   xibForPlatformWithName:@"SCPRSpinnerViewController"]
                  bundle:nil];
#else
  /*self.spinner = [[SCPRSpinnerViewController alloc]
                  initWithNibName:[[DesignManager shared]
                                   xibForPlatformWithName:@"SCPRAltSpinnerViewController"]
                  bundle:nil];*/
#endif
  
  /*[self.spinner spinWithFinishedToken:@"content_load_finished"
                               inView:self.view
   pushUp:YES];*/
  
  self.displayQueue = [[NSMutableArray alloc] init];
  //[self.view sendSubviewToBack:self.spinner.view];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tileFaded:)
                                               name:@"tile_disappearing"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(drawerOpened)
                                               name:@"drawer_opened"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(drawerClosed)
                                               name:@"drawer_closed"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentLoadFinished)
                                               name:@"content_load_finished"
                                             object:nil];
  
}

- (void)setup {
  
  self.articleRetainer = [[NSMutableDictionary alloc] init];
  
  
  for ( NSString *topic in self.schema ) {
    NSMutableArray *usWorld = [self.contentDelegate mediaContentForTopic:topic];
    if ( [usWorld count] < kMinimumArticleQuantity ) {
      continue;
    }
    NSLog(@"%@ is strong enough",topic);
    [self setupForTopic:topic padding:NO];
    
  }
  [self.displayQueue removeAllObjects];
}

- (void)setupForTopic:(NSString *)topic padding:(BOOL)padding {

  
  @synchronized(self) {
    if ( padding ) {
      if ( [self.paddingHash objectForKey:topic] ) {
        return;
      } else {
        [self.paddingHash setObject:@1
                           forKey:topic];
      }
    }
  }
  
  
  for ( unsigned j = 0; j < [self.schema count]; j++ ) {
    
    NSString *topicCandidate = [self.schema objectAtIndex:j];
    if ( ![topicCandidate isEqualToString:topic] ) {
      continue;
    }
    
    NSMutableArray *usWorld = [self.contentDelegate mediaContentForTopic:[self.schema objectAtIndex:j]];
    UIScrollView *quad = (UIScrollView*)[self valueForKey:[NSString stringWithFormat:@"quad%d",j+1]];
    quad.contentSize = CGSizeMake([usWorld count]*quad.frame.size.width,
                                  quad.frame.size.height);
    
    [quad setDelegate:self];
    
    for ( UIView *v in [quad subviews] ) {
      [v removeFromSuperview];
    }
  
    //NSLog(@"New content count for %@ is %d",topic,[usWorld count]);
    for ( unsigned i = 0; i < [usWorld count]; i++ ) {
      
      SCPRTileViewController *tvc = nil;
   
      NSString *base = [self.schema objectAtIndex:j];
      NSString *key = [NSString stringWithFormat:@"%@-%d",base,i];
      
      SCPRTileViewController *tvcInc = [self.articleRetainer objectForKey:key];
      if ( tvcInc ) {
        [tvcInc.view removeFromSuperview];
        tvcInc.observableScroller = nil;
      }
      
      tvc = [[SCPRTileViewController alloc]
                                     initWithNibName:[[DesignManager shared]
                                                      xibForPlatformWithName:@"SCPRTileViewController"]
                                     bundle:nil];
    

      
      tvc.view.frame = CGRectMake(i*tvc.view.frame.size.width,kScrollerTopPadding,
                                  tvc.view.frame.size.width,
                                  tvc.view.frame.size.height);
      

      
      
      quad.showsHorizontalScrollIndicator = NO;
      quad.showsVerticalScrollIndicator = NO;
      
      
      tvc.ghostFrame = tvc.view.frame;
      tvc.ghostIndex = i;
      tvc.parentTileContainer = self;
      
      [self.articleRetainer setObject:tvc forKey:key];
      tvc.observableScroller = quad;
      
      if ( i == 1 ) {
        quad.contentOffset = CGPointMake(-1.0, 0.0);

      }

      
      tvc.view.frame = tvc.view.frame;
      if ( j % 2 == 0 ) {
        tvc.leftSide = YES;
      } else {
        tvc.leftSide = NO;
      }
      

      [tvc wireUpArticle:[usWorld objectAtIndex:i]];
      [quad addSubview:tvc.view];
    }
  
    [UIView animateWithDuration:0.33 animations:^{
      quad.alpha = 1.0;
    } completion:^(BOOL finished) {
      if ( padding ) {
        [self.paddingHash setObject:@1 forKey:topic];
        SCPRViewController *scpr = [[Utilities del] viewController];
        [scpr workOnBackgroundFetch];
      }
    }];

  }
  


  
}

- (void)contentLoadFinished {
  for ( unsigned j = 0; j < 4; j++ ) {
    NSString *timerKey = [NSString stringWithFormat:@"timer%d",j+1];
    NSTimer *timer = (NSTimer*)[self valueForKey:timerKey];
    if ( [timer isValid] ) {
      [timer invalidate];
    }
    UIScrollView *quad = (UIScrollView*)[self valueForKey:[NSString stringWithFormat:@"quad%d",j+1]];
    quad.contentOffset = CGPointMake(0.0,0.0);
    
    [self setValue:[NSTimer scheduledTimerWithTimeInterval:1.0*((random() % kSpinTimerInterval) + kSpinTimerInterval)
                                                    target:self
                                                  selector:@selector(spinTile:)
                                                  userInfo:quad
                                                   repeats:YES]
            forKey:timerKey];
  }
  

}

- (void)appendContentForTopic:(NSString *)topic {
  [self setupForTopic:topic padding:YES];
}

- (void)viewDidAppear:(BOOL)animated {

  
  if ( self.rearmOnAppearance ) {
    [self arm];
    self.rearmOnAppearance = NO;
  }
  
  SCPRSingleArticleCollectionViewController *collection = (SCPRSingleArticleCollectionViewController*)self.pushed;
  if ( collection ) {
    self.pushed = nil;
  }
  
}

- (void)arm {
  
  if ( [[Utilities del] drawerOpen] ) {
    return;
  }
  
  for ( unsigned i = 0; i < [self.schema count]; i++ ) {
  
    NSString *scrollerkey = [NSString stringWithFormat:@"quad%d",i+1];
    UIScrollView *scroller = (UIScrollView*)[self valueForKey:scrollerkey];

      NSString *timerKey = [NSString stringWithFormat:@"timer%d",i+1];
      NSTimer *timer = (NSTimer*)[self valueForKey:timerKey];
      if ( [timer isValid] ) {
        [timer invalidate];
      }
      
      [self setValue:[NSTimer scheduledTimerWithTimeInterval:1.0*((random() % kSpinTimerInterval) + kSpinTimerInterval)
                                                      target:self
                                                    selector:@selector(spinTile:)
                                                    userInfo:scroller
                                                     repeats:YES]
              forKey:timerKey];
    
  }
}

- (void)disarm {
  [self.timer1 invalidate];
  [self.timer2 invalidate];
  [self.timer3 invalidate];
  [self.timer4 invalidate];
  self.timer1 = nil;
  self.timer2 = nil;
  self.timer3 = nil;
  self.timer4 = nil;
}

#pragma mark - ScrollView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  
  NSString *offsetKey = [NSString stringWithFormat:@"anchoredOffset%ld",(long)scrollView.tag];
  [self.scrollLocks removeObjectForKey:offsetKey];
  
  CGPoint origin = [[self valueForKey:offsetKey] CGPointValue];
  ScrollDirection direction = ScrollDirectionUnknown;
  NSString *directionKey = [NSString stringWithFormat:@"direction%ld",(long)scrollView.tag];
  if ( origin.x > scrollView.contentOffset.x ) {
    direction = ScrollDirectionRight;
  } else {
    direction = ScrollDirectionLeft;
  }
  
  [self setValue:[NSNumber numberWithInt:direction]
          forKey:directionKey];
  
  
  for ( unsigned i = 0; i < [self.schema count]; i++ ) {
    NSString *scrollerkey = [NSString stringWithFormat:@"quad%d",i+1];
    UIScrollView *scroller = (UIScrollView*)[self valueForKey:scrollerkey];
    if ( scrollView == scroller ) {
      NSString *timerKey = [NSString stringWithFormat:@"timer%d",i+1];
      NSTimer *timer = (NSTimer*)[self valueForKey:timerKey];
      if ( [timer isValid] ) {
        [timer invalidate];
      }
      
      [self setValue:[NSTimer scheduledTimerWithTimeInterval:1.0*((random() % kSpinTimerInterval) + kSpinTimerInterval)
                                                      target:self
                                                    selector:@selector(spinTile:)
                                                    userInfo:scroller
                                                     repeats:YES]
              forKey:timerKey];
    }
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  
  NSString *offsetKey = [NSString stringWithFormat:@"anchoredOffset%ld",(long)scrollView.tag];
  
  if ( [self.scrollLocks objectForKey:offsetKey] ) {
    return;
  }
  
  [self setValue:[NSValue valueWithCGPoint:scrollView.contentOffset]
          forKey:offsetKey];
  [self.scrollLocks setObject:@1 forKey:offsetKey];
  
}

- (void)spinTile:(NSTimer*)timer {
  UIScrollView *scroller = (UIScrollView*)[timer userInfo];
  CGSize pageSize = scroller.frame.size;
  
  NSString *directionKey = [NSString stringWithFormat:@"direction%ld",(long)scroller.tag];
  ScrollDirection direction = (ScrollDirection)[[self valueForKey:directionKey] intValue];
  
  if ( direction == ScrollDirectionUnknown ) {
    if ( scroller.contentOffset.x < scroller.contentSize.width-pageSize.width-kBounceSize ) {
      direction = ScrollDirectionLeft;

      [self setValue:[NSNumber numberWithInt:direction]
              forKey:directionKey];
      
      CGPoint newOffset = CGPointMake(scroller.contentOffset.x+pageSize.width+kBounceSize,
                                           0.0);
      [self autoFlip:scroller newFrame:[NSValue valueWithCGPoint:newOffset] direction:1];

    
    } else {
      direction = ScrollDirectionRight;
   
      [self setValue:[NSNumber numberWithInt:direction]
              forKey:directionKey];
      
      CGPoint newOffset = CGPointMake(scroller.contentOffset.x-pageSize.width-kBounceSize,
                                    0.0);
      [self autoFlip:scroller newFrame:[NSValue valueWithCGPoint:newOffset] direction:-1];
    
    }
  } else {
    if ( direction == ScrollDirectionLeft ) {
      if ( scroller.contentOffset.x >= scroller.contentSize.width-pageSize.width-kBounceSize ) {
        
        [self setValue:[NSNumber numberWithInt:ScrollDirectionRight]
                forKey:directionKey];
        
        CGPoint newOffset = CGPointMake(scroller.contentOffset.x-pageSize.width-kBounceSize,
                                      0.0);
        [self autoFlip:scroller newFrame:[NSValue valueWithCGPoint:newOffset] direction:-1];
      } else {
        CGPoint newOffset = CGPointMake(scroller.contentOffset.x+pageSize.width+kBounceSize,
                                        0.0);
        [self autoFlip:scroller newFrame:[NSValue valueWithCGPoint:newOffset] direction:1];
      }
    }
    if ( direction == ScrollDirectionRight ) {
      if ( scroller.contentOffset.x <= 0.0) {
        [self setValue:[NSNumber numberWithInt:ScrollDirectionLeft]
                forKey:directionKey];
        
        CGPoint newOffset = CGPointMake(scroller.contentOffset.x+pageSize.width+kBounceSize,
                                      0.0);
        [self autoFlip:scroller newFrame:[NSValue valueWithCGPoint:newOffset] direction:1];
      } else {
        CGPoint newOffset = CGPointMake(scroller.contentOffset.x-pageSize.width-kBounceSize,
                                        0.0);
        [self autoFlip:scroller newFrame:[NSValue valueWithCGPoint:newOffset] direction:-1];
      }
    }
  }
}

- (void)autoFlip:(UIScrollView*)scroller newFrame:(NSValue *)frame direction:(NSInteger)directior {
  //for ( unsigned i = 0; i < [self.schema count]; i++ ) {
    
    NSDictionary *values = @{ @"scroller" : scroller, @"frame" : frame, @"direction" : [NSNumber numberWithInt:(int)directior] };
    [self.bounceQueue addObject:values];
    
    [UIView animateWithDuration:1.1 animations:^{
      [scroller setContentOffset:[frame CGPointValue] animated:NO];
      } completion:^(BOOL finished) {
        [self bounceView];
    }];

  //}
}

- (void)bounceView {
  
  NSDictionary *values = [self.bounceQueue objectAtIndex:0];
  ScrollDirection direction = (ScrollDirection) [[values objectForKey:@"direction"] intValue];
  CGPoint overshot = [[values objectForKey:@"frame"] CGPointValue];
  UIScrollView *scroller = [values objectForKey:@"scroller"];
  CGPoint set;
  
  if ( direction == ScrollDirectionLeft ) {
    
    set = CGPointMake(overshot.x-kBounceSize,overshot.y);
    
  } else {
    
    set = CGPointMake(overshot.x+kBounceSize,overshot.y);
  }
  
  [scroller setContentOffset:set animated:YES];
  @synchronized(self) {
    [self.bounceQueue removeObjectAtIndex:0];
  }
  
}

- (void)tickObject:(NSTimer*)timer {
  NSDictionary *values = (NSDictionary*)[timer userInfo];
  UIScrollView *scroller = [values objectForKey:@"scroller"];
  NSInteger direction = [[values objectForKey:@"direction"] intValue];
  scroller.contentOffset = CGPointMake(scroller.contentOffset.x+(direction*1.0),0.0);
  CGPoint target = [[values objectForKey:@"frame"] CGPointValue];
  
  if ( scroller.contentOffset.x == target.x ) {
    [timer invalidate];
  }
}

#pragma mark - ContentContainer
- (void)handleDrillDown:(NSDictionary *)content {
  [self disarm];
  
  self.rearmOnAppearance = YES;
  
  SCPRSingleArticleCollectionViewController *collection = [[SCPRSingleArticleCollectionViewController alloc]
                                                           initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRSingleArticleCollectionViewController"]
                                                           bundle:nil];
  
  self.pushed = collection;
  SCPRAppDelegate *del = [Utilities del];
  SCPRViewController *mvc = (SCPRViewController*)del.viewController;
  
  collection.view.frame = collection.view.frame;
  

  NSDictionary *category = [content objectForKey:@"category"];
  NSMutableArray *media = [self.contentDelegate mediaContentForTopic:[category objectForKey:@"slug"]];
  
  NSUInteger index = 0;
  for ( unsigned i = 0; i < [media count]; i++ ) {
    NSDictionary *story = [media objectAtIndex:i];
    if ( story == content ) {
      index = i;
      break;
    }
  }
  
  [self.navigationController
   pushViewController:collection animated:YES];
  
  mvc.mainPageScroller.scrollEnabled = NO;
  
  collection.parentContainer = nil;
  collection.category = ContentCategoryNews;
  [collection setupWithCollection:media
                 beginningAtIndex:index
                     processIndex:YES];
  
  [[[Utilities del] globalTitleBar] morph:BarTypeModal
                                container:collection.currentPage];
  
  collection.collectionType = @"Tile View";
  
  [[AnalyticsManager shared] logEvent:@"story_read"
                       withParameters:@{ @"id" : [content objectForKey:@"id"],
                                         @"date" : [NSDate stringFromDate:[NSDate date] withFormat:@"MMM dd, YYYY HH:mm"],
                                         @"accessed_from" : @"Tile View",
                                         @"audio_on" : ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO" }];
}

- (void)unplug {
  

  [self disarm];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  for ( SCPRTileViewController *tile in [self.articleRetainer allValues] ) {
    [[NSNotificationCenter defaultCenter] removeObserver:tile];
    tile.parentTileContainer = nil;
    tile.observableScroller = nil;
  }
  [self.articleRetainer removeAllObjects];
  self.articleRetainer = nil;
  
}

#pragma mark - ContentProcessor

- (NSInteger)pageIndex {
  return 0;
}

#pragma mark - UI
- (void)drawerOpened {
  [self disarm];
}

- (void)drawerClosed {
  [self arm];
}

- (void)tileFaded:(NSNotification*)note {
  NSNumber *n = (NSNumber*)[note object];
  NSArray *quads = @[ self.quad1, self.quad2, self.quad3, self.quad4 ];
  
  NSInteger index = [n intValue];
  SCPRTileViewController *tvc = [quads objectAtIndex:index];
  
  NSDictionary *article = [self.articles objectAtIndex:(self.stackPointer+1) % [self.articles count]];
  [tvc wireUpArticle:article];
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.4];
  tvc.cloakView.alpha = 0.0;
  [UIView commitAnimations];
  
  @synchronized(self) {
    self.stackPointer++;
  }
}

- (void)processArticles:(NSArray *)articles {
  self.articles = articles;
  NSArray *quads = @[ self.quad1, self.quad2, self.quad3, self.quad4 ];
  for ( unsigned i = 0; i < 4; i++ ) {
    NSDictionary *d = [self.articles objectAtIndex:i];
    SCPRTileViewController *tvc = [quads objectAtIndex:i];
    tvc.index = i;
    [tvc wireUpArticle:d];
  }
}

- (BOOL)shouldAutorotate {
#ifdef SUPPORT_LANDSCAPE
  return YES;
#else
  return NO;
#endif
}



- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  
  NSLog(@"DEALLOCATING TILE OVERVIEW VIEW CONTROLLER...");
  
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
