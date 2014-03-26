//
//  SCPRDrawerCell.m
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRDrawerCell.h"
#import "global.h"
#import "SCPRDrawerViewController.h"
#import "SCPRTopicSchema.h"
#import "SCPRViewController.h"

@implementation SCPRDrawerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if ( self ) {
    self.labelSeat.backgroundColor = [[DesignManager shared] deepCharcoalColor];
  }
  
  return self;
}

- (NSString*)reuseIdentifier {
  return @"drawer_cell";
}

- (void)prepareForReuse {
  self.indexHint = -1;
  self.submenuTableView.delegate = nil;
  self.submenuTableView.dataSource = nil;
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  /*[super setSelected:selected animated:animated];
  if ( selected ) {
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            350.0);
  } else {
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            44.0);
  }
  SCPRDrawerViewController *dvc = (SCPRDrawerViewController*)self.parentMenuController;
  [dvc.internalTable reloadData];*/
}

- (CGFloat)determineHeightForDatasource {
  
  CGFloat f = 50.0+self.submenuTableView.frame.size.height;
  return f;
}

- (NSMutableArray*)acquireContentsFromSchema {
  
  if ( self.indexHint == - 1 ) {
    // unprepped
    return nil;
  }
  
  SCPRDrawerViewController *dvc = (SCPRDrawerViewController*)self.parentMenuController;
  NSMutableArray *schema = [dvc.schema mutableCopy];
  
  // Get topic object associated with this row's heading
  NSMutableDictionary *topic = [schema objectAtIndex:self.indexHint];
  
  // Get list of sub-topics
  NSMutableArray *contents = [topic objectForKey:@"submenu"];
  return contents;
}

- (void)placeObservers {

}

- (void)setAlpha:(CGFloat)alpha {
  alpha = 1.0;
}

#pragma mark - Utilities
- (NSString*)stringForCellTapped:(NSIndexPath *)indexPath {
  //NSString *submenu = [[self acquireContentsFromSchema] objectAtIndex:indexPath.row];
  NSString *title = self.menuTitle;

  return [NSString stringWithFormat:@"%@-%ld",title,
          (long)indexPath.row];
}

#pragma mark - UITableView sh*t
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSMutableArray *schema = [self acquireContentsFromSchema];
  if ( schema ) {
    return [schema count];
  }
  
  return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *cell = [self.submenuTableView dequeueReusableCellWithIdentifier:@"submenu_cell"];
  if ( !cell ) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:@"submenu_cell"];
  }
  
  NSMutableArray *contents = [self acquireContentsFromSchema];
  if ( contents ) {
    [cell.textLabel titleizeText:[contents objectAtIndex:indexPath.row]
                            bold:NO
                   respectHeight:YES];
    cell.textLabel.textColor = [[DesignManager shared] number2pencilColor];
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SCPRViewController *vc = [[Utilities del] viewController];
  [vc handleDrawerCommand:[NSString stringWithFormat:@"%ld|%ld",(long)self.indexHint,(long)indexPath.row]];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( indexPath.row == [[self acquireContentsFromSchema] count]-1) {
    //[self placeObservers];
  }
  
  cell.textLabel.font = [UIFont systemFontOfSize:14.0];
  [cell.textLabel titleizeText:cell.textLabel.text
                          bold:NO
                 respectHeight:YES];
}

@end
