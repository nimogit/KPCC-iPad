//
//  SCPRUnderConstructionViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 7/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRUnderConstructionViewController.h"
#import "global.h"

@interface SCPRUnderConstructionViewController ()

@end

@implementation SCPRUnderConstructionViewController

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
  
  self.view.backgroundColor = [[DesignManager shared] lightClayColor];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
