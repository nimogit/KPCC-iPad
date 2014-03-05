//
//  SCPRCompDoubleCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRCompDoubleCell.h"
#import "global.h"

@implementation SCPRCompDoubleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSString*)reuseIdentifier {
  return @"comp_double";
}

- (void)prepareForReuse {
  self.articleCell0.headlineLabel.frame = CGRectMake(self.articleCell0.headlineLabel.frame.origin.x,
                          self.articleCell0.headlineLabel.frame.origin.y,
                          self.articleCell0.headlineLabel.frame.size.width,
                          46.0);
  self.articleCell1.headlineLabel.frame = CGRectMake(self.articleCell1.headlineLabel.frame.origin.x,
                                                     self.articleCell1.headlineLabel.frame.origin.y,
                                                     self.articleCell1.headlineLabel.frame.size.width,
                                                     46.0);
  self.articleCell0.splashImage.image = nil;
  
  self.articleCell0.topicBannerView.frame = self.articleCell0.originalTopicSeatFrame;
  self.articleCell0.topicLabel.frame = self.articleCell0.originalTopicLabelFrame;
  self.articleCell1.topicBannerView.frame = self.articleCell1.originalTopicSeatFrame;
  self.articleCell1.topicLabel.frame = self.articleCell1.originalTopicLabelFrame;
  
  self.articleCell1.splashImage.image = nil;
  
  self.articleCell0.locked = NO;
  self.articleCell1.locked = NO;
  
  [self.articleCell0 arm];
  [self.articleCell1 arm];
  
}

- (void)mergeWithArticles:(NSArray *)articles {
  self.articleFacades = [[NSMutableArray alloc] init];
  for ( unsigned i = 0; i < [articles count]; i++ ) {
    NSDictionary *article = [articles objectAtIndex:i];
    NSString *key = [NSString stringWithFormat:@"articleCell%d",i];
    SCPRCompositeCellViewController *cell = [self valueForKey:key];
    NSString *imgUrl = [Utilities extractImageURLFromBlob:article
                                                  quality:AssetQualityLarge];
    [cell.splashImage loadImage:imgUrl quietly:NO];
    cell.splashImage.clipsToBounds = YES;
    cell.relatedArticle = article;
    NSString *title = [article objectForKey:@"short_title"];
    [cell.headlineLabel titleizeText:title
                                bold:YES
                       respectHeight:YES];
    
    if ( ![Utilities pureNil:[article objectForKey:@"category"]] ) {
      NSDictionary *topic = [article objectForKey:@"category"];
      
      
      NSString *catTitle = [topic objectForKey:@"title"];
      if ( ![Utilities pureNil:catTitle] ) {
        catTitle = [catTitle uppercaseString];
        if ( [catTitle rangeOfString:@"ENVIRONMENT"].location != NSNotFound ) {
          cell.topicBannerView.frame = CGRectMake(cell.topicBannerView.frame.origin.x,
                                                  cell.topicBannerView.frame.origin.y,
                                                  cell.topicBannerView.frame.size.width+kWiderBannerPush,
                                                  cell.topicBannerView.frame.size.height);
          cell.topicLabel.frame = CGRectMake(cell.topicLabel.frame.origin.x,
                                                  cell.topicLabel.frame.origin.y,
                                                  cell.topicLabel.frame.size.width+kWiderBannerPush,
                                                  cell.topicLabel.frame.size.height);
        }
        [cell.topicLabel titleizeText:[catTitle uppercaseString]
                                 bold:YES
                        respectHeight:NO];
      } else {
        [cell.topicLabel titleizeText:@"TRENDING"
                                 bold:YES
         respectHeight:YES];
      }
    } else {
      [cell.topicLabel titleizeText:@"TRENDING"
                               bold:YES
       respectHeight:YES];
    }
    cell.topicLabel.center = CGPointMake(cell.topicLabel.center.x,
                                         cell.topicBannerView.frame.size.height/2.0-1.0);
    [self.articleFacades addObject:cell];
  }
  

}

@end
