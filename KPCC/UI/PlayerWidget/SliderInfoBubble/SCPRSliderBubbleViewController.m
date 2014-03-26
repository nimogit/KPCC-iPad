//
//  SCPRSliderBubbleViewController.m
//  KPCC
//
//  Created by Ben on 4/10/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSliderBubbleViewController.h"
#import "global.h"

@interface SCPRSliderBubbleViewController ()

@end

@implementation SCPRSliderBubbleViewController

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
  
  self.view.layer.cornerRadius = 4.0;
  self.view.backgroundColor = [[DesignManager shared] peachColor];
  
  [[DesignManager shared] applyPerimeterShadowTo:self.view];
  
    // Do any additional setup after loading the view from its nib.
}

- (void)setControlledSlider:(UISlider *)controlledSlider {
  _controlledSlider = controlledSlider;
  
  // KVO is not working at the moment, use the slider event handling
  /*[controlledSlider addObserver:self
                     forKeyPath:@"value"
                        options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                        context:NULL];*/
  
}


#pragma mark - Timer
- (void)disarmTimer {
  if ( self.fadeTimer ) {
    if ( [self.fadeTimer isValid] ) {
      [self.fadeTimer invalidate];
    }
    self.fadeTimer = nil;
  }
}

- (void)armTimer {
  [self disarmTimer];
  self.fadeTimer = [NSTimer scheduledTimerWithTimeInterval:kFadeTime
                                                    target:self
                                                  selector:@selector(fadeBubble)
                                                  userInfo:nil
                                                   repeats:NO];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ( !self.showing ) {
    self.showing = YES;
    [self dropBubbleOntoWindow];
  }
  [self armTimer];


  UISlider *s = (UISlider*)object;
  if ( self.sliderType == SliderTypeVolume ) {
    NSInteger percentage = round(((double)s.value / (double)1.0)*100);
    self.valueLabel.text = [NSString stringWithFormat:@"%ld%%",(long)percentage];
  }
  
}

- (void)manualAdjustment:(CGFloat)value {
  if ( !self.showing ) {
    self.showing = YES;
    [self dropBubbleOntoWindow];
  }
  [self armTimer];
  
  
  if ( self.sliderType == SliderTypeVolume ) {
    NSInteger percentage = round(((double)value / (double)1.0)*100);
    self.valueLabel.text = [NSString stringWithFormat:@"%ld%%",(long)percentage];
  }
}

#pragma mark - UI
- (void)dropBubbleOntoWindow {
  if ( [Utilities isIpad] ) {
    self.view.alpha = 1.0;
    CGRect raw = self.parentContainer.frame;
    UIWindow *window = [[Utilities del] window];
  
    CGRect cooked = [window convertRect:raw fromView:self.parentContainer];
    self.view.frame = CGRectMake(cooked.origin.x,cooked.origin.y,
                               self.view.frame.size.width,
                               self.view.frame.size.height);
  
    [window addSubview:self.view];
  } else {
    self.view.alpha = 1.0;
    CGRect raw = self.parentContainer.frame;
    UIWindow *window = [[Utilities del] window];
    
    self.view.frame = CGRectMake(raw.origin.x,raw.origin.y+raw.size.height,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
    
    [window addSubview:self.view];
    
  }
}

- (void)fadeBubble {
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.13];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(burstBubble)];
  self.view.alpha = 0.0;
  [UIView commitAnimations];
}

- (void)burstBubble {
  [self.view removeFromSuperview];
  self.showing = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
