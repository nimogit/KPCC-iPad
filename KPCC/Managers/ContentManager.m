//
//  ContentManager.m
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "ContentManager.h"
#import "global.h"
#import "domain.h"
#import "UIDevice+IdentifierAddition.h"
#import "SBJson.h"
#import <Parse/Parse.h>
#import "SCPRViewController.h"
#import "SCPRQueueCellViewController.h"
#import "SCPRMasterRootViewController.h"
#import "SCPRDrawerViewController.h"

#define kImageFileLimit 180
#define kImageMemoryFileLimit 20
#define kImageSwappingLimit 50
#define kArticleExpireInDays 3
#define kProgramExpireInMinutes 20
#define kImageCacheMBLimit 20.0
#define kMaxNewsContent 8

static ContentManager *singleton = nil;

@implementation ContentManager

+ (ContentManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      singleton = [[ContentManager alloc] init];
    
      singleton.globalImageQueue = [[NSOperationQueue alloc] init];
      singleton.resizeVector = [[NSMutableArray alloc] init];
      singleton.deactivationQueue = [[NSMutableDictionary alloc] init];
      singleton.globalCompositeNews = [[NSMutableDictionary alloc] init];
      
      NSMutableDictionary *marshalledNews = singleton.globalCompositeNews;
      [marshalledNews setObject:[[NSMutableArray alloc] init]
                         forKey:@"trending"];
      [marshalledNews setObject:[[NSMutableArray alloc] init]
                         forKey:@"general"];
      
      singleton.currentNewsPage = 1;
      [singleton managedObjectModel];
      [singleton managedObjectContext];
      [singleton loadSettings];
      [singleton setPassiveProgramCheck:YES];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [singleton threadedSaveContext:singleton.persistentStoreCoordinator];
      });
    }
  }
  
  return singleton;
}

- (void)resetNewsContent {
  [[ContentManager shared] setCurrentNewsPage:1];
  
  NSMutableDictionary *marshalledNews = [self globalCompositeNews];
  [marshalledNews setObject:[[NSMutableArray alloc] init]
                     forKey:@"trending"];
  [marshalledNews setObject:[[NSMutableArray alloc] init]
                     forKey:@"general"];
  
  self.compositeNewsLookupHash = [@{} mutableCopy];
  [self.settings setEditionsJson:@""];

  [[ContentManager shared] setGlobalCompositeNews:marshalledNews];
  [[QueueManager shared] setStories:@{}];

  [[ContentManager shared].settings setLastEditionsSync:nil];
  [[ContentManager shared].settings setLastCompositeNewsSync:nil];
  [[NetworkManager shared] setCompositeEditionsFetchFinished:NO];
  [[NetworkManager shared] setCompositeMainNewsFetchFinished:NO];

  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
}

- (NSDictionary*)buildDeviceObject {
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  [dictionary setObject:[[UIDevice currentDevice] model]
                 forKey:@"deviceType"];
  
  [dictionary setObject:[[UIDevice currentDevice] systemName]
                 forKey:@"deviceSystemName"];
  
  [dictionary setObject:[[UIDevice currentDevice] systemVersion]
                 forKey:@"deviceSystemVersion"];
  
  NSString *usableToken = [Utilities pureNil:[self.settings pushToken]] ? @"" : [self.settings pushToken];
  [dictionary setObject:usableToken
                 forKey:@"pushToken"];
  
  return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSString*)modelBase {
  return @"kpcc";
}

#pragma mark - Settings
- (void)syncSettingsWithParse {
#ifdef USE_PARSE
  PFQuery *query = [PFQuery queryWithClassName:@"UserInfo"];
  NSLog(@"Device ID : %@",self.settings.deviceID);
  
  [query whereKey:@"deviceID"
          equalTo:self.settings.deviceID];

  [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    
      if ( error ) {
        [self performSelectorOnMainThread:@selector(leaveSettingsAlone)
                               withObject:nil
                            waitUntilDone:NO];
        return;
      }

      if ( object ) {
        [self performSelectorOnMainThread:@selector(readParse:)
                               withObject:@{ @"user" : object }
                            waitUntilDone:NO];
        return;
      } else {
        [self performSelectorOnMainThread:@selector(writeToParse)
                               withObject:nil
                            waitUntilDone:NO];
        return;
      }
      
      [self performSelectorOnMainThread:@selector(leaveSettingsAlone)
                             withObject:nil
                          waitUntilDone:NO];
      return;
        
  }];

#endif
}

- (void)leaveSettingsAlone {
  self.settings.lastKnownConnectionType = [[NetworkManager shared] networkInformation];
  [self setSkipParse:YES];
  [self writeSettings];
}

- (void)readParse:(NSDictionary*)meta {

  __block NSString *before = [self.settings favoriteProgramsAsJson];

  PFUser *user = [meta objectForKey:@"user"];
  [user fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    [self.settings setTotalListeningTime:[[user objectForKey:@"totalListeningTime"] doubleValue]];
    [self.settings setUserFacebookInformation:[user objectForKey:@"userFacebookInformation"]];
    [self.settings setTwitterInformation:[user objectForKey:@"userTwitterInformation"]];
    [self.settings setLinkedInInformation:[user objectForKey:@"userLinkedInInformation"]];
    [self.settings setLinkedInToken:[user objectForKey:@"linkedInToken"]];
    if ( ![Utilities pureNil:[user objectForKey:@"membershipInformation"]] ) {
      [self.settings setMemberInformation:[user objectForKey:@"membershipInformation"]];
    }
    NSDate *rfcDate = [Utilities dateFromRFCString:[user objectForKey:@"linkedInTokenExpire"]];
    [self.settings setLinkedInTokenExpire:rfcDate];
    [self.settings setLastKnownConnectionType:[user objectForKey:@"lastKnownConnectionType"]];
    [self.settings setSingleSignOnWithLinkedIn:[[user objectForKey:@"singleSignOnWithLinkedIn"] boolValue]];
    [self.settings setProfileImageURL:[user objectForKey:@"profileImageURL"]];
    [self.settings setParseId:[user objectId]];
    [self.settings setParseInitiated:YES];
    
    NSString *userFaveJson = [user objectForKey:@"favoritePrograms"];
    [self.settings setFavoriteProgramsAsJson:userFaveJson];
    
    NSDictionary *devices = [user objectForKey:@"devices"];
    NSDictionary *devicePT = [devices objectForKey:[self.settings deviceID]];
    
    [self.settings setPushToken:[devicePT objectForKey:@"pushToken"]];
    [self setSkipParse:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self setPerformWriteOnMainThread:YES];
      [self setSkipParse:YES];
      [self writeSettings];
    
      if ( [[SocialManager shared] isAuthenticatedWithFacebook] ||
        [[SocialManager shared] isAuthenticatedWithLinkedIn] ||
        [[SocialManager shared] isAuthenticatedWithTwitter] ||
          [[SocialManager shared] isAuthenticatedWithMembership] ) {
      

        [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                            object:nil];

      } else {
        
        if ( ![self.settings.favoriteProgramsAsJson isEqualToString:before] ) {

          [[NSNotificationCenter defaultCenter] postNotificationName:@"favorites_modified"
                                                              object:nil];
 
        }
      }
    });
  }];
}

- (void)sanitizeSettings {
  if ( ![self.settings userFacebookInformation] ) {
    [self.settings setUserFacebookInformation:@""];
  }
  if ( ![self.settings twitterInformation] ) {
    [self.settings setTwitterInformation:@""];
  }
  if ( ![self.settings linkedInInformation] ) {
    [self.settings setLinkedInInformation:@""];
  }
  if ( ![self.settings linkedInToken] ) {
    [self.settings setLinkedInToken:@""];
  }
  if ( ![self.settings linkedInTokenExpire] ) {
    [self.settings setLinkedInTokenExpire:[NSDate dateWithTimeIntervalSince1970:0]];
  }
  if ( ![self.settings lastKnownConnectionType] ) {
    [self.settings setLastKnownConnectionType:@""];
  }
  if ( ![self.settings profileImageURL] ) {
    [self.settings setProfileImageURL:@""];
  }
  if ( ![self.settings deviceID] ) {
    [self.settings setDeviceID:@""];
  }
  if ( ![self.settings parseId] ) {
    [self.settings setParseId:@""];
  }
  if ( ![self.settings pushToken] ) {
    [self.settings setPushToken:@""];
  }
  if ( ![self.settings parseDeviceId] ) {
    [self.settings setParseDeviceId:@""];
  }
}

- (void)loadSettings {
  if ( self.settings ) {
    self.settings = nil;
  }
  
  NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings"];
  if ( data ) {
    self.settings = (SCPRSettings*)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self syncSettingsWithParse];
    [self sanitizeSettings];
    self.parseReady = YES;
  } else {
    self.settings = [[SCPRSettings alloc] init];
    
    NSUUID *uid = [[UIDevice currentDevice] identifierForVendor];
    
    self.settings.deviceID = [uid UUIDString];

    self.settings.lastCacheCleanDate = [NSDate date];
    [self sanitizeSettings];
    [self syncSettingsWithParse];
  }
}


/**********************************************************/
// -- Developer Note --
// One kind of quirky thing (besides the threading) that's happening here is that unless self.skipParse is explicitly set to "YES" then the app will
// automatically persist relevant settings data to Parse. After some time it became apparent that the inverse behavior probably should have been implemented
// i.e. skipParse becomes pushDataToParse, and then it's explicitly set to "YES" whenever the app needs to sync its newly written data to Parse. As it were,
// that change was never made, so what you'll see a lot throughout the app is a call to [[ContentManager shared] setSkipParse:YES] right before [[ContentManager shared]
// writeSettings]. Parse is pretty responsive but as with all network calls and anything where we reach out we should save on doing unnecessary work, and because what's
// up in Parse is a subset of the local settings here there end up being a lot of writes that don't involve the set that's up in Parse. So try to heed this methodology
// where possible.
- (void)writeSettings {
  if ( self.threadLock ) {
    return;
  }
  
  [self sanitizeSettings];
  
  @synchronized(self) {
    self.threadLock = YES;
  }
  
  BOOL forceMainThread = NO;
  
#ifdef FORCE_MAIN_THREAD_SETTINGS
  forceMainThread = YES;
#endif
  
  if ( self.performWriteOnMainThread || forceMainThread ) {
    [self threadedSettings];
    self.performWriteOnMainThread = NO;
    return;
  }
  
  if ( [NSThread isMainThread] ) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [self threadedSettings];
    });
  } else {
    [self threadedSettings];
  }
}

- (void)threadedSettings {
  if ( self.settings ) {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.settings];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"settings"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ( self.skipParse || !self.parseReady ) {
      if ( self.skipParse ) {
        self.skipParse = NO;
      }
    } else {

      [self writeToParse];

    }
  }
  @synchronized(self) {
    self.threadLock = NO;
  }
}

- (void)forceSettingsWithParse {
  self.skipParse = YES;
  [self writeSettings];
  [self writeToParse];
}

- (void)writeToParse {
#ifdef USE_PARSE
  __block PFObject *parseBlock = nil;
  PFQuery *query = [PFQuery queryWithClassName:@"UserInfo"];
  

  [query whereKey:@"deviceID" equalTo:[self.settings deviceID]];
  [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    
    NSAssert([NSThread isMainThread], @"This should be a background thread...");
    parseBlock = object;
    
    if ( !parseBlock ) {
      
      NSLog(@"Creating new parse block...");
      parseBlock = [PFObject objectWithClassName:@"UserInfo"];
      NSDictionary *devices = @{ [self.settings deviceID] : [self buildDeviceObject] };
      [parseBlock setObject:devices forKey:@"devices"];
    } else {
      NSDictionary *devices = [parseBlock objectForKey:@"devices"];
      if ( ![devices objectForKey:[self.settings deviceID]] ) {
        NSMutableDictionary *mutable = [devices mutableCopy];
        [mutable setObject:[self buildDeviceObject]
                    forKey:[self.settings deviceID]];
        [parseBlock setObject:[NSDictionary dictionaryWithDictionary:mutable]
                       forKey:@"devices"];
      }
    }

    // Push all listened segments up to Parse
    NSArray *segments = [[ContentManager shared] findAllSegments];
    for ( Segment *s in segments ) {
      
      NSDictionary *article = (NSDictionary*)[s.originalArticle JSONValue];
      article = [self bakeInIDForArticle:article];

      if ( [s.completed boolValue] ) {
        PFQuery *segmentQuery = [PFQuery queryWithClassName:@"ListenedSegments"];
        [segmentQuery whereKey:@"device_id" equalTo:[self.settings deviceID]];
        [segmentQuery whereKey:@"segment_id" equalTo:[article objectForKey:@"id"]];
        PFObject *result = [segmentQuery getFirstObject];
        if ( !result ) {
          result = [PFObject objectWithClassName:@"ListenedSegments"];
        } else {
          continue;
        }
        
        [result setObject:[article objectForKey:@"id"] forKey:@"segment_id"];
        [result setObject:[self.settings deviceID] forKey:@"device_id"];
        if ( s.program ) {
          [result setObject:s.program forKey:@"program_name"];
        } else {
          [result setObject:@"" forKey:@"program_name"];
        }
        [result setObject:s.originalArticle forKey:@"json"];
        [result setObject:[NSDate date] forKey:@"completed_at"];
        [result saveEventually:^(BOOL succeeded, NSError *error) {
          if ( !succeeded ) {
            NSLog(@"Problem pushing to Parse : %@",[error localizedDescription]);
            
            [[AnalyticsManager shared] logEvent:@"parsePersistenceFailure"
                                 withParameters:@{ @"action" : @"saving_completed_segment" }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"segment_tracked"
                                                                object:nil];
            
          } else {
            
            NSLog(@"Successfully wrote completed segment to Parse : %@",[NSDate stringFromDate:[NSDate date]
                                                                                    withFormat:@"YYYY-MM-dd hh:mm:ss"]);
    
            [[NSNotificationCenter defaultCenter] postNotificationName:@"segment_tracked"
                                                                object:nil];

          }
        }];
      }
    }
    
    if ( ![Utilities pureNil:[[SocialManager shared] userName]] ) {
      [parseBlock setObject:[[SocialManager shared] userName]
                     forKey:@"userName"];
    }
    
    NSNumber *listeningTime = [NSNumber numberWithDouble:[self.settings totalListeningTime]];
    [parseBlock setObject:listeningTime forKey:@"totalListeningTime"];
    
    [parseBlock setObject:[[SocialManager shared] signInInformation]
                   forKey:@"loggedInWith"];
    
    if ( [[SocialManager shared] isAuthenticatedWithFacebook] && ![Utilities pureNil:self.settings.userFacebookInformation] ) {
      [parseBlock setObject:[self.settings userFacebookInformation]
                     forKey:@"userFacebookInformation"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"userFacebookInformation"];
    }
    
    if ( [[SocialManager shared] isAuthenticatedWithTwitter] && ![Utilities pureNil:self.settings.twitterInformation] ) {
      [parseBlock setObject:[self.settings twitterInformation]
                     forKey:@"userTwitterInformation"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"userTwitterInformation"];
    }
    
    if ( [[SocialManager shared] isAuthenticatedWithLinkedIn] && ![Utilities pureNil:self.settings.linkedInInformation] ) {
      
      [parseBlock setObject:[self.settings linkedInInformation]
                     forKey:@"userLinkedInInformation"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"userLinkedInInformation"];
    }
    
    if ( [[SocialManager shared] isAuthenticatedWithMembership] && ![Utilities pureNil:self.settings.memberInformation] ) {
      [parseBlock setObject:[self.settings memberInformation]
                     forKey:@"membershipInformation"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"membershipInformation"];
    }
    
    [parseBlock setObject:[NSNumber numberWithBool:[self.settings singleSignOnWithLinkedIn]]
                   forKey:@"singleSignOnWithLinkedIn"];
    
    if ( ![Utilities pureNil:[self.settings lastKnownConnectionType]] ) {
      [parseBlock setObject:[self.settings lastKnownConnectionType]
                     forKey:@"lastKnownConnectionType"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"lastKnownConnectionType"];
    }
    
    if ( ![Utilities pureNil:[self.settings remindersString]] ) {
      [parseBlock setObject:[self.settings remindersString]
                     forKey:@"reminders"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"reminders"];
    }
    
    if ( ![Utilities pureNil:[self.settings linkedInToken]] ) {
      [parseBlock setObject:[self.settings linkedInToken]
                     forKey:@"linkedInToken"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"linkedInToken"];
    }
    
    if ( ![Utilities pureNil:[self.settings linkedInTokenExpire]] ) {
      [parseBlock setObject:[Utilities stringFromRFCDate:[self.settings linkedInTokenExpire]]
                     forKey:@"linkedInTokenExpire"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"linkedInTokenExpire"];
    }
    
    if ( ![Utilities pureNil:[self.settings profileImageURL]] ) {
      [parseBlock setObject:[self.settings profileImageURL]
                     forKey:@"profileImageURL"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"profileImageURL"];
    }
    
    if ( ![Utilities pureNil:[self.settings deviceID]] ) {
      [parseBlock setObject:[self.settings deviceID]
                     forKey:@"deviceID"];
    } else {
      [parseBlock setObject:@""
                     forKey:@"deviceID"];
    }
    
    NSString *userFaves = [self.settings favoriteProgramsAsJson];
    if ( ![Utilities pureNil:userFaves] ) {
      [parseBlock setObject:userFaves
                     forKey:@"favoritePrograms"];
    } else {
      [parseBlock setObject:@"[]" forKey:@"favoritePrograms"];
    }
    
    [parseBlock saveEventually:^(BOOL succeeded, NSError *error) {
      if ( !succeeded ) {
        NSLog(@"Problem pushing to Parse : %@",[error localizedDescription]);
        
        [[AnalyticsManager shared] logEvent:@"parsePersistenceFailure"
                             withParameters:@{ @"action" : @"saving_user_info" }];
      } else {
        
        NSLog(@"Successfully saved to Parse : %@",[NSDate stringFromDate:[NSDate date]
                                                              withFormat:@"YYYY-MM-dd hh:mm:ss"]);
      }
      
      PFInstallation *currentInstallation = [PFInstallation currentInstallation];
      [currentInstallation saveEventually];
    }];
    
    if ( ![self.settings parseInitiated] ) {
      NSString *objectId = [parseBlock objectId];
      NSLog(@"Parse ID : %@",objectId);
      
      [self.settings setParseId:objectId];
      [self.settings setParseInitiated:YES];
      [self setSkipParse:YES];
      [self performSelectorOnMainThread:@selector(writeSettings)
                             withObject:nil
                          waitUntilDone:NO];
    }
  }];
#endif
}

- (void)checkCurrentVersion:(id)delegate {

#ifdef USE_PARSE
  PFQuery *q = [PFQuery queryWithClassName:@"CurrentVersion"];
  [q getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [delegate currentVersionCallback:object];
    });
  }];
#endif
}


- (void)checkForPromotionalMaterial {
  PFQuery *q = [PFQuery queryWithClassName:@"AdditionalAppContent"];
  [q getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      if ( !object ) {
        [self.settings setPromotionalContent:@""];
        [self setSkipParse:YES];
        [self setPerformWriteOnMainThread:YES];
        [self writeSettings];
        [[[Utilities del] globalDrawer] respin];
        return;
      }
      
      NSMutableDictionary *dRepresentation = [[NSMutableDictionary alloc] init];
      NSDate *begins = [object objectForKey:@"begins_at"];
      NSDate *ends = [object objectForKey:@"ends_at"];
      NSDate *now = [NSDate date];
      
      if ( [now timeIntervalSince1970] > [begins timeIntervalSince1970] &&
          [now timeIntervalSince1970] < [ends timeIntervalSince1970] ) {
        
        NSArray *keys = [object allKeys];
        for ( NSString *key in keys ) {
          id obj = [object objectForKey:key];
          if ( [obj isKindOfClass:[NSDate class]] ) {
            NSDate *d = (NSDate*)obj;
            NSString *newValue = [Utilities stringFromRFCDate:d];
            [dRepresentation setObject:newValue
                                forKey:key];
          } else {
            [dRepresentation setObject:[object objectForKey:key]
                              forKey:key];
          }
        }
        
        NSString *json = [dRepresentation JSONRepresentation];
        [self.settings setPromotionalContent:json];
        [self setSkipParse:YES];
        [self setPerformWriteOnMainThread:YES];
        [self writeSettings];
      } else {
        [self.settings setPromotionalContent:@""];
        [self setSkipParse:YES];
        [self setPerformWriteOnMainThread:YES];
        [self writeSettings];
      }
      
      [[[Utilities del] globalDrawer] respin];
      
    });
  }];
}

- (NSArray*)drawerSchema {
  NSError *fileError = nil;
  NSString *json = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"faketopicschema"
                                                                                      ofType:@"json"]
                                             encoding:NSUTF8StringEncoding
                                                error:&fileError];
  if ( [Utilities pureNil:self.settings.favoriteProgramsAsJson] ) {
    json = [json stringByReplacingOccurrencesOfString:kFavoritesMacro
                                           withString:@""];
  } else {
    
    NSMutableArray *faves = (NSMutableArray*)[self.settings.favoriteProgramsAsJson JSONValue];
    [faves sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      NSDictionary *d1 = (NSDictionary*)obj1;
      NSDictionary *d2 = (NSDictionary*)obj2;
      
      NSString *s1 = [d1 objectForKey:@"title"];
      NSString *s2 = [d2 objectForKey:@"title"];
      
      return (NSComparisonResult)[s1 localizedCaseInsensitiveCompare:s2];
    }];
    
    NSString *base = @"";
    for ( unsigned i = 0; i < [faves count]; i++ ) {
      NSDictionary *fave = [faves objectAtIndex:i];
      if ( i > 0 ) {
        base = [base stringByAppendingString:@","];
      }
      base = [base stringByAppendingString:[NSString stringWithFormat:@"\"%@\"",[fave objectForKey:@"title"]]];
    }
    json = [json stringByReplacingOccurrencesOfString:kFavoritesMacro
                                           withString:base];
  }

  return (NSArray*)[json JSONValue];
}

- (NSDictionary*)fullProgramObjectForTitle:(NSString *)title {
  NSArray *programs = [Utilities loadJson:@"fakeprograms"];
  for ( NSDictionary *program in programs ) {
    if ( [title isEqualToString:[program objectForKey:@"title"]] ) {
      return program;
    }
  }
  
  return @{};
}

- (NSArray*)favoritedProgramsList {
  return (NSArray*)[[self.settings favoriteProgramsAsJson] JSONValue];
}

#pragma mark - Program cache
- (NSMutableArray*)filterPrograms:(NSArray*)programs {
  [[AnalyticsManager shared] tS];
  if ( !programs ) {
    
    NSArray *json = nil;
    id jc = (NSArray*)[Utilities loadJson:@"mpl"];
      
    if ( [jc isKindOfClass:[NSString class]] ) {
      json = [(NSString*)jc JSONValue];
    } else {
      json = (NSArray*)jc;
    }

    self.masterProgramList = [[NSMutableDictionary alloc] init];
    
    for ( NSDictionary *program in json ) {
      
      if ( [Utilities pureNil:[program objectForKey:@"air_status"]] || ![[program objectForKey:@"air_status"] isEqualToString:@"onair"] ) {
        continue;
      }
      [self.masterProgramList setObject:program
                                 forKey:[program objectForKey:@"slug"]];
    }
    
    NSMutableArray *sorted = [[self.masterProgramList allValues] mutableCopy];
    [sorted sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      NSDictionary *d1 = (NSDictionary*)obj1;
      NSDictionary *d2 = (NSDictionary*)obj2;
      
      NSString *s1 = [d1 objectForKey:@"title"];
      NSString *s2 = [d2 objectForKey:@"title"];
      
      return (NSComparisonResult)[s1 localizedCaseInsensitiveCompare:s2];
    }];
    
    self.sortedProgramsCache = sorted;
    
    [[ScheduleManager shared] createProgramMap];
    
    return sorted;
  }
  
  self.masterProgramList = [[NSMutableDictionary alloc] init];
  
  NSMutableArray *filtered = [[NSMutableArray alloc] init];
  NSLog(@"Program count before filter : %d",[programs count]);
  for ( NSDictionary *program in programs) {
    
    if ( [Utilities pureNil:[program objectForKey:@"air_status"]] || ![[program objectForKey:@"air_status"] isEqualToString:@"onair"] ) {
      continue;
    }
    [filtered addObject:program];
    [self.masterProgramList setObject:program
                               forKey:[program objectForKey:@"slug"]];
  }
  
  NSMutableArray *sorted = filtered;
  [sorted sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSDictionary *d1 = (NSDictionary*)obj1;
    NSDictionary *d2 = (NSDictionary*)obj2;
    
    NSString *s1 = [d1 objectForKey:@"title"];
    NSString *s2 = [d2 objectForKey:@"title"];
    
    return (NSComparisonResult)[s1 localizedCaseInsensitiveCompare:s2];
  }];
  
  self.sortedProgramsCache = sorted;

  [[FileManager shared] writeFileFromData:[[self.masterProgramList allValues] JSONRepresentation]
                               toFilename:@"mpl.json"];
  
  [[AnalyticsManager shared] tF:@"Program sorting : new"];
  NSLog(@"Program count after filter : %d",[filtered count]);

  self.sortedProgramsCache = filtered;
  return filtered;
}

- (NSMutableArray*)sortedProgramList {
  if ( self.sortedProgramsCache ) {
    return self.sortedProgramsCache;
  }
  
  NSMutableArray *values = [[self.masterProgramList allValues] mutableCopy];
  [values sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSDictionary *d1 = (NSDictionary*)obj1;
    NSDictionary *d2 = (NSDictionary*)obj2;
    
    NSString *s1 = [d1 objectForKey:@"title"];
    NSString *s2 = [d2 objectForKey:@"title"];
    
    return (NSComparisonResult)[s1 localizedCaseInsensitiveCompare:s2];
  }];
  
  return values;
}

- (NSDictionary*)programCacheForProgram:(NSDictionary *)programObject {
  NSString *key = [Utilities sha1:[programObject objectForKey:@"title"]];
  NSDictionary *data = [self.programCache objectForKey:key];
  if ( data ) {
    NSDate *cacheDate = [data objectForKey:@"updated_at"];
    if ( [[NSDate date] timeIntervalSince1970] - [cacheDate timeIntervalSince1970] > 60*kProgramExpireInMinutes ) {
      [self.programCache removeObjectForKey:key];
      return nil;
    }
    
    return [data objectForKey:@"meta"];
  }
  return nil;
}

- (void)addProgramToCache:(NSDictionary *)programObject data:(NSArray *)data {
  
  NSString *key = [Utilities sha1:[programObject objectForKey:@"title"]];
  NSDictionary *cache = @{ @"meta" : data, @"updated_at" : [NSDate date] };
  [self.programCache setObject:cache
                        forKey:key];
  
}

- (NSMutableArray*)minimizedProgramFavorites:(NSString *)json {
  NSArray *maximized = (NSArray*)[json JSONValue];
  NSMutableArray *stripped = [[NSMutableArray alloc] init];
  for ( NSDictionary *program in maximized ) {
    NSMutableDictionary *minimizedProgram = [[NSMutableDictionary alloc] init];
    [minimizedProgram setObject:[program objectForKey:@"title"] forKey:@"title"];
    [minimizedProgram setObject:[program objectForKey:@"slug"] forKey:@"slug"];
    [stripped addObject:minimizedProgram];
  }
  return stripped;
}

- (NSDictionary*)maximizedProgramForMinimized:(NSDictionary *)program {
  return [self.masterProgramList objectForKey:[program objectForKey:@"slug"]];
}

- (NSString*)imageNameForProgram:(NSDictionary *)program {
  NSString *titleized = [Utilities titleize:[program objectForKey:@"title"]];
  NSString *imageStr = [NSString stringWithFormat:@"%@_splash.jpg",titleized];
  
  @try {
    NSString *path = [[NSBundle mainBundle] pathForResource:imageStr ofType:@""];
    if ( !path ) {
      imageStr = @"generic_splash.jpg";
    }
  } @catch ( NSException *e ) {
    imageStr = @"generic_splash.jpg";
  }
  
  return imageStr;
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  [self filterPrograms:content];
}

#pragma mark - ArticleStubs
- (ArticleStub*)stubForArticle:(NSDictionary *)article {
  
  NSString *dent = [Utilities sha1:[article objectForKey:@"permalink"]];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ArticleStub"
                                            inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@",dent];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
  
  if ( [objects count] == 0 ) {
    return nil;
  }
  
  return [objects objectAtIndex:0];

}

- (ArticleStub*)stubForBreakingNews:(NSString *)payload {
  NSString *dent = [Utilities sha1:payload];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ArticleStub"
                                            inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@",dent];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
  if ( [objects count] == 0 ) {
    ArticleStub *stub = nil;
    stub = (ArticleStub*)[NSEntityDescription insertNewObjectForEntityForName:@"ArticleStub"
                                                       inManagedObjectContext:self.managedObjectContext];
    stub.created_at = [NSDate date];
    stub.body = payload;
    stub.links = @"BREAKING NEWS";
    stub.identifier = dent;
    
    [self saveContext];
    
    return stub;
  }
  return nil;
}

- (void)persistStubForArticle:(NSDictionary *)article treatedBody:(NSString *)body links:(NSDictionary *)links {
#ifdef USE_BACKGROUND_PERSISTENCE
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    [self threadedStubForArticle:self.persistentStoreCoordinator
                         article:article
                     treatedBody:body
                           links:links];
  });
#else
  NSString *dent = [Utilities sha1:[article objectForKey:@"permalink"]];
  ArticleStub *stub = [self stubForArticle:article];
  if ( stub ) {
    [stub setBody:body];
    [stub setLinks:[links JSONRepresentation]];
  } else {
    stub = (ArticleStub*)[NSEntityDescription insertNewObjectForEntityForName:@"ArticleStub"
                                                       inManagedObjectContext:self.managedObjectContext];
    stub.created_at = [NSDate date];
    stub.body = body;
    stub.links = [links JSONRepresentation];
    stub.identifier = dent;
    
  }
#endif
}

- (void)threadedStubForArticle:(NSPersistentStoreCoordinator *)mainThreadPSC article:(NSDictionary *)article treatedBody:(NSString *)body links:(NSDictionary *)links {
  NSString *dent = [Utilities sha1:[article objectForKey:@"permalink"]];
  ArticleStub *stub = [self stubForArticle:article];
  if ( stub ) {
    [stub setBody:body];
    [stub setLinks:[links JSONRepresentation]];
  } else {
    stub = (ArticleStub*)[NSEntityDescription insertNewObjectForEntityForName:@"ArticleStub"
                                                       inManagedObjectContext:self.managedObjectContext];
    stub.created_at = [NSDate date];
    stub.body = body;
    stub.links = [links JSONRepresentation];
    stub.identifier = dent;
  }
  
  NSError *error = nil;
  NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
  [managedObjectContext setPersistentStoreCoordinator:mainThreadPSC];
  if (managedObjectContext != nil)
  {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
    {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
}

#pragma mark - Push
- (BOOL)isRegisteredForPushKey:(NSString *)key {
#ifdef USE_PARSE
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  NSArray *channels = [currentInstallation channels];
  for ( NSString *candidate in channels ) {
    if ( [candidate isEqualToString:key] ) {
      return YES;
    }
  }
#endif
  return NO;
  
}

- (void)editPushForBreakingNews:(BOOL)on {
#ifdef USE_PARSE
  
  NSString *pushKey = kPushKeyBreakingNews;
#ifdef SANDBOX_PUSHES
  pushKey = kPushKeySandbox;
#endif
  if ( on ) {
      NSLog(@"Registering for push on %@",pushKey);
      
      [[Utilities del] setOperatingWithPushType:PushTypeBreakingNews];
      [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|
       UIRemoteNotificationTypeBadge|
       UIRemoteNotificationTypeSound];
      
  } else {
    [self unregisterPushNotifications];
  }
#endif
}

- (void)unregisterPushNotifications {
  [[UIApplication sharedApplication] unregisterForRemoteNotifications];
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  
  NSString *pushKey = kPushKeyBreakingNews;
#ifdef SANDBOX_PUSHES
  pushKey = kPushKeySandbox;
#endif
  
  [currentInstallation removeObject:pushKey
                             forKey:@"channels"];
  
  [self.settings setPushToken:@""];
  [self writeSettings];
}

- (void)editPushForEvents:(BOOL)on {
#ifdef USE_PARSE
  if ( on ) {
    if ( [Utilities pureNil:[self.settings pushToken]] ) {
      
      [[Utilities del] setOperatingWithPushType:PushTypeEvents];
      [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|
       UIRemoteNotificationTypeBadge|
       UIRemoteNotificationTypeSound];
      
    } else {
      PFInstallation *currentInstallation = [PFInstallation currentInstallation];
      [currentInstallation addUniqueObject:kPushKeyEvents
                                    forKey:@"channels"];
      [currentInstallation saveInBackground];
    }
  } else {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation removeObject:kPushKeyEvents
                               forKey:@"channels"];
    [currentInstallation saveInBackground];
  }
#endif
}

#pragma mark - Helpers
- (void)displayPushMessageWithPayload:(NSDictionary *)userInfo {
  NSDictionary *ui = [userInfo objectForKey:@"aps"];
  NSString *alert = [ui objectForKey:@"alert"];
  
#ifdef DEBUG
  for ( NSString *key in [ui allKeys] ) {
    NSLog(@"APNS KEY : %@",key);
  }
  for ( NSString *ext in [userInfo allKeys] ) {
    NSLog(@"APNS EXT KEY : %@", ext);
  }
#endif
  
  [[ContentManager shared].settings setLastAlertPayload:alert];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  NSString *happeningCap = [[@"HAPPENING NOW" lowercaseString] capitalizedString];
  NSString *allcaps = [happeningCap uppercaseString];
  NSString *allLow = [happeningCap lowercaseString];
  
  if ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive ) {
    if ( [alert rangeOfString:happeningCap].location == NSNotFound &&
        [alert rangeOfString:allcaps].location == NSNotFound &&
        [alert rangeOfString:allLow].location == NSNotFound ) {
      
      [root showBreakingNewsWithMessage:alert action:^{
        [root hideBreakingNews];
        NSLog(@" ***** RECEIVED NOTIFICATION : ID %@",[userInfo objectForKey:@"alertId"]);
        [self convertBreakingNewsToArticle:[userInfo objectForKey:@"alertId"]];
      }];
      
    } else {
      [root showBreakingNewsWithMessage:alert action:^{
        [root hideBreakingNews];
        [[[Utilities del] viewController] primeUI:ScreenContentTypeEventsPage
                                         newsPath:@""];
      }];
    }
  } else {
    if ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground ) {
      NSLog(@" ******** BACKGROUND ALERT RECEIVED *********");
    } else if ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive ) {
      NSLog(@" ******** INACTIVE ALERT RECEIVED ********* ");
    }
  }
  
}


- (void)convertBreakingNewsToArticle:(NSString *)alertID {
  NSString *allstr = [NSString stringWithFormat:@"%@/alerts/%@",kServerBase,alertID];
  NSURL *allUrl = [NSURL URLWithString:allstr];
  NSURLRequest *allReq = [NSURLRequest requestWithURL:allUrl];
  [NSURLConnection sendAsynchronousRequest:allReq
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *allR, NSData *allD, NSError *allE) {
                           
                           if ( allE ) {
                             [[AnalyticsManager shared] failureFetchingContent:allstr];
                             return;
                           }
                           
                           NSString *allResponse = [[NSString alloc]
                                                    initWithData:allD
                                                    encoding:NSUTF8StringEncoding];
                           
                           if ( allResponse ) {
                             
                             NSDictionary *alert = [allResponse JSONValue];
                             if ( alert ) {
                               NSString *url = [alert objectForKey:@"public_url"];
                               if ( url ) {
#ifdef FAKE_PUSH_NOTIFICATION
                                 url = @"http://www.yahoo.com/";
#endif
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
                                   [root displayAtomicArticleWithURL:url];
                                 });
                                 
                               }
                             }
                             
                             
                           }
                           
                         }];
}

- (BOOL)isKPCCArticle:(NSDictionary*)sourceArticle {
  
  NSString *url = [sourceArticle objectForKey:@"url"];
  if ( !url ) {
    url = [sourceArticle objectForKey:@"permalink"];
  }
  if ( !url ) {
    url = [sourceArticle objectForKey:@"public_url"];
  }
  
  return [self isKPCCURL:url];
}

- (BOOL)isKPCCURL:(NSString *)url {
  if (!url) {
    return NO;
  }
  
  if ([url rangeOfString:@"scpr.org"].location != NSNotFound) {
    if ([url rangeOfString:@"projects.scpr.org"].location != NSNotFound) {
      return NO;
    }
    
    if ([url rangeOfString:@"www.scpr.org"].location == NSNotFound) {
      return NO;
    }

    NSRange r = [url rangeOfString:@"scpr.org"];
    NSString *guts = [url substringFromIndex:r.location];
    NSArray *comps = [guts componentsSeparatedByString:@"/"];
    if ([comps count] <= 3) {
      // Flatpage
      return NO;
    }

    // Types to not serve native
    if ([guts rangeOfString:@"/events/"].location != NSNotFound || [guts rangeOfString:@"/elections/"].location != NSNotFound ) {
      return NO;
    }

    return YES;
  }
  
  if ([url rangeOfString:@"kpcc.org"].location != NSNotFound) {
    if ([url rangeOfString:@"www.kpcc.org"].location == NSNotFound) {
      return NO;
    }

    return YES;
  }

  return NO;
}


- (BOOL)maxPagesReached {
  return self.currentNewsPage >= kMaxNewsContent;
}

- (void)queueDeactivation:(id<Deactivatable>)articleKey {
  [self.deactivationQueue setObject:articleKey
                             forKey:[articleKey deactivationToken]];
}

- (void)popDeactivation:(NSString *)token {
  //NSLog(@"%@ is OK for deletion",token);
  [self.deactivationQueue removeObjectForKey:token];
}


- (void)patch:(NSString*)version {

  if ( [self userIsMissingPatch:@"1.0.1"] ) {
    [self writePatch:@"1.0.1"];
    [[ScheduleManager shared] createProgramMap];
  }
}

- (void)writePatch:(NSString *)patch {
  NSString *rom = [[ContentManager shared].settings rom];
  if ( rom ) {
    rom = [rom stringByAppendingString:[NSString stringWithFormat:@"[%@]",patch]];
  } else {
    rom = [NSString stringWithFormat:@"[%@]",patch];
  }
  [[ContentManager shared].settings setRom:rom];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
}

- (BOOL)userIsMissingPatch:(NSString *)patch {
  NSString *rom = [[ContentManager shared].settings rom];
  if ( !rom ) {
    return YES;
  }
  
  NSString *formatted = [NSString stringWithFormat:@"[%@]",patch];
  return [rom rangeOfString:formatted].location == NSNotFound;
}

- (void)pushToResizeVector:(id<Rotatable>)rotatable {
      NSLog(@"**** PUSHING %@ TO RESIZE VECTOR",[[rotatable class] description]);
  [self.resizeVector addObject:rotatable];
  
  NSLog(@"Number of items in resize vector : %d",[self.resizeVector count]);

}

- (void)popFromResizeVector {
  if ( [self.resizeVector count] > 0 ) {
    id obj = [self.resizeVector lastObject];
    NSLog(@"**** POPPING %@ FROM RESIZE VECTOR",[[obj class] description]);
    if ( [self.resizeVector count] == 1 ) {
      [self.resizeVector removeAllObjects];
    } else {
      [self.resizeVector removeLastObject];
    }
  }
  NSLog(@"Number of items in resize vector : %d",[self.resizeVector count]);
}

- (NSString*)nameForModelType:(ModelType)type {
  NSString *typeString = nil;
  switch (type) {
    case ModelTypeSegment:
      typeString = @"Segment";
      break;
    case ModelTypeCollection:
      typeString = @"Collection";
      break;
    case ModelTypeKeyword:
      typeString = @"Keyword";
      break;
    default:
      break;
  }
  return typeString;
}

- (NSString*)nameForScreenContentType:(NSInteger)contentType {
  ScreenContentType type = (ScreenContentType)contentType;
  NSString *properName = @"";
  switch (type) {
    case ScreenContentTypeSnapshotPage:
      properName = @"editions";
      break;
    case ScreenContentTypeProgramPage:
    case ScreenContentTypeProgramAZPage:
      properName = @"programs";
      break;
    case ScreenContentTypeEventsPage:
      properName = @"cfflive";
      break;
    case ScreenContentTypeVideoPhotoPage:
      properName = @"videophoto";
      break;
    case ScreenContentTypeCompositePage:
      properName = @"mysteryview";
      break;
    case ScreenContentTypeProfilePage:
      properName = @"userprofile";
      break;
    case ScreenContentTypeFeedback:
      properName = @"feedback";
      break;
    case ScreenContentTypeOnboarding:
      properName = @"onboarding";
      break;
    case ScreenContentTypeDynamicPage:
    case ScreenContentTypeNewsPage:
    case ScreenContentTypeUnknown:
      default:
      properName = @"unknown";
      break;
  }
  
  return properName;
}

- (NSString*)prettyNameForScreenContentType:(NSInteger)contentType {
  ScreenContentType type = (ScreenContentType)contentType;
  NSString *properName = @"";
  switch (type) {
    case ScreenContentTypeSnapshotPage:
      properName = @"The Short List";
      break;
    case ScreenContentTypeProgramPage:
    case ScreenContentTypeProgramAZPage:
      properName = @"Programs";
      break;
    case ScreenContentTypeEventsPage:
      properName = @"Live Events";
      break;
    case ScreenContentTypeVideoPhotoPage:
      properName = @"Photo & Video";
      break;
    case ScreenContentTypeCompositePage:
      properName = @"News";
      break;
    case ScreenContentTypeProfilePage:
      properName = @"User Profile";
      break;
    case ScreenContentTypeFeedback:
      properName = @"Feedback";
      break;
    case ScreenContentTypeOnboarding:
      properName = @"Onboarding";
      break;
    case ScreenContentTypeDynamicPage:
    case ScreenContentTypeNewsPage:
    case ScreenContentTypeUnknown:
    default:
      properName = @"unknown";
      break;
  }
  
  return properName;
}

- (NSDictionary*)bakeInIDForArticle:(NSDictionary *)article {
  if ( ![article objectForKey:@"id"] ) {
    NSArray *audio = [article objectForKey:@"audio"];
    if ( [audio count] > 0 ) {
      NSDictionary *seg = [audio objectAtIndex:0];
      NSMutableDictionary *writable = [article mutableCopy];
      [writable setObject:[seg objectForKey:@"article_obj_key"]
                   forKey:@"id"];
      article = [NSDictionary dictionaryWithDictionary:writable];
    }
  }
  
  return article;
}

- (NSDictionary*)bakeInShortTitleForArticle:(NSDictionary *)article {
  if ( ![article objectForKey:@"short_title"] ) {

    NSMutableDictionary *writable = [article mutableCopy];
    [writable setObject:[article objectForKey:@"title"]
                   forKey:@"short_title"];
    article = [NSDictionary dictionaryWithDictionary:writable];
    
  }
  
  return article;
}

- (NSDictionary*)bakeInBylineForArticle:(NSDictionary *)article {
  if ( ![article objectForKey:@"byline"] ) {
    NSDictionary *seg = [article objectForKey:@"program"];
    if ( seg ) {
      NSMutableDictionary *writable = [article mutableCopy];
      [writable setObject:[seg objectForKey:@"title"]
                   forKey:@"byline"];
      article = [NSDictionary dictionaryWithDictionary:writable];
    } else {
      NSMutableDictionary *writable = [article mutableCopy];
      [writable setObject:@""
                   forKey:@"byline"];
      article = [NSDictionary dictionaryWithDictionary:writable];
    }
  }
  
  return article;
}

- (NSDictionary*)bakeInThumbnailForArticle:(NSDictionary *)article thumb:(NSString*)thumbUrl {
  if ( [article objectForKey:@"assets"] && [[article objectForKey:@"assets"] count] > 0 ) {
    return article;
  }
  
  if ( !thumbUrl ) {
    if ( [article objectForKey:@"program"] ) {
      NSDictionary *program = [article objectForKey:@"program"];
      NSString *title = [program objectForKey:@"title"];
      NSString *flat = [Utilities titleize:title];
      thumbUrl = [NSString stringWithFormat:@"small_%@_splash.jpg",flat];
    }
  }
  
  NSMutableDictionary *modified = [article mutableCopy];
  NSMutableDictionary *assets = [[NSMutableDictionary alloc] init];
  [assets setObject:@{ @"url" : thumbUrl } forKey:@"thumbnail"];
  
  if ( [thumbUrl rangeOfString:@"http"].location == NSNotFound ) {
    [modified setObject:@1 forKey:@"local_image"];
  }
  [modified setObject:@[assets] forKey:@"assets"];
  
  return [NSDictionary dictionaryWithDictionary:modified];
}

- (NSDictionary*)bakeInProgramToSegment:(NSDictionary *)segment program:(NSDictionary *)program oid:(NSString *)oid {
  if ( [segment objectForKey:@"program"] ) {
    return segment;
  }
  if ( !program ) {
    return segment;
  }
  
  NSMutableDictionary *mSegment = [segment mutableCopy];
  [mSegment setObject:program forKey:@"program"];
  
  [mSegment setObject:[program objectForKey:@"title"]
               forKey:@"byline"];
  
  if ( oid ) {
    [mSegment setObject:oid forKey:@"parent_id"];
  }
  
  return [NSDictionary dictionaryWithDictionary:mSegment];
}

- (BOOL)storyHasVideoAsset:(NSDictionary *)story {
  NSArray *assets = [story objectForKey:@"assets"];
  if ( assets && [assets count] > 0 ) {
    NSDictionary *lead = [assets objectAtIndex:0];
    if ( lead ) {
      if ( [lead objectForKey:@"native"] ) {
        NSDictionary *n = [lead objectForKey:@"native"];
        NSString *type = [n objectForKey:@"type"];
        if ( ![type isEqualToString:@"BrightcoveVideo"] ) {
          return YES;
        }
      }
    }
  }
  
  return NO;
}

- (BOOL)storyHasYouTubeAsset:(NSDictionary*)story {
  NSArray *assets = [story objectForKey:@"assets"];
  if ( assets && [assets count] > 0 ) {
    NSDictionary *lead = [assets objectAtIndex:0];
    if ( lead ) {
      if ( [lead objectForKey:@"native"] ) {
        NSDictionary *native = [lead objectForKey:@"native"];
        return [[native objectForKey:@"type"] isEqualToString:@"YoutubeVideo"];
      }
    }
  }
  
  return NO;
}

#pragma mark - Ad Counting
- (void)resetAdTracking {
  self.swipeCount = 0;
  self.adCount = 0;
}

- (void)tickSwipe:(UISwipeGestureRecognizerDirection)direction
           inView:(UIView*)hopefullyAScroller
      penultimate:(BOOL)penultimate
    silenceVector:(NSMutableArray *)silenceVector {
  
  if ([[AnalyticsManager shared].numberOfSwipesPerAd intValue] <= 0) {
    return;
  }
  if ([[AnalyticsManager shared].numberOfAdsPerSession intValue] <= 0) {
    return;
  }
  
  self.swipeCount++;
  
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  
  // If we haven't reached/exceeded our number of swipes between ads:
  // prepare one offscreen.
  if (self.swipeCount == [[AnalyticsManager shared].numberOfSwipesPerAd intValue] - 1) {
    if (self.adCount < [[AnalyticsManager shared].numberOfAdsPerSession intValue]) {
      
      if (penultimate) {
        self.swipeCount--;
        return;
      }
      
      
      [self setObserveForSwipe:direction];
      [[ContentManager shared] setAdReadyOffscreen:YES];
      [[[Utilities del] masterRootController] deliverAd:direction
                                               intoView:hopefullyAScroller
                                                silence:silenceVector];
    }
  }
  
  // If we've met our swipe count, display the prepared offscreen ad.
  if (self.swipeCount >= [[AnalyticsManager shared].numberOfSwipesPerAd intValue]) {
    if ([self adReadyOffscreen]) {
      if (direction != [self observeForSwipe]) {
        
        self.observeForSwipe = direction;
        [[[Utilities del] masterRootController] undeliverAd];
        
        [[AnalyticsManager shared] logEvent:@"ad_was_loaded_but_avoided"
                             withParameters:@{}];
     
        [self setObserveForSwipe:direction];
        [[ContentManager shared] setAdReadyOffscreen:YES];
        
        [[[Utilities del] masterRootController] deliverAd:direction
                                                 intoView:hopefullyAScroller
                                                  silence:silenceVector];
      } else {
        
        self.adReadyOffscreen = NO;
        self.swipeCount = 0;
        self.adIsDisplayingOnScreen = YES;
        
        //[(UIScrollView*)hopefullyAScroller setScrollEnabled:NO];
        [root.adPresentationView bringSubviewToFront:root.dfpAdViewController.view];
        [root armDismissal];
        
        // A view may need to tell the ad to hide a few on-screen views when it displays
        if (silenceVector) {
          [UIView animateWithDuration:0.33 animations:^{
            for ( UIView *v in silenceVector ) {
              v.alpha = 0.0;
            }
          }];
        }
        
        if (self.adFailure) {
          [[AnalyticsManager shared] logEvent:@"ad_delivery_failed"
                               withParameters:@{}];
          
          [[[Utilities del] masterRootController] adDidFail];
          
          if (self.adFailureTimer) {
            if ([self.adFailureTimer isValid]) {
              [self.adFailureTimer invalidate];
            }
          }

          self.adFailureTimer = [NSTimer scheduledTimerWithTimeInterval:1.45
                                                                 target:self
                                                               selector:@selector(killAdOnscreen:)
                                                               userInfo:nil
                                                              repeats:NO];
        } else {

          [[AnalyticsManager shared] logEvent:@"ad_delivery_succeeded"
                               withParameters:@{}];
          
        }
        
        [self setAdCount:[self adCount]+1];
        [self setAdFailure:NO];
        
      } // if (direction != [self observeForSwipe])
    } // if ad ready offscreen
  } // if reaching swipe count
}

- (void)killAdOnscreen:(NSTimer*)timer {
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  [root killAdOnscreen:nil];
}

#pragma mark - Model operations
- (id)findModelByName:(NSString *)name andType:(ModelType)type {
  NSString *modelName = [self nameForModelType:type];
  if ( !modelName ) {
    return nil;
  }
  NSString *secret = [Utilities generateSlug:name];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:modelName
                                            inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"slug = %@",secret];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
  
  if ( [objects count] == 0 ) {
    return nil;
  }
  
  return [objects objectAtIndex:0];
}

#pragma mark - Queue
- (Collection*)createQueue {
  Collection *queue = (Collection*)[self findModelByName:@"Queue"
                                                 andType:ModelTypeCollection];
  if ( !queue ) {
    queue = (Collection*)[NSEntityDescription insertNewObjectForEntityForName:@"Collection"
                                                       inManagedObjectContext:self.managedObjectContext];
    queue.name = @"Queue";
    queue.slug = [Utilities generateSlug:queue.name];
    queue.collectionType = [NSNumber numberWithInt:CollectionTypeUserPlaylist];
  }
  
  [self saveContext];
  
  return queue;
}

#pragma mark - Schedulers
- (Scheduler*)findSchedulerForProgram:(NSString *)slug {
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Scheduler"
                                            inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"slug = %@",slug];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
  
  if ( [objects count] == 0 ) {
    return nil;
  }
  
  return [objects objectAtIndex:0];
  
}

- (Scheduler*)createSchedulerForProgram:(NSString *)slug {
  
  Scheduler *s = [self findSchedulerForProgram:slug];
  if ( !s ) {
    s = (Scheduler*)[NSEntityDescription insertNewObjectForEntityForName:@"Scheduler"
                                                  inManagedObjectContext:self.managedObjectContext];
    s.slug = slug;
  } else {
    s.slug = slug;
    s.lastsync = nil;
  }
  
  [self saveContext];
  
  return s;
  
}

- (void)destroySchedulerForProgram:(NSString *)slug {
  Scheduler *s = [self findSchedulerForProgram:slug];
  if ( s ) {
    [self.managedObjectContext deleteObject:s];
    [self saveContext];
  }
}

#pragma mark - Segments
- (NSArray*)orderedSegmentsForCollection:(Collection *)collection {
  
  NSSet *set = [collection segments];
  NSMutableArray *unsorted = [NSMutableArray arrayWithArray:[set allObjects]];
  NSArray *sorted = [unsorted sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    
    Segment *one = (Segment*)obj1;
    Segment *two = (Segment*)obj2;
    
    NSNumber *d1 = one.queuePosition;
    NSNumber *d2 = two.queuePosition;
    
    if ( [d1 intValue] == [d2 intValue] ) {
      NSDate *added1 = one.addedToQueueDate;
      NSDate *added2 = two.addedToQueueDate;
      if ( [added1 earlierDate:added2] == added1 ) {
        return (NSComparisonResult)NSOrderedDescending;
      } else {
        return (NSComparisonResult)NSOrderedAscending;
      }
    }
    if ( [d1 intValue] < [d2 intValue] ) {
      return (NSComparisonResult)NSOrderedAscending;
    } else {
      return (NSComparisonResult)NSOrderedDescending;
    }
    
  }];
  
  for ( unsigned j = 0; j < [sorted count]; j++ ) {
    Segment *seg = [sorted objectAtIndex:j];
    seg.queuePosition = [NSNumber numberWithInt:j];
  }
  
  [[ContentManager shared] saveContextOnMainThread];
  
  return sorted;
}

- (NSArray*)findAllSegments {
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Segment"
                                            inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
  
  NSError *error = nil;
  NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
  
  if ( [Utilities pureNil:objects] ) {
    return @[];
  }
  
  return objects;
}

- (Segment*)findSegmentBySlug:(NSString*)slug {
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Segment"
                                            inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"slug = %@",slug];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
  
  if ( [objects count] == 0 ) {
    return nil;
  }
  
  return [objects objectAtIndex:0];

}

- (Segment*)segmentFromArticle:(NSDictionary *)article {
  
  NSString *keyToUse = [article objectForKey:@"permalink"] ? @"permalink" : @"public_url";
  
  NSString *key = [Utilities sha1:[article objectForKey:keyToUse]];
  if ( [key isEqualToString:@"nothing"] ) {
    NSLog(@"Bad Article!!!");
    abort();
    return nil;
  }
  
  Segment *candidate = [self findSegmentBySlug:key];
  
  article = [self bakeInIDForArticle:article];
  if ( !candidate ) {
    candidate = (Segment*)[NSEntityDescription insertNewObjectForEntityForName:@"Segment"
                                                       inManagedObjectContext:self.managedObjectContext];
    candidate.seekposition = [NSNumber numberWithDouble:0.0];
  }
  candidate.queuePosition = [NSNumber numberWithInt:-1];
  candidate.slug = key;
  
  if ( [article objectForKey:@"short_title"] ) {
    candidate.name = [article objectForKey:@"short_title"];
  } else if ( [article objectForKey:@"title"] ) {
    candidate.name = [article objectForKey:@"title"];
  }

  NSArray *audio = [article objectForKey:@"audio"];
  if ( [audio count] > 0 ) {
    candidate.url = [[audio objectAtIndex:0] objectForKey:@"url"];
    NSString *duration = [[audio objectAtIndex:0] objectForKey:@"duration"];
    if ( ![Utilities pureNil:duration] ) {
      candidate.duration = [NSNumber numberWithDouble:[duration intValue]];
    } else {
      candidate.duration = @0;
    }
    NSString *airString = [[audio objectAtIndex:0] objectForKey:@"uploaded_at"];
    if ( [Utilities pureNil:airString] ) {
      airString = [article objectForKey:@"air_date"];
    }
    NSDate *airdate = [Utilities dateFromRFCString:airString];
    candidate.airdate = airdate;
  } else {
    
    if ( [article objectForKey:@"air_date"] ) {
      NSDate *airdate = [Utilities dateFromRFCString:[article objectForKey:@"air_date"]];
      candidate.airdate = airdate;
    }
  }
  
  NSDictionary *program = [article objectForKey:@"program"];
  if ( program ) {
    candidate.program = [program objectForKey:@"title"];
  }
  
  candidate.originalArticle = [article JSONRepresentation];
  [self saveContext];
  
  return candidate;
}

- (NSSet*)findSegmentsWithKeyword:(id)keyword {
  if ( [keyword isKindOfClass:[Keyword class]] ) {
    Keyword *asKeyword = (Keyword*)keyword;
    return asKeyword.segments;
  }
  if ( [keyword isKindOfClass:[NSString class]] ) {
    NSString *asString = (NSString*)keyword;
    asString = [asString lowercaseString];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Keyword" inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE[c] %@",asString];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:predicate];
    

    NSError *error = nil;
    Keyword *chuck = (Keyword*) [[self.managedObjectContext executeFetchRequest:request error:&error] objectAtIndex:0];
    if ( chuck ) {
      return chuck.segments;
    }
  }
  return [[NSSet alloc] init];
}

- (void)removeSegment:(id)segment fromCollection:(id)collection {
  [self removeSegment:segment fromCollection:collection suspendCommit:NO];
}

- (void)removeSegment:(id)segment fromCollection:(id)collection suspendCommit:(BOOL)suspendCommit {

  NSManagedObjectContext *cxToUse = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundThreadObjectContext;
    NSString *thread = [NSThread isMainThread] ? @"main_thread" : @"bg_thread";
    NSLog(@"Using %@ for removal...",thread);
    
  Collection *asCollection = (Collection*)collection;
  [asCollection removeSegmentsObject:(Segment*)segment];

  Segment *asSegment = (Segment*)segment;
  asSegment.addedToQueueDate = nil;
  asSegment.queuePosition = @-1;
  
  if ( !suspendCommit ) {
    NSError *error = nil;
    if ( ![cxToUse save:&error] ) {
      NSLog(@"Problem removing segment : %@",[error localizedDescription]);
      abort();
    }
  }

}

- (void)addSegment:(id)segment toCollection:(id)collection {

  NSManagedObjectContext *cxToUse = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundThreadObjectContext;
  NSString *thread = [NSThread isMainThread] ? @"main_thread" : @"bg_thread";
  NSLog(@"Using %@ for removal...",thread);
    
  Collection *asCollection = (Collection*)collection;
  Segment *asSegment = (Segment*)segment;
  asSegment.addedToQueueDate = [NSDate date];
  
  if ( [self articleExists:asSegment inCollection:asCollection] ) {
    return;
  }

  [asCollection addSegmentsObject:(Segment*)segment];
  
  NSError *error = nil;
  

  if ( ![cxToUse save:&error] ) {
    NSLog(@"Problem adding segment : %@",[error localizedDescription]);
    abort();
  }
  
}

- (void)pushSegment:(id)segment toCollection:(id)collection {
  Collection *asCollection = (Collection*)collection;
  Segment *asSegment = (Segment*)segment;
  
  if ( [self articleExists:asSegment inCollection:asCollection] ) {
    return;
  }
  
  [asCollection addSegmentsObject:asSegment];
  
  NSError *error = nil;
  if ( ![self.managedObjectContext save:&error] ) {
    NSLog(@"Problem removing segment : %@",[error localizedDescription]);
    abort();
  }
}

- (void)destroySegment:(Segment *)segment {
  [self.managedObjectContext deleteObject:segment];
  [self saveContext];
}

- (BOOL)articleExists:(id)segment inCollection:(id)collection {

  Collection *asCollection = (Collection*)collection;
  
  if ( [segment isKindOfClass:[Segment class]] ) {
    Segment *asSegment = (Segment*)segment;
    NSSet *set = [asCollection segments];
    for ( Segment *s in set ) {
      if ( [s.slug isEqualToString:asSegment.slug] ) {
     
        return YES;
      }
    }
  
  }
  if ( [segment isKindOfClass:[NSDictionary class]] ) {
    NSDictionary *d = (NSDictionary*)segment;
    NSSet *set = [asCollection segments];
    NSString *shortTitle = [d objectForKey:@"short_title"];
    if ( !shortTitle ) {
      shortTitle = [d objectForKey:@"title"];
    }
    for ( Segment *s in set ) {
      NSString *segName = s.name;
      if ( [shortTitle isEqualToString:segName] ) {

        NSDictionary *oa = [s.originalArticle JSONValue];

        if ( [d objectForKey:@"segments"] ) {
          return YES;
        }
        if ( [[(NSDictionary*)segment objectForKey:@"id"] isEqualToString:[oa objectForKey:@"id"]] ) {
          return YES;
        }
      }
    }
  }
  return NO;
}

- (void)loadAudioMetaDataForAudio:(id)audio {
  if ( [audio isKindOfClass:[NSString class]] ) {
    // Program name
    NSString *titlized = [Utilities titleize:audio];
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@_splash.jpg",titlized]];
    if ( !img ) {
      img = [UIImage imageNamed:@"kpcc-twitter-logo.png"];
    }
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:img];
    
    
    self.audioMetaData = @{ MPMediaItemPropertyArtist : @"89.3 KPCC",
                            MPMediaItemPropertyTitle : (NSString*)audio,
                            MPMediaItemPropertyArtwork : artwork };
                            
  } else {
    // Story
    NSDictionary *article = (NSDictionary*)audio;
    NSString *titleKey = [article objectForKey:@"title"] ? @"title" : @"short_title";
    
    if ( [article objectForKey:@"program"] ) {
      NSDictionary *program = [article objectForKey:@"program"];
      NSString *title = [program objectForKey:@"title"];
      NSString *titlized = [Utilities titleize:title];
      UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@_splash.jpg",titlized]];
      if ( !img ) {
        img = [UIImage imageNamed:@"kpcc-twitter-logo.png"];
      }
      MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:img];
      
      self.audioMetaData = @{ MPMediaItemPropertyArtist : @"89.3 KPCC",
                              MPMediaItemPropertyTitle : title,
                              MPMediaItemPropertyArtwork : artwork };
      
      return;
    }
    self.audioMetaData = @{ MPMediaItemPropertyArtist : @"89.3 KPCC",
                            MPMediaItemPropertyTitle : [article objectForKey:titleKey] };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      
      NSString *urlString = [Utilities extractImageURLFromBlob:article
                                                       quality:AssetQualityLarge];
      NSURL *url = [NSURL URLWithString:urlString];
      NSData *d = [NSData dataWithContentsOfURL:url];
      UIImage *img = [UIImage imageWithData:d];
      
      if ( !img ) {
        img = [UIImage imageNamed:@"kpcc-twitter-logo.png"];
      }
      
      MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:img];
      self.audioMetaData = @{ MPMediaItemPropertyArtist : @"89.3 KPCC",
                              MPMediaItemPropertyTitle : [article objectForKey:titleKey],
                              MPMediaItemPropertyArtwork : artwork };
      
      [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.audioMetaData];
      
    });
  }
}

#pragma mark - Image caching


- (void)initDataStores {
  
  NSLog(@"Initializing data stores...");
  [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
  
  int cacheSizeMemory = 1*1024*1024; // 1MB
  int cacheSizeDisk = 96*1024*1024; // 96MB
  NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory
                                                          diskCapacity:cacheSizeDisk
                                                              diskPath:@"nsurlcache"];
  [NSURLCache setSharedURLCache:sharedCache];
  
  NSError *error = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *imageCachePath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"images"];
  BOOL dir;
  
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:imageCachePath isDirectory:&dir];
  if ( !dirExists ) {
    
    [[NSFileManager defaultManager] createDirectoryAtPath:imageCachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if ( error ) {
      NSLog(@"CREATING IMAGE DIRECTORY - %@",[error localizedDescription]);
      return;
    }
  }
  
  NSMutableArray *images = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageCachePath
                                                                                                              error:&error]];
  
  NSLog(@"Number of images : %d",[images count]);
  
  if ( error ) {
    NSLog(@"ENUMERATING IMAGE DIRECTORY - %@",[error localizedDescription]);
    return;
  }
  
  self.imageCache = [[NSMutableDictionary alloc] init];
  [self printCacheUsage];

  self.programCache = [[NSMutableDictionary alloc] init];
  [self systemClean];
}

- (void)synthesizeStory {
  
  if ( [self.operatingOnStories count] > 0 ) {
    NSDictionary *d = [self.operatingOnStories objectAtIndex:0];
    NSLog(@"Fetching image data for %@",[d objectForKey:@"short_title"]);
    @synchronized(self) {
      [self.operatingOnStories removeObjectAtIndex:0];
    }
    UIImageView *img = [[UIImageView alloc] init];
    [img loadImage:[Utilities extractImageURLFromBlob:d
                                              quality:AssetQualityFull] quietly:YES];
  }
  
  if ( [self.mutableTrendingStories count] == 0 && [self.mutableGeneralStories count] == 0 ) {
    if ( self.synthesisTimer ) {
      if ( [self.synthesisTimer isValid] ) {
        [self.synthesisTimer invalidate];
      }
      self.synthesisTimer = nil;
    }
    self.operatingOnStories = nil;
    return;
  }
  
  if ( self.operatingOnStories == self.mutableTrendingStories ) {
    self.operatingOnStories = self.mutableGeneralStories;
  } else {
    self.operatingOnStories = self.mutableTrendingStories;
  }
  
}

- (void)writeImageDirectlyIntoCache:(id)image {
  if ( [image isKindOfClass:[NSString class]] ) {
    NSString *imgName = (NSString*)image;
    NSString *path = [[NSBundle mainBundle] pathForResource:imgName ofType:@""];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    [self.imageCache setObject:img
                        forKey:[Utilities sha1:imgName]];
  }
}

- (void)writeImage:(UIImage *)image forHash:(NSString *)hash {
#ifdef EXPERIMENTAL_CACHING
  [self.imageCache setObject:image forKey:hash];
  [self smartMemorySweep];
#endif
}

- (void)sweepDiskAndMemory {
  [[ContentManager shared].settings setLastCacheCleanDate:[NSDate date]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *imageCachePath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"images"];
  NSError *error = nil;
  NSMutableArray *images = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageCachePath
                                                                                                              error:&error]];
  NSInteger kb = 0;
  
  for ( unsigned i = 0; i < [images count]; i++ ) {
    NSString *file = [images objectAtIndex:i];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",imageCachePath,file];
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
      continue;
    }
    if ( ![[NSFileManager defaultManager] isReadableFileAtPath:filePath] ) {
      [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
      if ( error ) {
        continue;
      }
      continue;
    }
    
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:filePath];
    [fh closeFile];
    
    NSDictionary *att = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    kb += [att fileSize];
  }
  
  if ( floor(kb / 1024) > kImageCacheMaxSizeDisk ) {
    for ( unsigned i = 0; i < [images count]; i++ ) {
      if ( i % 2 == 0 ) {
        NSString *file = [images objectAtIndex:i];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",imageCachePath,file];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
      }
    }
  }
  
  [self sweepMemory];
}

- (CGFloat)imageCacheSizeInMB {
  NSInteger size = 0;
  NSMutableArray *badKeys = [[NSMutableArray alloc] init];
  for ( NSString *key in [self.imageCache allKeys] ) {
    @try {
      
      UIImage *img = [self.imageCache objectForKey:key];
      NSData *imgData = UIImagePNGRepresentation(img);
      size += [imgData length];
      
    } @catch (NSException *e) {
      
      NSLog(@"*** Image in cache was bad ***");
      [badKeys addObject:key];
      
    }
  }
  
  for ( NSString *key in badKeys ) {
    [self.imageCache removeObjectForKey:key];
  }
  return size / (1024.0*1024.0);
}

- (void)printCacheUsage {
  
#ifdef LOG_DEALLOCATIONS
  NSInteger memoryUsage = [[NSURLCache sharedURLCache] currentMemoryUsage];
  NSInteger disk = [[NSURLCache sharedURLCache] currentDiskUsage];
  CGFloat memInMB = (CGFloat)memoryUsage/(1024.0*1024.0);
  CGFloat diskInMB = (CGFloat)disk/(1024.0*1024.0);
  NSLog(@"CACHE : %1.2f MB (Memory), %1.2f MB (Disk)",memInMB,diskInMB);
#endif
}

- (void)smartMemorySweep {
  
  if ( [self.imageCache count] < kImageMemoryFileLimit ) {
    return;
  }
  
  if ( [self imageCacheSizeInMB] > kImageCacheMBLimit ) {
    [self sweepMemory];
  }
}

- (void)sweepMemory {
  NSLog(@"Sweeping memory");
  [self printCacheUsage];
  [self.imageCache removeAllObjects];
}

- (void)destroyDiskAndMemoryCache {
  NSLog(@"Destorying disk and memory cache.. bye bye");
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *imageCachePath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"images"];
    NSError *error = nil;
    NSMutableArray *images = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageCachePath
                                                                                                                error:&error]];
    
    for ( unsigned i = 0; i < [images count]; i++ ) {
      NSString *file = [images objectAtIndex:i];
      NSString *filePath = [NSString stringWithFormat:@"%@/%@",imageCachePath,file];
      if ( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        continue;
      }
      
      [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
      if ( error ) {
        continue;
      }
      
    }
  });
  
  [self.imageCache removeAllObjects];
  self.imageCache = [[NSMutableDictionary alloc] init];
}

- (void)systemClean {

  if ( [[ContentManager shared].settings.lastCacheCleanDate daysAgo] > kCacheCleaningThreshold ) {

    [self sweepDiskAndMemory];
    
    // Find outdated article stubs and remove them
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ArticleStub"
                                              inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    [request setFetchLimit:100];
    
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    for ( ArticleStub *stub in objects ) {
      if ( [stub.identifier rangeOfString:@"_saved"].location == NSNotFound ) {
        if ( [stub.created_at daysAgo] > kArticleExpireInDays ) {
          NSLog(@"Removing article because it's too old");
          [self.managedObjectContext deleteObject:stub];
        }
      }
    }

    // Find outdated and non-queued segments and clean them out too
    request = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"Segment"
                                              inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    for ( Segment *segment in objects ) {
      if ( ![segment addedToQueueDate] ) {
        [self.managedObjectContext deleteObject:segment];
      }
    }
    
    [self saveContext];
    [self destroyDiskAndMemoryCache];
    [self.settings setLastCacheCleanDate:[NSDate date]];
    [self setSkipParse:YES];
    [self writeSettings];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dir = [NSString stringWithFormat:@"%@/html",[paths objectAtIndex:0]];
    
    error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir
                                                                         error:&error];
    if ( error ) {
      NSLog(@"Couldn't process html directory");
      return;
    }
    
    for ( NSString* file in files ) {
      NSString *fq = [dir stringByAppendingPathComponent:file];
      [[NSFileManager defaultManager] removeItemAtPath:fq error:&error];
      if ( error ) {
        NSLog(@"Couldn't remove file : %@",file);
      }
    }
    NSLog(@"Finished cleaning system...");
  }
}

- (UIImage*)retrieveImageFromCache:(NSString*)link {
  NSString *hash = [Utilities sha1:link];
  if ( self.imageCache ) {
    UIImage *memoryImage = [self.imageCache objectForKey:hash];
    if ( memoryImage ) {
      return memoryImage;
    }
  }
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *imageCachePath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"images"];
  
  UIImage *img = nil;
  NSString *filePath = [imageCachePath stringByAppendingPathComponent:hash];
  if ( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
      img = [UIImage imageWithContentsOfFile:filePath];
  }
  return img;
}


- (UIImage*)retrieveSandboxedImageFromDisk:(NSString*)link {
  NSString *hash = [Utilities sha1:link];
  UIImage *memoryImage = [self.imageCache objectForKey:hash];
  if ( memoryImage ) {
    return memoryImage;
  }
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *imageCachePath = [NSString stringWithFormat:@"%@/%@/%@", [paths objectAtIndex:0], @"images", @"sandbox"];
  
  UIImage *img = nil;
  NSString *filePath = [imageCachePath stringByAppendingPathComponent:hash];
  if ( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
    @synchronized(self) {
      img = [UIImage imageWithContentsOfFile:filePath];
    }
  }
  return img;
}

- (NSString*)writeImageToDisk:(NSData *)img forHash:(NSString*)hash {
  return [self writeImageToDisk:img forHash:hash sandbox:NO];
}

- (NSString *)writeImageToDisk:(NSData *)img forHash:(NSString *)hash sandbox:(BOOL)sandbox {
  return [self writeImageToDisk:img forHash:hash sandbox:sandbox atomically:YES];
}

- (NSString*)writeImageToDisk:(NSData *)img forHash:(NSString *)hash sandbox:(BOOL)sandbox atomically:(BOOL)atomically {

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *imageCachePath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"images"];
  if ( sandbox ) {
    BOOL directory;
    NSError *error = nil;
    imageCachePath = [NSString stringWithFormat:@"%@/%@/%@", [paths objectAtIndex:0], @"images", @"sandbox"];
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:imageCachePath
                                              isDirectory:&directory] ) {
      [[NSFileManager defaultManager] createDirectoryAtPath:imageCachePath
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&error];
    }
    
  }
  
  NSString *filePath = [imageCachePath stringByAppendingPathComponent:hash];
  if ( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
    [img writeToFile:filePath atomically:YES];
  }

  return filePath;
}


#pragma mark - Core Data stack
- (void)saveContext
{
#ifdef USE_BACKGROUND_PERSISTENCE
  
  if ( [self.managedObjectContext hasChanges] ) {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
      if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
      {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
      }
    }
  } else {
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [self threadedSaveContext:self.persistentStoreCoordinator];
    });
    
  }
#else
  NSError *error = nil;
  NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
  if (managedObjectContext != nil)
  {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
    {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
#endif
}

- (void)saveContextInBackground {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [self threadedSaveContext:self.persistentStoreCoordinator];
  });
}

- (void)saveContextOnMainThread {
  NSError *error = nil;
  NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
  if (managedObjectContext != nil)
  {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
    {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
}

- (void)threadedSaveContext:(NSPersistentStoreCoordinator *)mainThreadPSC {
  
  NSError *error = nil;
  if ( !self.backgroundThreadObjectContext ) {
    self.backgroundThreadObjectContext = [[NSManagedObjectContext alloc] init];
    [self.backgroundThreadObjectContext setPersistentStoreCoordinator:mainThreadPSC];
  }
  
  NSManagedObjectContext *managedObjectContext = self.backgroundThreadObjectContext;
  
  
  if (managedObjectContext != nil)
  {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
    {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    } else {
      
      if ( error ) {
        NSLog(@"***** Could not save ***** %@ %@ %@",error,[error localizedDescription],[error userInfo]);
      } else {
        NSLog(@"***** NOT SAVING BECAUSE NO CHANGES *****");
      }
      
    }
  }
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
  if (_managedObjectContext != nil)
  {
    return _managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil)
  {
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
  }
  return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
  if (_managedObjectModel != nil)
  {
    return _managedObjectModel;
  }
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self modelBase]
                                            withExtension:@"momd"];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
  if (_persistentStoreCoordinator != nil)
  {
    return _persistentStoreCoordinator;
  }
  
  NSString *pathComponent = [NSString stringWithFormat:@"%@.sqlite",[self modelBase]];
  NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:pathComponent];
  
  NSError *error = nil;
  NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
  
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
  {
    /*
     Replace this implementation with code to handle the error appropriately.
     
     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
     
     Typical reasons for an error here include:
     * The persistent store is not accessible;
     * The schema for the persistent store is incompatible with current managed object model.
     Check the error message to determine what the actual problem was.
     
     
     If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
     
     If you encounter schema incompatibility errors during development, you can reduce their frequency by:
     * Simply deleting the existing store:
     [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
     
     * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
     [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
     
     Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
     
     */
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
  
  return _persistentStoreCoordinator;
}

- (void)empty {
  return;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
