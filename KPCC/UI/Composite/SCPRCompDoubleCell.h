//
//  SCPRCompDoubleCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRCompositeCellViewController.h"
#import "SCPRCompBaseCell.h"

@interface SCPRCompDoubleCell : SCPRCompBaseCell

@property (nonatomic,strong) IBOutlet SCPRCompositeCellViewController *articleCell0;
@property (nonatomic,strong) IBOutlet SCPRCompositeCellViewController *articleCell1;
@property NSInteger index;
@property (nonatomic,strong) NSArray *relatedArticles;

- (void)mergeWithArticles:(NSArray*)articles;

@end
