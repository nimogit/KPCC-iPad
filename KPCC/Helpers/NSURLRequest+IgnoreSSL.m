//
//  NSURLRequest+IgnoreSSL.m
//  SCPR.org
//
//  Created by Ben Hochberg on 10/23/12.
//  Copyright (c) 2012 SCPR.org. All rights reserved.
//
#ifndef PRODUCTION
#import "NSURLRequest+IgnoreSSL.h"

@implementation NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
	// ignore certificate errors only for this domain
	if ([host hasSuffix:@"scpr.org"])
	{
		return YES;
	}
	else
	{
		return YES;
	}
}

@end
#endif