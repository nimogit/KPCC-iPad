//
//  SCPREventsHeaderViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREventsHeaderViewController.h"
#import "global.h"

@interface SCPREventsHeaderViewController ()

@end

@implementation SCPREventsHeaderViewController

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
  
  self.view.backgroundColor = [[DesignManager shared] kpccDarkOrangeColor];
  [self.headerCaptionLabel extrude];
  [self.headerCaptionLabel snapText:self.headerTitle
                               bold:NO
   respectHeight:YES];
  
  
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
