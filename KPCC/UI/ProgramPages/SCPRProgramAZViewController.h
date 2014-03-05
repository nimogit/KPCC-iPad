//
//  SCPRProgramAZViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/25/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRFlatShadedButton.h"
#import "NetworkManager.h"
#import "SCPRAppDelegate.h"

@interface SCPRProgramAZViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate,Rotatable>


@property (nonatomic,strong) IBOutlet UICollectionView *programPickerView;
@property (nonatomic,strong) NSMutableArray *programs;
@property (nonatomic,strong) IBOutlet UICollectionViewFlowLayout *flowController;
@property (nonatomic,strong) IBOutlet UILabel *programHeadingLabel;
@property (nonatomic,strong) NSMutableDictionary *checkedItems;
@property (nonatomic,strong) NSMutableDictionary *cellPool;
@property (nonatomic,strong) NSString *originalHashValue;
@property (nonatomic,strong) IBOutlet UICollectionReusableView *saveFooter;
@property (nonatomic,strong) IBOutlet UIButton *saveButton;
@property (nonatomic,strong) NSArray *programsMasterList;
@property (nonatomic,strong) NSMutableDictionary *autoAddItems;

@property (nonatomic,strong) id pushedProgram;
@property CGRect originalTitleFrameSize;
@property BOOL editMode;
@property BOOL shill;

- (UIImage*)imageForProgram:(NSDictionary*)program;
- (NSString*)hashForCurrentlyChecked;
- (void)checkToEnableDoneButton;
- (IBAction)doneTapped:(id)sender;
- (void)mergeWithToolbar;

@end
