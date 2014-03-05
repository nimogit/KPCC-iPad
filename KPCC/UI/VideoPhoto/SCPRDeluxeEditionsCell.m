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
  
  self.shortListController.view.frame = self.shortListController.view.frame;
  self.shortListController.fromNews = YES;
  [self.shortListController setupWithEdition:self.mainEdition];
  self.clipsToBounds = YES;
  
  [self.shortListController shrink];
  [self.shortListController pushTitleUp];
  //self.shortListController.timestampLabel.alpha = 0.0;
  
  [[DesignManager shared] avoidNeighbor:self.shortListController.shortListTitleLabel
                               withView:self.shortListController.timestampLabel
                              direction:NeighborDirectionAbove
                                padding:3.0];
  
  [self.shortListController.drillDownButton addTarget:self
                                               action:@selector(handleEditionDrill)
                                     forControlEvents:UIControlEventTouchUpInside];
  
  if ( ![Utilities isIOS7] ) {
    
    if ( [Utilities isLandscape] ) {
      CGRect r = CGRectMake(0.0, 0.0, self.frame.size.width,
                            self.frame.size.height);
      CGRect big = CGRectMake(0.0, 0.0, self.frame.size.width,
                              768.0);
      self.shortListController.cruxView.frame = r;
      [self.shortListController.leadAssetImage removeFromSuperview];
      self.contentView.frame = r;
      [self.shortListController.view addSubview:self.shortListController.leadAssetImage];
      [self.shortListController.view sendSubviewToBack:self.shortListController.leadAssetImage];
      self.shortListController.leadAssetImage.frame = big;
      
      NSString *asset = [Utilities extractImageURLFromBlob:self.mainEdition
                                                   quality:AssetQualityFull
                                              forceQuality:YES];
      [self.shortListController.leadAssetImage loadImage:asset];
      [self.contentView addSubview:self.shortListController.view];
    } else {
      [self addSubview:self.shortListController.view];
    }
    
  } else {
    [self addSubview:self.shortListController.view];
  }
  
  
  
  
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
