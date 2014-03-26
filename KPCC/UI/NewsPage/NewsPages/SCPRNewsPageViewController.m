//
//  SCPRNewsPageViewController.m
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRNewsPageViewController.h"
#import "SCPRNewsPageContainerController.h"
#import "SCPRSingleArticleViewController.h"
#import "SCPRClipBannerViewController.h"
#import "SCPRSingleArticleCollectionViewController.h"
#import "SCPRViewController.h"
#import "SCPRAppDelegate.h"

#define kVerticalPadding 90.0

@interface SCPRNewsPageViewController ()

@end

@implementation SCPRNewsPageViewController

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
  
  self.view.backgroundColor = [[DesignManager shared] number1pencilColor];
  self.decorativeStripeView.backgroundColor = [[DesignManager shared] kpccOrangeColor];
  self.view.clipsToBounds = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(scrollViewScrolled:)
                                               name:@"main_scroller_scrolled"
                                             object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
  SCPRNewsPageContainerController *npc = (SCPRNewsPageContainerController*)self.parentContainer;
  if ( npc.designatedNav ) {
    //NSLog(@"Nav still in play");
  } else {
   // NSLog(@"Nav deallocated");
  }
}




#pragma mark - ContentContainer
- (void)scrollViewScrolled:(NSNotification*)note {
  NSNumber *n = (NSNumber*)[note object];
  CGFloat index = [n floatValue];
  
  if ( abs((int)index-(int)self.pageIndex) > kNewsCacheThreshold ) {
    //[self deactivatePage];
  }

}

- (void)unplug {
  
}

- (void)handleDrillDown:(NSDictionary *)content {
  
  

  SCPRSingleArticleCollectionViewController *collection = [[SCPRSingleArticleCollectionViewController alloc]
                                                           initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRSingleArticleCollectionViewController"]
                                                           bundle:nil];

  self.pushed = collection;
  SCPRAppDelegate *del = [Utilities del];
  SCPRViewController *mvc = (SCPRViewController*)del.viewController;
  mvc.topicSelector.alpha = 0.0;
  
  NSUInteger index = 0;
  for ( unsigned i = 0; i < [self.contentDelegate mediaContentForTopic:self.topicSlug].count; i++ ) {
    NSDictionary *story = [[self.contentDelegate mediaContentForTopic:self.topicSlug] objectAtIndex:i];
    if ( [[Utilities webstyledSlug:story] isEqualToString:[Utilities webstyledSlug:content]] ) {
      index = i;
      break;
    }
  }

  SCPRNewsPageContainerController *container = (SCPRNewsPageContainerController*)self.parentContainer;
  UINavigationController *nav = container.designatedNav;
  [nav pushViewController:collection animated:YES];

  mvc.mainPageScroller.scrollEnabled = NO;

  collection.parentContainer = self;
  [collection setupWithCollection:[self.contentDelegate mediaContentForTopic:self.topicSlug]
               beginningAtIndex:index
                   processIndex:YES];

}

- (void)reloadPage {
  
}

- (void)activatePage {
  if ( !self.activated ) {
    
    [self.topPart removeFromSuperview];
    [self.split1 removeFromSuperview];
    [self.split2 removeFromSuperview];
    
    [[DesignManager shared] applyPerimeterShadowTo:self.topPart];
    
    SCPRNewsPageContainerController *npc = (SCPRNewsPageContainerController*)self.parentContainer;
    if ( !self.floatingSponsorView ) {
      self.floatingSponsorView = npc.bannerAdView;
      self.floatingSponsorView.alpha = 0.0;
    }
    self.topicTitleLabel = npc.pageTitleLabel;
    
    self.topicTitleLabel.textColor = [[DesignManager shared] kpccDarkOrangeColor];
    [self.topicTitleLabel snapText:[[NetworkManager shared] stringForSchemaComponent:self.topicTitleCode]
                              bold:YES];
    
    NSInteger count = [self.contentDelegate numberOfStoriesPerPage];
    for ( unsigned i = 0; i < count; i++ ) {
      
      NSMutableArray *content = [self.contentDelegate mediaContentForTopic:self.topicSlug];
      if ( (self.pageIndex*count)+i >= [content count] ) {
        continue;
      }
      
      NSDictionary *thing = [[self.contentDelegate mediaContentForTopic:self.topicSlug] objectAtIndex:(self.pageIndex*count)+i];
      
      [self templateBigTopSplitBottom:i
                                style:self.templateType];
      
      NSString *baseHeadline = [NSString stringWithFormat:@"headline%d",i+1];
      NSString *baseBlurb = [NSString stringWithFormat:@"blurb%d",i+1];
      NSString *baseImage = [NSString stringWithFormat:@"image%d",i+1];
      NSString *baseByline = [NSString stringWithFormat:@"byline%d",i+1];
      UIImageView *image = (UIImageView*)[self valueForKey:baseImage];
      if ( image ) {
        NSString *imgUrl = [Utilities extractImageURLFromBlob:thing
                                                      quality:AssetQualityFull];
        if ( ![Utilities pureNil:imgUrl] ) {
          [image loadImage:imgUrl quietly:YES];
        }
      }
      
      UILabel *byline = (UILabel*)[self valueForKey:baseByline];
      if ( byline ) {
        
        if ( ![Utilities pureNil:[thing objectForKey:@"byline"]] &&
            ![Utilities pureNil:[thing objectForKey:@"published_at"]] ) {
          NSString *bylineStr = [thing objectForKey:@"byline"];
          NSString *dateStr = [thing objectForKey:@"published_at"];
          NSDate *dateObj = [Utilities dateFromRFCString:dateStr];
          NSString *pretty = [NSDate stringFromDate:dateObj
                                       withFormat:@"MMM d, YYYY, h:mm a"];
          [byline bodytextSnap:[NSString stringWithFormat:@"%@ | %@",bylineStr,pretty]
                 respectHeight:NO];
          
          byline.alpha = 1.0;
        }
      }
      UILabel *headline = (UILabel*)[self valueForKey:baseHeadline];
      if ( headline ) {
        if ( ![Utilities pureNil:[thing objectForKey:@"short_title"]] ) {
          [headline headlineSnap:[thing objectForKey:@"short_title"]
                   respectHeight:NO];
          headline.alpha = 1.0;
        }
      }
      
      UILabel *blurb = (UILabel*)[self valueForKey:baseBlurb];
      if ( blurb ) {
        if ( ![Utilities pureNil:[thing objectForKey:@"teaser"]] ) {
          NSString *sanitized = [Utilities unwebbifyString:[thing objectForKey:@"teaser"]];
          [blurb kernedBodytextSnap:sanitized respectHeight:NO];
          blurb.alpha = 1.0;
        }
      }
      

    
    
    }
    [self arrange];
    
    self.activated = YES;
  }

  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.4];
  self.view.alpha = 1.0;
  [UIView commitAnimations];
}

- (void)deactivatePage {
  if ( !self.activated ) {
    return;
  }
  
  self.activated = NO;
  SCPRNewsPageContainerController *npc = (SCPRNewsPageContainerController*)self.parentContainer;
  npc.observableScroller = nil;
  
  /*[self.topPart removeFromSuperview];
  [self.split1 removeFromSuperview];
  [self.split2 removeFromSuperview];
  
  self.topPart = nil;
  self.split1 = nil;
  self.split2 = nil;*/
 
  
  NSArray *bases = @[ @"image", @"byline", @"headline", @"blurb" ];
  for ( unsigned i = 0; i < 4; i++ ) {
    NSString *base = [bases objectAtIndex:i];
    for ( unsigned j = 0; j < 4; j++ ) {
      NSString *key = [NSString stringWithFormat:@"%@%d",base,j+1];
      [self setValue:nil forKey:key];
    }
  }
  
  UIView *clip = [self.view viewWithTag:kClipBannerTag];
  [clip removeFromSuperview];
  
  npc.child = nil;
  
}

- (void)pad {
  
}



#pragma mark - Templates
- (void)templateBigTopSplitBottom:(NSInteger)index style:(NSUInteger)tempStyle {
  NSInteger count = [self.contentDelegate numberOfStoriesPerPage];
  NSDictionary *thing = [[self.contentDelegate mediaContentForTopic:self.topicSlug] objectAtIndex:(self.pageIndex*count)+index];
  NSString *sectionType = @"";
  NSString *ratio = @"";
  if ( index == 0 ) {
    sectionType = @"SingleTop";
  }
  if ( index == 1 ) {
    sectionType = @"Split";
  }
  if ( index == 2 ) {
    sectionType = @"Split";
  }
  
  ratio = [[DesignManager shared] aspectCodeForContentItem:thing
                                                   quality:AssetQualityFull];
  
  
  NSRange r = [ratio rangeOfString:@"_clip"];
  BOOL aspectFit = NO;
  if ( r.location != NSNotFound ) {
    ratio = [ratio substringToIndex:r.location];
    aspectFit = YES;
  }
  NSString *nib = [NSString stringWithFormat:@"SCPRNewsPage%@%@",sectionType,ratio];
  NSString *cookedNib = [[DesignManager shared] xibit:nib
                                                style:self.templateType];
  //NSLog(@"Cooked nib name : %@",cookedNib);
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:cookedNib
                                                   owner:self
                                                 options:nil];
  SCPRHBTView *section = [objects objectAtIndex:0];
  section.relatedArticle = thing;
  section.navigator = self;
  section.aspectCode = [NSString stringWithFormat:@"%@%@",sectionType,ratio];
  section.templateStyle = self.templateType;
  
  if ( index == 0 ) {
    section.frame = CGRectMake(36.0,0.0,
                               section.frame.size.width,
                               section.frame.size.height-30.0);
    self.topPart = section;
    
  }
  if ( index == 1 || index == 2 ) {
    if ( index == 1 ) {
      // Left split
      section.frame = CGRectMake(0.0,self.topPart.frame.origin.y+self.topPart.frame.size.height+kVerticalPadding,
                                 section.frame.size.width,section.frame.size.height);
      self.split1 = section;
      

    }
    if ( index == 2 ) {
      section.frame = CGRectMake(self.split1.frame.size.width+self.split1.frame.origin.x,self.topPart.frame.origin.y+self.topPart.frame.size.height+kVerticalPadding,
                                 section.frame.size.width,section.frame.size.height);
      
      self.split2 = section;
      self.split2.rightSide = YES;
    }
    
    
  }
  
  NSString *baseHeadline = [NSString stringWithFormat:@"headline%ld",index+1];
  NSString *baseBlurb = [NSString stringWithFormat:@"blurb%ld",index+1];
  NSString *baseImage = [NSString stringWithFormat:@"image%ld",index+1];
  NSString *baseByline = [NSString stringWithFormat:@"byline%ld",index+1];
  
  // Remove gray line for now
  self.grayLine.alpha = 0.0;
  
  [self setValue:section.headLine
          forKey:baseHeadline];
  [self setValue:section.blurb1
          forKey:baseBlurb];
  [self setValue:section.image1
          forKey:baseImage];
  [self setValue:section.byLine
          forKey:baseByline];
  
  if ( aspectFit ) {
    section.image1.clipsToBounds = YES;
    section.image1.contentMode = UIViewContentModeScaleAspectFill;
  }
  
  if ( section.bannerAdView ) {
    [self setValue:section.bannerAdView
            forKey:@"floatingSponsorView"];
  }
  
  self.topPart.articleIndex = (kNumberOfStoriesPerPage*self.pageIndex);
  self.split1.articleIndex = (kNumberOfStoriesPerPage*self.pageIndex)+1;
  self.split2.articleIndex = (kNumberOfStoriesPerPage*self.pageIndex)+2;
  
  [self.view addSubview:section];

  //self.view.alpha = 0.0;
}


- (void)appendArticles:(NSArray *)articles {
  for ( unsigned i = 0; i < [articles count]; i++ ) {
    NSDictionary *thing = [articles objectAtIndex:i];
  
    NSString *sectionType = @"";
    NSString *ratio = @"";

    sectionType = @"Split";

  
    ratio = [[DesignManager shared] aspectCodeForContentItem:thing
                                                   quality:AssetQualityFull];
  
    if ( [Utilities pureNil:ratio] ) {
      // WHo knows?
      ratio = @"Sq";
    }
    NSRange r = [ratio rangeOfString:@"_clip"];
    BOOL aspectFit = NO;
    if ( r.location != NSNotFound ) {
      ratio = [ratio substringToIndex:r.location];
      aspectFit = YES;
    }
    NSString *nib = [NSString stringWithFormat:@"SCPRNewsPage%@%@",sectionType,ratio];
    NSString *cookedNib = [[DesignManager shared] xibit:nib
                                                style:self.templateType];
 
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:cookedNib
                                                   owner:self
                                                 options:nil];
    SCPRHBTView *section = [objects objectAtIndex:0];
    section.relatedArticle = thing;
    section.navigator = self;
    section.aspectCode = [NSString stringWithFormat:@"%@%@",sectionType,ratio];
    section.templateStyle = self.templateType;
  


    if ( i == 1 ) {
      // Left split
      section.frame = CGRectMake(0.0,self.topPart.frame.origin.y+self.topPart.frame.size.height+kVerticalPadding,
                                 section.frame.size.width,section.frame.size.height);
      self.split1 = section;
      
      
    }
    if ( i == 0 ) {
      section.frame = CGRectMake(self.split1.frame.size.width+self.split1.frame.origin.x,self.topPart.frame.origin.y+self.topPart.frame.size.height+kVerticalPadding,
                                 section.frame.size.width,section.frame.size.height);
      
      self.split2 = section;
      self.split2.rightSide = YES;
    }
    
    
  
    NSString *baseHeadline = [NSString stringWithFormat:@"headline%d",i+1];
    NSString *baseBlurb = [NSString stringWithFormat:@"blurb%d",i+1];
    NSString *baseImage = [NSString stringWithFormat:@"image%d",i+1];
    NSString *baseByline = [NSString stringWithFormat:@"byline%d",i+1];
  
    // Remove gray line for now
    self.grayLine.alpha = 0.0;
  
    [self setValue:section.headLine
          forKey:baseHeadline];
    [self setValue:section.blurb1
          forKey:baseBlurb];
    [self setValue:section.image1
          forKey:baseImage];
    [self setValue:section.byLine
          forKey:baseByline];
  
    if ( aspectFit ) {
      section.image1.clipsToBounds = YES;
      section.image1.contentMode = UIViewContentModeScaleAspectFill;
    }
  
    if ( section.bannerAdView ) {
      [self setValue:section.bannerAdView
            forKey:@"floatingSponsorView"];
    }
  
    self.split1.articleIndex = (kNumberOfStoriesPerPage*self.pageIndex)+1;
    self.split2.articleIndex = (kNumberOfStoriesPerPage*self.pageIndex)+2;
  
    [self.view addSubview:section];
  
  }

}

- (void)arrange {
  
  [[DesignManager shared] applyBaseShadowTo:self.floatingSponsorView];
  self.floatingSponsorView.layer.cornerRadius = 4.0;
  self.floatingSponsorView.backgroundColor = [UIColor redColor];

  
  [self.topPart arrange];
  [self.split1 arrange];
  [self.split2 arrange];
  
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.18];
  self.topicTitleLabel.alpha = 1.0;
  self.floatingSponsorView.alpha = 1.0;
  [UIView commitAnimations];
}

- (BOOL)shouldAutorotate {
  return [[DesignManager shared] inSingleArticle];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)clipBannerToTop:(NSString *)withMessage {
  
  SCPRClipBannerViewController *clip = [[SCPRClipBannerViewController alloc]
                                        initWithNibName:[[DesignManager shared]
                                                         xibForPlatformWithName:@"SCPRClipBannerViewController"]
                                        bundle:nil];
  clip.view.frame = CGRectMake(self.topPart.frame.origin.x-21.0,
                               self.topPart.frame.origin.y+(0.97*self.topPart.frame.size.height),
                               clip.view.frame.size.width,
                               clip.view.frame.size.height);
  clip.view.tag = kClipBannerTag;
  [self.view addSubview:clip.view];
  
}

- (void)dealloc {
  //NSLog(@"Siyonara from Single News Page!");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
