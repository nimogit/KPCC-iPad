//
//  SCPRSliderBubbleViewController.h
//  KPCC
//
//  Created by Ben on 4/10/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
  SliderTypeUnknown = 0,
  SliderTypeVolume = 1,
  SliderTypeScrubber = 2
} SliderType;

@interface SCPRSliderBubbleViewController : UIViewController {
  UILabel *_valueLabel;
  SliderType _sliderType;
  
  UISlider *_controlledSlider;
  
  // Presentation
  BOOL _showing;
  NSTimer *_fadeTimer;
}

- (void)armTimer;
- (void)disarmTimer;
- (void)dropBubbleOntoWindow;
- (void)manualAdjustment:(CGFloat)value;

@property (nonatomic,strong) IBOutlet UILabel *valueLabel;
@property (nonatomic,strong) UISlider *controlledSlider;
@property (nonatomic,weak) UIView *parentContainer;
@property (nonatomic) SliderType sliderType;

@property BOOL showing;
@property (nonatomic,strong) NSTimer *fadeTimer;
@end
