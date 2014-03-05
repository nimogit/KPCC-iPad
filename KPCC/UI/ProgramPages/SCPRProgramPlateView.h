//
//  SCPRProgramPlateView.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/25/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRSmallCutViewController.h"

@interface SCPRProgramPlateView : UICollectionViewCell

@property (nonatomic,strong) IBOutlet UIView *stripeView;
@property (nonatomic,strong) IBOutlet UILabel *titleLabel;
@property (nonatomic,strong) IBOutlet UIImageView *programImage;
@property (nonatomic,strong) IBOutlet UIImageView *checkmarkImage;
@property (nonatomic,strong) IBOutlet UIView *blueBarView;
@property (nonatomic,strong) IBOutlet UIView *blueSeatView;
@property (nonatomic,strong) IBOutlet UILabel *favoriteLabel;
@property (nonatomic,strong) IBOutlet UIImageView *gradientImage;
@property (nonatomic,strong) IBOutlet UIImageView *whiteHeartImage;
@property (nonatomic,strong) NSString *currentImageTitle;
@property (nonatomic,weak) id parentController;
@property (nonatomic,strong) NSString *slug;
@property (nonatomic,strong) SCPRSmallCutViewController *smallCutController;
@property (nonatomic,strong) IBOutlet UIView *autoAddSeat;
@property (nonatomic,strong) IBOutlet UIButton *autoAddButton;

@property CGRect originalTitleFrame;
@property CGRect originalTitleFrameEditMode;

@property BOOL cancelAnimRequested;
@property BOOL pulsing;
@property BOOL favorite;
@property BOOL autoadd;
@property NSInteger cellIndex;

- (void)primeWithProgram:(NSDictionary*)program;
- (void)pulse;
- (void)stopPulsing;
- (void)favoriteUI:(BOOL)fave;
- (void)updateSelf;
- (void)primeAutoAdd:(BOOL)autoadd;
- (IBAction)autoAddTapped:(id)sender;

@end
