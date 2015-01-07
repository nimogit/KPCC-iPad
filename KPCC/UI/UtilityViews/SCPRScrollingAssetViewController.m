//
//  SCPRScrollingAssetViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRScrollingAssetViewController.h"
#import "global.h"

@interface SCPRScrollingAssetViewController ()

@end

static CGFloat expanseLimit = 100.0;

@implementation SCPRScrollingAssetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  

  self.titleCaptionLabel.alpha = 0.0;
  self.footerCaption.alpha = 0.0;
  self.mainCaptionLabel.alpha = 0.0;
  self.progressLabel.alpha = 0.0;
  self.headerCaption.alpha = 0.0;
  self.footerCaption.alpha = 0.0;
  
  if ( [Utilities isLandscape] ) {
    if ( ![Utilities isIOS7] ) {
      for ( UIView *v in [self.view subviews] ) {
        v.center = CGPointMake(v.center.x,v.center.y-20.0);
#ifdef DEBUG
        //v.backgroundColor = [[DesignManager shared] turquoiseCrystalColor:0.42];
#endif
      }
    }
  }
  
  self.originalBylineHeight = self.footerCaption.frame;
  self.originalCaptionHeight = self.mainCaptionLabel.frame;
  self.originalHeadlineHeight = self.titleCaptionLabel.frame;
  self.originalCaptionSeatFrame = self.captionSeat.frame;
  [self.progressLabel titleizeText:@"•••"
                              bold:NO
                     respectHeight:NO];
  
  [self.headerCaption snapText:self.headerCaption.text bold:NO];
  [self.footerCaption snapText:self.footerCaption.text bold:NO];
  
  self.scroller.delegate = self;
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidLayoutSubviews {
  if ( self.needsSetup ) {
    self.needsSetup = NO;
    [self sourceWithArticle:self.article];
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deactivate {
  self.article = nil;
  for ( UIView *sv in self.scroller.subviews ) {
    [sv removeFromSuperview];
  }
  self.scroller = nil;
  [self.imageVector removeAllObjects];
  self.imageVector = nil;
}

- (void)sourceWithArticle:(NSDictionary *)article {
  self.article = article;
  [self.spinner startAnimating];
  self.miniQueue = [[NSOperationQueue alloc] init];
  self.actualSizeLookupHash = [[NSMutableDictionary alloc] init];
  [self.scroller setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSLog(@" //// Removing %ld views ////", (long)self.scroller.subviews.count);
  
  for ( UIView *v in self.scroller.subviews ) {
    [v removeFromSuperview];
  }
  
  NSArray *assets = [article objectForKey:@"assets"];
  
  self.imageVector = [[NSMutableArray alloc] init];
  self.ownerVector = [[NSMutableArray alloc] init];
  self.scroller.contentSize = CGSizeMake(self.scroller.frame.size.width*[assets count],
                                         self.scroller.frame.size.height);
  
  for ( unsigned i = 0; i < [assets count]; i++ ) {
    UIView *seat = [[UIView alloc] initWithFrame:CGRectMake((i*self.scroller.frame.size.width),
                                                            0.0,
                                                            self.scroller.frame.size.width,
                                                            self.scroller.frame.size.height)];
    
    
    seat.backgroundColor = [UIColor clearColor];
    
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
    iv.frame = CGRectMake(0.0,0.0,self.scroller.frame.size.width,
                          self.scroller.frame.size.height);
    
    [self.scroller printDimensionsWithIdentifier:@"Image Scroller"];
    
    iv.center = CGPointMake(seat.frame.size.width/2.0,
                           seat.frame.size.height/2.0);
    [seat addSubview:iv];
    iv.backgroundColor = [UIColor clearColor];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.clipsToBounds = YES;
    [self.scroller addSubview:seat];
    
    NSDictionary *asset = [assets objectAtIndex:i];
    NSMutableDictionary *metaData = [[NSMutableDictionary alloc] init];
    if ( ![Utilities pureNil:[asset objectForKey:@"owner"]] ) {
      [metaData setObject:[asset objectForKey:@"owner"]
                   forKey:@"owner"];
    } else {
      [metaData setObject:@"" forKey:@"owner"];
    }
    
    if ( ![Utilities pureNil:[asset objectForKey:@"title"]] ) {
      [metaData setObject:[asset objectForKey:@"title"]
                   forKey:@"title"];
    } else {
      [metaData setObject:@"" forKey:@"title"];
    }
    
    if ( ![Utilities pureNil:[asset objectForKey:@"caption"]] ) {
      [metaData setObject:[asset objectForKey:@"caption"]
                   forKey:@"caption"];
    } else {
      [metaData setObject:@""
                   forKey:@"caption"];
    }
    
    [self.ownerVector addObject:metaData];
    
    NSDictionary *full = [asset objectForKey:@"full"];
    NSString *url = [full objectForKey:@"url"];
    if ( [url rangeOfString:@"http://"].location != NSNotFound ||
        [url rangeOfString:@"https://"].location != NSNotFound ) {
      //[iv loadImage:[full objectForKey:@"url"]];
      [iv loadImage:[full objectForKey:@"url"]
            quietly:NO
              queue:self.miniQueue
         completion:^{
           
           CGRect r = [iv frameForImage];
           NSValue *v = [NSValue valueWithCGRect:r];
           [self.actualSizeLookupHash setObject:v
                                         forKey:[NSString stringWithFormat:@"%d",i]];
           if ( self.currentIndex == i) {
             [self applyMeta:metaData
                  withOffset:i];
           }
           
         }];
      
    } else {
      [iv loadLocalImage:[full objectForKey:@"url"]
                 quietly:NO];
    }
    
    [self.imageVector addObject:iv];

  }
  
  NSMutableDictionary *meta = [self.ownerVector objectAtIndex:0];
  [self applyMeta:meta withOffset:0];
  
  [self.view layoutIfNeeded];
  [self.scroller layoutIfNeeded];
  [self.scroller setContentOffset:CGPointMake(self.currentIndex*self.scroller.frame.size.width,
                                              0.0)];

}



#pragma mark - ScrollView
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [UIView animateWithDuration:0.15 animations:^{
    self.titleCaptionLabel.alpha = 0.0;
    self.footerCaption.alpha = 0.0;
    self.mainCaptionLabel.alpha = 0.0;
    self.progressLabel.alpha = 0.0;
  }];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  NSInteger offset = self.scroller.contentOffset.x / self.scroller.frame.size.width;
  NSDictionary *meta = [self.ownerVector objectAtIndex:offset];  
  [self applyMeta:meta withOffset:offset];
  self.currentIndex = offset;
  
}

- (void)applyMeta:(NSDictionary *)meta withOffset:(NSInteger)offset {
  
  NSString *key = [NSString stringWithFormat:@"%d",offset];
  BOOL fadein = NO;
  if ( ![self.actualSizeLookupHash objectForKey:key] ) {

    return;
  } else {
    fadein = YES;
  }
  
    self.titleCaptionLabel.frame = self.originalHeadlineHeight;
    self.footerCaption.frame = self.originalBylineHeight;
    self.mainCaptionLabel.frame = self.originalCaptionHeight;
    
    [self.footerCaption titleizeText:[meta objectForKey:@"owner"]
                                bold:NO
     respectHeight:YES];
    [self.titleCaptionLabel titleizeText:[self.article objectForKey:@"title"]
                                    bold:NO
     respectHeight:YES];
    [self.mainCaptionLabel titleizeText:[meta objectForKey:@"caption"]
                                   bold:NO
     respectHeight:YES];
  
#ifdef DEBUG
    //self.mainCaptionLabel.backgroundColor = [UIColor greenColor];
#endif
  
    NSString *progress = [NSString stringWithFormat:@"%d of %d",offset+1,[self.imageVector count]];
    

    self.progressLabel.text = progress;
    

    
    if ( self.captionExpanded ) {
      [self contractCaption];
    }
    
    [self.captionExpansionButton removeFromSuperview];
    self.captionExpansionButton = [[UIButton alloc] initWithFrame:self.mainCaptionLabel.frame];
    self.captionExpansionButton.backgroundColor = [UIColor clearColor];
    

    [self.captionSeat addSubview:self.captionExpansionButton];
    
    self.captionExpanded = NO;
    [self.captionExpansionButton addTarget:self
                                    action:@selector(expandCaption)
                          forControlEvents:UIControlEventTouchUpInside];
  
  
    if ( fadein ) {
        [UIView animateWithDuration:0.22 animations:^{
          self.titleCaptionLabel.alpha = 1.0;
          self.footerCaption.alpha = 1.0;
          self.mainCaptionLabel.alpha = 1.0;
          self.progressLabel.alpha = 1.0;
        }];
    }
  
}

- (void)expandCaption {
  
  if ( self.captionExpanded ) {
    return;
  }
  [UIView animateWithDuration:0.25 animations:^{
    
    self.captionSeat.layer.backgroundColor = [[DesignManager shared] frostedWindowColor:0.75].CGColor;
    self.mainCaptionLabel.textColor = [[DesignManager shared] deepOnyxColor];
    self.mainCaptionLabel.numberOfLines = 0;
    UIFont *f = self.mainCaptionLabel.font;
    
    self.mainCaptionLabel.font = [[DesignManager shared]
                                  latoRegular:f.pointSize+4.0];

    
    [self.mainCaptionLabel titleizeText:self.mainCaptionLabel.text
                                   bold:NO
                          respectHeight:YES];
    
    
    
  } completion:^(BOOL finished) {
    self.captionExpanded = YES;
    [self.captionExpansionButton removeTarget:self
                                       action:@selector(expandCaption)
                             forControlEvents:UIControlEventTouchUpInside];
    [self.captionExpansionButton addTarget:self
                                    action:@selector(contractCaption)
                          forControlEvents:UIControlEventTouchUpInside];
  }];
  
}

- (void)contractCaption {
  [UIView animateWithDuration:0.25 animations:^{
    
    self.captionSeat.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.mainCaptionLabel.textColor = [UIColor whiteColor];
    self.captionSeat.frame = self.originalCaptionSeatFrame;
    self.captionSeat.layer.cornerRadius = 0.0;
    self.mainCaptionLabel.numberOfLines = 3;
    
    UIFont *f = self.mainCaptionLabel.font;
    self.mainCaptionLabel.font = [[DesignManager shared]
                                  latoRegular:f.pointSize-4.0];
    
    [self.mainCaptionLabel titleizeText:self.mainCaptionLabel.text
                                   bold:NO
                          respectHeight:YES];
    

    
    
  } completion:^(BOOL finished) {
    self.captionExpanded = NO;
    [self.captionExpansionButton removeTarget:self
                                       action:@selector(contractCaption)
                             forControlEvents:UIControlEventTouchUpInside];
    [self.captionExpansionButton addTarget:self
                                    action:@selector(expandCaption)
                          forControlEvents:UIControlEventTouchUpInside];
    self.captionExpansionButton.frame = self.mainCaptionLabel.frame;
  }];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  NSInteger index = self.scroller.contentOffset.x / self.scroller.frame.size.width;
  return [self.imageVector objectAtIndex:index];
}

#pragma mark - ar
- (BOOL)shouldAutorotate {
  return YES;
}


#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING EXTRA ASSETS VIEW CONTROLLER");
}
#endif

@end
