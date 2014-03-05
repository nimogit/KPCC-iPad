//
//  SCPRCompositeNewsViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRSpinnerViewController.h"

@interface SCPRCompositeNewsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) IBOutlet UITableView *compositeNewsTable;
@property (nonatomic,strong) NSDictionary *compositeNews;
@property (nonatomic,strong) UIView *dummySingle;
@property (nonatomic,strong) UIView *dummyDouble;
@property (nonatomic,strong) id pushed;
@property (nonatomic,strong) SCPRSpinnerViewController *spinner;

- (void)focusArticle:(NSDictionary*)article;

@end
