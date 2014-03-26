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
    //dispatch_sync(dispatch_get_main_queue(), ^{
      NSString *fKey = [NSString stringWithFormat:@"facade%d",i];
      NSDictionary *dict = [self.posts objectAtIndex:i];
      SCPRDeluxeNewsFacadeViewController *facade = (SCPRDeluxeNewsFacadeViewController*)[self valueForKey:fKey];
      CGRect standInFrame = facade.view.frame;
      
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
          [facade.view removeFromSuperview];
          
          // Only display cells with no asset if it's not embiggened
          NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                                  xibForPlatformWithName:@"SCPRDeluxeNewsCellNoAsset"]
                                                           owner:facade
                                                         options:nil];
          UIView *v = [objects objectAtIndex:0];
          v.frame = standInFrame;
          [self addSubview:facade.view];
          
          [facade arm];
          facade.cardView.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
          facade.cardView.layer.borderWidth = 1.0;
          //facade.cardView.layer.cornerRadius = 3.0;
          
        }
      }
      
      [facade mergeWithPVArticle:dict];
      facade.parentPVController = parent;
    //});
  }
  
  
  self.primed = YES;
  self.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  //self.backgroundColor = [UIColor orangeColor];
  
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
  NSString *rui = [NSString stringWithFormat:@"vpc%@%d%@",aspect,(int)[self.posts count],orientation];
  
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
