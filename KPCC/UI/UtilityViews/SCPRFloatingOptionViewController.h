//
//  SCPRFloatingOptionViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/27/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OptionsDelegate <NSObject>

- (void)pressRemoved;
- (void)optionSelected:(NSInteger)option;


@end

@interface SCPRFloatingOptionViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIButton *option1;
@property (nonatomic,strong) IBOutlet UIButton *option2;
@property (nonatomic,strong) IBOutlet UIButton *option3;
@property (nonatomic,strong) IBOutlet UIButton *option4;
@property (nonatomic,strong) IBOutlet UIButton *option5;
@property (nonatomic,strong) IBOutlet UILabel *optionDescriptionLabel;
@property (nonatomic,weak) id<OptionsDelegate> delegate;
@property (nonatomic,strong) NSDictionary *sourceableData;

@property (nonatomic,strong) NSMutableDictionary *originalFrameHash;
@property BOOL isPresenting;

- (void)animateIntoPlace;
- (void)animateBack;

- (IBAction)optionSelected:(id)sender;

@end
