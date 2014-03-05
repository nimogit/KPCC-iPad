//
//  SCPR404ViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 7/17/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPR404ViewController.h"
#import "global.h"

@interface SCPR404ViewController ()

@end

@implementation SCPR404ViewController

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
  
  self.somethingWrongLabel.textColor = [[DesignManager shared] gloomyCloudColor];
  self.view.backgroundColor = [UIColor clearColor];
  [self.somethingWrongLabel titleizeText:self.somethingWrongLabel.text
                                    bold:YES];
    // Do any additional setup after loading the view from its nib.
}

- (void)deactivate {
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
