//
//  SCPRVolumeWidgetViewController.m
//  KPCC
//
//  Created by Ben on 4/10/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRVolumeWidgetViewController.h"
#import "global.h"

@interface SCPRVolumeWidgetViewController ()

@end

@implementation SCPRVolumeWidgetViewController

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
  
  self.view.transform = CGAffineTransformMakeRotation([Utilities degreesToRadians:270.0]);
  self.volumeSlider.value = [[AudioManager shared] currentPlayerVolume];
  self.sliderBubble = [[SCPRSliderBubbleViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRSliderBubbleViewController"]
                                                                       bundle:nil];
  self.sliderBubble.controlledSlider = self.volumeSlider;
  self.sliderBubble.sliderType = SliderTypeVolume;
  self.sliderBubble.parentContainer = self.view;
  
  self.volumeSlider.maximumTrackTintColor = [[DesignManager shared] kpccOrangeColor];
  self.volumeSlider.minimumTrackTintColor = [[DesignManager shared] kpccDarkOrangeColor];
  
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Event handling
- (IBAction)sliderMoved:(id)sender {
  [[AudioManager shared] adjustVolume:self.volumeSlider.value];
  if ( self.sliderBubble ) {
    [self.sliderBubble manualAdjustment:self.volumeSlider.value];
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
