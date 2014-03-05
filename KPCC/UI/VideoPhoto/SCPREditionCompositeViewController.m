//
//  SCPREditionCompositeViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREditionCompositeViewController.h"
#import "global.h"
#import "SCPRDeluxeNewsViewController.h"

@interface SCPREditionCompositeViewController ()

@end

@implementation SCPREditionCompositeViewController

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
  
  self.splashImage.clipsToBounds = YES;
  

  
    // Do any additional setup after loading the view from its nib.
}

- (void)setIsPrimary:(BOOL)isPrimary {
  _isPrimary = isPrimary;
  

}

- (void)setupWithEdition:(NSDictionary *)edition {
  self.edition = edition;
  if ( self.index != 0 ) {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"patternedGradient"
                                                           ofType:@"png"];
  
    self.cloakView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:bundlePath]];
  } else {
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"compositeEditionsGradient"
                                                           ofType:@"png"];
    
    self.cloakView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:bundlePath]];
  }
  
  self.splashImage.clipsToBounds = YES;
  self.view.clipsToBounds = YES;
  
  self.cloakView.contentMode = UIViewContentModeScaleToFill;
  self.cloakView.autoresizingMask = UIViewAutoresizingNone;
  self.cloakView.frame = CGRectMake(0.0, self.view.frame.size.height-self.cloakView.frame.size.height,
                                    self.view.frame.size.width,
                                    self.cloakView.frame.size.height);
  
  self.cloakView.alpha = 0.0;
  CGFloat offset = self.index * 83.0;
  self.splashImage.center = CGPointMake(self.splashImage.center.x,
                                        self.splashImage.center.y+offset);
  
  self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0,0.0,self.view.frame.size.width,self.view.frame.size.height)];
  
  [self.view addSubview:self.actionButton];
  [self.view addSubview:self.cloakView];
  [self.view bringSubviewToFront:self.cloakView];
  [self.view bringSubviewToFront:self.headlineLabel];
  [self.view bringSubviewToFront:self.categoryLabel];
  [self.view bringSubviewToFront:self.actionButton];
  
  [self.headlineLabel sansifyTitleText:[edition objectForKey:@"headline"]
                                  bold:NO
                         respectHeight:YES];
  
  [[DesignManager shared] avoidNeighbor:self.categoryLabel
                               withView:self.headlineLabel
                              direction:NeighborDirectionAbove
                                padding:4.0];
  
  NSDictionary *category = [edition objectForKey:@"category"];
  if ( ![Utilities pureNil:category] ) {
    NSString *name = [category objectForKey:@"title"];
    if ( ![Utilities pureNil:name] ) {
      [self.categoryLabel titleizeText:[name uppercaseString]
                                  bold:NO];
    }
  }
  
  
  
  NSString *url = [Utilities extractImageURLFromBlob:edition
                                             quality:AssetQualityFull];
  [self.splashImage loadImage:url quietly:NO queue:nil completion:^{
    [UIView animateWithDuration:0.25 animations:^{
      self.cloakView.alpha = 1.0;
    } completion:^(BOOL finished) {
      [self.actionButton addTarget:self
                            action:@selector(buttonTapped:)
                  forControlEvents:UIControlEventTouchUpInside];
    }];
  }];
  
}

- (void)buttonTapped:(id)sender {
  
  SCPRDeluxeNewsViewController *parentNews = (SCPRDeluxeNewsViewController*)self.parent;
  [parentNews handleDrillDown:self.edition];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
