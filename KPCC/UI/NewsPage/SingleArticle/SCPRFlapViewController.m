//
//  SCPRFlapViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRFlapViewController.h"
#import "global.h"

@interface SCPRFlapViewController ()

@end

@implementation SCPRFlapViewController

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

- (void)setRightFlap:(BOOL)rightFlap {
  _rightFlap = rightFlap;
  
  if ( rightFlap ) {
    self.flapBody.frame = CGRectMake(self.view.frame.size.width-self.flapBody.frame.size.width,
                                     0.0,
                                     self.flapBody.frame.size.width,
                                     self.flapBody.frame.size.height);
  }
  
}

- (void)attachFlapToView:(id)view inPosition:(FlapPosition)position {
  self.flapBody.backgroundColor = [[DesignManager shared] obsidianColor:1.0];
  self.shadowView.backgroundColor = [[DesignManager shared] obsidianColor:0.75];
  
  UIView *parent = (UIView*)view;
  parent.clipsToBounds = NO;
  
  if ( position == FlapPostitionRight ) {
    self.rightFlap = YES;
    [parent addSubview:self.view];
    self.view.frame = CGRectMake(parent.frame.size.width-self.view.frame.size.width/2.0,
                                 0.0,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
    
    CATransform3D tform = CATransform3DIdentity;
    tform.m34 = -1.0 / 1000;
    tform = CATransform3DRotate(tform, [Utilities degreesToRadians:90.0],
                                0.0, 1.0, 0.0);
    [self.view.layer setTransform:tform];

    
    /*[self.view.layer setTransform:CATransform3DMakeRotation([Utilities degreesToRadians:90.0],
                                                            0.0, 1.0, 0.0)];*/
    
  } else {
    [parent addSubview:self.view];
    self.view.frame = CGRectMake(-1.0*(self.view.frame.size.width/2.0),
                                 0.0,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
    
    
    CATransform3D tform = CATransform3DIdentity;
    tform.m34 = -1.0 / 1000;
    tform = CATransform3DRotate(tform, [Utilities degreesToRadians:-90.0],
                                0.0, 1.0, 0.0);
    [self.view.layer setTransform:tform];
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
