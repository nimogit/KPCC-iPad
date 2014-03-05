//
//  SCPRCompSingleCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRCompSingleCell.h"
#import "global.h"

@implementation SCPRCompSingleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)prepareForReuse {
  
  self.articleCell0.topicBannerView.frame = self.articleCell0.originalTopicSeatFrame;
  self.articleCell0.topicLabel.frame = self.articleCell0.originalTopicLabelFrame;
  self.articleCell0.splashImage.image = nil;
  self.articleCell0.headlineLabel.frame = self.articleCell0.originalHeadlineLabelFrame;
  self.articleCell0.locked = NO;
  [self.articleCell0 arm];
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)mergeWithArticles:(NSArray *)articles {
  self.articleFacades = [[NSMutableArray alloc] init];
  self.relatedArticles = articles;
  for ( unsigned i = 0; i < [articles count]; i++ ) {
    NSDictionary *article = [articles objectAtIndex:i];
    NSString *key = [NSString stringWithFormat:@"articleCell%d",i];
    SCPRCompositeCellViewController *cell = [self valueForKey:key];
    
    NSString *imgUrl = [Utilities extractImageURLFromBlob:article
                                                  quality:AssetQualityFull];
    [cell.splashImage loadImage:imgUrl quietly:NO];
    
    NSString *title = [article objectForKey:@"short_title"];
    [cell.headlineLabel titleizeText:title
                                bold:YES
                       respectHeight:YES];
    cell.splashImage.clipsToBounds = YES;
    cell.relatedArticle = article;
    if ( self.index == 0 ) {
      [cell.topicLabel titleizeText:@"TOP STORY"
                               bold:YES
       respectHeight:YES];
    } else {

      [cell.topicLabel titleizeText:@"TRENDING"
                               bold:YES
       respectHeight:YES];
      
      [self.articleFacades addObject:cell];
    }
    cell.topicLabel.center = CGPointMake(cell.topicLabel.center.x,
                                         cell.topicBannerView.frame.size.height/2.0-1.0);
  }
  
}

- (NSString*)reuseIdentifier {
  return @"comp_single";
}



@end
