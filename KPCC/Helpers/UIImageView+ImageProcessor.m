//
//  UIImageView+ImageProcessor.m
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "UIImageView+ImageProcessor.h"
#import "global.h"

@implementation UIImageView (ImageProcessor)

- (void)loadImage:(NSString *)link {
  [self loadImage:link quietly:NO];
}

- (void)loadImage:(NSString *)link quietly:(BOOL)quietly {
  [self loadImage:link quietly:quietly blurry:NO];
}

- (void)loadImage:(NSString *)link quietly:(BOOL)quietly blurry:(BOOL)blurry {
  
  [self loadImage:link quietly:quietly queue:nil completion:nil];
  
}

- (void)loadImage:(NSString *)link quietly:(BOOL)quietly queue:(NSOperationQueue *)queue completion:(ImageAppearedCallback)block {
  [self loadImage:link quietly:quietly queue:queue forceSize:NO completion:block];
}

- (void)loadImage:(NSString *)link quietly:(BOOL)quietly queue:(NSOperationQueue *)queue forceSize:(BOOL)forceSize completion:(ImageAppearedCallback)block {
  if ( !quietly ) {
    self.alpha = 0.0;
  }
  
  
  if ( !link ) {
    // For debugging/test purposes, if the link is nil grab a random image
    [self loadLocalImage:@"kpcc-twitter-logo.png"
                 quietly:quietly];
    return;
  }
  
  __block UIImage *image = nil;
  
  //NSLog(@"Image Link : %@",[Utilities sha1:link]);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    image = [[ContentManager shared] retrieveImageFromCache:link];
    if ( !image ) {
      image = [UIImage imageNamed:link];
    }
    if ( !image ) {
      
      //NSLog(@" *********** IMAGE FETCH FROM WEB *********** ");
      dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:link];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        NSString *hash = [Utilities sha1:link];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[[ContentManager shared] globalImageQueue]
                               completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                                 
                                 if ( e ) {
                                   NSLog(@"Error fetching link : %@",link);
                                 }
                                 
                                 if ( !d ) {
                                   return;
                                 }
                                 
                                 //UIImage *fetchedImage = [UIImage imageWithData:d];
                                 //if ( fetchedImage ) {
                                   
                                   UIImage *fetchedImage = [UIImage imageWithContentsOfFile:[[ContentManager shared] writeImageToDisk:d forHash:hash]];
                                   dispatch_async(dispatch_get_main_queue(), ^{

                                     self.image = fetchedImage;
                                     
                                     CGFloat scale = [Utilities isRetina] ? 2.0 : 1.0;
                                     if ( forceSize ) {
                                       
                                       CGFloat cookedWidth = floorf(fetchedImage.size.width/scale);
                                       CGFloat cookedHeight = floorf(fetchedImage.size.height/scale);
                                       
                                       if ( cookedWidth > self.frame.size.width ) {
                                         cookedWidth = self.frame.size.width;
                                       }
                                       if ( cookedHeight > self.frame.size.height ) {
                                         cookedHeight = self.frame.size.height;
                                       }
                                       
                                       self.frame = CGRectMake(self.frame.origin.x,
                                                               self.frame.origin.y,
                                                               cookedHeight,
                                                               cookedWidth);
                                     }
                                     
                                     if ( quietly ) {
                                       self.alpha = 1.0;
                                     } else {
                                       [UIView animateWithDuration:0.22 animations:^{
                                         self.alpha = 1.0;
                                       } completion:^(BOOL finished) {
                                         if ( block ) {
                                           dispatch_async(dispatch_get_main_queue(), block);
                                         }
                                       }];
                                     }
                                     
                                     [[ContentManager shared] writeImage:fetchedImage
                                                                 forHash:[Utilities sha1:link]];
                                     
                                   });
                                   
                                 /*} else {
                                   
                                   NSLog(@"Error fetching image : %@",link);
                                   
                                 }*/
                                 
                            }];
      });
      
      
    } else {

      if ( !image ) {
        image = [UIImage imageNamed:link];
      }
      
      dispatch_async(dispatch_get_main_queue(), ^{
        
        self.image = image;
        
        CGFloat scale = [Utilities isRetina] ? 2.0 : 1.0;
        if ( forceSize ) {
          
          CGFloat cookedWidth = floorf(image.size.width/scale);
          CGFloat cookedHeight = floorf(image.size.height/scale);
          
          if ( cookedWidth > self.frame.size.width ) {
            cookedWidth = self.frame.size.width;
          }
          if ( cookedHeight > self.frame.size.height ) {
            cookedHeight = self.frame.size.height;
          }
          
          self.frame = CGRectMake(self.frame.origin.x,
                                  self.frame.origin.y,
                                  cookedHeight,
                                  cookedWidth);
        }
        
        if ( quietly ) {
          self.alpha = 1.0;
        } else {
          [UIView animateWithDuration:0.22 animations:^{
            self.alpha = 1.0;
          } completion:^(BOOL finished) {
            if ( block ) {
              dispatch_async(dispatch_get_main_queue(), block);
            }
          }];
        }
        
        [[ContentManager shared] writeImage:image
                                    forHash:[Utilities sha1:link]];
        
      });
      
    }
    
  });
}

- (UIImage*)scaledToSize:(CGSize)newSize;
{
  UIGraphicsBeginImageContext( newSize );
  [self.image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
  UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return newImage;
}

-(CGRect)frameForImage
{
  
  UIImageView *imageView = self;
  UIImage *image = self.image;
  
  float imageRatio = self.image.size.width / self.image.size.height;
  float viewRatio = imageView.frame.size.width / imageView.frame.size.height;
  
  if(imageRatio < viewRatio)
  {
    float scale = imageView.frame.size.height / image.size.height;
    float width = scale * image.size.width;
    float topLeftX = (imageView.frame.size.width - width) * 0.5;
    
    return CGRectMake(topLeftX, 0, width, imageView.frame.size.height);
  }
  else
  {
    float scale = imageView.frame.size.width / image.size.width;
    float height = scale * image.size.height;
    float topLeftY = (imageView.frame.size.height - height) * 0.5;
    
    return CGRectMake(0, topLeftY, imageView.frame.size.width, height);
  }
}


- (void)reportError:(NSString*)link {
  
}

- (void)applyImage:(UIImage *)image completion:(ImageAppearedCallback)block {
  self.image = image;
  
  [UIView animateWithDuration:0.22 animations:^{
    self.alpha = 1.0;
  } completion:^(BOOL finished) {
    if ( block ) {
      dispatch_async(dispatch_get_main_queue(), block);
    }
  }];
  
}
- (void)applyImage:(UIImage*)image {
  [self applyImage:image completion:nil];
}



- (void)applyImageQuietly:(UIImage*)image completion:(ImageAppearedCallback)block {
  self.image = image;
  self.alpha = 1.0;
  
  if ( block ) {
    dispatch_async(dispatch_get_main_queue(), block);
  }
}

- (void)applyImageQuietly:(UIImage *)image {
  [self applyImageQuietly:image completion:nil];
}

- (void)applyImageBlurrily:(UIImage*)image {
  self.image = [image stackBlur:3];
  self.alpha = 1.0;
}

- (void)loadLocalImage:(NSString *)link quietly:(BOOL)quietly {
  
  [self loadLocalImage:link quietly:quietly thumbscale:NO];

}

- (void)loadLocalImage:(NSString *)link quietly:(BOOL)quietly thumbscale:(BOOL)thumbscale {
  
  //NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");
  
  if ( [Utilities pureNil:link] ) {
    link = @"kpcc-twitter-logo.png";
  }
  
  if ( !quietly ) {
    self.alpha = 0.0;
  }
  
  __block UIImage *img = [[ContentManager shared].imageCache objectForKey:[Utilities sha1:link]];
  if ( img ) {
    
    if ( thumbscale ) {
      CGSize scaled = CGSizeMake(img.size.width*.33, img.size.height*.33);
      img = [self scaledToSize:scaled];
    }
    self.image = img;
    if ( !quietly ) {
      [UIView animateWithDuration:0.22 animations:^{
        self.alpha = 1.0;
      }];
    } else {
      self.alpha = 1.0;
    }
    return;
  }
  
  //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    
    
    UIImage *sandbox = [[ContentManager shared] retrieveSandboxedImageFromDisk:link];
    if ( sandbox ) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if ( thumbscale ) {
          CGSize scaled = CGSizeMake(img.size.width*.33, img.size.height*.33);
          img = [self scaledToSize:scaled];
        }
        self.image = img;
        if ( !quietly ) {
          [UIView animateWithDuration:0.22 animations:^{
            self.alpha = 1.0;
          }];
        } else {
          self.alpha = 1.0;
        }
        
        [[ContentManager shared].imageCache setObject:sandbox
                                               forKey:[Utilities sha1:link]];
        
        return;
      });
    }
    
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:link ofType:@""];
    imgPath = [[FileManager shared] copyFromMainBundleToDocuments:link
                                               destName:link];

    img = [UIImage imageWithContentsOfFile:imgPath];
    //self.image = img;
    if ( thumbscale ) {
   
      //img = [self scaledToSize:scaled];
    }
    
    
    if ( self.image ) {
      /*[[ContentManager shared].imageCache setObject:self.image
                                             forKey:[Utilities sha1:link]];*/
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self.image = img;
      if ( !quietly ) {
        [UIView animateWithDuration:0.22 animations:^{
          self.alpha = 1.0;
        }];
      } else {
        self.alpha = 1.0;
      }
    });
  
  //});

}

- (void)fin {
  
}

@end
