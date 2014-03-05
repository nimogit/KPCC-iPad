//
//  AlarmManager.m
//  KPCC
//
//  Created by John Meeker on 2/25/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import "AlarmManager.h"

static AlarmManager *singleton = nil;

@implementation AlarmManager

+ (AlarmManager*)shared {
  if (!singleton) {
    @synchronized(self) {
      singleton = [[AlarmManager alloc] init];
      [singleton prime];
    }
  }
  return singleton;
}

- (void)prime {
  self.isSleepTimerActive = NO;
}

-(void)startTimer:(int)duration {
  if (self.timer) {
    [self.timer invalidate];
  }
  self.secondsLeft = duration;
  self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updateTimeLeft) userInfo:nil repeats: YES];
  self.isSleepTimerActive = YES;
}

-(void)stopTimer {
  if (self.timer) {
    [self.timer invalidate];
    self.timer = nil;
  }
  self.secondsLeft = 0;
  self.isSleepTimerActive = NO;
}

-(void)updateTimeLeft {  
  self.secondsLeft--;
  if (self.secondsLeft <= 0) {
    [self finishTimer];
  }
}

-(void)finishTimer {
  [[AudioManager shared] stopStream];
  _secondsLeft = 0;
  if (self.timer) {
    [self.timer invalidate];
    self.timer = nil;
  }
  self.isSleepTimerActive = NO;
}

@end
