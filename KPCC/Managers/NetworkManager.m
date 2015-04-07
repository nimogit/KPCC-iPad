//
//  NetworkManager.m
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "NetworkManager.h"
#import "global.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "SBJson.h"
#import <Parse/Parse.h>

static NetworkManager *singleton = nil;

@implementation NetworkManager

+ (NetworkManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      
      singleton = [[NetworkManager alloc] init];
      singleton.programsFetchQueue = [[NSOperationQueue alloc] init];
      singleton.networkHealthReachability = [Reachability reachabilityForInternetConnection];
      [[NSNotificationCenter defaultCenter] addObserver:singleton
                                               selector:@selector(reachabilityChanged:)
                                                   name:kReachabilityChangedNotification
                                                 object:nil];
      [singleton.networkHealthReachability startNotifier];
    }
  }
  
  return singleton;
}

- (BOOL)isReadyForRefresh {
#ifdef DEBUG
  return YES;
#endif
  NSDate *lastRefresh = self.lastContentRefresh;
  if ( lastRefresh ) {
    return [lastRefresh isOlderThanInSeconds:180];
  }
  return YES;
}

#pragma mark - Schema
- (NSString*)stringForSchemaComponent:(NSString *)code {
  NSArray *comps = [code componentsSeparatedByString:@"-"];
  NSString *key = [comps objectAtIndex:0];
  NSInteger root = [[comps objectAtIndex:1] intValue];
  NSMutableDictionary *t = [self.globalSchema.topicHeadings objectForKey:key];
  NSMutableArray *contents = [t objectForKey:@"contents"];
  return [contents objectAtIndex:root % [contents count]];
}

#pragma mark - Reachability
- (void)reachabilityChanged:(NSNotification*)note {
  if ( ![self.networkHealthReachability isReachable] ) {
    [[AnalyticsManager shared] networkDisappeared];
  }
  
  [[[ContentManager shared] settings] setLastKnownConnectionType:[self networkInformation]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
}

- (NetworkHealth)checkNetworkHealth:(NSString *)server {
  if ([self.networkHealthReachability isReachable]) {
    if ( server ) {
      Reachability *serverReach = [Reachability reachabilityWithHostname:server];
      if ( [serverReach isReachable] ) {
        return NetworkHealthAllOK;
      } else {
        return NetworkHealthServerDown;
      }
    } else {
      return NetworkHealthAllOK;
    }
  }
  
  return NetworkHealthNetworkDown;
}

- (NSString*)networkInformation {
  
  NetworkStatus remoteHostStatus = [self.networkHealthReachability currentReachabilityStatus];
  
  if ( remoteHostStatus == ReachableViaWiFi ) {
    return @"Wi-Fi";
  }
  if ( remoteHostStatus == ReachableViaWWAN ) {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    NSString *carrierName = [carrier carrierName];
    return carrierName;
  }
  
  return @"No Connection";
}

- (BOOL)isWifi {
  return [[self networkInformation] isEqualToString:@"Wi-Fi"];
}

- (NSString*)readabilityAPIKey {
  return [[[[FileManager shared] globalConfig] objectForKey:@"Readability"] objectForKey:@"ApiKey"];
}

#pragma mark - Indexed accessors
- (SCPRTopicSchema*)fetchTopicSchema {
#ifdef NETWORK_STUBS
  if ( self.globalSchema ) {
    return self.globalSchema;
  }
  
  SCPRTopicSchema *schema = [[SCPRTopicSchema alloc] init];
  schema.topicHeadings = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                                            pathForResource:@"faketopicschema"
                                                                            ofType:@"plist"]];
  NSArray *unsorted = [schema.topicHeadings allKeys];
  NSArray *sorted = [unsorted sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSString *key1 = (NSString*)obj1;
    NSString *key2 = (NSString*)obj2;
    
    NSMutableDictionary *val1 = [schema.topicHeadings objectForKey:key1];
    NSMutableDictionary *val2 = [schema.topicHeadings objectForKey:key2];
    
    NSInteger index1 = [[val1 objectForKey:@"index"] intValue];
    NSInteger index2 = [[val2 objectForKey:@"index"] intValue];
    
    return (NSComparisonResult)index1 > index2;
  }];
  
  schema.sortedTopics = [[NSMutableArray alloc] init];
  for ( unsigned i = 0; i < [sorted count]; i++ ) {
    NSString *key = [sorted objectAtIndex:i];
    NSMutableDictionary *topic = [schema.topicHeadings objectForKey:key];
    [topic setObject:key forKey:@"topicTitle"];
    [schema.sortedTopics addObject:topic];
  }
  
  self.globalSchema = schema;
  return schema;
  
  // Network calls are stubbed out, use local file
  
#else
  
#endif
}

- (void)requestFromKPCCWithEndpoint:(NSString *)endpoint andDisplay:(id<ContentProcessor>)display {
  [self requestFromKPCCWithEndpoint:endpoint andDisplay:display flags:nil];
}

- (void)requestFromKPCCWithEndpoint:(NSString *)endpoint andDisplay:(id<ContentProcessor>)display flags:(NSDictionary *)flags {
  NSURL *url = [NSURL URLWithString:endpoint];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  
  NSOperationQueue *queue = nil;
  if ( [flags objectForKey:@"slug"] ) {
    // Throttle this since we could potentially be fetching about 30 requests at a time
    queue = self.programsFetchQueue;
  } else {
    queue = [[NSOperationQueue alloc] init];
  }
  
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:queue
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             [[AnalyticsManager shared] failureFetchingContent:endpoint];
                             return;
                           }
                           
                           NSString *dataString = [[NSString alloc] initWithData:d
                                                                        encoding:NSUTF8StringEncoding];
                           if ( dataString ) {
                             id chunk = [dataString JSONValue];
                             if ( chunk ) {
                               
                               NSDictionary *elements = @{ @"chunk" : chunk,
                                                           @"port" : display };
                               
                               if ( flags && [flags count] > 0 ) {
                                 elements = @{ @"chunk" : chunk,
                                               @"port" : display,
                                               @"flags" : flags };
                               }
                               
                               self.failoverCount = 0;
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 
                                 if ( [flags objectForKey:@"events"] ) {
                                   [self processEventsData:elements];
                                 } else {
                                   [self processContentData:elements];
                                 }
                               });
                               
     
                             } else {
                               
                               if ( self.failoverCount < kFailoverThreshold ) {
                                 self.failoverCount++;
                                 [self requestFromKPCCWithEndpoint:endpoint
                                                        andDisplay:display
                                                             flags:flags];
                                 return;
                               } else {
                                 self.failoverCount = 0;
                               }
                               
                               [[AnalyticsManager shared] failureFetchingContent:endpoint];
                             }
                           } else {
                             [[AnalyticsManager shared] failureFetchingContent:endpoint];
                           }
                           
                         }];
}

- (void)fetchTrendingArticles:(id<ContentProcessor>)display {
  
  __block NSMutableDictionary *compositeNews = [[ContentManager shared] globalCompositeNews];
  
  NSString *urlString = [NSString stringWithFormat:@"%@/buckets/homepage",kServerBase];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                             return;
                           }
                           
                           NSString *dataString = [[NSString alloc] initWithData:d
                                                                        encoding:NSUTF8StringEncoding];
                           if ( dataString ) {
                             id chunk = [dataString JSONValue];
                             if ( chunk ) {
                               
                               NSArray *articles = [chunk objectForKey:@"articles"];
                               NSArray *truncated = [articles subarrayWithRange:NSMakeRange(0, 10)];
                               
                               
                               [compositeNews setObject:truncated
                                                 forKey:@"trending"];
                               [compositeNews setObject:display
                                                 forKey:@"processor"];
                               
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 
                                 [self processCompositeData:compositeNews];
                                 
                               });
                             }
                           }
                         }];
}

- (void)fetchAllContent:(id<ContentProcessor>)display {
  self.lastContentRefresh = [NSDate date];
  NSString *urlString = [NSString stringWithFormat:@"%@/content?limit=39",kServerBase];
  [self requestFromKPCCWithEndpoint:urlString andDisplay:display];
}

- (void)fetchContentWithPath:(NSString *)newsPath display:(id<ContentProcessor>)display {
#ifdef NETWORK_STUBS
  [self processContentData:@{ @"chunk" : @[ @{} ], @"port" : display }];
#endif
}

- (void)fetchContentForProgramPage:(NSString *)newsPath display:(id<ContentProcessor>)display {
#ifdef NETWORK_STUBS
  NSString *urlString = [NSString stringWithFormat:@"%@/episodes?program=%@&limit=20",kServerBase,newsPath];
  if ( newsPath ) {
    [self requestFromKPCCWithEndpoint:urlString andDisplay:display flags:@{ @"slug" : newsPath }];
  } else {
    [self requestFromKPCCWithEndpoint:urlString andDisplay:display];
  }
#endif
}

- (void)fetchContentForVideoPhotoPage:(id<ContentProcessor>)display {
  
  self.videoPhotoObjects = [[NSMutableDictionary alloc] init];
  
  NSString *urlString = [NSString stringWithFormat:@"%@/posts?limit=20",kAudioVisionServerBase];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                             return;
                           }
                           
                           NSString *dataString = [[NSString alloc] initWithData:d
                                                                        encoding:NSUTF8StringEncoding];
                           if ( dataString ) {
                             NSArray *chunk = (NSArray*)[dataString JSONValue];
                             if ( chunk ) {
                               
                               [self.videoPhotoObjects setObject:chunk
                                                          forKey:@"all_posts"];
                               
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 
                                 
                                 NSString *urlString = [NSString stringWithFormat:@"%@/buckets/mobile-feature",kAudioVisionServerBase];
                                 NSURL *url = [NSURL URLWithString:urlString];
                                 NSURLRequest *request = [NSURLRequest requestWithURL:url];
                                 [NSURLConnection sendAsynchronousRequest:request
                                                                    queue:[[NSOperationQueue alloc] init]
                                                        completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                                 
                                                          if ( e ) {
                                                            [[AnalyticsManager shared] failureFetchingContent:urlString];
                                                            return;
                                                          }
                                                          
                                                          NSString *dataString = [[NSString alloc] initWithData:d
                                                                                                       encoding:NSUTF8StringEncoding];
                                                          if ( dataString ) {
                                                            NSDictionary *chunk = (NSDictionary*)[dataString JSONValue];
                                                            if ( chunk ) {
                                                              
                                                              
                                                              [self.videoPhotoObjects setObject:[chunk objectForKey:@"posts"]
                                                                                         forKey:@"big_posts"];
                                                              
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                NSDictionary *meta = @{ @"content" : self.videoPhotoObjects,
                                                                                        @"processor" : display };
                                                                
                                                                [self processVideoPhotoData:meta];
                                                              });
                                                              
                                                            }
                                                          }
                                                        }];
                               });
                               
                             } else {
                               [[AnalyticsManager shared] failureFetchingContent:urlString];
                             }
                           } else {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                           }
                         }];
}

- (void)fetchContentForProgramAZPage:(id<ContentProcessor>)display {

  NSMutableDictionary *masterProgramList = [[ContentManager shared] masterProgramList];
  if ( ![Utilities pureNil:masterProgramList] ) {
    [self processContentData:@{ @"chunk" : [[ContentManager shared] sortedProgramList], @"port" : display }];
  } else {
    NSString *urlString = [NSString stringWithFormat:@"%@/programs",kServerBase];
    [self requestFromKPCCWithEndpoint:urlString andDisplay:display];
  }

}

- (void)fetchContentForProgramAZPageSilently {
  NSString *urlString = [NSString stringWithFormat:@"%@/programs",kServerBase];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             [[AnalyticsManager shared] failureFetchingContent:@"Program AZ"];
                             return;
                           }
                           
                           NSString *dataString = [[NSString alloc] initWithData:d
                                                                        encoding:NSUTF8StringEncoding];
                           if ( dataString ) {
                             id chunk = [dataString JSONValue];
                             if ( chunk ) {
                               [[ContentManager shared] filterPrograms:chunk];
                             }
                           }
                         }];
}

- (void)fetchContentForMasterProgramsList:(id<ContentProcessor>)display {
  NSMutableDictionary *masterProgramList = [[ContentManager shared] masterProgramList];
  if ( ![Utilities pureNil:masterProgramList] ) {
    [self processContentData:@{ @"chunk" : [[ContentManager shared] sortedProgramList], @"port" : display, @"flags" : @{ @"master" : @1 } }];
  } else {
    NSString *urlString = [NSString stringWithFormat:@"%@/programs",kServerBase];
    [self requestFromKPCCWithEndpoint:urlString andDisplay:display flags:@{ @"master" : @1}];
  }
}

- (void)fetchContentForEventsPage:(NSString *)newsPath display:(id<ContentProcessor>)display {
  NSDate *date = [NSDate date];
  NSString *pretty = [NSDate stringFromDate:date
                                 withFormat:@"YYYY-MM-dd"];
  
  NSString *urlString = [NSString stringWithFormat:@"%@/events?start_date=%@",kServerBase,pretty];
  [self requestFromKPCCWithEndpoint:urlString
                         andDisplay:display
                              flags:@{ @"events" : @1 }];
}

- (void)fetchProgramInformationFor:(NSDate *)thisTime display:(id<ContentProcessor>)display {
  NSString *urlString = [NSString stringWithFormat:@"%@/schedule/at?time=%d",kServerBase,(NSInteger)[thisTime timeIntervalSince1970]];
  [self requestFromKPCCWithEndpoint:urlString
                         andDisplay:display];
}

- (void)fetchContentForSnapshotPage:(id<ContentProcessor>)display {
  [self fetchContentForSnapshotPage:display
                              flags:@{}];
}

- (void)fetchContentForSnapshotPage:(id<ContentProcessor>)display flags:(NSDictionary *)flags {
  
  NSString *count = [NSString stringWithFormat:@"%d",kEditionsTotal];
  
  NSDate *editionsSync = [[ContentManager shared].settings lastEditionsSync];
  if ( editionsSync && ![editionsSync isOlderThanInSeconds:10*60] ) {
    NSString *json = [[ContentManager shared].settings editionsJson];
    if ( ![Utilities pureNil:json] ) {
      
      NSDictionary *flagContainer = @{};
      if ( flags ) {
        flagContainer = flags;
      }
      
      id jsonObj = [json JSONValue];
      if ( !jsonObj ) {
        NSLog(@"Bad cache on editions data ****************** ");
      } else {
        NSDictionary *elements = @{
                                 @"chunk" : jsonObj,
                                 @"port" : display,
                                 @"flags" : flagContainer
                                 };
      
        [self processContentData:elements];
        NSLog(@"Using cached editions from : %@",[NSDate stringFromDate:editionsSync withFormat:@"MM dd, hh:mm a"]);
        return;
      }
    }
  }
  [[ContentManager shared].settings setEditionsJson:@""];
  [[ContentManager shared].settings setLastEditionsSync:[NSDate date]];
  
  NSString *urlString = [NSString stringWithFormat:@"%@/editions?limit=%@",kServerBase,count];
  NSMutableDictionary *mutable = [[NSMutableDictionary alloc] init];
  if ( flags ) {
     mutable = [[NSDictionary dictionaryWithDictionary:flags] mutableCopy];
  }
  [mutable setObject:@1 forKey:@"cache_results"];
  
  [self requestFromKPCCWithEndpoint:urlString
                         andDisplay:display
                              flags:[NSDictionary dictionaryWithDictionary:mutable]];
}

- (void)fetchEditionsInBackground {
  
  NSInteger count = 12;
  NSString *urlString = [NSString stringWithFormat:@"%@/editions?limit=%d",kServerBase,count];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *req = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:req
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                           
                           if ( connectionError ) {
                             NSLog(@"Problem fetching Short Lists...");
                             return;
                           }
                           
                           NSString *es = [[NSString alloc] initWithData:data
                                                                encoding:NSUTF8StringEncoding];
                           if ( [Utilities pureNil:es] ) {
                             NSLog(@"Problem fetching Short Lists...");
                             return;
                           }
                           
                           [[ContentManager shared].settings setEditionsJson:es];
                           [[ContentManager shared] setSkipParse:YES];
                           [[ContentManager shared] writeSettings];
                           
                         }];
  
}

- (void)fetchContentForEditionals:(id<ContentProcessor>)display {
  
  NSString *json = [[ContentManager shared].settings editionsJson];
  if ( ![Utilities pureNil:json] ) {
    NSArray *editions = [json JSONValue];
    if ( [editions count] >= 12 ) {
      NSArray *final6 = [editions subarrayWithRange:NSMakeRange(6, 6)];
      dispatch_async(dispatch_get_main_queue(), ^{
        [display handleEditionals:final6];
      });
      return;
    }
  }
  
  NSString *count = [NSString stringWithFormat:@"%d",kEditionsTotal/2];
  NSString *urlString = [NSString stringWithFormat:@"%@/editions?limit=%@&page=2",kServerBase,count];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *req = [NSURLRequest requestWithURL:url];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                             
                             if ( connectionError ) {
                               NSLog(@"Problem with Editionals... : %@",[connectionError userInfo]);
                               return;
                             }
                             
                             if ( data ) {
                               
                               NSString *s = [[NSString alloc] initWithData:data
                                                                   encoding:NSUTF8StringEncoding];
                               
                               if ( ![Utilities pureNil:s] ) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   [display handleEditionals:[s JSONValue]];
                                 });
                               }
                               
                             }
                             
                           }];
  });

  
}

- (void)fetchContentForScheduleThisWeek:(id<ContentProcessor>)display {
#ifndef FAKE_LOCAL_NOTIFICATION
  NSDate *last = [[ContentManager shared].settings lastReminderSync];
  if ( abs([last daysAgoAgainstMidnight]) >= 1 ) {
#endif
    [[ScheduleManager shared] setCachedSchedule:nil];
#ifndef FAKE_LOCAL_NOTIFICATION
  }
#endif
  
  [[ScheduleManager shared] setFetchType:DataFetchReminders];
  if ( [[ScheduleManager shared] cachedSchedule] ) {
    [self processContentData:@{ @"chunk" : [[ScheduleManager shared] cachedSchedule], @"port" : display}];
  } else {
    NSString *urlString = [NSString stringWithFormat:@"%@/schedule",kServerBase];
    [self requestFromKPCCWithEndpoint:urlString andDisplay:display];
  }
}

- (void)fetchContentForSingleArticle:(NSString *)articleURL display:(id<ContentProcessor>)display {
  
  if ( !articleURL ) {
    return;
  }
  
  NSString *urlString = [NSString stringWithFormat:@"%@/content/by_url?url=%@",kServerBase,articleURL];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                             return;
                           }
                           
                           NSString *dataString = [[NSString alloc] initWithData:d
                                                                        encoding:NSUTF8StringEncoding];
                           if ( dataString ) {
                             NSDictionary *chunk = (NSDictionary*)[dataString JSONValue];
                             if ( chunk ) {
                               
                               if ( [chunk objectForKey:@"error"] ) {
                                 [[AnalyticsManager shared] failureFetchingContent:urlString];
                                 return;
                               }
                               
                               NSDictionary *elements = @{ @"chunk" : chunk,
                                                         @"port" : display,
                                                           };
                               [self performSelectorOnMainThread:@selector(processContentDataSingle:)
                                                    withObject:elements
                                                 waitUntilDone:NO];
                             } else {
                               [[AnalyticsManager shared] failureFetchingContent:urlString];
                             }
                           } else {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                           }
                           
                         }];

}

- (void)fetchContentForSingleArticle:(NSString *)articleURL completion:(CompletionBlockWithValue)completion {
  if ( !articleURL ) {
    return;
  }
  
  NSString *urlString = [NSString stringWithFormat:@"%@/content/by_url?url=%@",kServerBase,articleURL];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                             return;
                           }
                           
                           NSString *dataString = [[NSString alloc] initWithData:d
                                                                        encoding:NSUTF8StringEncoding];
                           if ( dataString ) {
                             NSDictionary *chunk = (NSDictionary*)[dataString JSONValue];
                             if ( chunk ) {
                               
                               if ( [chunk objectForKey:@"error"] ) {
                                 [[AnalyticsManager shared] failureFetchingContent:urlString];
                                 return;
                               }
                               
                               [self processContentDataSingle:chunk completion:completion];
                               
                             } else {
                               [[AnalyticsManager shared] failureFetchingContent:urlString];
                             }
                           } else {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                           }
                           
                         }];
}

- (void)fetchContentForTopic:(NSString *)topic display:(id<ContentProcessor>)display flags:(NSDictionary *)flags {
  
  NSInteger threshold = [[flags objectForKey:@"quantity"] intValue];

  
  NSString *urlString = [NSString stringWithFormat:@"%@/articles?categories=%@&limit=%d",kServerBase,topic,threshold];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                             return;
                           }
                           
                           NSString *dataString = [[NSString alloc] initWithData:d
                                                                        encoding:NSUTF8StringEncoding];
                           if ( dataString ) {
                             NSDictionary *chunk = (NSDictionary*)[dataString JSONValue];
                             if ( chunk ) {
                               NSDictionary *elements = @{ @"chunk" : chunk,
                                                           @"port" : display,
                                                           @"topic" : topic
                                                           };
                               [self performSelectorOnMainThread:@selector(processContentAdditional:)
                                                      withObject:elements
                                                   waitUntilDone:NO];
                             } else {
                               [[AnalyticsManager shared] failureFetchingContent:urlString];
                             }
                           } else {
                             [[AnalyticsManager shared] failureFetchingContent:urlString];
                           }
                           
                         }];
}

- (void)fetchContentForUserProfile:(id<ContentProcessor>)display {
#ifdef USE_PARSE
  PFQuery *query = [PFQuery queryWithClassName:@"ListenedSegments"];
  [query whereKey:@"device_id" equalTo:[[ContentManager shared].settings deviceID]];
  [query orderByDescending:@"completed_at"];
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    
    if ( error ) {
      NSLog(@"Error getting any previous listens.. returning the empty set : %@",[error localizedDescription]);
      [self performSelectorOnMainThread:@selector(processContentData:)
                             withObject:@{ @"chunk" : @[], @"port" : display }
                          waitUntilDone:NO];
      return;
    }
    
    
    [self performSelectorOnMainThread:@selector(processContentData:)
                           withObject:@{ @"chunk" : objects, @"port" : display }
                        waitUntilDone:NO];
    
  }];
#else
  [self performSelectorOnMainThread:@selector(processContentData:)
                         withObject:@{ @"chunk" : @[], @"port" : display }
                      waitUntilDone:NO];
#endif

}

- (void)reduceArticle:(NSString *)url processor:(id<ContentProcessor>)processor {
  
  [[AnalyticsManager shared] logEvent:@"user_readabilitizing"
                       withParameters:@{}];
  
  NSString *fullURL = [NSString stringWithFormat:@"https://readability.com/api/content/v1/parser?url=%@&token=%@",url,[self readabilityAPIKey]];
  NSURL *reqURL = [NSURL URLWithString:fullURL];
  NSURLRequest *request = [NSURLRequest requestWithURL:reqURL];
  [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc]init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             NSLog(@"Error reducing article with Readability : %@",[e localizedDescription]);
                             return;
                           }
                           
                           NSString *response = [[NSString alloc] initWithData:d
                                                                      encoding:NSUTF8StringEncoding];
                           
                           NSDictionary *reduced = [response JSONValue];
                           NSLog(@"After : %@",reduced);
                           
                           if ( reduced && ![reduced objectForKey:@"error"] ) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                               [processor handleReducedArticle:reduced];
                             });
                           } else {
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                               [[[UIAlertView alloc]
                                 initWithTitle:@"Couldn't use Readability"
                                 message:@"There was a problem using Readability with this article. If the problem persists please contact mobilefeedback@kpcc.org to tell us which article you're having trouble with"
                                 delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil] show];
                             });
                             
                           }
                           
                         }];
}

- (NSString*)localReduction:(NSString *)fullContent processor:(id<ContentProcessor>)processor {
  NSError *error = NULL;
  
  if ( !fullContent ) {
    NSDictionary *reduced = @{ @"title" : @"Oops!", @"content" : @"We're sorry but there was an error trying to prep this page for the best reading experience...", @"lead_image_url" : @"" };
    [processor handleReducedArticle:reduced];
    return @"";
  }
  
  fullContent = [fullContent stringByReplacingOccurrencesOfString:@"\r"
                                                       withString:@""];
  fullContent = [fullContent stringByReplacingOccurrencesOfString:@"\n"
                                                       withString:@""];
  
  NSArray *strips = (NSArray*)[Utilities loadJson:@"strippable"];
  NSMutableArray *stripItems = [[NSMutableArray alloc] init];
  for ( NSString *pattern in strips ) {
    
    NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:pattern
                                options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                error:&error];
    
    [regex enumerateMatchesInString:fullContent options:0 range:NSMakeRange(0, [fullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
      NSString *strip = [fullContent substringWithRange:[match range]];
      
      if ( [strip rangeOfString:@"byline"].location != NSNotFound ) {
        return;
      }
      
      NSDictionary *meta = @{ @"string" : [fullContent substringWithRange:[match range]], @"pattern" : pattern,
                              @"range" : [NSValue valueWithRange:[match range]] };
      
      [stripItems addObject:meta];
      
    }];
  }
  
  NSArray *unmutable = [NSArray arrayWithArray:stripItems];
  for ( NSDictionary *stripMeta in [unmutable reverseObjectEnumerator] ) {
    NSString *strip = [stripMeta objectForKey:@"string"];
    if ( [strip rangeOfString:@"byline"].location != NSNotFound ) {
      continue;
    }
    if ( [fullContent rangeOfString:strip].location == NSNotFound ) {
      continue;
    }

    fullContent = [fullContent stringByReplacingOccurrencesOfString:strip
                                                       withString:@""];
  }
  
  NSLog(@"Content after initial reduction : %@",fullContent);
  
  __block NSString *title = @"";
  NSRegularExpression *regexTitle = [NSRegularExpression
                                regularExpressionWithPattern:@"<title>(.*?)</title>"
                                options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                error:&error];
  [regexTitle enumerateMatchesInString:fullContent options:0 range:NSMakeRange(0, [fullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    // your code to handle matches here
    NSInteger numberOfRanges = [match numberOfRanges];
    if ( numberOfRanges > 1 ) {
      title = [fullContent substringWithRange:[match rangeAtIndex:1]];
    } else {
      title = @"Article";
    }
  }];
  
  // AUDIOVISION CHEAT
  NSString *articleRegEx = @"";
  
  __block NSString *shortened = [NSString stringWithString:fullContent];
  __block NSRegularExpression *bigStripper;
  if ( [fullContent rangeOfString:@"<article class=\"essay\">"].location != NSNotFound ) {
    articleRegEx = @"<article class=\"essay\">.*?</article>";
    
    bigStripper = [NSRegularExpression
                                        regularExpressionWithPattern:articleRegEx
                                        options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                        error:&error];
    [bigStripper enumerateMatchesInString:fullContent options:0 range:NSMakeRange(0, [fullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
      shortened = [fullContent substringWithRange:[match range]];
    }];
    
  } else {
    NSArray *containers = [Utilities loadJson:@"article_containers"];
    
    __block BOOL interestingPartFound = NO;
    for ( unsigned i = 0; i < [containers count]; i++ ) {
      
      if ( interestingPartFound ) {
        break;
      }

      articleRegEx = [containers objectAtIndex:i];
        
      bigStripper = [NSRegularExpression
                                            regularExpressionWithPattern:articleRegEx
                                            options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                            error:&error];
      [bigStripper enumerateMatchesInString:fullContent options:0 range:NSMakeRange(0, [fullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        
        interestingPartFound = YES;
        NSString *matched = [fullContent substringWithRange:[match range]];
        if ( [matched rangeOfString:@"=\"items\"]"].location != NSNotFound ) {
          int x =1;
          x++;
        }
        shortened = [NSString stringWithString:matched];
        
      }];
    }
  }

  __block BOOL imageFoundInInterestingPartOfBody = NO;
  NSMutableArray *images = [[NSMutableArray alloc] init];
  NSRegularExpression *imageRX = [NSRegularExpression
                                  regularExpressionWithPattern:@"<img.*?/?>"
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                  error:&error];
  [imageRX enumerateMatchesInString:shortened options:0 range:NSMakeRange(0, [shortened length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    // your code to handle matches here
    imageFoundInInterestingPartOfBody = YES;
    [images addObject:[shortened substringWithRange:[match range]]];
  }];
  

  [imageRX enumerateMatchesInString:fullContent options:0 range:NSMakeRange(0, [fullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    // your code to handle matches here
    [images addObject:[fullContent substringWithRange:[match range]]];
  }];

  CGFloat largestSize = 0.0;
  NSString *leadImage = nil;
  BOOL widthOrHeightFound = NO;
  for ( NSString *img in images ) {
    CGFloat width = 0.0;
    
    if ( [img rangeOfString:@"width"].location != NSNotFound ) {
      NSString *widthStr = [Utilities getValueForHTMLTag:@"width" inBody:img];
      width = [widthStr floatValue];
      widthOrHeightFound = YES;
    }
    
    CGFloat height = 0.0;
    if ( [img rangeOfString:@"height"].location != NSNotFound ) {
      NSString *heightStr = [Utilities getValueForHTMLTag:@"height" inBody:img];
      height = [heightStr floatValue];
      widthOrHeightFound = YES;
    }
    
    if ( widthOrHeightFound ) {
      CGFloat product = width*height;
      if ( product > largestSize ) {
        leadImage = img;
        largestSize = product;
      }
    } else {
      leadImage = [images objectAtIndex:0];
    }
  }

  if ( !leadImage ) {
    leadImage = @"";
  }

  NSString *originalFullContent = [NSString stringWithString:fullContent];
  fullContent = [NSString stringWithString:shortened];
  
  // KPCC CHEAT
  bigStripper = [NSRegularExpression
                 regularExpressionWithPattern:@"<div class=\"static-slides\".*?>.*?<br/>"
                 options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                 error:&error];
  [bigStripper enumerateMatchesInString:fullContent options:0 range:NSMakeRange(0, [fullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    shortened = [fullContent stringByReplacingOccurrencesOfString:[fullContent substringWithRange:[match range]]
                                                       withString:@""];
  }];

  NSString *justPs = @"";
  fullContent = [NSString stringWithString:shortened];
  
  NSMutableArray *ps = [[NSMutableArray alloc] init];
  NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:@"<p.*?>.*?</p>"
                                options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                error:&error];
  [regex enumerateMatchesInString:fullContent options:0 range:NSMakeRange(0, [fullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    // your code to handle matches here
    [ps addObject:[fullContent substringWithRange:[match range]]];
  }];
  
  for ( unsigned i = 0; i < [ps count]; i++ ) {
    NSString *p = [ps objectAtIndex:i];
    __block NSString *stripped = [NSString stringWithString:p];
    if ( ![Utilities pureNil:leadImage] ) {
      NSRegularExpression *imageRX = [NSRegularExpression
                                      regularExpressionWithPattern:@"<img.*?/?>"
                                      options:NSRegularExpressionCaseInsensitive
                                      error:&error];
      [imageRX enumerateMatchesInString:p options:0 range:NSMakeRange(0, [p length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        // your code to handle matches here
        stripped = [p stringByReplacingOccurrencesOfString:[p substringWithRange:[match range]]
                                                withString:@""];
      }];
      
      p = stripped;
    }
    
    justPs = [justPs stringByAppendingString:p];
  }
  
  NSArray *bylines = [Utilities loadJson:@"byline_containers"];
  
  __block NSString *candidateByline = nil;
  for ( NSString *byline in bylines ) {
    
    if ( candidateByline ) {
      break;
    }
    NSRegularExpression *bylineRX = [NSRegularExpression
                                   regularExpressionWithPattern:byline
                                   options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                   error:&error];
    [bylineRX enumerateMatchesInString:originalFullContent options:0 range:NSMakeRange(0, [originalFullContent length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
      if ( [match numberOfRanges] > 1 ) {
        NSRange actualMatch = [match rangeAtIndex:1];
        candidateByline = [originalFullContent substringWithRange:actualMatch];
      }
    }];
  
  }
  
  if ( !candidateByline ) {
    candidateByline = @"";
  }
  
  NSLog(@" is : %@",shortened);

  NSDictionary *reduced = @{ @"title" : title, @"content" : justPs, @"lead_image_url" : leadImage, @"byline" : candidateByline };
  [processor handleReducedArticle:reduced];

  return @"";
}

- (void)remoteReductionForArticle:(NSString *)url processor:(id<ContentProcessor>)processor {

  NSURL *reqURL = [NSURL URLWithString:url];
  NSLog(@"Reducing %@",url);
  
  NSURLRequest *request = [NSURLRequest requestWithURL:reqURL];
  [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             NSLog(@"Error reducing article with Readability : %@",[e localizedDescription]);
                             return;
                           }

                           NSString *response = [[NSString alloc] initWithData:d
                                                                      encoding:NSUTF8StringEncoding];
                           
                           dispatch_sync(dispatch_get_main_queue(), ^{
                             [self localReduction:response processor:processor];
                           });
                         }];
}

#pragma mark - Processing
- (void)processCompositeData:(NSDictionary *)compositeContent {
  @synchronized(self) {
    self.compositeMainNewsFetchFinished = YES;
  }
  
  [[ContentManager shared].settings setLastCompositeNewsSync:[NSDate date]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  NSMutableDictionary *hash = [[NSMutableDictionary alloc] init];
  NSArray *trending = [compositeContent objectForKey:@"trending"];
  NSArray *general = [compositeContent objectForKey:@"general"];
  
  for ( NSDictionary *trendingArticle in trending ) {
    if ( [trendingArticle objectForKey:@"short_title"] ) {
      NSString *hashedTitle = [Utilities sha1:[trendingArticle objectForKey:@"short_title"]];
      [hash setObject:@1 forKey:hashedTitle];
    }
  }
  
  if ( !trending || !general ) {
    return;
  }
  
  NSLog(@" *** Going to embiggen %d stories",[hash count]);
  NSDictionary *final = @{ @"trending" : trending,
                           @"general" : general,
                           @"lookup" : hash,
                           @"totalCount" : [NSNumber numberWithInt:[general count]] };
  
  id<ContentProcessor> processor = [compositeContent objectForKey:@"processor"];

  NSMutableDictionary *temp = [compositeContent mutableCopy];
  [temp removeObjectForKey:@"processor"];
  NSDictionary *slimHash = [NSDictionary dictionaryWithDictionary:temp];
  
  [[ContentManager shared] setGlobalCompositeNews:[slimHash mutableCopy]];
  
  NSInteger currentNewsPage = [[ContentManager shared] currentNewsPage];
  NSLog(@"CURRENT NEWS PAGE : %d",currentNewsPage);
  
  [[ContentManager shared] setCurrentNewsPage:[[ContentManager shared] currentNewsPage]+1];
  
  if ( [processor respondsToSelector:@selector(handleCompositeNews:)] ) {
    if ( ![[ContentManager shared].settings editionsJson] ) {
      [NSTimer scheduledTimerWithTimeInterval:0.66
                                       target:self
                                     selector:@selector(finishJob:)
                                     userInfo:@{ @"processor" : processor, @"final" : final }
                                      repeats:NO];
    } else {
      [processor handleCompositeNews:final];
    }
  }
}

- (void)finishJob:(NSTimer*)timer {
  NSDictionary *meta = [timer userInfo];
  id<ContentProcessor> processor = [meta objectForKey:@"processor"];
  NSDictionary *final = [meta objectForKey:@"final"];
  [processor handleCompositeNews:final];
}

- (void)processEventsData:(NSDictionary *)content {
  id<ContentProcessor> processor = [content objectForKey:@"port"];
  NSMutableArray *unprocessed = [[content objectForKey:@"chunk"] mutableCopy];
  NSMutableArray *vpData = [[NSMutableArray alloc] init];
  for ( NSDictionary *event in unprocessed ) {
    NSString *type = [event objectForKey:@"event_type"];
    if ( [type isEqualToString:@"cult"] ||
          [type isEqualToString:@"comm"] ||
        [type isEqualToString:@"hall"] ) {
      [vpData addObject:event];
    }
  }
  NSMutableDictionary *real = [[NSMutableDictionary alloc] init];
  
  if ( ![Utilities pureNil:vpData] ) {
    NSDictionary *leadEvent = [vpData objectAtIndex:0];
    NSMutableDictionary *bigPosts = [[NSMutableDictionary alloc] init];
    
    if ( [[ScheduleManager shared] eventIsLive:leadEvent] ) {
      [bigPosts setObject:@1 forKey:[leadEvent objectForKey:@"id"]];
    }
    
    [real setObject:vpData forKey:@"all_posts"];
    [real setObject:bigPosts forKey:@"big_posts"];
    
  } else {
    [real setObject:@[] forKey:@"all_posts"];
    [real setObject:@{} forKey:@"big_posts"];
  }
  
  [processor handleEvents:real];
}

- (void)processVideoPhotoData:(NSDictionary *)videoPhotoContent {
  id<ContentProcessor> processor = [videoPhotoContent objectForKey:@"processor"];
  NSMutableDictionary *vpData = [[videoPhotoContent objectForKey:@"content"] mutableCopy];
  NSArray *bigPosts = [vpData objectForKey:@"big_posts"];
  NSMutableDictionary *big = [[NSMutableDictionary alloc] init];
  
  NSMutableArray *filtered = [[NSMutableArray alloc] init];
  for ( NSDictionary *d in bigPosts ) {
    if ( [d objectForKey:@"id"] ) {
      [big setObject:@1 forKey:[d objectForKey:@"id"]];
      [filtered addObject:d];
    } else {
      continue;
    }
  }
  
  bigPosts = [NSArray arrayWithArray:filtered];
  
  NSArray *all = [vpData objectForKey:@"all_posts"] ? [vpData objectForKey:@"all_posts"] : @[];
  
  NSDictionary *realVPData = @{ @"all_posts" : all,
                                @"big_posts" : big };
  
  [processor handleVideoPhoto:realVPData];
}

- (NSInteger)satisfactoryLoadBalanceBetween:(NSMutableArray *)thisArray andThatArray:(NSMutableArray *)thatArray {
  for ( int x = 0; x < [thatArray count]; x++ ) {
    
    NSInteger adjustedThat = [thatArray count]-x;
    NSInteger adjustedThis = [thisArray count]+x;
    NSInteger diff = abs((int)floorf(adjustedThis/6.0) - adjustedThat);
    if ( diff <= 3 ) {
      return x;
    }
  }
  
  return 0;
}

- (void)processContentData:(NSDictionary *)content {
  
  [[Utilities del] setServerDown:NO];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"fetch_ok"
                                                      object:nil];
  
  NSDictionary *flags = @{};
  if ( [content objectForKey:@"flags"] ) {
    flags = [content objectForKey:@"flags"];
  }
  
  id<ContentProcessor> display = [content objectForKey:@"port"];
  id data = [content objectForKey:@"chunk"];
  
  if ( [flags objectForKey:@"cache_results"] ||
    ![display respondsToSelector:@selector(handleProcessedContent:flags:)] ||
    [flags objectForKey:@"composite"] ) {
 
    NSLog(@"Caching Editions data...");

    [[ContentManager shared].settings setEditionsJson:[data JSONRepresentation]];
    [[ContentManager shared] setSkipParse:YES];
    [[ContentManager shared] writeSettings];
  
    @synchronized(self) {
      self.compositeEditionsFetchFinished = YES;
    }
  
    if ( [flags objectForKey:@"composite"] ) {
      return;
    }
  }
  
  
  if ( [Utilities pureNil:data] ) {
    [display handleProcessedContent:@[] flags:flags];
    return;
  }
  
  if ( [data isKindOfClass:[NSDictionary class]] ) {
    [display handleProcessedContent:@[data] flags:flags];
  } else {
    [display handleProcessedContent:data flags:flags];
  }
}

- (void)processContentAdditional:(NSDictionary*)content {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"fetch_ok"
                                                      object:nil];
  
  NSArray *data = [content objectForKey:@"chunk"];
  id<ContentProcessor> display = [content objectForKey:@"port"];
  [display handleAdditionalContent:data forTopic:[content objectForKey:@"topic"]];
}

- (void)processContentDataSingle:(NSDictionary*)content {
  NSDictionary *data = [content objectForKey:@"chunk"];
  id<ContentProcessor> display = [content objectForKey:@"port"];
  [display handleProcessedContent:@[data] flags:@{}];
}

- (void)processContentDataSingle:(NSDictionary *)content completion:(CompletionBlockWithValue)completion {
  NSDictionary *data = content;
  dispatch_async(dispatch_get_main_queue(), ^{
    if ( completion ) {
      completion(data);
    }
  });

}

@end
