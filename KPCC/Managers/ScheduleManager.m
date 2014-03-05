//
//  ScheduleManager.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "ScheduleManager.h"
#import "global.h"
#import "SCPRPlayerWidgetViewController.h"

static ScheduleManager *singleton = nil;

@implementation ScheduleManager

+ (ScheduleManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      singleton = [[ScheduleManager alloc] init];
    }
  }
  
  return singleton;
}

- (void)armScheduleUpdater {
  
  // -- Developer Note --
  //
  // I've created a macro called TURN_OFF_UNTESTED_FEATURES to block off development that's happening here in the last few days of my employment.
  // Because I'm just adding this code now and it's not going to get a chance to really be QA'd or even smoke tested too much before I leave, it'd
  // be good to remove the functionality from builds to ensure their stability during the transition. This macro is enabled in the Production target
  // only, so keep in mind that development and release builds will contain the candidate code. Once the code is blessed, remove this macro from the
  // lines below.
  //
#ifndef TURN_OFF_UNTESTED_FEATURES
  [self disarmScheduleUpdater];
  self.refreshScheduleTimer = [NSTimer scheduledTimerWithTimeInterval:120.0
                                                               target:self
                                                             selector:@selector(updatePlayerUI)
                                                             userInfo:nil
                                                              repeats:YES];
#endif
}

- (void)disarmScheduleUpdater {
  if ( self.refreshScheduleTimer ) {
    if ( [self.refreshScheduleTimer isValid] ) {
      [self.refreshScheduleTimer invalidate];
    }
    
    self.refreshScheduleTimer = nil;
  }
}

- (void)updatePlayerUI {
  
  if ( [[AudioManager shared] isPlayingAnyAudio] ) {
    if ( [[AudioManager shared] isPlayingOnDemand] ) {
      return;
    }
  }
  
  [[NetworkManager shared] fetchProgramInformationFor:[NSDate date]
                                                display:[[Utilities del] globalPlayer]];
    

  
}

- (void)addReminder:(NSDictionary *)program reminderType:(ReminderType)type {
  
  NSString *key = [Utilities sha1:[program objectForKey:@"title"]];
  NSString *settings = [[ContentManager shared].settings remindersString];
  NSMutableDictionary *settingsHash = (NSMutableDictionary*)[settings JSONValue];
  if ( [Utilities pureNil:settingsHash] ) {
    settingsHash = [[NSMutableDictionary alloc] init];
  }
  if ( ![settingsHash objectForKey:key] ) {
    [settingsHash setObject:@1 forKey:key];
  }
  [[ContentManager shared].settings setRemindersString:[settingsHash JSONRepresentation]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  self.fetchType = DataFetchReminders;
  [[NetworkManager shared] fetchContentForScheduleThisWeek:self];
  
}

- (void)removeReminder:(NSDictionary *)program {
  NSArray *reminders = [[UIApplication sharedApplication] scheduledLocalNotifications];
  NSString *key = [Utilities sha1:[program objectForKey:@"title"]];
  for ( UILocalNotification *note in reminders ) {
    NSDictionary *ui = [note userInfo];
    NSString *val = [ui objectForKey:@"key"];
    if ( [val isEqualToString:key] ) {
      [[UIApplication sharedApplication] cancelLocalNotification:note];
    }
  }
  
  NSString *settings = [[ContentManager shared].settings remindersString];
  NSMutableDictionary *settingsHash = (NSMutableDictionary*)[settings JSONValue];

  [settingsHash removeObjectForKey:key];
  [[ContentManager shared].settings setRemindersString:[settingsHash JSONRepresentation]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
}

- (void)fetchProgramInformationFor:(NSDate *)thisTime {
  
}

#pragma mark - Utility
- (NSDictionary*)makeSenseOfPrettyDateString:(NSString *)string {
  
  if ( [string rangeOfString:@"Weekdays"].location != NSNotFound ) {
    NSRange parse = [string rangeOfString:@"Weekdays"];
    NSString *rest = [string substringFromIndex:parse.location+parse.length];
    
    BOOL openDigitTrap = NO;
    NSString *time = @"";
    for ( unsigned i = 0; i < [rest length]; i++ ) {
      unichar c = [rest characterAtIndex:i];
      if ( [Utilities isDigit:c] || c == ':' ) {
        openDigitTrap = YES;
        time = [time stringByAppendingString:[rest substringWithRange:NSMakeRange(i, 1)]];
      } else {
        if ( openDigitTrap ) {
          break;
        }
      }
    }
    
    BOOL am = NO;
    NSRange timeRange = [rest rangeOfString:time];
    timeRange.location += timeRange.length;
    for ( unsigned j = timeRange.location; j < [rest length]; j++ ) {
      unichar e = [rest characterAtIndex:j];
      if ( e == 'a' || e == 'A' ) {
        am = YES;
        break;
      }
      if ( e == 'p' || e == 'P' ) {
        break;
      }
    }
    
    NSDate *now = [NSDate date];
    NSDate *specificTime = [NSDate date];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSMonthCalendarUnit
                                                            fromDate:specificTime];
    
    NSString *hour = time;
    NSString *minutes = @"00";
    if ( [time rangeOfString:@":"].location != NSNotFound ) {
      NSArray *comps = [time componentsSeparatedByString:@":"];
      hour = [comps objectAtIndex:0];
      minutes = [comps objectAtIndex:1];
    }
    
    NSInteger hourInt = [hour intValue];
    if ( !am ) {
      hourInt+=12;
    }
    NSInteger minuteInt = [minutes intValue];
    
    [comps setMinute:minuteInt];
    [comps setHour:hourInt];
    
    NSDate *startingDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    if ( [startingDate earlierDate:now] == startingDate ) {
      startingDate = [startingDate dateChangedBy:1];
      
      NSDateComponents *dayCheck = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit
                                                                   fromDate:startingDate];
      NSInteger dayofWeek = [dayCheck weekday];
      if ( dayofWeek == 7 ) {
        startingDate = [startingDate dateChangedBy:2];
      }
      if ( dayofWeek == 1 ) {
        startingDate = [startingDate dateChangedBy:1];
      }
    }
    
    return @{ @"frequency" : @"weekdays", @"time" : startingDate };
  } else {
    
    NSDictionary *days = @{ @"Monday" : @1,
      @"Tuesday" : @2,
      @"Wednesday" : @3,
      @"Thursday" : @4,
      @"Friday" : @5,
      @"Saturday" : @6,
      @"Sunday" : @7 };

    
    NSRange earliest = NSMakeRange(NSNotFound, 0);
    NSString *earliestStr = @"";
    NSArray *keys = [days allKeys];
    for ( NSString *key in keys ) {
      if ( [string rangeOfString:key].location != NSNotFound ) {
        if ( [string rangeOfString:key].location < earliest.location ) {
          earliest = [string rangeOfString:key];
          earliestStr = key;
        }
      }
    }
    
    BOOL openDigitTrap = NO;
    NSString *time = @"";
    NSRange final = [string rangeOfString:earliestStr];
    NSString *rest = [string substringFromIndex:final.location+final.length];
    for ( unsigned i = 0; i < [rest length]; i++ ) {
      unichar c = [rest characterAtIndex:i];
      if ( [Utilities isDigit:c] || c == ':' ) {
        openDigitTrap = YES;
        time = [time stringByAppendingString:[rest substringWithRange:NSMakeRange(i, 1)]];
      } else {
        if ( openDigitTrap ) {
          break;
        }
      }
    }
    
    NSDate *now = [NSDate date];
    NSDate *specificTime = [NSDate date];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSMonthCalendarUnit
                                                              fromDate:specificTime];
    
    BOOL am = NO;
    NSRange timeRange = [rest rangeOfString:time];
    timeRange.location += timeRange.length;
    for ( unsigned j = timeRange.location; j < [rest length]; j++ ) {
      unichar e = [rest characterAtIndex:j];
      if ( e == 'a' || e == 'A' ) {
        am = YES;
        break;
      }
      if ( e == 'p' || e == 'P' ) {
        break;
      }
    }
    
    NSString *hour = time;
    NSString *minutes = @"00";
    if ( [time rangeOfString:@":"].location != NSNotFound ) {
      NSArray *comps = [time componentsSeparatedByString:@":"];
      hour = [comps objectAtIndex:0];
      minutes = [comps objectAtIndex:1];
    }
    
    NSInteger hourInt = [hour intValue];
    if ( !am ) {
      hourInt+=12;
    }
    NSInteger minuteInt = [minutes intValue];
    
    [comps setMinute:minuteInt];
    [comps setHour:hourInt];
    
    NSDate *startingDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    if ( [startingDate earlierDate:now] == startingDate ) {
      startingDate = [startingDate dateChangedBy:7];
    }
    
    return @{ @"frequency" : @"weekly", @"time" : startingDate };
  }
  
  return @{};
}

- (void)syncReminders:(NSArray *)schedule {
  
  self.cachedSchedule = schedule;
  
  [[ContentManager shared].settings setLastReminderSync:[NSDate date]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  [[UIApplication sharedApplication] cancelAllLocalNotifications];
  
#ifdef FAKE_LOCAL_NOTIFICATION

  NSDate *justBefore = [[NSDate date] dateByAddingTimeInterval:20];
  UILocalNotification *note = [[UILocalNotification alloc] init];
  NSString *slug = @"fresh-air";
  [note setFireDate:justBefore];
  [note setUserInfo:@{ @"key" : [Utilities sha1:@"Fresh Air"], @"slug" : slug, @"title" : @"Fresh Air" }];
  [note setAlertBody:@"Fresh Air is going to start, at least in this test"];
  [[UIApplication sharedApplication] scheduleLocalNotification:note];
  
#else
  NSMutableDictionary *reminders = [[[ContentManager shared].settings remindersString] JSONValue];
  for ( NSDictionary *scheduleItem in schedule ) {
    NSString *title = [scheduleItem objectForKey:@"title"];
    if ( [reminders objectForKey:[Utilities sha1:title]] ) {
      
      NSDictionary *prog = [scheduleItem objectForKey:@"program"];
      NSString *slug = @"";
      if ( prog ) {
        slug = [prog objectForKey:@"slug"];
      } else {
        slug = [[scheduleItem objectForKey:@"title"] lowercaseString];
        slug = [slug stringByReplacingOccurrencesOfString:@" " withString:@"-"];
      }
      
      NSString *actualStr = [scheduleItem objectForKey:@"starts_at"];
      NSDate *actualDate = [Utilities dateFromRFCString:actualStr];
      NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit
                                                                fromDate:actualDate];
      [comps setMinute:[comps minute]-5];
      NSDate *justBefore = [[NSCalendar currentCalendar] dateFromComponents:comps];
      NSString *alertBody = [NSString stringWithFormat:@"%@ is about to start",[scheduleItem objectForKey:@"title"]];
      
      UILocalNotification *note = [[UILocalNotification alloc] init];
      [note setFireDate:justBefore];
      [note setUserInfo:@{ @"key" : [Utilities sha1:title], @"slug" : slug, @"title" : title }];
      [note setAlertBody:alertBody];
      [[UIApplication sharedApplication] scheduleLocalNotification:note];
      
      NSLog(@"Scheduling a reminder for %@ at %@",[scheduleItem objectForKey:@"title"],[NSDate stringFromDate:justBefore
                                                                                                   withFormat:@"MM/dd/YYYY hh:mm a"]);
    }
  }
#endif
  
}

- (void)syncLatestPrograms:(NSMutableArray *)hint {
  
  [[ContentManager shared].settings setLastLatestEpisodesSync:[NSDate date]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    
    NSMutableArray *slugs = [[NSMutableArray alloc] init];
    if ( !hint ) {
      NSString *userJson = [[ContentManager shared].settings favoriteProgramsAsJson];
      NSMutableArray *favorites = (NSMutableArray*)[userJson JSONValue];
      for ( NSDictionary *program in favorites ) {
        [slugs addObject:[program objectForKey:@"slug"]];
      }
    } else {
      slugs = hint;
    }
    
    for ( NSString *slug in slugs ) {
      
      Scheduler *s = [[ContentManager shared] findSchedulerForProgram:slug];
      if ( !s ) {
        continue;
      }
      
      self.fetchType = DataFetchLatestEpisodes;
      [[NetworkManager shared] fetchContentForProgramPage:slug display:self];
      
    }
      
  });

  
}

- (BOOL)eventIsLive:(NSDictionary *)leadEvent {
  NSString *ds = [leadEvent objectForKey:@"starts_at"];
  NSDate *sd = [Utilities dateFromRFCString:ds];
  NSDate *now = [NSDate date];
  NSInteger seconds = (NSInteger)[now timeIntervalSince1970];
  NSString *finStr = [leadEvent objectForKey:@"ends_at"];
  NSDate *finish = [Utilities dateFromRFCString:finStr];
  
  NSDateComponents *c = [[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:finish];
  [c setHour:23];
  [c setMinute:59];
  finish = [[NSCalendar currentCalendar] dateFromComponents:c];
  
  if ( seconds > ([sd timeIntervalSince1970]-(60*30)) && seconds < [finish timeIntervalSince1970] ) {
    if ( [[ContentManager shared] storyHasYouTubeAsset:leadEvent] ) {
      return YES;
    }
  }
  
  return NO;

}

- (NSString*)determineTypeByDate:(NSDate *)date {
  
  NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit|NSWeekdayOrdinalCalendarUnit|NSHourCalendarUnit
                                                            fromDate:date];
  
  NSInteger wdO = [comps weekday];
  if ( wdO == LocalWeekdaySunday ||
      wdO == LocalWeekdaySaturday ) {
    // Saturday or Sunday
    return @"Weekend Reads";
  }
  
  if ( wdO == LocalWeekdayFriday ) {
    if ( [comps hour] > 13 ) {
      // Friday after 1:00p
      return @"Weekend Reads";
    }
  }
  
  if ( [comps hour] >= 12 ) {
    return @"P.M. Edition";
  }
  
  return @"A.M. Edition";
  
}

- (void)createProgramMap {
  NSString *urlString = [NSString stringWithFormat:@"%@/programs",kServerBase];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *req = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:req
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                           
                           if ( connectionError ) {
                             return;
                           }
                           
                           NSString *s = [[NSString alloc] initWithData:data
                                                               encoding:NSUTF8StringEncoding];
                           if ( s ) {
                             
                             [[ContentManager shared] filterPrograms:[s JSONValue]];
                             
                           }
                           
                         }];
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  if ( self.fetchType == DataFetchReminders ) {
    [self syncReminders:content];
  }
  if ( self.fetchType == DataFetchLatestEpisodes ) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSAssert([flags objectForKey:@"slug"], @"SLUG IS REQUIRED");
      NSString *slug = [flags objectForKey:@"slug"];
      Scheduler *s = [[ContentManager shared] findSchedulerForProgram:slug];
      NSInteger progCount = 0;
      if ( !s.lastsync ) {
        
        if ( [content count] > 0 ) {
          progCount = 1;
          NSDictionary *episode = [content objectAtIndex:0];
          int counter = 0;
          while ( ![self validateEpisodeHasAudio:episode] ) {
            episode = nil;
            counter++;
            if ( counter >= [content count] ) {
              break;
            }
            episode = [content objectAtIndex:counter];
          }
          
          if ( episode ) {
            s.lastsync = [Utilities dateFromRFCString:[episode objectForKey:@"air_date"]];
            dispatch_async(dispatch_get_main_queue(), ^{
              [[QueueManager shared] addToQueue:episode
                                        asset:nil
                              playImmediately:NO];
              
              [[Utilities del] incrementNewItemCount];
            });
          }
        }
        
      } else {
        
        NSMutableArray *add = [[NSMutableArray alloc] init];
        NSDate *final = nil;
        for ( unsigned i = 0; i < [content count]; i++ ) {
          NSDictionary *episode = [content objectAtIndex:i];
          NSDate *candidate = [Utilities dateFromRFCString:[episode objectForKey:@"air_date"]];
          if ( [candidate earlierDate:s.lastsync] == s.lastsync ) {
            [add addObject:episode];
            final = candidate;
          } else {
            break;
          }
        }
        if ( final ) {
          s.lastsync = final;
        }
        progCount = [add count];
        
        dispatch_async(dispatch_get_main_queue(), ^{
          for ( NSDictionary *episode in add ) {

            [[QueueManager shared] addToQueue:episode
                                      asset:nil
                            playImmediately:NO];
            
            [[Utilities del] incrementNewItemCount];
            
          }
        });

      }

    });
  }
  
}

- (BOOL)validateEpisodeHasAudio:(NSDictionary *)episode {
  NSArray *audio = [episode objectForKey:@"audio"];
  if ( audio && [audio count] > 0 ) {
    return YES;
  }
  
  NSArray *segments = [episode objectForKey:@"segments"];
  if ( segments && [segments count] > 0 ) {
    for ( NSDictionary *segment in segments ) {
      audio = [segment objectForKey:@"audio"];
      if ( audio && [audio count] > 0 ) {
        return YES;
      }
    }
  }
  
  return NO;
  
}

@end
