//
//  SCPRVideoContentViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 4/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRBCVideoContentViewController.h"
#import "global.h"

@interface SCPRBCVideoContentViewController ()

@end

@implementation SCPRBCVideoContentViewController
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  
    // Do any additional setup after loading the view from its nib.
}

- (void)loadVideoWithID:(NSString*)videoID {
  self.catalog = [[BCOVCatalogService alloc] initWithToken:@"B9QsGib-s6G0ndDAU7s9bgarVp4eRMvHJa7kyNLOdW6SkPU9KbmS-g.."];
  self.facade = [[BCOVPlayerSDKManager sharedManager] newPlaybackFacadeWithFrame:self.view.frame];
  [self.catalog findVideoWithVideoID:videoID parameters:@{ @"media_delivery" : @"http_ios"} completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
    [self performSelectorOnMainThread:@selector(playVideo:)
                           withObject:video waitUntilDone:NO];
  }];
  
  [self.catalog findVideoByID:videoID options:@{ @"media_delivery" : @"http_ios"}
                    callBlock:^(BCError *error, BCVideo *video) {
                      [self performSelectorOnMainThread:@selector(playVideo:)
                                             withObject:video waitUntilDone:NO];
                    }];

}

- (void)playVideo:(id)video {
  
  self.video = (BCOVVideo*)video;
  [self.facade setVideos:[[BCOVPlaylist alloc] initWithVideo:self.video]];
  [self.facade play];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

@end
