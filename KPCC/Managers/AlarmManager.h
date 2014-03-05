//
//  AlarmManager.h
//  KPCC
//
//  Created by John Meeker on 2/25/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "global.h"

@interface AlarmManager : NSObject

-(void)startTimer:(int)duration;
-(void)stopTimer;
-(void)finishTimer;
-(void)updateTimeLeft;

@property int secondsLeft;
@property(nonatomic,strong) NSTimer *timer;
@property (atomic) BOOL isSleepTimerActive;

+ (AlarmManager*)shared;

@end
