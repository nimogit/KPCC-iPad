//
//  SCPRHBTView.m
//  KPCC
//
//  Created by Ben Hochberg on 4/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRHBTView.h"
#import "SCPRViewController.h"
#import "SCPRNewsPageViewController.h"
#import "SCPRSingleArticleViewController.h"

@implementation SCPRHBTView

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
    
    
  }
  
  return self;
}

- (void)makeTappable {
  UITapGestureRecognizer *imageTapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(drillDown)];
  [self.image1 addGestureRecognizer:imageTapper];
  
  self.image1.userInteractionEnabled = YES;
  
  UITapGestureRecognizer *headlineTapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(drillDown)];
  [self.headLine addGestureRecognizer:headlineTapper];
  
  self.headLine.userInteractionEnabled = YES;
  
  UITapGestureRecognizer *blurbTapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(drillDown)];
  [self.blurb1 addGestureRecognizer:blurbTapper];
  
  self.blurb1.userInteractionEnabled = YES;
  
}

- (void)drillDown {
  [self.navigator handleDrillDown:self.relatedArticle];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)arrange {
  
  //[[DesignManager shared] applyLeftOrangeShadowTo:self.matteView];
  
  self.listenNowButton.alpha = 0.0;
  self.addToQueueButton.alpha = 0.0;
  
  
  if ( self.grayDividerView ) {
    self.grayDividerView.vertical = YES;
    self.grayDividerView.frame = CGRectMake(self.grayDividerView.frame.origin.x,
                                            self.grayDividerView.frame.origin.y,
                                            self.grayDividerView.frame.size.width,
                                            self.frame.size.height);
    self.grayDividerView.padding = 8.0;
    [self.grayDividerView setNeedsDisplay];
  }
  
  /*self.matteView.layer.borderColor = [[DesignManager shared] kpccOrangeColor].CGColor;
  self.matteView.layer.borderWidth = 1.0;*/
  
  self.backgroundColor = [[DesignManager shared] number1pencilColor];
  
  // DISCRETE DRAWING OPERATIONS PER TEMPLATE
  if ( self.templateStyle == NewsPageTemplateBigTopSplitBtm ) {
    [self makeTappable];
    
    if ( [self.aspectCode isEqualToString:@"SingleTop43"] ||
      [self.aspectCode isEqualToString:@"SingleTop32"] ||
      [self.aspectCode isEqualToString:@"SingleTopSq"]  ) {
    

      
      /*[[DesignManager shared] alignTopOf:self.headLine
                              withView:self.image1];*/
    
      [[DesignManager shared] avoidNeighbor:self.headLine
                                 withView:self.byLine
                                direction:NeighborDirectionAbove
                                  padding:4.0];
    
      [[DesignManager shared] avoidNeighbor:self.byLine
                                   withView:self.blurb1
                                  direction:NeighborDirectionAbove
                                    padding:4.0];
      
      
      
      UIView *anchorToUse = /*imageY > blurbY ? */self.image1;
      
      [[DesignManager shared] avoidNeighbor:anchorToUse
                                   withView:self.listenNowButton
                                  direction:NeighborDirectionAbove
                                    padding:4.0];
      
      [[DesignManager shared] avoidNeighbor:anchorToUse
                                   withView:self.addToQueueButton
                                  direction:NeighborDirectionAbove
                                    padding:4.0];
      
      [[DesignManager shared] alignLeftOf:self.addToQueueButton
                                 withView:anchorToUse];
      
      [[DesignManager shared] avoidNeighbor:self.addToQueueButton
                                   withView:self.listenNowButton
                                  direction:NeighborDirectionToLeft
                                    padding:12.0];
      
      
      if ( self.blurb1.frame.origin.y+self.blurb1.frame.size.height > self.frame.size.height ) {
        self.blurb1.frame = CGRectMake(self.blurb1.frame.origin.x,
                                          self.blurb1.frame.origin.y,
                                          self.blurb1.frame.size.width,
                                          self.frame.size.height-4.0);
      }
      
      
      
      
    
    }
  }
  if ( self.templateStyle == NewsPageTemplateSplitTopSplitBtm ) {
    [self makeTappable];
    if ( [self.aspectCode isEqualToString:@"SingleTop43"] ||
        [self.aspectCode isEqualToString:@"SingleTop32"] ||
        [self.aspectCode isEqualToString:@"SingleTopSq"] ||
        [self.aspectCode isEqualToString:@"SingleTop23"] ) {
      
      [[DesignManager shared] avoidNeighbor:self.headLine
                                   withView:self.byLine
                                  direction:NeighborDirectionAbove
                                    padding:4.0];
      
      [[DesignManager shared] avoidNeighbor:self.byLine
                                   withView:self.blurb1
                                  direction:NeighborDirectionAbove
                                    padding:4.0];
      
      if ( self.blurb1.frame.origin.y+self.blurb1.frame.size.height > self.matteView.frame.size.height ) {
        self.blurb1.frame = CGRectMake(self.blurb1.frame.origin.x,
                                          self.blurb1.frame.origin.y,
                                          self.blurb1.frame.size.width,
                                          self.matteView.frame.size.height-4.0);
      }
      
    }
  }
  
  // SHARED DRAWING OPERATIONS
  if ( [self.aspectCode isEqualToString:@"Split43"] ||
      [self.aspectCode isEqualToString:@"Split32"] ||
      [self.aspectCode isEqualToString:@"SplitSq"] ) {
    
    
    if ( self.rightSide ) {
      self.image1.frame = CGRectMake(self.headLine.frame.origin.x,
                                        self.image1.frame.origin.y,
                                        self.image1.frame.size.width,
                                        self.image1.frame.size.height);
    }
    
    [[DesignManager shared] avoidNeighbor:self.headLine
                                 withView:self.byLine
                                direction:NeighborDirectionAbove
                                  padding:4.0];
    
    [[DesignManager shared] avoidNeighbor:self.byLine
                                 withView:self.blurb1
                                direction:NeighborDirectionAbove
                                  padding:4.0];
    
  }
  if ( [self.aspectCode isEqualToString:@"Split23"] ||
      [self.aspectCode isEqualToString:@"Split34"] ||
      [self.aspectCode isEqualToString:@"SingleTop23"] ) {
    
    [[DesignManager shared] avoidNeighbor:self.headLine
                                 withView:self.byLine
                                direction:NeighborDirectionAbove
                                  padding:4.0];
    
  }
  
  
  if ( [self.aspectCode isEqualToString:@"SingleArticle"] ) {
    
  }
  
}

- (void)mergeWithArticle {
  [self mergeWithArticle:NO];
}
- (void)mergeWithArticle:(BOOL)blurry {
  if ( !self.relatedArticle ) {
    return;
  }
  
  NSDictionary *thing = self.relatedArticle;
  NSString *baseHeadline = [NSString stringWithFormat:@"headLine"];
  NSString *baseBlurb = [NSString stringWithFormat:@"blurb%d",1];
  NSString *baseImage = [NSString stringWithFormat:@"image%d",1];
  NSString *baseByline = [NSString stringWithFormat:@"byLine"];
  UIImageView *image = (UIImageView*)[self valueForKey:baseImage];
  if ( image ) {
#ifdef TESTING_SPECIAL_UI
    NSString *imgUrl = [Utilities extractImageURLFromBlob:thing
                                                  quality:AssetQualityFull];
#else
    NSString *imgUrl = [Utilities extractImageURLFromBlob:thing
                                                  quality:AssetQualityFull];
#endif
    if ( ![Utilities pureNil:imgUrl] ) {
      //[image loadImage:imgUrl quietly:YES blurry:blurry];
    }
  }
  
  UILabel *byline = (UILabel*)[self valueForKey:baseByline];
  if ( byline ) {
    
    NSString *bylineKey = self.snapshotContent ? @"source" : @"byline";
    NSString *publishedKey = self.snapshotContent ? @"article_published_at" : @"published_at";
    
    if ( ![Utilities pureNil:[thing objectForKey:bylineKey]] &&
        ![Utilities pureNil:[thing objectForKey:publishedKey]] ) {
      NSString *bylineStr = [thing objectForKey:bylineKey];
      NSString *dateStr = [thing objectForKey:publishedKey];
      NSDate *dateObj = [Utilities dateFromRFCString:dateStr];
      NSString *pretty = [NSDate stringFromDate:dateObj
                                     withFormat:@"MMM d, YYYY, h:mm a"];
#ifdef TESTING_SPECIAL_UI
      byline.text = [NSString stringWithFormat:@"%@ | %@",bylineStr,pretty];
#else
      [byline snapText:[NSString stringWithFormat:@"%@ | %@",bylineStr,pretty]
                  bold:NO
       respectHeight:YES];
#endif
      byline.alpha = 1.0;
    } else {
      byline.alpha = 0.0;
    }
  }
  UILabel *headline = (UILabel*)[self valueForKey:baseHeadline];
  if ( headline ) {
    
    NSString *headlineKey = self.snapshotContent ? @"headline" : @"title";
    if ( ![Utilities pureNil:[thing objectForKey:headlineKey]] ) {
#ifdef TESTING_SPECIAL_UI
      headline.text = [thing objectForKey:headlineKey];
#else
      [headline snapText:[thing objectForKey:headlineKey]
                    bold:YES
       respectHeight:YES];
#endif
      headline.alpha = 1.0;
    }
  }
  
  UILabel *blurb = (UILabel*)[self valueForKey:baseBlurb];
  if ( blurb ) {
    
    NSString *blurbKey = self.snapshotContent ? @"summary" : @"teaser";
    if ( ![Utilities pureNil:[thing objectForKey:blurbKey]] ) {
      NSString *sanitized = [Utilities unwebbifyString:[thing objectForKey:blurbKey]];
      [blurb modText:sanitized];
      blurb.alpha = 1.0;
    }
  }
  
  UILabel *category = (UILabel*)[self valueForKey:@"topicLabel"];
  if ( category ) {
    if ( ![Utilities pureNil:[thing objectForKey:@"category"]] ) {
      NSDictionary *topic = [thing objectForKey:@"category"];
      NSString *title = [topic objectForKey:@"title"];
      if ( ![Utilities pureNil:title] ) {
        category.text = title;
      } else {
        category.text = @"Miscellaneous";
      }
    } else {
      category.text = @"Miscellaneous";
    }
  }
  
  self.alpha = 1.0;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if ( self.singleArticle ) {
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(closeGate)
                                 userInfo:nil
                                  repeats:NO];
  }
}

- (void)closeGate {
  SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.parentContainer;
  svc.gateOpen = NO;
}

- (void)flush {
  self.headLine = nil;
  self.image1 = nil;
  self.image2 = nil;
  self.image3 = nil;
  self.byLine = nil;
  self.blurb1 = nil;
  self.blurb2 = nil;
  self.blurb3 = nil;
  self.blurb4 = nil;
}

@end
