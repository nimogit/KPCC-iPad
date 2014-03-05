//
//  UIImageView+ImageProcessor.h
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ImageAppearedCallback)(void);

@interface UIImageView (ImageProcessor)

- (CGRect)frameForImage;
- (void)loadImage:(NSString*)link;
- (void)loadImage:(NSString*)link quietly:(BOOL)quietly;
- (void)loadImage:(NSString *)link quietly:(BOOL)quietly blurry:(BOOL)blurry;
- (void)loadImage:(NSString *)link quietly:(BOOL)quietly queue:(NSOperationQueue*)queue completion:(ImageAppearedCallback)block;
- (void)loadImage:(NSString*)link quietly:(BOOL)quietly queue:(NSOperationQueue*)queue forceSize:(BOOL)forceSize completion:(ImageAppearedCallback)block;

- (void)loadLocalImage:(NSString*)link quietly:(BOOL)quietly;
- (void)loadLocalImage:(NSString*)link quietly:(BOOL)quietly thumbscale:(BOOL)thumbscale;
- (UIImage*)scaledToSize:(CGSize)size;

- (void)applyImage:(UIImage*)image completion:(ImageAppearedCallback)block;
- (void)applyImageQuietly:(UIImage*)image completion:(ImageAppearedCallback)block;
- (void)applyImage:(UIImage*)image;
- (void)applyImageQuietly:(UIImage*)image;



@end
