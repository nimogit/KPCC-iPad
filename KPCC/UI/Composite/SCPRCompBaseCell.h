//
//  SCPRCompBaseCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/20/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRCompBaseCell : UITableViewCell

@property (nonatomic,strong) NSMutableArray *articleFacades;
- (BOOL)isLocked;

@end
