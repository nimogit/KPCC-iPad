//
//  KPCC_iPad_Tests.m
//  KPCC-iPad-Tests
//
//  Created by Ben Hochberg on 6/18/15.
//  Copyright (c) 2015 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AudioManager.h"

@interface KPCC_iPad_Tests : XCTestCase

@end

@implementation KPCC_iPad_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLiveStreamUrl{
    // This is an example of a functional test case.
  [[AudioManager shared] buildStreamer:nil];
  
  AVAsset *currentPlayerAsset = player.currentItem.asset;
  if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
    XCTFail(@"Something went wrong loading the URL");
    return;
  }
  
  // return the NSURL
  NSURL *u = [(AVURLAsset *)currentPlayerAsset URL];
  
  XCTAssert([[u absoluteString] rangeOfString:@"http://live.scpr.org/kpcclive?ua=SCPRIPAD"].location != NSNotFound, @"URL Loading Passed");
  
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
