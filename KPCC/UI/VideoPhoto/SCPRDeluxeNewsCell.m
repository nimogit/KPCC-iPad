//
//  SCPRDeluxeNewsCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRDeluxeNewsCell.h"
#import "global.h"
#import "SCPRDeluxeNewsViewController.h"

@implementation SCPRDeluxeNewsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)prime:(id)parent {
  
  if ( self.primed ) {
    return;
  }
  
#ifdef FAKE_NO_ASSET
  NSMutableDictionary *replacable = [[NSMutableDictionary alloc] init];
#endif
  for ( unsigned i = 0; i < [self.posts count]; i++ ) {
  
      NSString *fKey = [NSString stringWithFormat:@"facade%d",i];
      NSDictionary *dict = [self.posts objectAtIndex:i];
      SCPRDeluxeNewsFacadeViewController *facade = (SCPRDeluxeNewsFacadeViewController*)[self valueForKey:fKey];
      
#ifdef FAKE_NO_ASSET
    
    if ( [(SCPRDeluxeNewsViewController*)parent contentType] == ScreenContentTypeCompositePage ) {
      if ( !facade.embiggened ) {
        int rady = random() % 10;
        if ( rady > 7 ) {
          NSMutableDictionary *mutable = [dict mutableCopy];
          [mutable setObject:@{} forKey:@"assets"];
          dict = [NSDictionary dictionaryWithDictionary:mutable];
          [replacable setObject:dict forKey:[NSString stringWithFormat:@"%d",i]];
        }
      }
    }
#endif
      
      if ( [Utilities pureNil:[dict objectForKey:@"assets"]] ) {
        if ( !facade.embiggened ) {
          
          CGRect cFrame = facade.view.frame;
          NSDictionary *values = @{ @"frame" : [NSValue valueWithCGRect:cFrame],
                                    @"left" : @(self.leftSpacing.constant),
                                    @"top" : @(self.topSpacing.constant),
                                    @"between" : @(self.betweenConstraint.constant),
                                    @"width" : @(self.widthConstraint.constant),
                                    @"index" : @(i) };
                                    
          
          [facade.view removeFromSuperview];
          

          // Only display cells with no asset if it's not embiggened
          NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                                  xibForPlatformWithName:@"SCPRDeluxeNewsCellNoAsset"]
                                                           owner:facade
                                                         options:nil];
          UIView *v = [objects objectAtIndex:0];
          v.frame = cFrame;
          [self swapFacades:v container:facade values:values];
          
          [facade arm];
          facade.cardView.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
          facade.cardView.layer.borderWidth = 1.0;

          
        }
      }
      
      [facade mergeWithPVArticle:dict];
      facade.parentPVController = parent;

  }
  
  
  self.primed = YES;
  self.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  //self.backgroundColor = [UIColor orangeColor];
  
}

- (void)swapFacades:(UIView *)newFacade container:(SCPRDeluxeNewsFacadeViewController *)container values:(NSDictionary *)values {
  [self.containerSlateView addSubview:newFacade];
  [self.containerSlateView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [newFacade setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSString *hLayoutString = @"";
  NSString *vLayoutString = @"";
  NSDictionary *views = nil;
  NSInteger index = [values[@"index"] intValue];
  if ( index == 0 ) {
    
    hLayoutString = [NSString stringWithFormat:@"H:|-(%@)-[facade0(%@)]-(%@)-[facade1(%@)]",values[@"left"],values[@"width"],
                     values[@"between"],values[@"width"]];
    vLayoutString = [NSString stringWithFormat:@"V:|-(%@)-[facade0(%ld)]-(0)-|",values[@"top"],(long)newFacade.frame.size.height];
    views = @{ @"facade0" : newFacade, @"facade1" : self.facade1.view };
    
  } else {
    
    hLayoutString = [NSString stringWithFormat:@"H:|-(%@)-[facade0(%@)]-(%@)-[facade1(%@)]",values[@"left"],values[@"width"],values[@"between"],values[@"width"]];
    vLayoutString = [NSString stringWithFormat:@"V:|-(%@)-[facade1(%ld)]-(0)-|",values[@"top"],(long)newFacade.frame.size.height];
    views = @{ @"facade0" : self.facade0.view, @"facade1" : newFacade };
    
  }
  
  NSLog(@"hConstraints : %@",hLayoutString);
  NSLog(@"vConstraints : %@",vLayoutString);
  
  NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:hLayoutString
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
  
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:vLayoutString
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
  
  [self.containerSlateView addConstraints:hConstraints];
  [self.containerSlateView addConstraints:vConstraints];
  
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSString*)reuseIdentifier {
  NSDictionary *dict = [self.posts objectAtIndex:0];
  NSString *aspect = [[DesignManager shared] aspectCodeForContentItem:dict
                                                              quality:AssetQualityFull];
  aspect = [aspect stringByReplacingOccurrencesOfString:@"_clip"
                                             withString:@""];
  
  if ( [self.posts count] > 1 ) {
    aspect = @"";
  } else {
    if ( self.facade0.embiggened ) {
      aspect = [NSString stringWithFormat:@"big%@",aspect];
    } else {
      aspect = @"";
    }
  }
  
  NSString *orientation = self.landscape ? @"LND" : @"PT";
  NSString *rui = [NSString stringWithFormat:@"vpc%@%d%@",aspect,[self.posts count],orientation];
  
  return rui;
}

- (void)squish {
  if ( self.squished )
    return;
  
  for ( unsigned i = 0; i < [self.posts count]; i++ ) {
    NSString *fKey = [NSString stringWithFormat:@"facade%d",i];
    SCPRDeluxeNewsFacadeViewController *facade = (SCPRDeluxeNewsFacadeViewController*)[self valueForKey:fKey];
    facade.view.center = CGPointMake(facade.view.center.x,facade.view.center.y-23.0);
    //self.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height-11.0);
  }
  
  self.squished = YES;
}

- (void)unsquish {
  for ( unsigned i = 0; i < [self.posts count]; i++ ) {
    NSString *fKey = [NSString stringWithFormat:@"facade%d",i];
    SCPRDeluxeNewsFacadeViewController *facade = (SCPRDeluxeNewsFacadeViewController*)[self valueForKey:fKey];
    facade.view.center = CGPointMake(facade.view.center.x,facade.view.center.y+23.0);
    //self.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height+11.0);
  }
  self.squished = NO;
}

- (void)prepareForReuse {
  for ( unsigned i = 0; i < [self.posts count]; i++ ) {
    if ( self.squished ) {
      [self unsquish];
    }
    
    NSString *fKey = [NSString stringWithFormat:@"facade%d",i];
    SCPRDeluxeNewsFacadeViewController *facade = (SCPRDeluxeNewsFacadeViewController*)[self valueForKey:fKey];
    facade.blurbLabel.frame = facade.originalBlurbFrame;
    facade.headlineLabel.frame = facade.originalHeadlineFrame;
  
    self.primed = NO;

  }
  
  self.squished = NO;
}

@end
