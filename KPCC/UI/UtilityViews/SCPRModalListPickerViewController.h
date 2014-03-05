//
//  SCPRModalListPickerViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ModalListPickerDelegate <NSObject>

@required
- (void)itemPickedFromTable:(id)item;
- (void)unhook;

@end

@protocol Listable <NSObject>

@required
- (NSString*)stringRepresentation;
- (id)item;

@end

@interface SCPRModalListPickerViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>


@property (nonatomic,strong) IBOutlet UITableView *listTable;
@property (nonatomic,strong) NSArray *masterList;
@property (nonatomic,weak) id<ModalListPickerDelegate> delegate;
@property (nonatomic,strong) IBOutlet UIButton *dismissButton;
@property (nonatomic,strong) IBOutlet UIView *dismissHeader;
@property (nonatomic,strong) IBOutlet UILabel *messageLabel;
- (IBAction)dismissTapped:(id)sender;
- (void)sourceWithList:(NSArray*)list fromOrigin:(CGPoint)origin;
- (void)sourceWithList:(NSArray *)list fromOrigin:(CGPoint)origin andMessage:(NSString*)message;
- (void)killSelf;

@end
