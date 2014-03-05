//
//  SCPRShareCellViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/31/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRShareCellViewController.h"
#import "global.h"

@interface SCPRShareCellViewController ()

@end

@implementation SCPRShareCellViewController

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

- (void)setDisabled:(BOOL)disabled {
  _disabled = disabled;
  
  if ( disabled ) {
    self.disabledImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"circle_with_line.png"]];
    self.disabledImage.frame = CGRectMake(self.logoImage.frame.origin.x,self.logoImage.frame.origin.y,
                                          self.logoImage.frame.size.width,self.logoImage.frame.size.height);
    [self.view addSubview:self.disabledImage];
  } else {
    if ( self.disabledImage ) {
      [self.disabledImage removeFromSuperview];
      self.disabledImage = nil;
    }
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
