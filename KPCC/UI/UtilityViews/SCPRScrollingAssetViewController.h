//
//  SCPRScrollingAssetViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRAppDelegate.h"

@interface SCPRScrollingAssetViewController : UIViewController<Cloakable,UIScrollViewDelegate>

@property (nonatomic,strong) NSDictionary *article;
@property (nonatomic,strong) IBOutlet UIScrollView *scroller;
@property (nonatomic,strong) IBOutlet UIImageView *leftCurtain;
@property (nonatomic,strong) IBOutlet UIImageView *rightCurtain;
@property (nonatomic,strong) IBOutlet UILabel *headerCaption;
@property (nonatomic,strong) IBOutlet UILabel *footerCaption;
@property (nonatomic,strong) NSMutableArray *imageVector;
@property (nonatomic,strong) NSMutableArray *ownerVector;
@property (nonatomic,strong) NSMutableDictionary *actualSizeLookupHash;
@property (nonatomic,strong) IBOutlet UILabel *progressLabel;
@property (nonatomic,strong) IBOutlet UILabel *mainCaptionLabel;
@property (nonatomic,strong) IBOutlet UILabel *titleCaptionLabel;
@property (nonatomic,strong) UIButton *captionExpansionButton;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,strong) IBOutlet UIView *captionSeat;
@property (nonatomic,strong) NSOperationQueue *miniQueue;

@property CGRect originalHeadlineHeight;
@property CGRect originalCaptionHeight;
@property CGRect originalBylineHeight;
@property CGRect originalCaptionSeatFrame;

@property (nonatomic,strong) NSString *articleTitle;

@property NSInteger currentIndex;
@property BOOL captionExpanded;

- (void)expandCaption;
- (void)contractCaption;

- (void)sourceWithArticle:(NSDictionary*)article;
- (void)deactivate;
- (void)applyMeta:(NSDictionary*)meta withOffset:(NSInteger)offset;

@end
