//
//  Utilities.m
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "Utilities.h"
#import <CFNetwork/CFNetwork.h>
#import <CommonCrypto/CommonDigest.h>
#import "global.h"
#import "SCPRTitlebarViewController.h"
#import "SCPRMasterRootViewController.h"

static NSString *kImgTagHint = @"<img src=\"";
static NSString *illegal = @"!@#$%^&*()+œ∑´®†¥¨ˆøπ{}[]“‘åß∂ƒ©˙∆˚¬…æ;'Ω\"Ω≈ç√∫˜µ,.<>/\\?Œ„:'|´‰ˇÁ¨ˆØ∏”’ÅÍÎÏ˝ÓÔÒÚÆ¸˛Ç◊ı˜Â¯˘¿⁄€‹›ﬁﬂ‡°·‚±¡™£¢∞§¶•ªº≠ -";
static char *alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation Utilities

+ (NSString*)urlize:(NSString *)dirty {
  
  NSString *escapedValue = [dirty stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return escapedValue;
  
}

#pragma mark - Environment checking
+ (BOOL)isIpad {
  return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+ (BOOL)isIOS7 {
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
    return NO;
  }
  
  return YES;
}

+ (BOOL)isRetina {
  return [[UIScreen mainScreen] scale] == 2.0;
}

+ (BOOL)isLandscape {
  return ([[DesignManager shared] predictedWindowSize].width > [[DesignManager shared] predictedWindowSize].height);
  
  //return UIDeviceOrientationIsLandscape([[Utilities del] masterRootController].interfaceOrientation);
}


#pragma mark - View manipulation
+ (void)manuallyStretchView:(UIView *)view {
  view.frame = CGRectMake(view.frame.origin.x,
                          view.frame.origin.y,
                          view.frame.size.width,
                          view.frame.size.height+20.0);
}

+ (void)animStart:(id)del sel:(SEL)sel {
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.25];
  if ( sel && del ) {
    [UIView setAnimationDelegate:del];
    [UIView setAnimationDidStopSelector:sel];
  }
}

+ (void)animEnd {
  [UIView commitAnimations];
}

#pragma mark - Digest

+ (NSString*)sha1:(NSString*)input {

  input = [NSString stringWithFormat:@"%@",input];
  
  
  const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
  NSData *data = [NSData dataWithBytes:cstr length:input.length];
  
  uint8_t digest[CC_SHA1_DIGEST_LENGTH];
  
  CC_SHA1(data.bytes, data.length, digest);
  
  NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
  
  for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x", digest[i]];
  
  return output;
}

+(NSString *)base64:(NSData *)input {
  int encodedLength = (((([input length] % 3) + [input length]) / 3) * 4) + 1;
  unsigned char *outputBuffer = malloc(encodedLength);
  unsigned char *inputBuffer = (unsigned char *)[input bytes];
  
  NSInteger i;
  NSInteger j = 0;
  int remain;
  
  for(i = 0; i < [input length]; i += 3) {
    remain = [input length] - i;
    
    outputBuffer[j++] = alphabet[(inputBuffer[i] & 0xFC) >> 2];
    outputBuffer[j++] = alphabet[((inputBuffer[i] & 0x03) << 4) |
                                 ((remain > 1) ? ((inputBuffer[i + 1] & 0xF0) >> 4): 0)];
    
    if(remain > 1)
      outputBuffer[j++] = alphabet[((inputBuffer[i + 1] & 0x0F) << 2)
                                   | ((remain > 2) ? ((inputBuffer[i + 2] & 0xC0) >> 6) : 0)];
    else
      outputBuffer[j++] = '=';
    
    if(remain > 2)
      outputBuffer[j++] = alphabet[inputBuffer[i + 2] & 0x3F];
    else
      outputBuffer[j++] = '=';
  }
  
  outputBuffer[j] = 0;
  
  NSString *result = [NSString stringWithCString:(const char*)outputBuffer
                                        encoding:NSUTF8StringEncoding];
  free(outputBuffer);
  
  return result;
}



#pragma mark - String Utilities
+ (NSString*)stripBadCharacters:(NSString *)dirty {
  
  NSString *str = [NSString stringWithString:dirty];

  NSMutableArray *illegalArray = [[NSMutableArray alloc] init];
  for ( unsigned x = 0; x < [illegal length]; x++ ) {
    NSString *sub = [illegal substringWithRange:NSMakeRange(x, 1)];
    [illegalArray addObject:sub];
  }
  
  @autoreleasepool {
    for ( NSString *c in illegalArray ) {
      str = [str stringByReplacingOccurrencesOfString:c
                                           withString:@""];
    }
  }

  
  return str;
  
}

+ (NSString*)stripLeadingZero:(NSString *)dirty {
  if ( !dirty || [dirty length] == 0 ) {
    return @"";
  }
  if ( [dirty characterAtIndex:0] == '0' ) {
    return [dirty substringFromIndex:1];
  }
  
  return dirty;
}

+ (NSString*)stripTrailingNewline:(NSString *)text {
  if ( [text characterAtIndex:[text length]-1] == '\n' ||
      [text characterAtIndex:[text length]-1] == '\r' ) {
    return [text substringToIndex:[text length]-1];
  }
  
  return text;
}

+ (NSString*)titleize:(NSString *)title {
  
  NSString *programName = [title lowercaseString];
  programName = [programName stringByReplacingOccurrencesOfString:@" " withString:@""];
  programName = [Utilities stripBadCharacters:programName];
  programName = [programName stringByReplacingOccurrencesOfString:@"." withString:@""];
  
  return programName;
  
}

+ (NSString*)unwebbifyString:(NSString *)dirty {
  return [self unwebbifyString:dirty respectLinebreaks:NO];
}



+ (NSString*)unwebbifyString:(NSString *)dirty respectLinebreaks:(BOOL)respectLinebreaks {
  
  [[AnalyticsManager shared] tS];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&rsquo;" withString:@"'"];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&mdash;" withString:@"—"];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&#039;" withString:@"'"];
  
  if ( !respectLinebreaks ) {
    dirty = [dirty stringByReplacingOccurrencesOfString:@"<p>" withString:@" "];
    dirty = [dirty stringByReplacingOccurrencesOfString:@"</p>" withString:@" "];
    dirty = [dirty stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    dirty = [dirty stringByReplacingOccurrencesOfString:@"\n" withString:@""];
  } else {
    dirty = [dirty stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
    dirty = [dirty stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    dirty = [dirty stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    dirty = [dirty stringByReplacingOccurrencesOfString:@"</p>" withString:@"\n\n"];
  }
  
  // Strip trailing newlines
  while ( [dirty characterAtIndex:[dirty length]-1] == '\n' ) {
    dirty = [dirty substringToIndex:[dirty length]-1];
  }
  
  dirty = [dirty stringByReplacingOccurrencesOfString:@"<blockquote>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"</blockquote>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"</em>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"<em>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"</strong>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"<strong>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"</ul>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"<ul>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"</li>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"<li>" withString:@""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&rdquo;" withString:@"\""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"&ldquo;" withString:@"\""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"<u>" withString:@"\""];
  dirty = [dirty stringByReplacingOccurrencesOfString:@"</u>" withString:@"\""];
  
  
  __block NSString *current = [NSString stringWithString:dirty];
  NSError *error = nil;
  
  NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:@"<span.*?>"
                                options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                error:&error];
  
  [regex enumerateMatchesInString:dirty options:0 range:NSMakeRange(0, [dirty length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
    
    NSString *matched = [dirty substringWithRange:[match rangeAtIndex:0]];
    current = [current stringByReplacingOccurrencesOfString:matched withString:@""];
    
  }];
  
  current = [current stringByReplacingOccurrencesOfString:@"</span>" withString:@""];
  
  __block NSString *hrefParser = [NSString stringWithString:current];
  NSError *errorHref = nil;
  
  NSRegularExpression *regexHref = [NSRegularExpression
                                    regularExpressionWithPattern:@"<a href.*?>"
                                    options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                    error:&errorHref];
  
  [regexHref enumerateMatchesInString:current options:0 range:NSMakeRange(0, [current length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
    
    NSString *matched = [current substringWithRange:[match rangeAtIndex:0]];
    hrefParser = [hrefParser stringByReplacingOccurrencesOfString:matched withString:@""];
    
  }];
  
  current = [hrefParser stringByReplacingOccurrencesOfString:@"</a>" withString:@""];
  
  __block NSString *imgParse = [NSString stringWithString:current];
  NSError *errorImg = nil;
  NSRegularExpression *regexImg = [NSRegularExpression
                                   regularExpressionWithPattern:@"<img.*?/>"
                                   options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                   error:&errorImg];
  [regexImg enumerateMatchesInString:current options:0 range:NSMakeRange(0, [current length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
    
    NSString *matched = [current substringWithRange:[match rangeAtIndex:0]];
    imgParse = [imgParse stringByReplacingOccurrencesOfString:matched withString:@""];
    
  }];
  
  
  current = [NSString stringWithString:imgParse];
  
  //[[AnalyticsManager shared] tF:@"Unwebiffy"];
  return current;
}

+ (NSString*)locateFirstParagraph:(NSString *)body {
  NSRange b = [body rangeOfString:@"<p>"];
  NSRange e = [body rangeOfString:@"</p>"];
  NSRange p = NSMakeRange(b.location+3, e.location-(b.location+3));
  NSString *paragraph = [body substringWithRange:p];
  return paragraph;
}


#pragma mark - Versioning
+ (NSString*)higherVersionBetween:(NSString *)thisVersion thatVersion:(NSString *)thatVersion {
  if ( [Utilities version:thisVersion isHigherThan:thatVersion] ) {
    return thisVersion;
  } else {
    return thatVersion;
  }
}

+ (BOOL)version:(NSString *)thisVersion isHigherThan:(NSString *)thatVersion {
  NSArray *thisComps = [thisVersion componentsSeparatedByString:@"."];
  NSArray *thatComps = [thatVersion componentsSeparatedByString:@"."];
  for ( unsigned i = 0; i < [thisComps count]; i++ ) {
    NSInteger first = [[thisComps objectAtIndex:i] intValue];
    NSInteger firstThat = [[thatComps objectAtIndex:i] intValue];
    
    if ( first == firstThat ) {
      continue;
    }
    if ( first > firstThat ) {
      return YES;
    } else {
      return NO;
    }
    
  }
  
  return YES;
}

+ (NSString*)prettyVersion {
#ifndef VERBOSE_VERSION
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
#else  
  return [NSString stringWithFormat:@"%@ %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
          [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
#endif
}

+ (NSString*)prettyShortVersion {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

#pragma mark - Date stuff
+ (NSString*)formalStringFromSeconds:(NSInteger)seconds {
  int s = seconds % 60;
  int minutes = (seconds / 60) % 60;
  int hours = seconds / 3600;
  
  return [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes,s];
}

+ (NSDate*)dateFromRFCString:(NSString *)dateString {
  NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
  //NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  
  //[rfc3339DateFormatter setLocale:enUSPOSIXLocale];
  //[rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'-'ZZ':'ZZ"];
  if ( [Utilities pureNil:dateString] ) {
    return [NSDate date];
  }
  dateString = [dateString stringByReplacingOccurrencesOfString:@":" withString:@""];
  [rfc3339DateFormatter setDateFormat:@"yyyy-MM-dd'T'HHmmssZZZ"];
  [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  
  // Convert the RFC 3339 date time string to an NSDate.
  NSDate *date = [rfc3339DateFormatter dateFromString:dateString];
  if ( !date ) {
    [rfc3339DateFormatter setDateFormat:@"yyyy-MM-dd'T'HHmmss.000ZZZ"];
    date = [rfc3339DateFormatter dateFromString:dateString];
  }
  return date;
}

+ (NSString*)stringFromRFCDate:(NSDate *)date {
  NSString *pretty = [NSDate stringFromDate:date
                                 withFormat:@"yyyy-MM-dd'T'HHmmssZZZ"];
  return pretty;
}

+ (NSString*)prettyStringFromRFCDateString:(NSString *)rawDate {
  NSDate *date = [self dateFromRFCString:rawDate];
  return [NSDate stringFromDate:date
                     withFormat:@"EEEE MMM d, YYYY"];
}

+ (NSString*)isoDateStringFromDate:(NSDate *)date {
  return [NSDate stringFromDate:date
                     withFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
}

+ (NSString*)prettyStringFromSocialCount:(NSInteger)count {

  if (count == 0) {
    return @"0";
  }
  
  if (count > 999) {
    float thousands = (float) count / 1000;
    NSNumberFormatter * formatter =  [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:1];
    [formatter setDecimalSeparator:@"."];
    [formatter setGroupingSeparator:@""];
    return [NSString stringWithFormat:@"%@K",[formatter stringFromNumber:[NSNumber numberWithFloat:thousands]]];
  } else {
    return [NSString stringWithFormat:@"%d", count];
  }
}

+ (NSString*)prettyStringFromSeconds:(NSInteger)seconds {
  
  if ( seconds == 0 ) {
    return @"None";
  }
  
  int s = seconds % 60;
  int minutes = (seconds / 60) % 60;
  int hours = seconds / 3600;
  int days = floor(hours/24);
  
  if ( s >= 30 ) {
    minutes++;
  }
  
  NSString *hourNoun = hours == 1 ? @"hour" : @"hours";
  NSString *dayNoun = @"days";
  NSString *minuteNoun = minutes == 1 ? @"minute" : @"minutes";
  NSString *prepend = @"";
  NSString *append = @"";
  NSString *hoursInclude = @"";
  if ( days >= 1 ) {
    if ( days == 1 ) {
      dayNoun = @"day";
    }
    hours = hours % 24;
    prepend = [NSString stringWithFormat:@" %02d %@",days,dayNoun];
  }
  
  if ( minutes >= 1 ) {
    append = [NSString stringWithFormat:@" %02d %@",minutes,minuteNoun];
  }
  
  if ( hours >= 1 ) {
    hoursInclude = [NSString stringWithFormat:@" %02d %@",hours,hourNoun];
  }
  
  if ( [Utilities pureNil:prepend] && [Utilities pureNil:append] ) {
    return [NSString stringWithFormat:@"About %d seconds",seconds];
  }
  
  return [NSString stringWithFormat:@"About%@%@%@",prepend,hoursInclude,append];
  
}

+ (NSInteger)earliestDate:(NSArray *)dates {
  
  NSDate *earliest = nil;
  NSInteger index = 0;
  for ( unsigned i = 0; i < [dates count]; i++ ) {
    
    NSDate *d = [dates objectAtIndex:i];
    if ( !earliest ) {
      earliest = d;
      continue;
    }
    
    if ( [d timeIntervalSince1970] < [earliest timeIntervalSince1970] ) {
      index = i;
      earliest = d;
    }
  }
  
  return index;
}

+ (NSInteger)latestDate:(NSArray *)dates {
  
  NSDate *latest = nil;
  NSInteger index = 0;
  for ( unsigned i = 0; i < [dates count]; i++ ) {
    
    NSDate *d = [dates objectAtIndex:i];
    if ( !latest ) {
      latest = d;
      continue;
    }
    
    if ( [d timeIntervalSince1970] > [latest timeIntervalSince1970] ) {
      index = i;
      latest = d;
    }
  }
  
  return index;
}

+ (NSString*)specialMonthDayFormatFromDate:(NSDate *)date {

  NSDateComponents *c = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSDayCalendarUnit
                                                        fromDate:date];
  
  NSInteger month = [c month];
  NSInteger day = [c day];
  
  NSString *ms = [Utilities stripLeadingZero:[NSString stringWithFormat:@"%d",month]];
  NSString *ds = [Utilities stripLeadingZero:[NSString stringWithFormat:@"%d",day]];
  NSString *dow = [NSDate stringFromDate:date
                              withFormat:@"EEEE"];
  
  return [NSString stringWithFormat:@"%@, %@/%@",dow,ms,ds];
  
}



#pragma mark - Content operations
+ (NSDictionary*)imageObjectFromBlob:(NSDictionary *)object quality:(AssetQuality)quality {
  NSString *qualityStr = @"";
  switch (quality) {
    case AssetQualityThumb:
      qualityStr = @"thumbnail";
      break;
    case AssetQualitySmall:
      qualityStr = @"small";
      break;
    case AssetQualityLarge:
      qualityStr = @"large";
      break;
    case AssetQualityFull:
      qualityStr = @"full";
      break;
    case AssetQualityUnknown:
      break;
    default:
      break;
  }
  
  
  NSMutableArray *assets = [object objectForKey:@"assets"];
  if ( ![Utilities pureNil:assets] ) {
    NSMutableDictionary *ofInterest = [assets objectAtIndex:0];
    if ( ![Utilities pureNil:ofInterest] ) {
      NSMutableDictionary *q = [ofInterest objectForKey:qualityStr];
      if ( ![Utilities pureNil:q] ) {
        return q;
      }
    }
  }
  
  return nil;
  
}

+ (NSDictionary*)overrideTopicForArticle:(NSDictionary *)article newTopic:(NSString *)topic {
  NSString *json = [article JSONRepresentation];
  NSDictionary *category = [article objectForKey:@"category"];
  if ( !category ) {
    return article;
  }
  
  NSString *replace = [category objectForKey:@"title"];
  json = [json stringByReplacingOccurrencesOfString:replace
                                         withString:topic];
  
  return (NSDictionary*)[json JSONValue];
}

+ (NSDictionary*)convertToArticle:(NSDictionary *)episodeOrSegment {
  NSMutableDictionary *fauxArticle = [[NSMutableDictionary alloc] init];
  [fauxArticle setObject:[episodeOrSegment objectForKey:@"title"]
                  forKey:@"short_title"];
  [fauxArticle setObject:@"http://notimplemented.com"
                  forKey:@"permalink"];
  [fauxArticle setObject:@"" forKey:@"teaser"];
  return [NSDictionary dictionaryWithDictionary:fauxArticle];
}

+ (NSString*)extractImageURLFromBlob:(NSString *)imgTag {
  if ( [Utilities pureNil:imgTag] ) {
    return @"";
  }
  NSRange img = [imgTag rangeOfString:kImgTagHint];
  
  if ( img.location != NSNotFound ) {
    NSString *firstStrip = [imgTag substringFromIndex:img.location+img.length];
    if ( firstStrip ) {
      NSRange crux = NSMakeRange(0, [firstStrip rangeOfString:@"\""].location);
      if ( crux.location != NSNotFound ) {
        return [firstStrip substringWithRange:crux];
      }
    }
  }
  
  return @"";
}

+ (BOOL)article:(NSDictionary *)article isSameAs:(NSDictionary *)thisArticle {
  //NSLog(@"Comparing : %@ with %@",[article objectForKey:@"permalink"],[thisArticle objectForKey:@"permalink"]);
  
  if ( [article objectForKey:@"id"] ) {
    if ( [thisArticle objectForKey:@"id"] ) {
      NSString *id1 = [Utilities sha1:[article objectForKey:@"id"]];
      NSString *id2 = [Utilities sha1:[thisArticle objectForKey:@"id"]];
      return [id1 isEqualToString:id2];
    } else {
      return NO;
    }
  }
  if ( [article objectForKey:@"permalink"] ) {
    NSString *hash1 = [Utilities sha1:[article objectForKey:@"permalink"]];
    NSString *hash2 = [Utilities sha1:[thisArticle objectForKey:@"permalink"]];
    return [hash1 isEqualToString:hash2];
  } else if ( [article objectForKey:@"title"] ) {
    NSString *hash1 = [Utilities sha1:[article objectForKey:@"title"]];
    NSString *hash2 = [Utilities sha1:[thisArticle objectForKey:@"title"]];
    return [hash1 isEqualToString:hash2];
  }
  
  return NO;
}

+ (NSString*)extractImageURLFromBlob:(NSDictionary *)object quality:(AssetQuality)quality {
  return [Utilities extractImageURLFromBlob:object quality:quality forceQuality:NO];
}

+ (NSString*)extractImageURLFromBlob:(NSDictionary *)object quality:(AssetQuality)quality forceQuality:(BOOL)forceQuality {
  AssetQuality adjustedQuality = quality;
  
  if ( !forceQuality ) {
    if ( quality == AssetQualityFull ) {
      adjustedQuality = ![Utilities isRetina] ? AssetQualityLarge : AssetQualityFull;
    }
  }
  
  if ( ![Utilities isIpad] ) {
    if ( adjustedQuality == AssetQualityFull ) {
      adjustedQuality = AssetQualityLarge;
    } else if ( adjustedQuality == AssetQualityLarge ) {
      adjustedQuality = AssetQualitySmall;
    }
  }
  
  NSDictionary *q = [Utilities imageObjectFromBlob:object
                                           quality:adjustedQuality];
  if ( ![Utilities pureNil:q] ) {
    if ( adjustedQuality == AssetQualityFull ) {
      //NSLog(@"URL for Image : %@",[q objectForKey:@"url"]);
    }
    return [q objectForKey:@"url"];
  }
  
  return @"";
}

+ (NSDictionary*)collectTappableLinks:(NSString *)body {
  NSMutableDictionary *mutableLinks = [[NSMutableDictionary alloc] init];
  NSString *copy = [NSString stringWithString:body];
  NSString *token = @"<a ";
  NSRange link = [copy rangeOfString:token];
  while ( link.location != NSNotFound ) {
    
    NSString *frontClip = [copy substringFromIndex:link.location];
    NSRange end = [frontClip rangeOfString:@"</a>"];
    NSString *snippet = [frontClip substringToIndex:end.location];
    NSString *linkStr = [Utilities getValueForHTMLTag:@"href"
                                               inBody:snippet];
    [mutableLinks setObject:@1 forKey:linkStr];
    
    //NSLog(@"Link is %@",linkStr);
    
    copy = [frontClip substringFromIndex:end.location];
    link = [copy rangeOfString:token];
  }
  
  return [NSDictionary dictionaryWithDictionary:mutableLinks];
}

+ (BOOL)articleHasAsset:(NSDictionary *)article {
  NSDictionary *assets = [article objectForKey:@"assets"];
  if ( !assets ) {
    return NO;
  }
  
  if ( [assets count] == 0 ) {
    return NO;
  }
  
  return YES;
}

#pragma mark - List and vector helpers
+ (NSDictionary*)reverseHash:(NSDictionary *)hash {
  
  NSMutableDictionary *reversed = [[NSMutableDictionary alloc] init];
  for ( NSString *key in [hash allKeys] ) {
    NSArray *vals = [hash objectForKey:key];
    for ( NSString *val in vals ) {
      [reversed setObject:key forKey:val];
    }
  }
  
  return [NSDictionary dictionaryWithDictionary:reversed];
}

+ (BOOL)validLink:(NSString *)link {
  NSString *urlRegEx =
  @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
  NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
  return [urlTest evaluateWithObject:link];
}

+ (void)primeTitlebarWithText:(NSString *)text shareEnabled:(BOOL)shareEnabled container:(id<Backable>)container {
  [UIView animateWithDuration:0.33 animations:^{
    SCPRTitlebarViewController *titlebar = [[Utilities del] globalTitleBar];
    titlebar.kpccLogo.alpha = 0.0;
    titlebar.editionsLogo.alpha = 0.0;
    
    [titlebar.view addSubview:titlebar.pageTitleLabel];
    [titlebar.pageTitleLabel titleizeText:text bold:YES];
    
    // For showing NewsSectionTableViewController
    if (text && [text isEqualToString:@"SECTIONS"]) {
      [titlebar.pageTitleLabel setTextColor:[[DesignManager shared] sectionsBlueColor]];
    } else {
      [titlebar.pageTitleLabel setTextColor:[UIColor whiteColor]];
    }
    
    //titlebar.view.layer.backgroundColor = [UIColor clearColor].CGColor;
    titlebar.view.layer.backgroundColor = [[DesignManager shared] deepOnyxColor].CGColor;
    titlebar.pageTitleLabel.alpha = 1.0;
    titlebar.pageTitleLabel.hidden = NO;
    
    if ( shareEnabled ) {
      [titlebar applySharingButton];
    }
    
    if ( container ) {
      titlebar.container = container;
    }
    
  }];
  
}

+ (BOOL)isDigit:(unichar)candidate {
  switch (candidate) {
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      return YES;
      break;
      
    default:
      break;
  }
  
  return NO;
}

+ (BOOL)validateEmail:(NSString *)string {
  if ( !string || [string isEqualToString:@""] ) {
    return NO;
  }
  
  NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [emailTest evaluateWithObject:string];
}

#pragma mark - Resource loading
+ (id)loadJson:(NSString *)filename {
  
  NSString *candidate = [[FileManager shared] htmlContentFromFile:[NSString stringWithFormat:@"%@.json",filename]];
  if ( ![Utilities pureNil:candidate] ) {
    return candidate;
  }
  
  NSError *error = nil;
  NSString *s = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle]
                                                          pathForResource:filename
                                                          ofType:@"json"]
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];
  return [s JSONValue];
}

+ (id)loadNib:(NSString *)rawNibName objIndex:(NSInteger)objIndex {
  
  NSString *cn = [[DesignManager shared] xibForPlatformWithName:rawNibName];
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:cn
                                                   owner:nil
                                                 options:nil];
  return [objects objectAtIndex:objIndex];
}

+ (id)loadNib:(NSString *)rawNibName {
  return [Utilities loadNib:rawNibName objIndex:0];
}

+ (NSString*)loadHtmlAsString:(NSString*)htmlFileName {
  NSError *error = nil;
  NSString *s = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle]
                                                          pathForResource:htmlFileName
                                                          ofType:@"html"]
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];
  
  if ( error ) {
    s = @"<html><head></head><body></body></html>";
  }
  
  return s;
}




#pragma mark - Misc
+ (NSUInteger)snapshotEditionForTimeOfDay {
  NSDate *date = [NSDate date];
  NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSHourCalendarUnit
                                                            fromDate:date];
  NSUInteger hour = [comps hour];
  if ( hour < 12 ) {
    return 1;
  }
  if ( hour >= 12 && hour < 17 ) {
    return 2;
  }
  
  return 3;
}



+ (BOOL)pureNil:(id)object {
  if ( !object ) {
    return YES;
  }
  if ( object == [NSNull null] ) {
    return YES;
  }
  if ( [object isKindOfClass:[NSString class]] ) {
    return [(NSString*)object isEqualToString:@""];
  }
  if ( [object isKindOfClass:[NSArray class]] ) {
    return [object count] == 0;
  }
  if ( [object isKindOfClass:[NSDate class]] ) {
    NSDate *date = (NSDate*)object;
    if ( [date isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]] ) {
      return YES;
    }
  }
  if ( [object isKindOfClass:[NSDictionary class]] ) {
    if ( [object count] == 0 ) {
      return YES;
    }
  }
  return NO;
}

+ (NSString*)clipOutYouTubeID:(NSString *)fullLink {
  
  NSRange r = [fullLink rangeOfString:@"v="];
  if ( r.location != NSNotFound ) {
    NSString *rest = [fullLink substringFromIndex:r.location+r.length];
    if ( [rest rangeOfString:@"&"].location != NSNotFound ) {
      NSRange amp = [rest rangeOfString:@"&"];
      rest = [rest substringToIndex:amp.location];
    }
    return rest;
  }
  
  return @"";
  
}



+ (NSString*)generateSlug:(NSString*)name {
  
  name = [name lowercaseString];
  name = [Utilities stripBadCharacters:name];
  return name;
  
}

+ (NSString*)webstyledSlug:(NSDictionary *)article {
  
  NSString *shortTitle = [article objectForKey:@"permalink"];
  if ( [Utilities pureNil:shortTitle] ) {
    return @"nothing";
  }
  
  // Strip trailing slash
  if ( [shortTitle characterAtIndex:[shortTitle length]-1] == (unichar)'/' ) {
    shortTitle = [shortTitle substringToIndex:[shortTitle length]-1];
  }
  
  NSArray *comps = [shortTitle componentsSeparatedByString:@"/"];
  NSString *candidate = [comps lastObject];
  
  if ( ![Utilities pureNil:candidate] ) {
    
    NSString *published = [article objectForKey:@"published"];
    if ( [Utilities pureNil:published] ) {
      return candidate;
    } else {
      
      return [NSString stringWithFormat:@"%@-%@",candidate,published];
      
    }
  }
  
  return @"nothing";
}

+ (SCPRAppDelegate*)del {
  return (SCPRAppDelegate*)[UIApplication sharedApplication].delegate;
}

+ (SCPRViewController*)mainContainer {
  SCPRAppDelegate *del = [Utilities del];
  return (SCPRViewController*)del.viewController;
}

+ (CGFloat)degreesToRadians:(CGFloat) degrees {
  return degrees * M_PI / 180.0;
}

+ (CGFloat)radiansToDegrees:(CGFloat)radians {
  return radians * 180 / M_PI;
}

+ (NSString*)getValueForHTMLTag:(NSString *)tag inBody:(NSString *)body {
  
  NSString *newTag = @"";
  if ( ![tag characterAtIndex:[tag length]-1] == (unichar)'=' ) {
    newTag = [NSString stringWithFormat:@"%@=",tag];
  } else {
    newTag = tag;
  }
  
  NSArray *split = [body componentsSeparatedByString:newTag];
  if ( [split count] > 1 ) {
    NSString *unclippedValue = [split objectAtIndex:1];
    
    NSString *usingChar = @"\"";
    NSRange quote = [unclippedValue rangeOfString:usingChar];
    if ( quote.location == NSNotFound ) {
      usingChar = @"'";
      quote = [unclippedValue rangeOfString:usingChar];
      if ( quote.location == NSNotFound ) {
        NSLog(@"Bad string or key provided");
        return @"";
      }
    }
    
    NSString *quoteClip = [unclippedValue substringFromIndex:quote.location+1];
    NSRange endQuote = [quoteClip rangeOfString:usingChar];
    NSString *finalValue = @"";
    if ( endQuote.location != NSNotFound ) {
       finalValue = [quoteClip substringToIndex:endQuote.location];
    } else {
      finalValue = [quoteClip substringToIndex:[quoteClip length]-1];
    }
    return finalValue;
  }
  
  return @"";
  
}



+ (CGFloat)easeIn:(CGFloat)value {
  return (value == 0.0) ? value : pow(2, 10 * (value - 1));
}

@end
