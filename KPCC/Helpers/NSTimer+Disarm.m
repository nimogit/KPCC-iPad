//
//  NSTimer+Disarm.m
//  KPCC
//
//  Created by Ben on 4/10/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "NSTimer+Disarm.h"

@implementation NSTimer (Disarm)

- (void)disarm {
  if ( [self isValid] ) {
    [self invalidate];
  }
}

@end
