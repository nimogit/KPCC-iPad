//
//  SCPRDrawerCell.h
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRDrawerCell : UITableViewCell<UITableViewDataSource,UITableViewDelegate> {
  NSInteger _indexHint;
  UIView *_labelSeat;
  BOOL _expanded;
  UITableView *_submenuTableView;
  UIView *_shadowView;
}

- (NSMutableArray*)acquireContentsFromSchema;
- (CGFloat)determineHeightForDatasource;
- (void)placeObservers;
- (NSString*)stringForCellTapped:(NSIndexPath*)indexPath;

@property (nonatomic,strong) IBOutlet UILabel *headingLabel;
@property NSInteger indexHint;
@property BOOL expanded;
@property (nonatomic,strong) IBOutlet UIView *labelSeat;
@property (nonatomic,strong) IBOutlet UITableView *submenuTableView;
@property (nonatomic,weak) id parentMenuController;
@property (nonatomic,strong) IBOutlet UIView *shadowView;
@property (nonatomic,strong) NSString *menuTitle;
@property (nonatomic,strong) IBOutlet UIImageView *accessoryIcon;
@property (nonatomic,strong) IBOutlet UIImageView *leftAccessoryIcon;
@end
