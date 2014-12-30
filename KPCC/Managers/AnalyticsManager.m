//
//  AnalyticsManager.m
//  KPCC
//
//  Created by Ben on 4/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "AnalyticsManager.h"
#import "TestFlight.h"
#import "Flurry.h"
#import "global.h"
#import "SBJson.h"
#import <Parse/Parse.h>
#import "SCPR404ViewController.h"
#import "SCPRViewController.h"

static AnalyticsManager *singleton = nil;

@implementation AnalyticsManager

+ (AnalyticsManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      singleton = [[AnalyticsManager alloc] init];
      // Assembly line
      [[NSNotificationCenter defaultCenter] addObserver:singleton
                                               selector:@selector(logOut:)
                                                   name:@"logged_out"
                                                 object:nil];
    }
  }
  return singleton;
}

- (void)primeAnalytics {
  NSString *tfKey = [Utilities isIpad] ? [[[[FileManager shared] globalConfig] objectForKey:@"TestFlight"] objectForKey:@"iPadKey"] : [[[[FileManager shared] globalConfig] objectForKey:@"TestFlight"] objectForKey:@"iPhoneKey"];
  [TestFlight takeOff:tfKey];
  
  [Flurry setCrashReportingEnabled:YES];
#ifdef PRODUCTION
  [Flurry startSession: [[[[FileManager shared] globalConfig] objectForKey:@"Flurry"] objectForKey:@"ProductionKey"] ];
#elif RELEASE
  [Flurry startSession: [[[[FileManager shared] globalConfig] objectForKey:@"Flurry"] objectForKey:@"ProductionKey"] ];
#else
  //[Flurry setDebugLogEnabled:YES];
  [Flurry startSession: [[[[FileManager shared] globalConfig] objectForKey:@"Flurry"] objectForKey:@"DebugKey"] ];
#endif
  [Flurry setBackgroundSessionEnabled:NO];
}

#pragma mark - Ad serving
- (void)retrieveAdSettings {
  PFQuery *q = [PFQuery queryWithClassName:@"AdSettings"];

  NSString *buildType = @"PRODUCTION";
#ifndef PRODUCTION
  buildType = @"INTERNAL";
#endif
  
  [q whereKey:@"buildType" equalTo:buildType];
  [q getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    
    
    if ( error ) {
      NSLog(@"Error retrieving ad settings, defaulting to 5 and 5 : %@",[error userInfo]);
      [self setNumberOfSwipesPerAd:@5];
      [self setNumberOfAdsPerSession:@5];
      [self setAdVendorID: [[[[FileManager shared] globalConfig] objectForKey:@"AdSettings"] objectForKey:@"VendorId"] ];
      [self setAdUnitID:@"TEST_iPad_UnitV1_Web"];
      [self setUrlHint:@"g.doubleclick.net/aclk"];
      [self setAdGtpID: [[[[FileManager shared] globalConfig] objectForKey:@"AdSettings"] objectForKey:@"AdGtpId"] ];
      return;
    }
    
    /************************************************************/
    // -- Developer Note --
    //
    // To make ad serving a bit more flexible these settings are retrieved from Parse.
    //
    // numberOfAdsPerSession - Max number of total ads the user will see per session
    // numberOfSwipesPerAd - The number of swipes the user executes before an ad is served
    // adVendorID - Used to build the ID string that lets Google DFP know who we are. See webdfp.html, this value is inserted where the ||_ADVENDOR_ID_|| macro is
    // adUnitID - The second part of the ID string. See webdfp.html, this value is inserted where the ||_ADUNIT_ID_|| macro is
    // urlHint - The app needs to know to open an ad's URL in Safari and not inline, so this string is what the app will look for on the load
    //           request when an ad is tapped. The idea is that all links through DFP are uniform enough to distill this to one value, but if not then a different
    //           data structure might be required in order to store all possible values for ad URLs.
    //
    // adGTPID - ** As of now I think this value is irrelevant ** . The js that's generated by DFP for loading ads produces a value that changes each time it's generated.
    //            Because of this I decided to keep this value stored in Parse, but it seems to have no effect on the ad serving.
    //
    // In order to turn off ads remotely, set the numberOfAdsPerSession and the numberOfSwipesPerAd values to 0 in parse.
    //
    
    NSLog(@"Using ad settings for %@ with ID : %@",[object objectForKey:@"buildType"],[object objectId]);
    
    if ( object ) {
      [self setNumberOfAdsPerSession:[object objectForKey:@"numberOfAdsPerSession"]];
      [self setNumberOfSwipesPerAd:[object objectForKey:@"numberOfSwipesPerAd"]];
      [self setAdVendorID:[object objectForKey:@"adVendorID"]];
      [self setAdUnitID:[object objectForKey:@"adUnitID"]];
      [self setUrlHint:[object objectForKey:@"urlHint"]];
      [self setAdGtpID:[object objectForKey:@"adGTPID"]];
    } else {
      [self setNumberOfSwipesPerAd:@5];
      [self setNumberOfAdsPerSession:@5];
      [self setAdVendorID: [[[[FileManager shared] globalConfig] objectForKey:@"AdSettings"] objectForKey:@"VendorId"] ];
      [self setAdUnitID:@"TEST_iPad_UnitV1"];
      [self setUrlHint:@"g.doubleclick.net/aclk"];
      [self setAdGtpID: [[[[FileManager shared] globalConfig] objectForKey:@"AdSettings"] objectForKey:@"AdGtpId"] ];
    }
  }];
}

#pragma mark - Analytics Listening
- (void)logOut:(NSNotification*)note {
  
}

- (void)openTimedSessionForContentType:(NSInteger)contentType {
  if ( contentType == self.screenContent ) {
    return;
  }

  if ( self.timedSessionOpen ) {
    [self terminateTimedSessionForContentType:self.screenContent];
  }
  self.sessionBegan = [[NSDate date] timeIntervalSince1970];
  self.screenContent = contentType;
  self.timedSessionOpen = YES;
}

- (void)terminateTimedSessionForContentType:(NSInteger)contentType {
  if ( !self.timedSessionOpen ) {
    return;
  }

  self.timedSessionOpen = NO;
  NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
  NSInteger length = (NSInteger) now - self.sessionBegan;
  
  NSString *lengthStr = [NSString stringWithFormat:@"%d",length];
  NSString *name = [[ContentManager shared] nameForScreenContentType:self.screenContent];
  if ( contentType == ScreenContentTypeSnapshotPage ) {
    NSDictionary *focusedEditionObject = [[ContentManager shared] focusedEditionObject];
    NSString *eid = [NSString stringWithFormat:@"%@",[focusedEditionObject objectForKey:@"id"]];
    [self logEvent:[NSString stringWithFormat:@"user_viewed_%@",name]
    withParameters:@{ @"duration_in_seconds" : lengthStr, @"edition_id" : eid }];
  } else {
    [self logEvent:[NSString stringWithFormat:@"user_viewed_%@",name]
    withParameters:@{ @"duration_in_seconds" : lengthStr }];
  }
}

- (NSDictionary*)paramsForArticle:(NSDictionary *)article {
  NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
  if ( [article objectForKey:@"url"] ) {
    [params setObject:[article objectForKey:@"url"] forKey:@"article_url"];
  } else if ( [article objectForKey:@"permalink"] ) {
    [params setObject:[article objectForKey:@"permalink"]
               forKey:@"article_url"];
  }

  if ( [article objectForKey:@"id"] ) {
    [params setObject:[article objectForKey:@"id"]
               forKey:@"article_id"];
  }

  if ( [article objectForKey:@"short_title"] ) {
    [params setObject:[article objectForKey:@"short_title"]
               forKey:@"article_title"];
  }

  if ( [article objectForKey:@"headline"] ) {
    [params setObject:[article objectForKey:@"headline"]
               forKey:@"article_title"];
  }

  return [NSDictionary dictionaryWithDictionary:params];
}

#pragma mark - Error Logging
- (void)analyzeStreamError:(NSString *)comments {

  NSURL *liveURL = [NSURL URLWithString:kLiveStreamURL];
  NetworkHealth netHealth = [[NetworkManager shared] checkNetworkHealth:[liveURL host]];
  if ( NetworkHealthNetworkDown == netHealth ) {
    [self failStream:StreamStateLostConnectivity comments:comments];
  } else if ( NetworkHealthServerDown == netHealth ) {
    [self failStream:StreamStateServerFail comments:comments];
  } else {
    [self failStream:StreamStateUnknown comments:comments];
  }

  NSLog(@"Stream error...");
}

- (void)networkDisappeared {

  NSDictionary *analysis = @{ @"timeDropped" : [NSDate stringFromDate:[NSDate date]
                                                            withFormat:@"YYYY-MM-dd hh:mm:ss"] };
  [Flurry logEvent:@"networkFailure" withParameters:[self mergeParametersWithUserInfo:analysis callingFunction:@"networkDropped"]];
}

- (void)failureFetchingImage:(NSString *)link {

  NSDictionary *analysis = @{ @"timeFailed" : [NSDate stringFromDate:[NSDate date]
                                                          withFormat:@"YYYY-MM-dd hh:mm:ss"],
                              @"failedLink" : link };
  
  [Flurry logEvent:@"failureFetchingImage"
    withParameters:[self mergeParametersWithUserInfo:analysis
                                     callingFunction:@"failedFetchingImage"]
                      timed:YES];
}

- (void)failureFetchingContent:(NSString *)link {
  
  NSLog(@"Failure fetching content...");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self app404];
  });
  
  NSDictionary *analysis = @{ @"timeFailed" : [NSDate stringFromDate:[NSDate date]
                                                          withFormat:@"YYYY-MM-dd hh:mm:ss"],
                              @"failedLink" : link };
  
  [Flurry logEvent:@"failureFetchingContent"
    withParameters:[self mergeParametersWithUserInfo:analysis
                                     callingFunction:@"failedFetchingContent"]
                      timed:YES];
}

- (void)app404 {
  SCPRAppDelegate *del = [Utilities del];
  SCPR404ViewController *fourofour = [[SCPR404ViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                     xibForPlatformWithName:@"SCPR404ViewController"]
                                                                             bundle:nil];

  [del cloakUIWithCustomView:fourofour dismissible:YES];
  [del setServerDown:YES];
}

#pragma mark - Stream Analytics
- (void)failStream:(StreamState)cause comments:(NSString *)comments {

  @synchronized(self) {
    self.interruptionCause = cause;
    self.streamDropped = [NSDate date];
  }

  if ( !comments ) {
    comments = @"";
  }

  if ( self.audioStreamInFailedState ) {
    self.droppedPackets++;
  } else {
    NSDictionary *analysis = @{ @"cause" : [self stringForInterruptionCause:cause],
                                @"timeDropped"  : [NSDate stringFromDate:self.streamDropped
                                                              withFormat:@"YYYY-MM-dd hh:mm:ss"],
                                @"details" : comments };
    [Flurry logEvent:@"streamInterrupted"
    withParameters:[self mergeParametersWithUserInfo:analysis
                                     callingFunction:@"streamFailure"]
                                               timed:YES];
  }
  NSLog(@"Sending stream failure report to Flurry");
}

- (void)unfailStream {
  if ( self.audioStreamInFailedState ) {
    self.audioStreamInFailedState = NO;
    self.streamRestored = [NSDate date];
    
    NSDictionary *analysis = @{
                               
                              @"cause" : [self stringForInterruptionCause:self.interruptionCause],
                              @"timeDropped" : [NSDate stringFromDate:self.streamDropped
                                                            withFormat:@"YYYY-MM-dd hh:mm:ss"],
                              @"timeRestored" : [NSDate stringFromDate:self.streamRestored
                                                             withFormat:@"YYYY-MM-dd hh:mm:ss"],
                              @"droppedPackets" : [NSString stringWithFormat:@"%d",self.droppedPackets]
                              
                            };

    [Flurry logEvent:@"streamRestored"
    withParameters:[self mergeParametersWithUserInfo:analysis callingFunction:@"streamRestore"]
             timed:YES];
  }

  @synchronized(self) {
    self.interruptionCause = StreamStateHealthy;
    self.droppedPackets = 0;
    self.streamRestored = nil;
    self.streamDropped = nil;
  }
}

- (NSString*)stringForInterruptionCause:(StreamState)cause {
  NSString *english = @"";
  switch (cause) {
    case StreamStateLostConnectivity:
      english = @"Device lost connectivity";
      break;
    case StreamStateServerFail:
      english = [NSString stringWithFormat:@"Device could not communicate with : %@",kLiveStreamURL];
      break;
    case StreamStateHealthy:
    case StreamStateUnknown:
      english = @"Stream failed for unknown reason";
    default:
      break;
  }
  return english;
}

- (NSDictionary*)mergeParametersWithUserInfo:(NSDictionary *)extraParams callingFunction:(NSString *)callingFunction {

  NSLog(@"Sending analysis to Flurry : %@",callingFunction);
  NSDictionary *userInfo =  @{
           
                         @"deviceID" : [[ContentManager shared].settings deviceID],
                         @"lastKnownNetworkConnection" : [[ContentManager shared].settings lastKnownConnectionType]
           
           };
  
  NSMutableDictionary *combined = [NSMutableDictionary dictionaryWithDictionary:userInfo];
  [combined addEntriesFromDictionary:extraParams];
  return [NSDictionary dictionaryWithDictionary:combined];
}

- (void)tS {
#ifdef LOG_DEALLOCATIONS
  if ( self.timing ) {
    return;
  }
  
  @synchronized(self) {
    self.timing = YES;
  }
  self.start = [self getUptimeInMilliseconds];
#endif
}

- (void)tF:(NSString*)functionName {
#ifdef LOG_DEALLOCATIONS
  // Do some stuff that you want to time
  CGFloat endTime = [self getUptimeInMilliseconds];
  
  // Time elapsed in Mach time units.
  CGFloat elapsedMTU = endTime - self.start;
  
  NSLog(@"%1.3f seconds for %@", (CGFloat)elapsedMTU / 1000.0, functionName);
  @synchronized(self) {
    self.timing = NO;
  }
#endif
}

- (CGFloat) getUptimeInMilliseconds {
  const int64_t kOneMillion = 1000 * 1000;
  static mach_timebase_info_data_t s_timebase_info;
  
  if (s_timebase_info.denom == 0) {
    (void) mach_timebase_info(&s_timebase_info);
  }
  
  // mach_absolute_time() returns billionth of seconds,
  // so divide by one million to get milliseconds
  return (CGFloat)((mach_absolute_time() * s_timebase_info.numer) / (kOneMillion * s_timebase_info.denom));
}

- (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters {
  
  NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
  [userInfo setObject:[[ContentManager shared].settings deviceID]
               forKey:@"device_id"];
  
  double tlt = [[ContentManager shared].settings totalListeningTime];
  NSString *totalListening = [NSString stringWithFormat:@"%d",(int)tlt];
  
  [userInfo setObject:totalListening forKey:@"total_listening_time"];
  
  for ( NSString *key in [parameters allKeys] ) {
    [userInfo setObject:[parameters objectForKey:key]
                 forKey:key];
  }

#ifdef DEBUG
  // NSLog(@"Logging to Flurry now - %@ - with params %@", event, parameters);
#endif
  [Flurry logEvent:event withParameters:userInfo timed:YES];
}

@end
