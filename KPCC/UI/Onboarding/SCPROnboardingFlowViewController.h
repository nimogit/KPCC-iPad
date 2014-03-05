//
//  SCPROnboardingFlowViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRAppDelegate.h"

typedef enum {
  FlowStepUnknown = 0,
  FlowStepLanding,
  FlowStepMemberInfoInput,
  FlowStepMemberValidateSingle,
  FlowStepMemberValidateMultiple,
  FlowStepMemberValidateTwitterOrFacebook,
  FlowStepMemberValidateLinkedIn
} FlowStep;

@interface SCPROnboardingFlowViewController : UIViewController<Rotatable>

@property (nonatomic,strong) IBOutlet UIScrollView *cardScroller;
@property (nonatomic,strong) NSMutableArray *contentStack;
@property NSInteger currentStepIndex;
@property (nonatomic,weak) UIResponder *pusher;
@property CGFloat rubberbandingDistance;
@property (nonatomic,strong) UITapGestureRecognizer *tapper;
@property (nonatomic,strong) id cardMetaData;
@property BOOL firstRun;
@property (nonatomic,strong) IBOutlet UILabel *versionLabel;
@property (nonatomic,strong) IBOutlet UIButton *notRightNowButton;

- (void)setup;
- (void)pushCard:(NSInteger)step;
- (void)popCard;
- (void)rubberBandCard:(CGFloat)distance responder:(UIResponder*)pusher;
- (void)snapRubberBand;
- (void)finish;
- (IBAction)buttonTapped:(id)sender;
- (void)prepOrientation;

@end
