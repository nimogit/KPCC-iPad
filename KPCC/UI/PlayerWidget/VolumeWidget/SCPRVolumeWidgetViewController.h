//
//  SCPRVolumeWidgetViewController.h
//  KPCC
//
//  Created by Ben on 4/10/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SCPRSliderBubbleViewController.h"

@interface SCPRVolumeWidgetViewController : UIViewController {
  UISlider *_volumeSlider;
  SCPRSliderBubbleViewController *_sliderBubble;
}

@property (nonatomic,strong) IBOutlet UISlider *volumeSlider;
@property (nonatomic,strong) SCPRSliderBubbleViewController *sliderBubble;

- (IBAction)sliderMoved:(id)sender;

@end
