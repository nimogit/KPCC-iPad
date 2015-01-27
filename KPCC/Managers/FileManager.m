//
//  FileManager.m
//  KPCC
//
//  Created by Ben Hochberg on 4/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "FileManager.h"
#import "global.h"
#import "SBJson.h"

static FileManager *singleton = nil;

@implementation FileManager

+ (FileManager*)shared {
  if ( !singleton ) {
    singleton = [[FileManager alloc] init];
    [singleton copyFromMainBundleToDocuments:@"icon-embed.png"
                                    destName:@"icon-embed.png"
     root:YES];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed@2x.png"
                                    destName:@"icon-embed@2x.png"
     root:YES];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed.png"
                                    destName:@"icon-embed.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed@2x.png"
                                    destName:@"icon-embed@2x.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-twitter@2x.png"
                                    destName:@"icon-embed-twitter@2x.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-video@2x.png"
                                    destName:@"icon-embed-video@2x.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-map@2x.png"
                                    destName:@"icon-embed-map@2x.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-poll@2x.png"
                                    destName:@"icon-embed-poll@2x.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-twitter.png"
                                    destName:@"icon-embed-twitter.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-video.png"
                                    destName:@"icon-embed-video.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-map.png"
                                    destName:@"icon-embed-map.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-embed-poll.png"
                                    destName:@"icon-embed-poll.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"icon-blockquote-twitter.png"
                                    destName:@"icon-blockquote-twitter.png"
                                        root:NO];
    
    
    [singleton copyFromMainBundleToDocuments:@"icon-blockquote-twitter@2x.png"
                                    destName:@"icon-blockquote-twitter@2x.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"flatPlayOverlay.png"
                                    destName:@"flatPlayOverlay.png"
                                        root:NO];
    
    [singleton copyFromMainBundleToDocuments:@"flatPlayOverlay@2x.png"
                                    destName:@"flatPlayOverlay@2x.png"
                                        root:NO];
    
    NSArray *supported = [Utilities loadJson:@"embedsupport"];
    for ( NSString *service in supported ) {
      NSString *icon = [NSString stringWithFormat:@"icon-%@.png",service];
      NSString *retinaIcon = [NSString stringWithFormat:@"icon-%@@2x.png",service];
      
      BOOL exists = NO;
      @try {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:icon ofType:@"png"];
        if ( ![Utilities pureNil:path] ) {
          exists = YES;
        }
        
      } @catch (NSException *e) {
        exists = NO;
      }
      
      [singleton copyFromMainBundleToDocuments:icon
                                      destName:icon
                                          root:NO];
      
      [singleton copyFromMainBundleToDocuments:retinaIcon
                                      destName:retinaIcon
                                          root:NO];
    }
    
    [singleton setupConfigFile];
  }

  return singleton;
}

- (void) setupConfigFile {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
  self.globalConfig = [[NSDictionary alloc] initWithContentsOfFile:path];
}


- (NSString*)formattedEmailForArticle:(NSDictionary *)article {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"email_payload"
                                                   ofType:@"html"];
  NSError *error = nil;
  NSString *template = [[NSString alloc] initWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
  NSString *img = [Utilities extractImageURLFromBlob:article quality:AssetQualityLarge];
  if ( [Utilities pureNil:img] ) {
    img = @"";
  }
  
  NSString *title = [article objectForKey:@"short_title"] ? [article objectForKey:@"short_title"] : [article objectForKey:@"headline"];
  if ( !title ) {
    title = [article objectForKey:@"title"];
  }
  NSString *teaser = [article objectForKey:@"teaser"] ? [article objectForKey:@"teaser"] : [article objectForKey:@"summary"];
  NSString *link = [article objectForKey:@"permalink"] ? [article objectForKey:@"permalink"] : [article objectForKey:@"url"];
  if ( !link ) {
    link = [article objectForKey:@"public_url"];
  }
  
  NSString *formatted = [NSString stringWithFormat:template,title,img,
                         teaser,
                         link];
  
  return formatted;
}

- (NSString*)basicPlaceholderTemplate:(NSString *)body {
  
  NSString *idiom = [Utilities isIpad] ? @"" : @"iphone";
  NSString *cssPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"basic%@",idiom]
                                                      ofType:@"css"];
  NSError *cssError = nil;
  NSString *css = [NSString stringWithContentsOfFile:cssPath
                                            encoding:NSUTF8StringEncoding
                                               error:&cssError];
  
  NSString *leftPadding = [Utilities isLandscape] ? @"110px" : @"90px";
  NSString *rightPadding = [Utilities isLandscape] ? @"106px" : @"86px";
  NSString *topPadding = @"1px";
  
  if ( ![Utilities isIpad] ) {
    leftPadding = @"18px";
    rightPadding = @"16px";
    topPadding = @"20px";
  }
  
  CGFloat width = [[UIScreen mainScreen] bounds].size.width;
  NSString *maxCWidth = [NSString stringWithFormat:@"%ldpx",(long)(width-([leftPadding floatValue]+[rightPadding floatValue]))];
  NSString *maxBWidth = [NSString stringWithFormat:@"%ldpx",(long)width];
  
  css = [css stringByReplacingOccurrencesOfString:kLeftPaddingMacro withString:leftPadding];
  css = [css stringByReplacingOccurrencesOfString:kRightPaddingMacro withString:rightPadding];
  css = [css stringByReplacingOccurrencesOfString:kTopMarginMacro withString:topPadding];
  css = [css stringByReplacingOccurrencesOfString:kMaxContainerWidthMacro withString:maxCWidth];
  css = [css stringByReplacingOccurrencesOfString:kMaxBodyWidth withString:maxBWidth];
  
  NSString *base = [NSString stringWithFormat:@"<html><head>%@</head><body><div id=\"container\">%@</div></body></html>",css,body];
  return base;
}

- (NSString*)standardExternalContentForReducedArticle:(NSDictionary *)reduced {
  NSString *body = [reduced objectForKey:@"content"];
  
  NSString *basic = [Utilities loadHtmlAsString:@"external_template"];
  
  NSError *error = nil;
  

  NSString *idiom = [Utilities isIpad] ? @"" : @"iphone";
  NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"basic%@",idiom]
                                                      ofType:@"css"];
  NSString *css = [[NSString alloc] initWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
  
  NSString *leadImage = [reduced objectForKey:@"lead_image_url"];
  if ( ![Utilities pureNil:[reduced objectForKey:@"lead_image_url"]] ) {
    basic = [basic stringByReplacingOccurrencesOfString:kImageMacro withString:[reduced objectForKey:@"lead_image_url"]];
    if ( [body rangeOfString:leadImage].location != NSNotFound ) {
      body = [body stringByReplacingOccurrencesOfString:leadImage withString:@""];
    }
  } else {
    basic = [basic stringByReplacingOccurrencesOfString:@"||_IMG_YIELD_||" withString:@""];
  }
  
  
  NSString *lp = [Utilities isIpad] ? @"90px" : @"18px";
  NSString *rp = [Utilities isIpad] ? @"86px" : @"16px";
  NSString *tp = [Utilities isIpad] ? @"1px" : @"20px";
  
  css = [css stringByReplacingOccurrencesOfString:kLeftPaddingMacro withString:lp];
  css = [css stringByReplacingOccurrencesOfString:kRightPaddingMacro withString:rp];
  css = [css stringByReplacingOccurrencesOfString:kTopMarginMacro withString:tp];
  
  basic = [basic stringByReplacingOccurrencesOfString:kStylingMacro withString:css];
  basic = [basic stringByReplacingOccurrencesOfString:kBodyMacro withString:body];
  basic = [basic stringByReplacingOccurrencesOfString:kHeadlineMacro withString:[reduced objectForKey:@"title"]];
  
  if ( ![Utilities pureNil:[reduced objectForKey:@"byline"]] ) {
    NSString *byline = [NSString stringWithFormat:@"%@",[reduced objectForKey:@"byline"]];
    basic = [basic stringByReplacingOccurrencesOfString:kBylineMacro
                                             withString:byline];
  } else {
    basic = [basic stringByReplacingOccurrencesOfString:kBylineMacro
                                             withString:@""];
  }
  return basic;
}

- (NSString*)flatEmbedWithReplacementData:(NSString *)vid width:(CGFloat)width height:(CGFloat)height service:(NSString *)service {
  NSString *base = [Utilities loadHtmlAsString:[NSString stringWithFormat:@"flat_%@",service]];
  base = [base stringByReplacingOccurrencesOfString:kWidthMacro
                                         withString:[NSString stringWithFormat:@"%d",(int)width]];
  base = [base stringByReplacingOccurrencesOfString:kHeightMacro
                                         withString:[NSString stringWithFormat:@"%d",(int)height]];
  base = [base stringByReplacingOccurrencesOfString:kEmbedMacro
                                         withString:vid];
  return base;
}

- (NSString*)flatYouTubeWithId:(NSString *)ytid width:(CGFloat)width height:(CGFloat)height {
  return [self flatEmbedWithReplacementData:ytid width:width height:height service:@"youtube"];
}

- (NSString*)flatVimeoEmbedWithId:(NSString *)vid width:(CGFloat)width height:(CGFloat)height {
  return [self flatEmbedWithReplacementData:vid width:width height:height service:@"vimeo"];
}

- (NSString*)writeFileFromData:(NSString *)string toFilename:(NSString *)filename {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *htmlPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"html"];
  BOOL dir;
  
  NSError *error = nil;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:htmlPath isDirectory:&dir];
  if ( !dirExists ) {
    [[NSFileManager defaultManager] createDirectoryAtPath:htmlPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if ( error ) {
      return @"";
    }
  }

  NSString *full = [htmlPath stringByAppendingPathComponent:filename];
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:full];
  
  if ( fileExists ) {
    [[NSFileManager defaultManager] removeItemAtPath:full
                                               error:&error];
  }
  
  [[NSFileManager defaultManager] createFileAtPath:full
                                          contents:[string dataUsingEncoding:NSUTF8StringEncoding]
                                        attributes:nil];
  
  return full;
}

- (void)cleanupTemporaryFiles {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *htmlPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"html"];
    BOOL dir;
    
    NSError *error = nil;
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:htmlPath
                                                          isDirectory:&dir];
    
    if ( !dirExists ) {
      return;
    }
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:htmlPath
                                                                            error:&error];
    int count = 0;
    for ( NSString *filename in contents ) {
      
      
      if ( [filename rangeOfString:@"article_base"].location == NSNotFound &&
           [filename rangeOfString:@"blank-"].location == NSNotFound ) {
        continue;
      }
      
      count++;
      NSString *full = [htmlPath stringByAppendingPathComponent:filename];
      BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:full];
      
      if ( fileExists ) {
        [[NSFileManager defaultManager] removeItemAtPath:full
                                                   error:&error];
        NSLog(@"Removed %@",[[full componentsSeparatedByString:@"/"] lastObject]);
      }
    }
    
    NSLog(@"Removed %d temporary files",count);
    
  });

  
}

- (NSString*)writeContents:(NSString *)data toFilename:(NSString *)filename {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *htmlPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"html"];
  BOOL dir;
  
  NSError *error = nil;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:htmlPath isDirectory:&dir];
  if ( !dirExists ) {
    [[NSFileManager defaultManager] createDirectoryAtPath:htmlPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if ( error ) {
      return @"";
    }
  }
  
  NSArray *comps = [filename componentsSeparatedByString:@"."];
  NSString *base = @"";
  NSString *suffix = @"";
  NSString *fullPath = @"";
  if ( [comps count] > 1 ) {
    base = [comps objectAtIndex:0];
    suffix = [comps objectAtIndex:1];
    fullPath = [[NSBundle mainBundle] pathForResource:base
                                               ofType:suffix];
  } else {
    base = [comps objectAtIndex:0];
    fullPath = [[NSBundle mainBundle] pathForResource:base
                                               ofType:@""];
  }
  
  NSString *copied = [NSString stringWithFormat:@"%@/html/%@",[paths objectAtIndex:0],filename];
  
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:copied];
  
  if ( fileExists ) {
    [[NSFileManager defaultManager] removeItemAtPath:copied
                                               error:&error];
  }
  
  if ( error ) {
    NSLog(@"Couldn't remove file at path : %@",copied);
  }
  
  [[NSFileManager defaultManager] createFileAtPath:copied
                                          contents:[data dataUsingEncoding:NSUTF8StringEncoding]
                                        attributes:nil];
  
  return copied;
  
}

- (NSString*)copyFromMainBundleToDocuments:(NSString*)sourceName destName:(NSString*)destName {
  return [self copyFromMainBundleToDocuments:sourceName destName:destName root:NO];
}

- (NSString*)copyFromMainBundleToDocuments:(NSString *)sourceName destName:(NSString *)destName root:(BOOL)root {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *htmlPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"html"];
  if ( root ) {
    htmlPath = [paths objectAtIndex:0];
  }
  BOOL dir;
  
  NSError *error = nil;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:htmlPath isDirectory:&dir];
  if ( !dirExists ) {
    [[NSFileManager defaultManager] createDirectoryAtPath:htmlPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if ( error ) {
      return @"";
    }
  }
  
  NSArray *comps = [sourceName componentsSeparatedByString:@"."];
  NSString *base = @"";
  NSString *suffix = @"";
  NSString *fullPath = @"";
  if ( [comps count] > 1 ) {
    base = [comps objectAtIndex:0];
    suffix = [comps objectAtIndex:1];
    fullPath = [[NSBundle mainBundle] pathForResource:base
                                               ofType:suffix];
  } else {
    base = [comps objectAtIndex:0];
    fullPath = [[NSBundle mainBundle] pathForResource:base
                                               ofType:@""];
  }
  
  NSString *copied = [NSString stringWithFormat:@"%@/html/%@",[paths objectAtIndex:0],destName];
  if ( root ) {
    copied = [NSString stringWithFormat:@"%@/%@",[paths objectAtIndex:0],destName];
  }
  
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:copied];
  
  if ( fileExists ) {
    if ( [suffix isEqualToString:@"png"] ) {
      return copied;
    }
    [[NSFileManager defaultManager] removeItemAtPath:copied
                                               error:&error];
  }
  
  if ( error ) {
    NSLog(@"Couldn't remove file at path : %@",copied);
  }
  
  if ( !fullPath ) {
    return @"";
  }
  
  [[NSFileManager defaultManager] copyItemAtPath:fullPath
                                          toPath:copied
                                           error:&error];
  if ( error ) {
    NSLog(@"Error copying %@ to %@ : %@",fullPath,copied,[error localizedDescription]);
  }
  
  return copied;
}

- (NSArray*)loadVideoPages:(NSArray *)links options:(NSDictionary *)options {
  
  // Options
  //
  // height{x} : 300.0
  // width{x} : 500.0

  NSError *error = nil;
  NSString *width = [Utilities isIpad] ? @"600.0" : @"300.0";
  NSString *height = [Utilities isIpad] ? @"338.0" : @"169.0";
  NSString *frame = [Utilities isIpad] ? @"768.0" : @"320.0";
  NSString *type = @"";
  
  NSString *template = @"<div></div>";
  
  int count = 0;
  
  NSMutableArray *paths = [[NSMutableArray alloc] init];
  
  
  
  for ( NSString *s in links ) {
    BOOL vimeoOrYouTube = NO;
    if ( [s rangeOfString:@"vimeo.com"].location != NSNotFound ) {
      template = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vimeo_container"
                                                                                          ofType:@"html"]
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
      
      NSArray *videoComponents = [s componentsSeparatedByString:@"/"];
      NSString *str = [videoComponents lastObject];
      
      template = [template stringByReplacingOccurrencesOfString:kEmbedMacro
                                                     withString:str];
      
      type = @"vimeo";
      vimeoOrYouTube = YES;
    }
    if ( [s rangeOfString:@"youtube.com"].location != NSNotFound ) {
      template = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"youtube_container"
                                                                                          ofType:@"html"]
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
      
      NSString *tokenizer = @"/";
      if ( [s rangeOfString:@"watch?"].location != NSNotFound ) {
        tokenizer = @"=";
      }
      
      NSArray *videoComponents = [s componentsSeparatedByString:tokenizer];
      NSString *str = [videoComponents lastObject];
      template = [template stringByReplacingOccurrencesOfString:kEmbedMacro
                                                     withString:str];
      
      type = @"youtube";
      vimeoOrYouTube = YES;
    }
    
    if ( !vimeoOrYouTube ) {
      NSString *bcPath = [NSString stringWithFormat:@"brightcove:%@",s];
      [paths addObject:bcPath];
      continue;
    }
    
    if ( options ) {
      NSValue *widthOverride = [options objectForKey:[NSString stringWithFormat:@"width%d",count]];
      if ( widthOverride ) {
        width = [NSString stringWithFormat:@"%@",widthOverride];
      }
      
      NSValue *heightOverride = [options objectForKey:[NSString stringWithFormat:@"height%d",count]];
      if ( heightOverride ) {
        height = [NSString stringWithFormat:@"%@",heightOverride];
      }
    }
    
    template = [template stringByReplacingOccurrencesOfString:kWidthMacro
                                                     withString:width];
    template = [template stringByReplacingOccurrencesOfString:kHeightMacro
                                                   withString:height];
    
    NSArray *videoComponents = [s componentsSeparatedByString:@"/"];
    NSString *str = [videoComponents lastObject];
    
    template = [template stringByReplacingOccurrencesOfString:kEmbedMacro
                                                   withString:str];
    
    template = [template stringByReplacingOccurrencesOfString:kFrameWidthMacro
                                                   withString:frame];
    
    //NSLog(@"Template : %@",template);
    
    NSString *hotPath = [self writeContents:template
                                 toFilename:[NSString stringWithFormat:@"currentvideo%d.html",count]];
    count++;
    
    [paths addObject:hotPath];
  }
  

  return paths;
}

- (NSString*)bodyWithInlineAsset:(NSString *)body image:(NSDictionary *)image {
  
  NSRange pRange = [body rangeOfString:@"<p>"];
  if ( pRange.location == NSNotFound ) {
    NSLog(@" ********** NO P TAG FOUND ********** ");
    return body;
  }
  
  NSString *caption = [image objectForKey:@"caption"];
  if ( [Utilities pureNil:caption] ) {
    caption = @"";
  }
  
  NSString *owner = [image objectForKey:@"owner"];
  if ( [Utilities pureNil:owner] ) {
    owner = @"";
  }
  
  NSDictionary *thumb = [image objectForKey:@"thumbnail"];
  NSString *width = [thumb objectForKey:@"width"];
  NSString *height = [thumb objectForKey:@"height"];
  
  NSString *first = [body substringToIndex:pRange.location];
  NSString *rest = [body substringFromIndex:pRange.location+pRange.length];
  NSString *snippet = [NSString stringWithFormat:@"<div id=\"floating_asset\"><img src=\"%@\" width=\"%@\" height=\"%@\"><br/>%@<div id=\"fa_credit\">%@</div></div>",[thumb objectForKey:@"url"],
                       width,height,caption,owner];
  NSString *reformed = [NSString stringWithFormat:@"%@<p>%@%@",first,snippet,rest];
  //NSLog(@"Reformed body : %@",reformed);
  
  return reformed;
  
  
}

- (NSString*)htmlContentFromFile:(NSString*)file {
  NSError *error = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *htmlPath = [NSString stringWithFormat:@"%@/%@/%@", [paths objectAtIndex:0], @"html",file];
  NSString *s = [[NSString alloc] initWithContentsOfFile:htmlPath
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];
  if ( error ) {
    return nil;
  }
  
  return s;
}

- (NSString*)htmlPageFromBody:(NSString *)body article:(NSDictionary *)article style:(StyleType)styleType {
  if ( [Utilities pureNil:body] ) {
    return @"Error fetching content";
  }
  
#ifdef TESTING_PARSER
  body = [Utilities loadHtmlAsString:@"parser_test"];
#endif
  
  NSString *leftPadding = [Utilities isLandscape] ? @"100px" : @"90px";
  NSString *rightPadding = [Utilities isLandscape] ? @"100px" : @"86px";
  NSString *lp = [Utilities isIpad] ? leftPadding : @"18px";
  NSString *rp = [Utilities isIpad] ? rightPadding : @"16px";
  NSString *tp = [Utilities isIpad] ? @"4px" : @"20px";
  CGFloat width = [[UIScreen mainScreen] bounds].size.width;
  NSString *maxCWidth = [NSString stringWithFormat:@"%ldpx",(long)(width-([lp floatValue]+[rp floatValue]))];
  NSString *maxBWidth = [NSString stringWithFormat:@"%ldpc",(long)width];

  

  NSArray *embeds = @[];

  
  embeds = [self collectEmbedded:body
                            type:VideoTypeYouTube];
  
  body = [self applyEmbeds:embeds
                      body:body];
  
  
  NSError *error = nil;
  NSString *content = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"basic"
                                                                                               ofType:@"html"]
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
  
  switch (styleType) {
    case StyleTypeBasic:
    {
      NSString *idiom = [Utilities isIpad] ? @"" : @"iphone";
      NSString *bsPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"basic%@",idiom]
                                                          ofType:@"css"];
      NSString *basicCSS = [NSString stringWithContentsOfFile:bsPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
      
      content = [content stringByReplacingOccurrencesOfString:kStylingMacro withString:basicCSS];
      break;
    }
    case StyleTypeNone:
    case StyleTypeSingleVideo:
    {
      content = [content stringByReplacingOccurrencesOfString:kStylingMacro withString:@""];
    }
    default:
      break;
  }
  
  content = [content stringByReplacingOccurrencesOfString:kYieldMacro withString:body];
  content = [content stringByReplacingOccurrencesOfString:kLeftPaddingMacro withString:lp];
  content = [content stringByReplacingOccurrencesOfString:kRightPaddingMacro withString:rp];
  content = [content stringByReplacingOccurrencesOfString:kTopMarginMacro withString:tp];
  //content = [content stringByReplacingOccurrencesOfString:kMaxContainerWidthMacro withString:maxCWidth];
  content = [content stringByReplacingOccurrencesOfString:kMaxBodyWidth withString:maxBWidth];
  /*if ( [embeds count] > 0 ) {
    content = [self modifyJavascriptInContainer:embeds
                                      container:content];
  }*/
  
  content = [self finalCleanup:content];
  
  NSString *articleName = [NSString stringWithFormat:@"article_base_%d.html",(int)random() % 308092];
  return [self writeContents:content toFilename:articleName];
}

- (NSString*)htmlPageFromBody:(NSString *)body {
  
  return [self htmlPageFromBody:body
                        article:nil];

}

- (NSString*)htmlPageFromBody:(NSString *)body article:(NSDictionary *)article {
  return [self htmlPageFromBody:body
                        article:article
                          style:StyleTypeBasic];
}

- (NSString*)finalCleanup:(NSString *)content {
  content = [content stringByReplacingOccurrencesOfString:kYouTubeYieldMacro
                                               withString:@""];
  content = [content stringByReplacingOccurrencesOfString:kYouTubeHashMacro
                                               withString:@""];
  content = [content stringByReplacingOccurrencesOfString:@"src=\"//" withString:@"src=\"http://"];
  
  return content;
}

/*******************************************************************************************
 -- Developer Note --
 This method signature should be deprecated. "type" is no longer used for anything. This method collects
 embeds based on the Embeditor signature and not any types defined by the app
 */
- (NSArray*)collectEmbedded:(NSString *)body type:(VideoType)type {
  
  NSMutableArray *embeds = [[NSMutableArray alloc] init];
  //if ( type == VideoTypeYouTube ) {
    NSString *token = @"<a class=\"embed-placeholder\"";
    NSRange partial = [body rangeOfString:token];
    NSInteger count = 0;
    NSInteger offset = 0;
    NSString *frontClip = [NSString stringWithString:body];
    while ( partial.location != NSNotFound ) {
      
      frontClip = [frontClip substringFromIndex:partial.location];
      offset += partial.location;
      
      NSRange endTag = [frontClip rangeOfString:@"</a>"];
      NSString *clipped = [frontClip substringToIndex:endTag.location+endTag.length];
    
      NSString *src = [Utilities getValueForHTMLTag:@"href"
                                             inBody:clipped];
      
      NSString *title = [Utilities getValueForHTMLTag:@"title"
                                               inBody:clipped];
      
      NSString *data = [Utilities getValueForHTMLTag:@"data-service"
                                              inBody:clipped];
      
      
      BOOL ssl = [src rangeOfString:@"https://"].location != NSNotFound;
      NSString *tokenB = ssl ? @"https://" : @"http://";
      
      if ( ssl ) {
        src = [src stringByReplacingOccurrencesOfString:tokenB
                                           withString:[NSString stringWithFormat:@"extern_ssl_%@://",data]];
      } else {
        src = [src stringByReplacingOccurrencesOfString:tokenB
                                             withString:[NSString stringWithFormat:@"extern_%@://",data]];
      }

      NSString *fauxStyle = @"";
      NSString *imgName = [Utilities isRetina] ? @"icon-embed@2x.png" : @"icon-embed.png";
      if ( [data isEqualToString:@"twitter"] ) {
        imgName = [Utilities isRetina] ? @"icon-embed-twitter@2x.png" : @"icon-embed-twitter.png";
      }
      if ( [data isEqualToString:@"vimeo"] || [data isEqualToString:@"youtube"] ) {
        imgName = [Utilities isRetina] ? @"icon-embed-video@2x.png" : @"icon-embed-video.png";
      }
      if ( [data isEqualToString:@"googlemaps"] ) {
        imgName = [Utilities isRetina] ? @"icon-embed-map@2x.png" : @"icon-embed-map.png";
      }
      if ( [data isEqualToString:@"polldaddy"] ) {
        imgName = [Utilities isRetina] ? @"icon-embed-poll@2x.png" : @"icon-embed-poll.png";
      }
      NSString *modifiedClip = [NSString stringWithFormat:@"<div class=\"oembed\" style=\"%@\"><div class=\"oembed-image\"><img width=\"27px\" height=\"19px\" src=\"%@\"></div><a href=\"%@\">%@</a></div>",fauxStyle,imgName,src,title];
    
      NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
      if ( [data isEqualToString:@"twitter"] ) {
        
        NSArray *comps = [src componentsSeparatedByString:@"/"];
        NSString *tid = [comps lastObject];
        NSString *full = [NSString stringWithFormat:@"twitter_%@",tid];
        
        modifiedClip = [NSString stringWithFormat:@"<div id=\"%@\"><div class=\"oembed\" style=\"%@\"><div class=\"oembed-image\"><img width=\"27px\" height=\"19px\" src=\"%@\"></div><a href=\"%@\">%@</a></div></div>",full,fauxStyle,imgName,src,title];
        
        if ( self.listener ) {
          [self.listener parserFoundItemOfInterest:[NSString stringWithFormat:@"twitter_%@",tid]];
        }
        
      }
      if ( [data isEqualToString:@"youtube"] ) {
        
        NSString *ytid = [Utilities clipOutYouTubeID:src];
        NSString *overlayImage = [Utilities isRetina] ? @"flatPlayOverlay@2x.png" : @"flatPlayOverlay.png";
        
        NSString *width = [Utilities isIpad] ? @"480px" : @"240px";
        NSString *height = [Utilities isIpad] ? @"360px" : @"180px";
        
        modifiedClip = [NSString stringWithFormat:@"<div id=\"framecontainer\"><div id=\"freezeframe\"><a href=\"%@\"><img style=\"background:url('http://img.youtube.com/vi/%@/0.jpg'); width: %@; height:%@;\" src=\"%@\"></a></div></div>",src,ytid,width,height,overlayImage];
        
        
      }

      //NSValue *value = [NSValue valueWithRange:NSMakeRange(offset, partial.length)];
      
      [params setObject:modifiedClip forKey:@"snippet"];
      [params setObject:clipped forKey:@"original"];
      
      /*NSDictionary *params = @{ @"snippet" : modifiedClip, @"original" : clipped };*/
      [embeds addObject:params];
      
      frontClip = [frontClip stringByReplacingOccurrencesOfString:clipped
                                                       withString:modifiedClip];
      
      count++;
      
      partial = [frontClip rangeOfString:token];

  }

  return [NSArray arrayWithArray:embeds];
}

- (NSString*)embedYouTubeInBody:(NSArray *)embeds body:(NSString *)body {
  
  for ( unsigned i = 0; i < [embeds count]; i++ ) {
    NSDictionary *embed = [embeds objectAtIndex:i];
    NSString *snippet = [embed objectForKey:@"snippet"];
    NSString *original = [embed objectForKey:@"original"];
    //NSLog(@"YouTube Snippet : %@",snippet);
    body = [body stringByReplacingOccurrencesOfString:original
                                           withString:snippet];
  }

  return body;
}

- (NSString*)applyEmbeds:(NSArray *)embeds body:(NSString *)body {
  
  for ( unsigned i = 0; i < [embeds count]; i++ ) {
    NSDictionary *embed = [embeds objectAtIndex:i];
    NSString *snippet = [embed objectForKey:@"snippet"];
    NSString *original = [embed objectForKey:@"original"];
    //NSLog(@"YouTube Snippet : %@",snippet);
    body = [body stringByReplacingOccurrencesOfString:original
                                           withString:snippet];
  }
  
  return body;
}

- (NSString*)modifyJavascriptInContainer:(NSArray *)embeds container:(NSString *)container {
  NSString *master = @"";
  NSString *hash = @"";
  for ( unsigned i = 0; i < [embeds count]; i++ ) {
    
    NSDictionary *embed = [embeds objectAtIndex:i];
    NSString *width = [embed objectForKey:@"width"];
    NSString *height = [embed objectForKey:@"height"];
    NSString *yID = [embed objectForKey:@"id"];
  
    
    NSError *error = nil;
    NSString *shellPath = [[NSBundle mainBundle] pathForResource:@"youtube_snippet"
                                                          ofType:@"html"];
    NSString *shell = [[NSString alloc] initWithContentsOfFile:shellPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    shell = [shell stringByReplacingOccurrencesOfString:kWidthMacro
                                             withString:width];
    shell = [shell stringByReplacingOccurrencesOfString:kHeightMacro
                                             withString:height];
    shell = [shell stringByReplacingOccurrencesOfString:kEmbedMacro
                                             withString:yID];
    shell = [shell stringByReplacingOccurrencesOfString:kYouTubeIDMacro
                                             withString:[NSString stringWithFormat:@"%d",i]];
    
    master = [NSString stringWithFormat:@"%@%@",master,shell];
    hash = [hash stringByAppendingFormat:@"hash['player%d'] = player%d; ",i,i];
    
  }
  
  

  container = [container stringByReplacingOccurrencesOfString:kYouTubeYieldMacro
                                         withString:master];
  container = [container stringByReplacingOccurrencesOfString:kYouTubeHashMacro
                                                   withString:hash];
  
  //NSLog(@"BODY IS NOW : %@",container);
  return container;
}

- (NSString*)replaceBadAssetLinks:(NSString *)source {

  NSDictionary *literal = (NSDictionary*)[Utilities loadJson:@"badassets"];
  NSArray *badAssets = [literal objectForKey:@"bad-assets"];
  
  
  for ( unsigned count = 0; count < [badAssets count]; count++ ) {
    NSDictionary *assetC = [badAssets objectAtIndex:count];
    NSString *asset = [assetC objectForKey:@"crux"];

    NSRange r = [source rangeOfString:asset];
    while ( r.location != NSNotFound ) {
      
      
      NSString *iframe = [assetC objectForKey:@"token"];
      
      NSRange countBackward = NSMakeRange(r.location-[iframe length], [iframe length]);
      NSString *candidate = [source substringWithRange:countBackward];
      BOOL found = NO;
      while ( countBackward.location > 0 ) {
        countBackward.location--;
        candidate = [source substringWithRange:countBackward];
        if ( [candidate isEqualToString:iframe] ) {
          found = YES;
          break;
        }
      }
      if ( found ) {
        
        NSString *endToken = [assetC objectForKey:@"token"];
        endToken = [endToken stringByReplacingOccurrencesOfString:@" " withString:@""];
        endToken = [endToken stringByReplacingOccurrencesOfString:@"<"
                                                       withString:@"</"];
        endToken = [endToken stringByAppendingString:@">"];
        NSString *frontClip = [source substringFromIndex:countBackward.location];
        NSRange end = [frontClip rangeOfString:endToken];
        if ( end.location == NSNotFound ) {
          continue;
        }
        NSString *snippet = [frontClip substringToIndex:end.location+end.length];
        NSString *value = [Utilities getValueForHTMLTag:@"src"
                                                 inBody:snippet];
        
        NSString *replacement = [NSString stringWithFormat:@"<a href=extern_%d%@>%@</a>",count,value,value];
        if ( !value || ![Utilities validLink:value] ) {
          replacement = @"";
        }
        
        
        NSLog(@"Replacing with %@",replacement);
        source = [source stringByReplacingOccurrencesOfString:snippet
                                                   withString:replacement];
      }
      
      r = [source rangeOfString:asset];
      
    }
    
  }
  
  return source;
}

@end
