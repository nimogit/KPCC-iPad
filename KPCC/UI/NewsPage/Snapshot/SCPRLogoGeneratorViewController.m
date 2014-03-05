//
//  SCPRLogoGeneratorViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/17/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRLogoGeneratorViewController.h"
#import "SCPRViewController.h"

@interface SCPRLogoGeneratorViewController ()

@end

@implementation SCPRLogoGeneratorViewController

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
  
  self.view.backgroundColor = [[DesignManager shared] translucentPeriwinkleColor];
  self.logoLabel.backgroundColor = [UIColor clearColor];
  self.logoLabel.textColor = [[DesignManager shared] offwhiteColor];
  //[self.logoLabel extrude];
  
    // Do any additional setup after loading the view from its nib.
}

- (UIImage*)renderWithText:(NSString *)text {

  SCPRAppDelegate *del = [Utilities del];
  self.view.frame = CGRectMake(0.0,0.0,self.view.frame.size.width,
                               self.view.frame.size.height);
  
  SCPRViewController *svc = [[Utilities del] viewController];
  [[[[Utilities del] globalTitleBar] view] setAlpha:0.0];
  svc.view.alpha = 0.0;
  [del.window addSubview:self.view];
   
  [self.logoLabel titleizeText:text bold:YES
             respectHeight:YES];
  
  UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 2.0);
	[self.view.layer.superlayer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
  [self.view removeFromSuperview];
  
  [[[[Utilities del] globalTitleBar] view] setAlpha:1.0];
  svc.view.alpha = 1.0;
  
  return resultingImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
