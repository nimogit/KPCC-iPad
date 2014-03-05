//
//  ScheduleManager.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkManager.h"

typedef enum {
  LocalWeekdayUnknown = 0,
  LocalWeekdaySunday,
  LocalWeekdayMonday,
  LocalWeekdayTuesday,
  LocalWeekdayWednesday,
  LocalWeekdayThursday,
  LocalWeekdayFriday,
  LocalWeekdaySaturday
} LocalWeekday;

typedef enum {
  ReminderTypeUnknown = 0,
  ReminderTypeBeginningOfProgram,
} ReminderType;

typedef enum {
  DataFetchUnknown = 0,
  DataFetchReminders,
  DataFetchLatestEpisodes,
} DataFetch;

@protocol ScheduleDelegate <NSObject>

- (void)programInformationFound;

@end

@interface ScheduleManager : NSObject<ContentProcessor>

@property (nonatomic,strong) NSArray *cachedSchedule;
@property DataFetch fetchType;
@property (nonatomic,strong) NSTimer *refreshScheduleTimer;

+ (ScheduleManager*)shared;

- (void)addReminder:(NSDictionary*)program reminderType:(ReminderType)type;
- (void)removeReminder:(NSDictionary*)program;
- (void)syncReminders:(NSArray*)schedule;

- (void)syncLatestPrograms:(NSMutableArray*)hint;
- (BOOL)eventIsLive:(NSDictionary*)leadEvent;

- (NSDictionary*)makeSenseOfPrettyDateString:(NSString*)string;

- (BOOL)validateEpisodeHasAudio:(NSDictionary*)episode;
- (void)createProgramMap;

- (NSString*)determineTypeByDate:(NSDate*)date;

- (void)armScheduleUpdater;
- (void)disarmScheduleUpdater;

@end
