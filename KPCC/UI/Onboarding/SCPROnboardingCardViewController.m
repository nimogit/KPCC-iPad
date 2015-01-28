
//
//  SCPROnboardingCardViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingCardViewController.h"
#import "SCPROnboardingStep1ViewController.h"
#import "SCPROnboardingStep2ViewController.h"
#import "SCPROnboardingStep3ViewController.h"
#import "SCPROnboardingStep4ViewController.h"
#import "SCPROnboardingStep5ViewController.h"
#import "SCPROnboardingStep6ViewController.h"

#import "global.h"

@interface SCPROnboardingCardViewController ()

@end

@implementation SCPROnboardingCardViewController

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
  
  self.cardCrux.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
  self.cardCrux.layer.borderWidth = 1.0;
  
  [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] clayColor]
                                     forButton:self.backButton];
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.backButton.titleLabel.font.pointSize]
                                forButton:self.backButton];
  
    // Do any additional setup after loading the view from its nib.
}

- (id<Cardable>)setupWithStep:(FlowStep)step andMaster:(id)master {
  
  UIViewController<Cardable> *stepCtrl = nil;
  self.contentScroller.clipsToBounds = YES;
  self.master = master;
  self.myStepIndex = step;
  
  NSString *base = [NSString stringWithFormat:@"SCPROnboardingStep%dViewController",step];
  
  switch (step) {
    case FlowStepLanding:
      stepCtrl = (UIViewController<Cardable> *)[[SCPROnboardingStep1ViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                         xibForPlatformWithName:base]
                                                                                                 bundle:nil];
    break;
    case FlowStepMemberInfoInput:
      stepCtrl = (UIViewController<Cardable> *)[[SCPROnboardingStep2ViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                              xibForPlatformWithName:base]
                                                                                      bundle:nil];
    break;
    case FlowStepMemberValidateSingle:
      stepCtrl = (UIViewController<Cardable> *)[[SCPROnboardingStep3ViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                         xibForPlatformWithName:base]
                                                                                                 bundle:nil];
      break;
    case FlowStepMemberValidateMultiple:
      stepCtrl = (UIViewController<Cardable> *)[[SCPROnboardingStep4ViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                           xibForPlatformWithName:base]
                                                                                                   bundle:nil];
      break;
    case FlowStepMemberValidateTwitterOrFacebook:
      stepCtrl = (UIViewController<Cardable> *)[[SCPROnboardingStep5ViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                           xibForPlatformWithName:base]
                                                                                                   bundle:nil];
      break;
    case FlowStepMemberValidateLinkedIn:
      stepCtrl = (UIViewController<Cardable> *)[[SCPROnboardingStep6ViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                           xibForPlatformWithName:base]
                                                                                                   bundle:nil];
      break;
    case FlowStepUnknown:
      break;
    default:
      break;
  }
  
  
  self.contentScroller.contentSize = CGSizeMake(self.contentScroller.frame.size.width,
                                                stepCtrl.view.frame.size.height);
  stepCtrl.view.frame = CGRectMake(0.0,0.0,self.contentScroller.frame.size.width,
                                   stepCtrl.view.frame.size.height);
  [stepCtrl setMaster:self.master];
  [stepCtrl prepUI];
  
  
  self.myCardContent = stepCtrl;
  
  [self.contentScroller addSubview:stepCtrl.view];
  
  return stepCtrl;
  
}

- (IBAction)backTapped:(id)sender {
  
  if ( [self.myCardContent respondsToSelector:@selector(backTapped)] ) {
    [self.myCardContent backTapped];
  }
  
  SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
  [flow snapRubberBand];
  [flow popCard];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
