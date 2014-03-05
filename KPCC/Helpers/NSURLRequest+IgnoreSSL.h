//
//  NSURLRequest+IgnoreSSL.h
//  SCPR.org
//
//  Created by Ben Hochberg on 10/23/12.
//  Copyright (c) 2012 SCPR. All rights reserved.
//
#ifndef PRODUCTION
#import <Foundation/Foundation.h>

@interface NSURLRequest (IgnoreSSL)


+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;


@end
#endif
