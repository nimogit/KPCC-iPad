//
//  UIImageView+Analysis.m
//  KPCC
//
//  Created by Ben on 5/10/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "UIImageView+Analysis.h"

@implementation UIImageView (Analysis)


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

@end
