//
//  SCPREditionCompositeViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPREditionCompositeViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIImageView *splashImage;
@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet UILabel *categoryLabel;
@property (nonatomic,strong) UIImageView *cloakView;
@property (nonatomic) BOOL isPrimary;
@property (nonatomic,strong) NSDictionary *edition;
@property NSInteger index;
@property (nonatomic,strong) UIButton *actionButton;
@property (nonatomic,weak) id parent;

- (void)setupWithEdition:(NSDictionary*)edition;

@end
