//
//  SCPRLinkedInShareViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/5/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

@class SCPRImageView;

@interface SCPRLinkedInShareViewController : UIViewController<Cloakable,UITextViewDelegate>

@property (nonatomic,strong) IBOutlet UIButton *shareButton;
@property (nonatomic,strong) IBOutlet UITextView *inputTextView;
@property (nonatomic,strong) IBOutlet UILabel *shareCaptionLabel;
@property (nonatomic,strong) IBOutlet UIView *shareContainerView;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet SCPRImageView *articleImageView;
@property (nonatomic,strong) IBOutlet UIImageView *linkedInLogoView;
@property (nonatomic,strong) IBOutlet UILabel *successLabel;
@property (nonatomic,strong) NSDictionary *article;

- (IBAction)shareTapped:(id)sender;

@end
