//
//  main.m
//  KPCC
//
//  Created by Ben on 4/2/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRAppDelegate.h"


int main(int argc, char *argv[])
{
  // SCPR iPad NFR
  //_CFEnableZombies();
  srandom(time(NULL));
  return UIApplicationMain(argc, argv, nil, NSStringFromClass([SCPRAppDelegate class]));
  
}
