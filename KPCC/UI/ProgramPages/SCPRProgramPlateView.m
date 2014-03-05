//
//  SCPRProgramPlateView.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/25/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRProgramPlateView.h"
#import "global.h"
#import "SCPRProgramAZViewController.h"

@implementation SCPRProgramPlateView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if ( self ) {
    self.clipsToBounds = YES;
    self.frame = self.frame;

  }
  
  return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)primeWithProgram:(NSDictionary *)program {
  
  self.blueBarView.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  self.blueSeatView.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  
  BOOL shift = NO;
  
  SCPRProgramAZViewController *az = (SCPRProgramAZViewController*)self.parentController;
  if ( !az.editMode ) {
    self.checkmarkImage.alpha = 0.0;
    self.blueSeatView.alpha = 0.0;
    self.blueBarView.alpha = 0.0;
    self.gradientImage.alpha = 0.0;
    self.programImage.alpha = 0.0;
    self.autoAddSeat.alpha = 0.0;
    self.titleLabel.frame = az.originalTitleFrameSize;
  } else {
    self.titleLabel.frame = az.originalTitleFrameSize;
    shift = YES;
  }
  
  self.slug = [program objectForKey:@"slug"];
  self.programImage.clipsToBounds = YES;
  NSString *titleized = [[ContentManager shared] imageNameForProgram:program];
  
  
  [self.favoriteLabel titleizeText:self.favoriteLabel.text
                              bold:NO];

  NSString *small = [NSString stringWithFormat:@"small_%@",titleized];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    __block UIImage *img = [UIImage imageNamed:small];
    dispatch_async(dispatch_get_main_queue(), ^{
      self.programImage.image = img;
      [UIView animateWithDuration:0.44 animations:^{
        self.programImage.alpha = 1.0;
        self.gradientImage.alpha = 1.0;
      }];
      
    });
  });
  
  self.currentImageTitle = titleized;
  
  NSString *title = [program objectForKey:@"title"];
  if ( [title length] == 26 ) {
    NSArray *spacing = [title componentsSeparatedByString:@" "];
    if ( [spacing count] > 1 ) {
      NSString *last = [spacing lastObject];
      NSString *newTitle = @"";
      for ( unsigned i = 0; i < [spacing count]; i++ ) {
        if ( i == [spacing count]-1 ) {
          break;
        }
        if ( i > 0 ) {
          newTitle = [newTitle stringByAppendingString:@" "];
        }
        newTitle = [newTitle stringByAppendingString:[spacing objectAtIndex:i]];
      }
      title = [NSString stringWithFormat:@"%@\n%@",newTitle,last];
    }
  }
  
  [self.titleLabel titleizeText:title
                           bold:NO
   respectHeight:YES];
  
  if ( shift ) {
    [[DesignManager shared] avoidNeighbor:self.autoAddSeat
                               withView:self.titleLabel
                              direction:NeighborDirectionBelow
                                padding:3.0];
  } else {
    
    self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x,
                                       self.frame.size.height-self.titleLabel.frame.size.height-10.0,
                                       self.titleLabel.frame.size.width,
                                       self.titleLabel.frame.size.height);
    self.originalTitleFrame = self.titleLabel.frame;
    
  }
  
}

- (void)updateSelf {
  SCPRProgramAZViewController *az = (SCPRProgramAZViewController*)self.parentController;
  [UIView animateWithDuration:0.22 animations:^{
    if ( az.editMode ) {
      
      [[DesignManager shared] avoidNeighbor:self.autoAddSeat
                                   withView:self.titleLabel
                                  direction:NeighborDirectionBelow
                                    padding:3.0];
      
      if ( self.favorite ) {
        self.blueBarView.alpha = 0.0;
        self.blueSeatView.alpha = 0.0;
        self.checkmarkImage.alpha = 1.0;

      } else {
        self.checkmarkImage.alpha = 0.0;
      }
      self.autoAddSeat.alpha = 1.0;
      
    } else {
      
      self.titleLabel.frame = self.originalTitleFrame;
      self.checkmarkImage.alpha = 0.0;
      self.autoAddSeat.alpha = 0.0;
      if ( self.favorite ) {
        self.blueSeatView.alpha = 1.0;
        self.blueBarView.alpha = 1.0;
      } else {
        self.blueBarView.alpha = 0.0;
        self.blueSeatView.alpha = 0.0;
      }
    }
  }];

}

- (void)primeForFavorite:(NSNotification*)note {
  NSDictionary *favePacket = [note object];
  if ( ![[favePacket objectForKey:@"slug"] isEqualToString:self.slug] ) {
    return;
  }
  

  NSNumber *fave = [favePacket objectForKey:@"favorited"];
  [self favoriteUI:([fave intValue] != 0)];
  
}

- (void)favoriteUI:(BOOL)fave {
  SCPRProgramAZViewController *az = (SCPRProgramAZViewController*)self.parentController;
  self.favorite = fave;
  if ( !fave ) {
  
    [self primeAutoAdd:NO];
    self.blueSeatView.alpha = 0.0;
    self.blueBarView.alpha = 0.0;
    self.checkmarkImage.alpha = 0.0;

  } else {

    if ( az.editMode ) {
      
      self.checkmarkImage.alpha = 1.0;
      self.blueSeatView.alpha = 0.0;
      self.blueBarView.alpha = 0.0;
      
    } else {
      
      self.checkmarkImage.alpha = 0.0;
      self.blueSeatView.alpha = 1.0;
      self.blueBarView.alpha = 1.0;
      
    }

  }
}

- (IBAction)autoAddTapped:(id)sender {
#ifndef STUB_AUTOADD
  [self primeAutoAdd:!self.autoadd];
#else
  
  [[AnalyticsManager shared] logEvent:@"user_wants_to_autoadd_program_faves"
                       withParameters:nil];
  
  [[[UIAlertView alloc] initWithTitle:@"Coming Soon"
                              message:@"This feature will be available in a build in the very near future!"
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
#endif

}

- (void)primeAutoAdd:(BOOL)autoadd {
  self.autoadd = autoadd;
  SCPRProgramAZViewController *az = (SCPRProgramAZViewController*)self.parentController;
  
  if ( self.autoadd ) {
    
    [az.autoAddItems setObject:@1 forKey:self.slug];
    
  
    
    [[DesignManager shared] globalSetImageTo:@"green_checkmark_circle.png"
                                   forButton:self.autoAddButton];
    if ( !self.favorite ) {
      
      [az.checkedItems setObject:[az.programs objectAtIndex:self.cellIndex]
                          forKey:self.slug];
      
      [self favoriteUI:YES];
    }
    
  } else {
    
    [az.autoAddItems setObject:@0 forKey:self.slug];
    
    [[DesignManager shared] globalSetImageTo:@"gray_minus_circle.png"
                                   forButton:self.autoAddButton];
  }
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.autoAddButton.titleLabel.font.pointSize]
                                forButton:self.autoAddButton];
  

}

- (void)pulse {
  
  /*
  if ( self.checkmarkImage.image ) {
    
    
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      self.pulsing = YES;
      self.checkmarkImage.transform = CGAffineTransformMakeScale(1.25, 1.25);
      self.checkmarkImage.alpha = 0.25;
      
    } completion:^(BOOL finished) {
  
      [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.checkmarkImage.transform = CGAffineTransformMakeScale(1.0, 1.0);
        self.checkmarkImage.alpha = 1.0;
      } completion:^(BOOL finished) {
        if ( self.cancelAnimRequested ) {
          self.cancelAnimRequested = NO;
          self.pulsing = NO;
          return;
        } else {
          [self pulse];
        }
      }];
    }];
    
  }*/
}

- (void)stopPulsing {
  /*
  if ( !self.pulsing ) {
    return;
  }
  
  self.cancelAnimRequested = YES;*/
}

- (void)prepareForReuse {
  SCPRProgramAZViewController *az = (SCPRProgramAZViewController*)self.parentController;
  if ( !az.editMode ) {
    self.programImage.alpha = 0.0;
    self.programImage.image = nil;
    self.checkmarkImage.alpha = 0.0;
    self.blueBarView.alpha = 0.0;
    self.blueSeatView.alpha = 0.0;
    self.currentImageTitle = nil;
    self.gradientImage.alpha = 0.0;
    self.slug = nil;
    self.titleLabel.frame = az.originalTitleFrameSize;
  } else {
    
    self.autoAddSeat.alpha = 1.0;
    self.titleLabel.frame = az.originalTitleFrameSize;
    [[DesignManager shared] avoidNeighbor:self.autoAddSeat
                                 withView:self.titleLabel
                                direction:NeighborDirectionBelow
                                  padding:3.0];
  }
  self.cellIndex = -1;
  self.favorite = NO;
  self.autoadd = NO;
}

- (NSString*)reuseIdentifier {
  return @"plate_cell";
}


@end
