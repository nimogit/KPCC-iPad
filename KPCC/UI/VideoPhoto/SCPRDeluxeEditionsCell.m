//
//  SCPRDeluxeEditionsCell.m
//  KPCC
//
//  Created by Ben on 8/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRDeluxeEditionsCell.h"
#import "SCPRDeluxeNewsViewController.h"

#import "global.h"

@implementation SCPRDeluxeEditionsCell

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

  }
  
  return self;
}

- (void)squish {
  
  if ( self.squished ) {
    return;
  }
  
  self.squished = YES;
  
}

- (void)prime:(id)parent {
  
  if ( !self.mainEdition ) {
    return;
  }
  
  if ( self.primed ) {
    [self.shortListController refresh];
    return;
  }
  
  if ( ![Utilities isIOS7] ) {
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
  }
  self.parentController = parent;
  self.primed = YES;
  
  [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                       xibForPlatformWithName:@"SCPREditionShortListViewController"]
                                owner:self.shortListController
                              options:nil];
  
  [self.contentView addSubview:self.shortListController.view];
  NSArray *typical = [[DesignManager shared] typicalConstraints:self.shortListController.view];
  [self.contentView addConstraints:typical];
  
  self.shortListController.view.frame = self.shortListController.view.frame;
  self.shortListController.fromNews = YES;
  
  [self.shortListController setupWithEdition:self.mainEdition];
  
  self.clipsToBounds = YES;
  
  
  [self.shortListController.drillDownButton addTarget:self
                                               action:@selector(handleEditionDrill)
                                     forControlEvents:UIControlEventTouchUpInside];
  
  
}

- (void)handleEditionDrill {
  SCPRDeluxeNewsViewController *dnc = (SCPRDeluxeNewsViewController*)self.parentController;
  NSArray *abstracts = [self.mainEdition objectForKey:@"abstracts"];
  [self.shortListController.spinner startAnimating];
  
  [UIView animateWithDuration:0.22 animations:^{
    self.shortListController.spinner.alpha = 1.0;
  } completion:^(BOOL finished) {
    
    [[NSNotificationCenter defaultCenter] addObserver:self.shortListController
                                             selector:@selector(hideSpinner)
                                                 name:@"editions_finished_building"
                                               object:nil];
    
    [dnc handleDrillDown:[abstracts objectAtIndex:0]];
  }];
  
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSString*)reuseIdentifier {
  return @"editions_cell";
}

@end
