//
//  SCPRSmallCutViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSmallCutViewController.h"
#import "global.h"
#import "SCPRTitlebarViewController.h"
#import "SCPRViewController.h"

@interface SCPRSmallCutViewController ()

@end

@implementation SCPRSmallCutViewController

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
  
  self.smallCutImage.clipsToBounds = YES;
  CGFloat scale = [[UIScreen mainScreen] scale];
  self.view.frame = CGRectMake(0.0,0.0,self.view.frame.size.width*(1/(2/scale)),
                               self.view.frame.size.height*(1/(2/scale)));
    // Do any additional setup after loading the view from its nib.
}

- (UIImage*)renderWithImage:(NSString*)imageStr {
  
  NSLog(@"Rendering %@",imageStr);
  CGFloat scale = [[UIScreen mainScreen] scale];

  self.smallCutImage.image = nil;
  [self.view removeFromSuperview];
  
  NSString *small = [NSString stringWithFormat:@"small_%@",imageStr];
  UIImage *image = [[ContentManager shared] retrieveSandboxedImageFromDisk:small];
  BOOL write = NO;
  if ( !image ) {
    
    write = YES;
    NSString *path = [[NSBundle mainBundle] pathForResource:imageStr ofType:@""];
    image = [UIImage imageWithContentsOfFile:path];
    
  } else {
    
    [[ContentManager shared].imageCache setObject:image
                                           forKey:[Utilities sha1:small]];
    
    return image;
  }
  
  SCPRAppDelegate *del = [Utilities del];
  

  
  SCPRViewController *svc = [[Utilities del] viewController];
  [[[[Utilities del] globalTitleBar] view] setAlpha:0.0];
  svc.view.alpha = 0.0;
  
  
  [del.window addSubview:self.view];
  
  [self.smallCutImage setImage:image];
  
  UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, scale);
	[self.view.layer.superlayer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
  [self.view removeFromSuperview];
  
  [[[[Utilities del] globalTitleBar] view] setAlpha:1.0];
  svc.view.alpha = 1.0;
  


  
  if ( write ) {
    
    if ( [imageStr rangeOfString:@"dinner"].location != NSNotFound ) {
      [[ContentManager shared] writeImageToDisk:UIImageJPEGRepresentation(resultingImage, 0.2)
                                        forHash:imageStr
                                        sandbox:YES];
    }
    
  }
  
  return resultingImage;
}

- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    for ( NSDictionary *program in content ) {
      NSString *programImageName = [[ContentManager shared] imageNameForProgram:program];
      [self renderWithImage:programImageName];
    }
  });

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
