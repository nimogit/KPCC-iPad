//
//  SCPRSnapshotCell.m
//  KPCC
//
//  Created by Ben Hochberg on 4/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSnapshotCell.h"
#import "global.h"

@implementation SCPRSnapshotCell

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goDark:)
                                                 name:@"go_dark"
                                               object:nil];
  }
  
  return self;
}

- (void)goDark:(NSNotification*)note {
  
  NSNumber *index = (NSNumber*)[note object];
  if ( [index intValue] == self.index ) {
    return;
  }
  
  [self cloakCard];
  
}

- (void)cloakCard {
  [UIView animateWithDuration:0.75 animations:^{
    self.cloak.alpha = 1.0;
  }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  

  
}

/*
- (void)drawRect:(CGRect)rect {
  


  
}
*/

- (void)animateCard {
  self.containerView.alpha = 0.0;
  self.containerView.frame = CGRectMake(self.frame.size.width,0.0,
                                        self.containerView.frame.size.width,
                                        self.containerView.frame.size.height);
  
  
  [UIView animateWithDuration:0.55 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    self.containerView.frame = CGRectMake(0.0,0.0,self.containerView.frame.size.width,
                                          self.containerView.frame.size.height);
    self.containerView.alpha = 1.0;
    self.cloak.alpha = 0.0;
    
  } completion:^(BOOL finished) {
    
  
    
  }];
  
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
