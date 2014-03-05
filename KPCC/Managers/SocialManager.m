//
//  SocialManager.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SocialManager.h"
#import "global.h"
#import "SBJson.h"
#import "SCPRViewController.h"
#import "SCPRExternalWebContentViewController.h"
#import "XMLDictionary.h"
#import "SCPRLinkedInShareViewController.h"
#import <MessageUI/MessageUI.h>
#import "SCPRListableObject.h"
#import "SCPRCircleView.h"
#import "UIImageView+Analysis.h"
#import "SCPRWebNewsContentViewController.h"

#ifndef PRODUCTION
#import "NSURLRequest+IgnoreSSL.h"
#endif

#define kMPRServer @"https://scprcontribute.publicradio.org/api/members/search.php"
#define kMPRHost @"http://scprcontibute.publicradio.org"


static SocialManager *singleton = nil;
@implementation SocialManager

+ (SocialManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      singleton = [[SocialManager alloc] init];
    }
  }
  
  return singleton;
}

- (void)checkForLoginCredentials {
  NSLog(@"Checking for login credentials...");
  if ( [self isAuthenticatedWithFacebook] ) {
    [self checkForFacebookCredentials];
  } else {
    [self logoutOfFacebook];
  }
  if ( [self isAuthenticatedWithTwitter] ) {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSString *json = [[ContentManager shared].settings twitterInformation];
    NSDictionary *d = (NSDictionary*)[json JSONValue];
    
    [accountStore requestAccessToAccountsWithType:twitterType
                                          options:nil
                                       completion:^(BOOL granted, NSError *error) {
                                         
                                         BOOL found = NO;
                                         if ( granted ) {
                                           NSArray *twitter = [accountStore accountsWithAccountType:twitterType];
                                           for ( ACAccount *account in twitter ) {
                                             if ( [[account username] isEqualToString:[d objectForKey:@"screen_name"]] ) {
                                               found = YES;
                                               self.activeTwitterAccount = account;
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self storeTwitterInformation:[[ContentManager shared].settings twitterInformation]];
                                               });
                                          
                                             }
                                           }
                                         }
                                         
                                         if ( !found ) {
                                           [self performSelectorOnMainThread:@selector(logoutOfTwitter)
                                                                  withObject:nil
                                                               waitUntilDone:NO];
                                         }
                                         
                                       }];

  } else {
    [self logoutOfTwitter];
  }
  
}

- (NSString*)userName {
  if ( [[SocialManager shared] isAuthenticatedWithFacebook] ) {
    return [self facebookName];
  } else if ( [[SocialManager shared] isAuthenticatedWithTwitter] ) {
    return [self twitterName];
  } else if ( [[SocialManager shared] isAuthenticatedWithLinkedIn] ) {
    return [self linkedInName];
  }
  
  return @"Anonymous";
}

- (ShareIntent)intentForString:(NSString *)str {
  if ( [str isEqualToString:@"facebook"] ) {
    return ShareIntentFacebook;
  }
  if ( [str isEqualToString:@"twitter"] ) {
    return ShareIntentTwitter;
  }
  if ( [str isEqualToString:@"tumblr"] ) {
    return ShareIntentTumblr;
  }
  if ( [str isEqualToString:@"email"] ) {
    return ShareIntentEmail;
  }
  if ( [str isEqualToString:@"linkedin"] ) {
    return ShareIntentLinkedIn;
  }
  if ( [str isEqualToString:@"debug"] ) {
    return ShareIntentDebug;
  }
  return ShareIntentUnknown;
}

- (NSString*)stringForIntent:(ShareIntent)intent {
  switch (intent) {
    case ShareIntentFacebook:
      return @"Facebook";
    case ShareIntentTwitter:
      return @"Twitter";
    case ShareIntentEmail:
      return @"Email";
    case ShareIntentLinkedIn:
      return @"LinkedIn";
    case ShareIntentDebug:
    case ShareIntentTumblr:
    case ShareIntentUnknown:
      return @"N/A";
  }
  
  return @"";
}

- (void)shareDispatcher:(ShareIntent)shareIntent article:(id)article delegate:(id)delegate {
  self.materialToShare = article;
  self.shareIntent = shareIntent;
  self.designatedDelegate = delegate;
  switch (self.shareIntent) {
    case ShareIntentFacebook:
      [self shareWithFacebook:article];
      break;
    case ShareIntentTwitter:
      [self shareWithTwitter:article];
      break;
    case ShareIntentLinkedIn:
      [self shareWithLinkedIn:article delegate:delegate];
      break;
    case ShareIntentEmail:
      [self shareWithEmail:article delegate:delegate];
      break;
    case ShareIntentDebug:
      [self shareWithEmail:article delegate:delegate debug:YES];
      break;
    case ShareIntentUnknown:
    case ShareIntentTumblr:
      [self shareDisabled];
      break;
    default:
      break;
  }

  
}

- (void)sharingFinished {
  
  NSString *name = @"";
  switch ( self.shareIntent ) {
    case ShareIntentEmail:
      name = @"email";
      break;
    case ShareIntentFacebook:
      name = @"facebook";
      break;
    case ShareIntentTwitter:
      name = @"twitter";
      break;
    case ShareIntentLinkedIn:
      name = @"linkedin";
      break;
    case ShareIntentTumblr:
    case ShareIntentUnknown:
    default:
      break;
  }
  
  [[AnalyticsManager shared] logEvent:@"shared_article"
                       withParameters:@{ @"shareType" : name }];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"sharing_finished"
                                                      object:[NSNumber numberWithInt:(int)self.shareIntent]];
  

  
  self.shareIntent = ShareIntentUnknown;
}

- (NSString*)signInInformation {
  if ( [self isAuthenticatedWithFacebook] ) {
    return @"Facebook";
  }
  if ( [self isAuthenticatedWithLinkedIn] ) {
    return @"LinkedIn";
  }
  if ( [self isAuthenticatedWithTwitter] ) {
    return @"Twitter";
  }
  if ( [self isAuthenticatedWithMembership] ) {
    return @"Member";
  }
  return @"Not Signed In";
}

- (BOOL)isConnected {
  NSString *sii = [self signInInformation];
  if ( [sii rangeOfString:@"Not Signed In"].location == NSNotFound ) {
    return YES;
  }
  
  return NO;
}

- (void)circumscribeImageWithURL:(NSString*)image toImage:(UIImageView *)imgView completion:(ImageAppearedCallback)completion {
  imgView.contentMode = UIViewContentModeScaleAspectFill;
  imgView.clipsToBounds = YES;
  [imgView loadImage:image quietly:NO
               queue:[[ContentManager shared] globalImageQueue]
           forceSize:NO
          completion:^{
            
            if ( completion ) {
              dispatch_async(dispatch_get_main_queue(), completion);
            }
            
          }];
}

- (void)failoverCirclize:(NSTimer*)timer {
  
  if ( self.failoverCount > 20 ) {
    self.failoverCount = 0;
    return;
  }
  
  self.failoverCount++;
  NSDictionary *meta = (NSDictionary*)[timer userInfo];
  ImageAppearedCallback callback = ^(void){};
  if ( [meta objectForKey:@"completion"] ) {
    callback = [meta objectForKey:@"completion"];
  }
  
  NSString *url = [meta objectForKey:@"url"];
  UIImageView *imgView = [meta objectForKey:@"imgView"];
  
  [self circumscribeImageWithURL:url
                         toImage:imgView completion:callback];
  
}

#pragma mark - LinkedIn
- (void)loginWithLinkedIn:(id)delegate silent:(BOOL)silent {
  self.linkedInSilence = silent;
  
  if ( !self.linkedInSilence ) {
    if ( [[ContentManager shared].settings linkedInToken] && ![Utilities pureNil:[[ContentManager shared].settings linkedInToken]] ) {
      [[ContentManager shared].settings setSingleSignOnWithLinkedIn:YES];
      [[ContentManager shared] writeSettings];
      
      [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                          object:nil];
      return;
    }
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkedInComplete:)
                                               name:@"linked_in_stored"
                                             object:nil];
  
  NSString *linkedInURL = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/authorization?response_type=code&scope=r_basicprofile%%20r_emailaddress%%20rw_nus&client_id=%@&state=%@&redirect_uri=%@",[self linkedInAppKey],[Utilities sha1:[NSString stringWithFormat:@"%d",(int)time(NULL)]],
                           [self linkedInRedirectPrefix]];
  NSURL *url = [NSURL URLWithString:linkedInURL];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  
  SCPRExternalWebContentViewController *webContent = [[SCPRExternalWebContentViewController alloc]
                                                      initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRExternalWebContentViewControllerSmall"
                                                                       ] bundle:nil];
  self.linkedInWebView = webContent;
  webContent.view.frame = webContent.view.frame;
  webContent.expectsRedirectURI = YES;
  webContent.delegate = (id<ExternalWebContentDelegate>)delegate;
  webContent.redirectPrefix = [self linkedInRedirectBase];
  webContent.webContentView.scrollView.scrollEnabled = NO;
  [[Utilities del] cloakUIWithCustomView:webContent];
  [webContent prime:request];
}

- (void)loginWithLinkedIn:(id)delegate silent:(BOOL)silent webcontent:(id)webcontent {
  
  
  self.linkedInSilence = silent;
  
  if ( !self.linkedInSilence ) {
    if ( [[ContentManager shared].settings linkedInToken] && ![Utilities pureNil:[[ContentManager shared].settings linkedInToken]] &&
        ![Utilities pureNil:[[ContentManager shared].settings linkedInInformation]] ) {
      [[ContentManager shared].settings setSingleSignOnWithLinkedIn:YES];
      [[ContentManager shared] writeSettings];
      [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                          object:nil];
      return;
    }
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkedInComplete:)
                                               name:@"linked_in_stored"
                                             object:nil];
  
  NSString *linkedInURL = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/authorization?response_type=code&scope=r_basicprofile%%20r_emailaddress%%20rw_nus&client_id=%@&state=%@&redirect_uri=%@",[self linkedInAppKey],[Utilities sha1:[NSString stringWithFormat:@"%d",(int)time(NULL)]],
                           [self linkedInRedirectPrefix]];
  NSURL *url = [NSURL URLWithString:linkedInURL];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  
  SCPRExternalWebContentViewController *webContent1 = (SCPRExternalWebContentViewController*)webcontent;
  self.linkedInWebView = webContent1;
  //[webContent1 loadView];
  webContent1.view.frame = webContent1.view.frame;
  webContent1.expectsRedirectURI = YES;
  webContent1.delegate = (id<ExternalWebContentDelegate>)delegate;
  webContent1.redirectPrefix = [self linkedInRedirectBase];
  webContent1.webContentView.scrollView.scrollEnabled = NO;
  [webContent1 prime:request];
}

- (void)linkedInTradeCodeForToken:(NSString *)code {
  NSString *linkedInURL = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/accessToken?grant_type=authorization_code&code=%@&client_secret=%@&client_id=%@&redirect_uri=%@",code,[self linkedInClientSecret],[self linkedInAppKey],
                           [self linkedInRedirectPrefix]];
  NSURL *url = [NSURL URLWithString:linkedInURL];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           
                           if ( e ) {
                             NSLog(@"Error auth-tokening from Linked In : %@",[e localizedDescription]);
                             [self performSelectorOnMainThread:@selector(linkedInFail)
                                                    withObject:nil
                                                 waitUntilDone:NO];
                             return;
                           }
                           
                           NSString *s = [[NSString alloc] initWithData:d
                                                               encoding:NSUTF8StringEncoding];
                           
                           NSDictionary *dict = (NSDictionary*)[s JSONValue];
                           [self performSelectorOnMainThread:@selector(storeLinkedInInformation:)
                                                  withObject:dict
                                               waitUntilDone:NO];
                         }];
}

- (void)storeLinkedInInformation:(NSDictionary *)info {
  
  NSDate *expiration = [NSDate date];
  long asSeconds = (long)[expiration timeIntervalSince1970];
  NSNumber *expirySeconds = [info objectForKey:@"expires_in"];
  asSeconds += [expirySeconds intValue];
  NSDate *future = [NSDate dateWithTimeIntervalSince1970:asSeconds];
  
  [[ContentManager shared].settings setLinkedInTokenExpire:future];
  [[ContentManager shared].settings setLinkedInToken:[info objectForKey:@"access_token"]];
  [[ContentManager shared] writeSettings];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"linked_in_stored"
                                                      object:@1];
}

- (void)linkedInFail {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"linked_in_stored"
                                                      object:@0];
}

- (void)linkedInComplete:(NSNotification*)note {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"linked_in_stored"
                                                object:nil];
  
  NSNumber *n = (NSNumber*)[note object];
  if ( [n intValue] == 1 ) {
    [self retrieveLinkedInInfo];
  }
}

- (void)retrieveLinkedInInfo {
  NSString *token = [[ContentManager shared].settings linkedInToken];
  NSString *urlString = [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~:(first-name,last-name,picture-url,industry,email-address)?oauth2_access_token=%@",token];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
                           
                           if ( e ) {
                             NSLog(@"Error getting LinkedIn Profile...%@",[e localizedDescription]);
                             return;
                           }
                           
                           
                           [self performSelectorOnMainThread:@selector(processBasicLinkedInProfile:)
                                                  withObject:d
                                               waitUntilDone:NO];
                           
                         }];
}

- (void)processBasicLinkedInProfile:(NSData *)xml {
  NSDictionary *object = [NSDictionary dictionaryWithXMLData:xml];
  NSString *raw = [[NSString alloc] initWithData:xml
                                        encoding:NSUTF8StringEncoding];
  [[ContentManager shared].settings setLinkedInInformation:raw];
  [[ContentManager shared].settings setProfileImageURL:[object objectForKey:@"picture-url"]];
  
  if ( !self.linkedInSilence ) {
    [[ContentManager shared].settings setSingleSignOnWithLinkedIn:YES];
    [[ContentManager shared] writeSettings];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                      object:nil];
  } else {
    self.linkedInSilence = NO;
    [[ContentManager shared].settings setSingleSignOnWithLinkedIn:NO];
    [[ContentManager shared] writeSettings];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in_silently"
                                                        object:nil];
  }
}

- (void)linkedInImageTo:(UIImageView *)imgView {
  [self linkedInImageTo:imgView completion:nil];
  
}

- (void)linkedInImageTo:(UIImageView *)imgView completion:(ImageAppearedCallback)completion {
  NSString *linkedIn = [[ContentManager shared].settings linkedInInformation];
  NSData *d = [linkedIn dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *dict = [NSDictionary dictionaryWithXMLData:d];
  NSString *img = [dict objectForKey:@"picture-url"];
  
  if ( [Utilities pureNil:img] ) {
    [imgView loadLocalImage:@"avatar-default.png"
                    quietly:NO];
    return;
  }
  
  [self circumscribeImageWithURL:img
                         toImage:imgView
                      completion:completion];
  
}

- (void)linkedInNameTo:(UILabel *)nameLabel {
  nameLabel.text = [self linkedInName];
  nameLabel.text = [nameLabel.text capitalizedString];
}

- (NSString*)linkedInName {
  NSString *linkedIn = [[ContentManager shared].settings linkedInInformation];
  if ( linkedIn ) {
    NSDictionary *object = [NSDictionary dictionaryWithXMLString:linkedIn];
    if ( object ) {
      NSString *first = [object objectForKey:@"first-name"];
      NSString *last = [object objectForKey:@"last-name"];
      return [NSString stringWithFormat:@"%@ %@",first,last];
    }
  }
  
  return @"Anonymous";
}

- (BOOL)isAuthenticatedWithLinkedIn {
  NSString *token = [[ContentManager shared].settings linkedInToken];
  NSDate *expire = [[ContentManager shared].settings linkedInTokenExpire];
  
  if ( [expire laterDate:[NSDate date]] != expire ) {
    [[ContentManager shared].settings setLinkedInTokenExpire:nil];
    [[ContentManager shared].settings setLinkedInToken:nil];
    [[ContentManager shared].settings setLinkedInInformation:nil];
    [[ContentManager shared].settings setSingleSignOnWithLinkedIn:NO];
    [[ContentManager shared] setSkipParse:YES];
    [[ContentManager shared] writeSettings];
    return NO;
  }
  
  if ( [Utilities pureNil:token] ) {
    return NO;
  }
  
  
  return [[ContentManager shared].settings singleSignOnWithLinkedIn];
}

- (BOOL)isSilentlyAuthenticatedWithLinkedIn {
  NSString *token = [[ContentManager shared].settings linkedInToken];
  NSDate *expire = [[ContentManager shared].settings linkedInTokenExpire];
  
  if ( [expire laterDate:[NSDate date]] != expire ) {
    [[ContentManager shared].settings setLinkedInTokenExpire:nil];
    [[ContentManager shared].settings setLinkedInToken:nil];
    [[ContentManager shared].settings setLinkedInInformation:nil];
    [[ContentManager shared].settings setSingleSignOnWithLinkedIn:NO];
    [[ContentManager shared] setSkipParse:YES];
    [[ContentManager shared] writeSettings];
    return NO;
  }
  
  if ( [Utilities pureNil:token] ) {
    return NO;
  }

  return YES;
}

- (void)logoutOfLinkedIn {
  [[ContentManager shared].settings setSingleSignOnWithLinkedIn:NO];
  [[ContentManager shared] writeSettings];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_out"
                                                      object:@"linkedin"];
}

- (void)shareWithLinkedIn:(id)article delegate:(id)delegate {
  
  self.materialToShare = article;
  if ( ![self isSilentlyAuthenticatedWithLinkedIn] ) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(failoverLinkedIn)
                                                 name:@"logged_in_silently"
                                               object:nil];
    [self loginWithLinkedIn:delegate silent:YES];
    return;
  }
  
  
  SCPRLinkedInShareViewController *linkedInShare = [[SCPRLinkedInShareViewController alloc]
                                                    initWithNibName:[[DesignManager shared]
                                                                     xibForPlatformWithName:@"SCPRLinkedInShareViewController"]
                                                    bundle:nil];

  

  NSDictionary *asDictionary = (NSDictionary*)article;
  linkedInShare.article = asDictionary;
  [[Utilities del] cloakUIWithCustomView:linkedInShare];
  
  
}

- (void)failoverLinkedIn {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in_silently"
                                                object:nil];
  
  [self shareWithLinkedIn:self.materialToShare
                 delegate:nil];
}

- (void)completeLinkedInShare:(NSString*)comments {
  
  NSDictionary *d = (NSDictionary*)self.materialToShare;
  NSString *title = [d objectForKey:@"short_title"] ? [d objectForKey:@"short_title"] : [d objectForKey:@"headline"];
  if ( !title ) {
    title = [d objectForKey:@"title"];
  }
  
  NSString *teaser = [d objectForKey:@"teaser"] ? [d objectForKey:@"teaser"] : [d objectForKey:@"summary"];
  NSString *link = [d objectForKey:@"permalink"] ? [d objectForKey:@"permalink"] : [d objectForKey:@"url"];
  if ( !link ) {
    link = [d objectForKey:@"public_url"];
  }
  NSString *comment = comments;
  NSString *token = [[ContentManager shared].settings linkedInToken];
  NSString *url = [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~/shares?oauth2_access_token=%@",token];
  
  NSError *error = nil;
  NSString *payload = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"linkedin_payload"
                                                                                         ofType:@"xml"]
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];
  NSString *complete = [NSString stringWithFormat:payload,comment,title,teaser,link];
  
  NSURL *urlObj = [NSURL URLWithString:url];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj];
  [request setHTTPMethod:@"POST"];
  
  NSData *data = [complete dataUsingEncoding:NSUTF8StringEncoding];
  [request setHTTPBody:data];
  [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
  [request setValue:[NSString stringWithFormat:@"%d",[data length]]
 forHTTPHeaderField:@"Content-Length"];
  [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
  
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *r, NSData *rd, NSError *e) {
                           
                           NSString *responseData = [[NSString alloc] initWithData:rd
                                                                          encoding:NSUTF8StringEncoding];
                           
                           if ( e ) {
                             NSLog(@"Error posting XML payload for LinkedIn : %@ : %@",e,responseData);
                             [self performSelectorOnMainThread:@selector(linkedInShareFinished:)
                                                    withObject:@0
                                                 waitUntilDone:NO];
                             return;
                           }
                           
                     
                           
                           NSLog(@"Response from LinkedIn : %@",responseData);
                           
                           [self performSelectorOnMainThread:@selector(linkedInShareFinished:)
                                                  withObject:@1
                                               waitUntilDone:NO];
                           
                         }];
  
}

- (void)linkedInShareFinished:(NSNumber*)result {
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"share_finished"
                                                      object:result];
}

- (void)linkedInLoginComplete {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in"
                                                object:nil];
  
  [[Utilities del] uncloakUI];
}

- (NSString*)linkedInAppKey {
  return [[[[FileManager shared] globalConfig] objectForKey:@"LinkedIn"] objectForKey:@"AppKey"];
}

- (NSString*)linkedInRedirectPrefix {
  return @"http://redirect.scpr.org";
}

- (NSString*)linkedInApiBase {
  return @"https://www.linkedin.com/uas";
}

- (NSString*)linkedInRedirectBase {
  return @"redirect.scpr.org";
}

- (NSString*)linkedInClientSecret {
  return [[[[FileManager shared] globalConfig] objectForKey:@"LinkedIn"] objectForKey:@"ClientSecret"];
}

#pragma mark - Twitter
- (void)discreteInlineTwitterAuth {
  
  NSString *consumerKey = [[[[FileManager shared] globalConfig] objectForKey:@"Twitter"] objectForKey:@"ConsumerKey"];
  NSString *consumerSecret = [[[[FileManager shared] globalConfig] objectForKey:@"Twitter"] objectForKey:@"ConsumerSecret"];
  
  NSString *consumerKeyRFC1738 = [consumerKey stringByAddingPercentEscapesUsingEncoding:
                                  NSASCIIStringEncoding];
  NSString *consumerSecretRFC1738 = [consumerSecret stringByAddingPercentEscapesUsingEncoding:
                                     NSASCIIStringEncoding];
  
  NSString *concatKeySecret = [[consumerKeyRFC1738 stringByAppendingString:@":"]    stringByAppendingString:consumerSecretRFC1738];
  
  NSLog(@"concatKeySecret:%@", concatKeySecret);
  
  NSString *concatKeySecretBase64 = [Utilities base64:[concatKeySecret dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSLog(@"concatKeySecretBase64:%@", concatKeySecretBase64);
  
  
  NSMutableURLRequest *request = [NSMutableURLRequest
                                  requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth2/token"]];
  
  [request setHTTPMethod:@"POST"];
  [request setValue:[@"Basic " stringByAppendingString:concatKeySecretBase64] forHTTPHeaderField:@"Authorization"];
  [request setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
  
  
  NSString *str = @"grant_type=client_credentials";
  NSData *httpBody = [str dataUsingEncoding:NSUTF8StringEncoding];
  [request setHTTPBody:httpBody];
  
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                           
                           if ( connectionError ) {
                             NSLog(@"Couldn't auth Twitter...");
                             return;
                           }
                           
                           if ( data ) {
                             
                             NSString *dataString = [[NSString alloc] initWithData:data
                                                                          encoding:NSUTF8StringEncoding];
                             
                             NSDictionary *obj = [dataString JSONValue];
                             NSString *at = [obj objectForKey:@"access_token"];
                             if ( ![Utilities pureNil:at] ) {
                               [[ContentManager shared].settings setTwitterBearerToken:at];
                               [[ContentManager shared] setSkipParse:YES];
                               [[ContentManager shared] writeSettings];
                             }
                             
                           }
                         }];
  
}

- (void)synthesizeTwitterTweet:(NSString *)twId container:(id)container {
  
  NSString *bearerToken = [[ContentManager shared].settings twitterBearerToken];
  if ( [Utilities pureNil:bearerToken] ) {
    return;
  }
  
  SCPRWebNewsContentViewController *wcc = (SCPRWebNewsContentViewController*)container;
  UIWebView *wView = wcc.webView;
  
  NSMutableURLRequest *request = [NSMutableURLRequest
                                  requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/show.json?id=%@",twId]]];
  
  [request setHTTPMethod:@"GET"];
  [request setValue:[NSString stringWithFormat:@"Bearer %@",bearerToken]
 forHTTPHeaderField:@"Authorization"];
  [request setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
  
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                           
                           
                           if ( data ) {
                             
                             NSString *ds = [[NSString alloc] initWithData:data
                                                                  encoding:NSUTF8StringEncoding];
                             NSDictionary *twResponse = [ds JSONValue];
                             NSString *text = [twResponse objectForKey:@"text"];
                             NSDictionary *user = [twResponse objectForKey:@"user"];
                             
                             NSString *screenName = [user objectForKey:@"screen_name"];
                             text = [text stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
                             NSString *snippet = [NSString stringWithFormat:@"<blockquote class=\"twitter-tweet\"><div id=\"twitter_bird\"><img src=\"icon-blockquote-twitter.png\"></div><div id=\"twitter-text\">%@<br/>-- @%@</div></blockquote>",text,screenName];
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                               
                               NSString *js = [NSString stringWithFormat:@"document.getElementById('twitter_%@').innerHTML = '%@'",twId,snippet];
                               
                               [wView stringByEvaluatingJavaScriptFromString:js];
                               [wcc.delegate refreshHeight];
                               
                             });
                             
                           }
                           
                         }];
  
}


- (ACAccount*)activeTwitterAccount {
  if ( _activeTwitterAccount ) {
    return _activeTwitterAccount;
  } else {
    if ( [self isAuthenticatedWithTwitter] ) {
      NSString *twitterInfo = [[ContentManager shared].settings twitterInformation];
      NSDictionary *literal = (NSDictionary*)[twitterInfo JSONValue];
    
      [self accountObjectForScreenName:[literal objectForKey:@"screen_name"] delegate:nil];
    }
  }
  
  return _activeTwitterAccount;
  
}


- (void)accountObjectForScreenName:(NSString *)name delegate:(id<Twitterable>)twitterable {
  ACAccountStore *accountStore = [[ACAccountStore alloc] init];
  ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  [accountStore requestAccessToAccountsWithType:twitterType
                                        options:nil
                                     completion:^(BOOL granted, NSError *error) {
                                       
                                       BOOL found = NO;
                                       if ( granted ) {
                                         NSArray *twitter = [accountStore accountsWithAccountType:twitterType];
                                         for ( ACAccount *account in twitter ) {
                                           if ( [[account username] isEqualToString:name] ) {
                                             found = YES;
                                             self.activeTwitterAccount = account;
                                             if ( twitterable ) {
                                               [twitterable currentAccountIdentified:account];
                                             }
                                           }
                                         }
                                       }
                                       
                                       
                                     }];
  

  
}

- (void)shareWithTwitter:(NSDictionary *)article {
  
  NSString *title = [article objectForKey:@"short_title"] ? [article objectForKey:@"short_title"] : [article objectForKey:@"headline"];
  if ( !title ) {
    title = [article objectForKey:@"title"];
  }
  NSString *link = [article objectForKey:@"permalink"] ? [article objectForKey:@"permalink"] : [article objectForKey:@"url"];
  if ( !link ) {
    link = [article objectForKey:@"public_url"];
  }
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];

  [composer setInitialText:title];
  [composer addURL:[NSURL URLWithString:link]];
  SCPRViewController *scpr = [[Utilities del] viewController];
  [scpr presentViewController:composer
                     animated:YES
                   completion:^{
                     
                     [self performSelectorOnMainThread:@selector(sharingFinished)
                                            withObject:nil
                                         waitUntilDone:NO];
                     
                   }];

}

- (void)handleTwitterInteraction:(id<Twitterable>)delegate displayedInFrame:(CGRect)frame {
  
  self.twitterDelegate = delegate;
  ACAccountStore *accountStore = [[ACAccountStore alloc] init];
   ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  [accountStore requestAccessToAccountsWithType:twitterType
                                        options:nil
                                     completion:^(BOOL granted, NSError *error) {
                                       
                                       if ( error ) {
                                         
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                          [self twitterAuthFailed:error delegate:delegate];
                                        });
                                           
                                           
                                        return; 
                                         
                                       }
                                       
                                       if ( granted ) {
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           NSArray *twitter = [accountStore accountsWithAccountType:twitterType];
                                           if ( [twitter count] > 1 ) {
                                             SCPRModalListPickerViewController *picker = [[SCPRModalListPickerViewController alloc]
                                                                                          initWithNibName:[[DesignManager shared]
                                                                                                           xibForPlatformWithName:@"SCPRModalListPickerViewController"]
                                                                                          bundle:nil];
                                             NSMutableArray *accounts = [[NSMutableArray alloc] init];
                                             for ( ACAccount *twitterAccount in twitter ) {
                                               SCPRListableObject *obj = [[SCPRListableObject alloc] init];
                                               obj.stringRepresentation = [NSString stringWithFormat:@"@%@",twitterAccount.username];
                                               obj.item = twitterAccount;
                                               [accounts addObject:obj];
                                             }
                                             
                                             UIViewController *vc = (UIViewController*)[[Utilities del] masterRootController];
                                             CGRect windowFrame = [vc.view convertRect:frame
                                                                                 fromView:[delegate twitterableView]];
                                             picker.delegate = self;
                                             self.twitterDelegate = delegate;
                                             
                                             [picker sourceWithList:[NSArray arrayWithArray:accounts]
                                                         fromOrigin:windowFrame.origin];
                                             self.genericRetainer = picker;
                                             
                                           } else {
                                             
                                             if ( [twitter count] > 0 ) {
                                               
                                               ACAccount *account = [twitter objectAtIndex:0];
                                               [self.twitterDelegate finishWithAccount:account];
                                               
                                             } else {
                                               
                                               [self twitterAuthFailed:error
                                                              delegate:delegate];
                                             }
                                             
                                           }
                                           
                                         });

                                                    
                                       }
                                     }];
 
  
}

- (void)loginWithTwitter:(ACAccount*)twitter {
  
  
  self.activeTwitterAccount = twitter;
  ACAccountStore *store = [[ACAccountStore alloc] init]; // Long-lived
  ACAccountType *twitterType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  [store requestAccessToAccountsWithType:twitterType
                                 options:nil completion:^(BOOL granted, NSError *error) {
                                   
                                   
                                   if ( granted ) {
                                     [self performSelectorOnMainThread:@selector(continueTwitter:)
                                                            withObject:twitter
                                                         waitUntilDone:NO];
                                   }
                                   
                                   
                                 }];
  

  
}

- (void)continueTwitter:(ACAccount*)twitter {
  ACAccountStore *store = [[ACAccountStore alloc] init]; // Long-lived
  ACAccountType *twitterType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  NSString *username = [twitter username];
  SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                          requestMethod:SLRequestMethodGET
                                                    URL:[NSURL URLWithString:@"http://api.twitter.com/1.1/users/show.json"]
                                             parameters:@{ @"screen_name" : username }];
  twitter.accountType = twitterType;
  [request setAccount:twitter];
  [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
    
    
    if ( error ) {
      NSLog(@"Error while connecting with Twitter... : %@",[error localizedDescription]);
      
    }
    
    NSString *s = [[NSString alloc] initWithData:responseData
                                        encoding:NSUTF8StringEncoding];
    
    
    [self performSelectorOnMainThread:@selector(storeTwitterInformation:)
                           withObject:s
                        waitUntilDone:NO];
    
  }];
}

- (void)storeTwitterInformation:(NSString *)twitterInfo {

  NSDictionary *twitterHash = (NSDictionary*)[twitterInfo JSONValue];
  [[ContentManager shared].settings setTwitterInformation:twitterInfo];
  
  NSString *normal = [twitterHash objectForKey:@"profile_image_url"];
  NSString *bigger = [normal stringByReplacingOccurrencesOfString:@"normal"
                                                       withString:@"bigger"];
  [[ContentManager shared].settings setProfileImageURL:bigger];
  [[ContentManager shared] writeSettings];
  
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                      object:nil];

    
}

- (void)logoutOfTwitter {
  [[ContentManager shared].settings setTwitterInformation:@""];
  [[ContentManager shared].settings setProfileImageURL:@""];
  [[ContentManager shared] writeSettings];
  
  self.activeTwitterAccount = nil;
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_out"
                                                      object:@"twitter"];
}

- (BOOL)isAuthenticatedWithTwitter {
  NSString *twitterInfo = [[ContentManager shared].settings twitterInformation];
  if ( ![Utilities pureNil:twitterInfo] ) {
    return YES;
  }
  
  return NO;
}

- (void)twitterImageTo:(UIImageView *)imgView {
  [self twitterImageTo:imgView completion:nil];
}

- (void)twitterImageTo:(UIImageView *)imgView completion:(ImageAppearedCallback)block {
  NSString *url = [[ContentManager shared].settings profileImageURL];
  if ( [Utilities pureNil:url] ) {
    NSString *twI = [[ContentManager shared].settings twitterInformation];
    if ( ![Utilities pureNil:twI] ) {
      NSDictionary *twitter = (NSDictionary*)[twI JSONValue];
      url = [twitter objectForKey:@"profile_image_url"];
      if ( !url ) {
        NSLog(@"Twitter info is there, but image is not present...");
        [imgView loadLocalImage:@"avatar-default.png"
                        quietly:NO];
        
      }
    }
  }
  
  
  
  [self circumscribeImageWithURL:url
                         toImage:imgView
   completion:block];
}

- (void)twitterNameTo:(UILabel *)nameLabel {
  [nameLabel titleizeText:[self twitterName]
                     bold:NO];
  nameLabel.text = [nameLabel.text lowercaseString];
  nameLabel.text = [nameLabel.text capitalizedString];
}

- (NSString*)twitterName {
  NSString *json = [[ContentManager shared].settings twitterInformation];
  if ( json ) {
    NSDictionary *d = (NSDictionary*)[json JSONValue];
    if ( d ) {
      return [d objectForKey:@"name"];
    }
  }
  
  return @"Anonymous";
}

- (void)twitterScreenNameTo:(UILabel *)titleLabel {
  NSString *json = [[ContentManager shared].settings twitterInformation];
  NSDictionary *d = (NSDictionary*)[json JSONValue];
  [titleLabel titleizeText:[NSString stringWithFormat:@"@%@",[d objectForKey:@"screen_name"]] bold:NO];
}

- (void)queryTweetsWithHashtag:(NSString *)hashtag respondTo:(id<Twitterable>)twitterable withAccount:(ACAccount*)twitterAccount {
  self.twitterDelegate = twitterable;
  ACAccountStore *store = [[ACAccountStore alloc] init]; // Long-lived
  ACAccountType *twitterType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  NSString *twitterBase = @"https://api.twitter.com/1.1/search/tweets.json?q=";
  NSString *hashedHash = [hashtag stringByReplacingOccurrencesOfString:@"#"
                                                            withString:@"%23"];
  NSString *reqStr = [NSString stringWithFormat:@"%@%@",twitterBase,hashedHash];
  SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                          requestMethod:SLRequestMethodGET
                                                    URL:[NSURL URLWithString:reqStr]
                                             parameters:nil/*@{ @"screen_name" : username }*/];
  twitterAccount.accountType = twitterType;
  [request setAccount:twitterAccount];
  [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
    
    
    if ( error ) {
      NSLog(@"Error while fetching Tweets with hashtag %@... : %@",hashtag,[error localizedDescription]);
      
    }
    
    NSString *s = [[NSString alloc] initWithData:responseData
                                        encoding:NSUTF8StringEncoding];
    
    
    [self performSelectorOnMainThread:@selector(compileTweets:)
                           withObject:s
                        waitUntilDone:NO];
    
  }];
}

- (void)compileTweets:(NSString*)tweets {
  
  NSDictionary *tweetHash = (NSDictionary*)[tweets JSONValue];
  if ( tweetHash ) {
    [self.twitterDelegate tweetsReceived:tweetHash];
  }
  
  
}

- (void)updateTwitterStatus:(NSString *)text {
  
}

- (void)twitterAuthFailed:(NSError *)error delegate:(id<Twitterable>)delegate {
  NSString *description = [error localizedDescription];
  if ( [description rangeOfString:@"com.apple.accounts error 6"].location != NSNotFound ) {
    [[[UIAlertView alloc] initWithTitle:@"No Twitter Accounts"
                                message:@"Please add a Twitter account in your device's settings"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    [delegate twitterAuthenticationFailed];
  } else {
    
    [[[UIAlertView alloc] initWithTitle:@"Twitter Login Failed"
                                message:@"We couldn't connect with Twitter. Try again later"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    
  }
}

#pragma mark - Facebook
- (void)shareWithFacebook:(id)article {
  
  NSString *title = [article objectForKey:@"short_title"] ? [article objectForKey:@"short_title"] : [article objectForKey:@"headline"];
  if ( !title ) {
    title = [article objectForKey:@"title"];
  }

  NSString *link = [article objectForKey:@"permalink"] ? [article objectForKey:@"permalink"] : [article objectForKey:@"url"];
  if ( !link ) {
    link = [article objectForKey:@"public_url"];
  }
  
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer setInitialText:title];
  [composer addURL:[NSURL URLWithString:link]];
  SCPRViewController *scpr = [[Utilities del] viewController];
  [scpr presentViewController:composer
                     animated:YES
                   completion:^{
                     [self performSelectorOnMainThread:@selector(sharingFinished)
                                            withObject:nil
                                         waitUntilDone:NO];
                   }];
  

  
}

- (void)shareDisabled {
  [self sharingFinished];
  [[[UIAlertView alloc] initWithTitle:@"Coming Soon"
                              message:@"We're workin' on it!"
                             delegate:nil
                    cancelButtonTitle:@"Got it!"
                    otherButtonTitles:nil] show];
}

- (void)persistentShare {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self shareDispatcher:self.shareIntent
                article:self.materialToShare
   delegate:self.designatedDelegate];
}



- (void)logoutOfFacebook {
  [[ContentManager shared].settings setProfileImageURL:nil];
  [[ContentManager shared].settings setUserFacebookInformation:nil];
  [[ContentManager shared] writeSettings];
  
  [[FBSession activeSession] closeAndClearTokenInformation];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_out"
                                                      object:@"facebook"];
}
- (BOOL)checkForFacebookCredentials {
  if ( [self isAuthenticatedWithFacebook] ) {
    if ( [[FBSession activeSession] state] == FBSessionStateOpen ||
        [[FBSession activeSession] state] == FBSessionStateOpenTokenExtended ) {
      return YES;
    }
    
    [[FBSession activeSession] openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
      
      [FBSession setActiveSession:session];
      
    }];
    
    return YES;
  }
  
  return NO;
}


- (void)facebookImageTo:(UIImageView *)imgView {
  [self facebookImageTo:imgView completion:^{
    
  }];
}

- (void)facebookImageTo:(UIImageView *)imgView completion:(ImageAppearedCallback)completion {
  imgView.alpha = 0.0;
  NSString *piu = [[ContentManager shared].settings profileImageURL];
  if ( [Utilities pureNil:piu] ) {
    
    
    [FBRequestConnection startWithGraphPath:@"me" parameters:@{ @"fields" : @"picture.type(large)" }
                                 HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                            
                            if ( error ) {
                              return;
                            }
                            
                            FBGraphObject *fbgo = (FBGraphObject*)result;
                            NSDictionary *pic = [fbgo objectForKey:@"picture"];
                            NSDictionary *data = [pic objectForKey:@"data"];
                            NSString *url = [data objectForKey:@"url"];
                            
                            
                            NSDictionary *meta = @{ @"viewport" : imgView,
                                                    @"content" : url };
                            if ( completion ) {
                              meta = @{ @"viewport" : imgView,
                                        @"content" : url,
                                        @"completion" : completion };
                            }
                            
                            [self performSelectorOnMainThread:@selector(threadedImageFetch:)
                                                   withObject:meta
                                                waitUntilDone:NO];
                            
                          }];
    
  } else {
    
    [self circumscribeImageWithURL:piu
                           toImage:imgView
                        completion:completion];
    
  }
}

- (void)threadedImageFetch:(id)result {
  NSDictionary *d = (NSDictionary*)result;
  UIImageView *container = [d objectForKey:@"viewport"];
  NSString *url = (NSString*)[d objectForKey:@"content"];
  
  ImageAppearedCallback completion = ^(void){};
  if ( [d objectForKey:@"completion"] ) {
    completion = [d objectForKey:@"completion"];
  }
  
  [self circumscribeImageWithURL:url
                         toImage:container
                      completion:completion];
  
  [[ContentManager shared].settings setProfileImageURL:url];
  [[ContentManager shared] writeSettings];
}

- (void)facebookNameTo:(UILabel *)nameLabel {
  NSString *fbi = [[ContentManager shared].settings userFacebookInformation];
  if ( ![Utilities pureNil:fbi] ) {
    NSMutableDictionary *d = (NSMutableDictionary*)[fbi JSONValue];
    nameLabel.text = [d objectForKey:@"name"];
    nameLabel.text = [nameLabel.text lowercaseString];
    nameLabel.text = [nameLabel.text capitalizedString];
  } else {
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
      if ( error ) {
        NSLog(@"Facebook : Error fetching user image : %@",[error localizedDescription]);
        return;
      }
      
      FBGraphObject *fbgo = (FBGraphObject*)result;
      
      NSDictionary *meta = @{ @"viewport" : nameLabel,
                              @"content" : fbgo };
      
      [self performSelectorOnMainThread:@selector(threadedNameFetch:)
                             withObject:meta
                          waitUntilDone:NO];
    }];
  }

  
  
}



- (void)threadedNameFetch:(id)result {
  
  NSDictionary *d = (NSDictionary*)result;
  UILabel *container = [d objectForKey:@"viewport"];
  FBGraphObject *fbgo = (FBGraphObject*)[d objectForKey:@"content"];
  container.text = [fbgo objectForKey:@"name"];
  container.text = [container.text capitalizedString];
  [[[ContentManager shared] settings] setUserFacebookInformation:[fbgo JSONRepresentation]];
  [[ContentManager shared] writeSettings];
}

- (NSString*)facebookName {
  NSString *fbi = [[ContentManager shared].settings userFacebookInformation];
  if ( ![Utilities pureNil:fbi] ) {
    NSMutableDictionary *d = (NSMutableDictionary*)[fbi JSONValue];
    return [d objectForKey:@"name"];
  }
  
  return @"Anonymous";
}

- (BOOL)isAuthenticatedWithFacebook {

  return [FBSession activeSession].state == FBSessionStateOpen ||
  [FBSession activeSession].state == FBSessionStateOpenTokenExtended ||
  FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded;
  
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
  switch (state) {
    case FBSessionStateOpen:
      if (!error) {
        // We have a valid session
        NSLog(@"User session found");
        
        [FBSession setActiveSession:session];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                            object:nil];
        
      }
      break;
    case FBSessionStateClosed:
    case FBSessionStateClosedLoginFailed:
      NSLog(@"Facebook: Error authenticating : %@",[error localizedDescription]);
      [FBSession.activeSession closeAndClearTokenInformation];
      break;
    default:
      break;
  }
  
  
  if (error) {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_fail"
                                                        object:nil];
    
  }
  
  
}

- (BOOL)authenticateWithFacebook {
  
  
  if ( [self isAuthenticatedWithFacebook] ) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                        object:nil];
    return YES;
  } else {
    
    @synchronized(self) {
      self.leavingForFacebookAuthRead = YES;
    }
    
    if ( SYSTEM_VERSION_LESS_THAN(@"6.0") ) {
      return [FBSession openActiveSessionWithPublishPermissions:@[@"publish_actions"]
                                                defaultAudience:FBSessionDefaultAudienceFriends
                                                   allowLoginUI:YES
                                              completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                                

                                                
                                                [self sessionStateChanged:session
                                                                    state:status
                                                                    error:error];
                                                
                                              }];
    } else {
      NSAssert([NSThread isMainThread], @"This should always be the main thread");
      return [FBSession openActiveSessionWithReadPermissions:nil
                                                allowLoginUI:YES
                                           completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                             
                                             NSDictionary *meta = @{};
                                             if ( error ) {
                                               meta = @{ @"session" : session, @"status" : [NSNumber numberWithInt:(NSInteger)status], @"error" : error };
                                             } else {
                                               meta = @{ @"session" : session, @"status" : [NSNumber numberWithInt:(NSInteger)status] };
                                             }
                                             
                                             [self performSelectorOnMainThread:@selector(threadStatus:)
                                                                    withObject:meta
                                                                 waitUntilDone:NO];
                                             
                                             
                                           }];
      
    }
  }
}

- (void)getPublished {

  @synchronized(self) {
    self.leavingForFacebookAuthPub = YES;
  }
  
  [FBSession openActiveSessionWithPublishPermissions:@[@"publish_actions"]
                                     defaultAudience:FBSessionDefaultAudienceFriends
                                        allowLoginUI:YES
                                   completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                     
                                     NSDictionary *meta = @{};
                                     if ( error ) {
                                       meta = @{ @"session" : session, @"status" : [NSNumber numberWithInt:(NSInteger)status], @"error" : error };
                                     } else {
                                       meta = @{ @"session" : session, @"status" : [NSNumber numberWithInt:(NSInteger)status] };
                                     }
                                     
                                     [self performSelectorOnMainThread:@selector(threadStatus:)
                                                            withObject:meta
                                                         waitUntilDone:NO];
                                     
                                   }];
}

- (void)threadStatus:(NSDictionary*)meta {
  [self sessionStateChanged:[meta objectForKey:@"session"]
                      state:(FBSessionState)[[meta objectForKey:@"status"] intValue]
                      error:[meta objectForKey:@"error"]];
}

#pragma mark - Membership validation
- (void)validateMembershipWithKeys:(NSDictionary *)keys delegate:(id<MemberStatusable>)delegate {
  // Do nothing for now
  
  [self setMemberEmailCandidate:[keys objectForKey:@"email"]];
  
  NSString *network = [NSString stringWithFormat:@"%@?email=%@&last_name=%@&zip=%@",kMPRServer,[keys objectForKey:@"email"],[keys objectForKey:@"last_name"],[keys objectForKey:@"zip"]];
  NSURL *url = [NSURL URLWithString:network];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

  
  NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"scprmember", @"scprlookitup"];
  NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
  NSString *authValue = [NSString stringWithFormat:@"Basic %@", [Utilities base64:authData]];
  [request setValue:authValue forHTTPHeaderField:@"Authorization"];
  
#ifndef PRODUCTION
  [NSURLRequest allowsAnyHTTPSCertificateForHost:kMPRHost];
#endif
  
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                             if ( connectionError ) {
                               NSLog(@"Error hitting MPR api : %@",[connectionError localizedDescription]);
                               [[NSNotificationCenter defaultCenter] postNotificationName:@"membership_validated"
                                                                                   object:@1];
                               return;
                             }
                             
                             NSString *member = [[NSString alloc] initWithData:data
                                                                      encoding:NSUTF8StringEncoding];
                             member = [member stringByReplacingOccurrencesOfString:@"\n"
                                                                        withString:@""];
                             
                             if ( [Utilities pureNil:member] ) {
                               [[NSNotificationCenter defaultCenter] postNotificationName:@"membership_validated"
                                                                                   object:@1];
                               return;
                             }
                             
                             id objects = [member JSONValue];
                             
                             if ( [objects isKindOfClass:[NSDictionary class]] ) {
                               if ( [(NSDictionary*)objects objectForKey:@"error"] ) {
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"membership_validated"
                                                                                     object:@1];
                                 return;
                               }
                             }
                             
                             [delegate processMemberData:(NSArray*)objects];
                             
                           });
                           
    
                         }];

  
#ifdef USE_FAKE_DATA
  int randy = random() % 10;
  NSArray *meta = @[];
  if ( randy > 4 ) {
    
    meta = [Utilities loadJson:@"fake_memberdata_multiple"];
    
  } else {
    
    meta = [Utilities loadJson:@"fake_memberdata_single"];
    
  }
  
  NSDictionary *marshalled = @{ @"delegate" : delegate,
                          @"meta" : meta };
  
  [NSTimer scheduledTimerWithTimeInterval:2.0
                                   target:self
                                 selector:@selector(fakeFinish:)
                                 userInfo:marshalled
                                  repeats:NO];
#endif
  
}

- (void)fakeFinish:(NSTimer*)timer {
  NSDictionary *info = (NSDictionary*)[timer userInfo];
  id<MemberStatusable> delegate = [info objectForKey:@"delegate"];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"membership_validated"
                                                      object:nil];
  
  [delegate processMemberData:[info objectForKey:@"meta"]];
}

- (void)loginWithMembershipInfo:(NSDictionary *)info {
  
  if ( [self isAuthenticatedWithFacebook] ) {
    [self logoutOfFacebook];
  } else if ( [self isAuthenticatedWithLinkedIn] ) {
    [self logoutOfLinkedIn];
  } else if ( [self isAuthenticatedWithTwitter] ) {
    [self logoutOfTwitter];
  }
  
  [[ContentManager shared].settings setMemberInformation:[info JSONRepresentation]];
  [[ContentManager shared] writeSettings];
  
  [self setMemberEmailCandidate:@""];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in"
                                                      object:nil];
}

- (BOOL)isAuthenticatedWithMembership {
  NSString *mi = [[ContentManager shared].settings memberInformation];
  return ![Utilities pureNil:mi];
}



- (void)memberImageTo:(UIImageView *)imageView {
  NSString *json = [[ContentManager shared].settings memberInformation];
  NSDictionary *inflated = [json JSONValue];
  NSString *donorClass = [inflated objectForKey:@"donor_class"];
  NSString *append = @"";
  if ( [donorClass rangeOfString:@"One-Time"].location != NSNotFound ) {
    append = @"member";
  } else {
    append = [donorClass lowercaseString];
    append = [append stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    append = [NSString stringWithFormat:@"%@",append];
  }
  
  NSString *avatar = [NSString stringWithFormat:@"avatar-%@.png",append];
  [imageView loadLocalImage:avatar quietly:NO];
}

- (void)memberNameTo:(UILabel *)label {
  NSString *json = [[ContentManager shared].settings memberInformation];
  NSDictionary *inflated = [json JSONValue];
  NSString *raw = [inflated objectForKey:@"member_name"];
  raw = [raw lowercaseString];
  
  [label titleizeText:[raw capitalizedString]
                 bold:NO];
}

- (void)memberDonorClassTo:(UILabel *)label {
  NSString *json = [[ContentManager shared].settings memberInformation];
  NSDictionary *inflated = [json JSONValue];
  [label titleizeText:[inflated objectForKey:@"donor_class"]
                 bold:NO];
}

- (void)logoutOfMembership {
  [[ContentManager shared].settings setMemberInformation:nil];
  [[ContentManager shared] writeSettings];

  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_out"
                                                      object:@"membership"];
}

#pragma mark - Modal List Picker
- (void)itemPickedFromTable:(id)item {
  ACAccount *account = (ACAccount*)item;
  [self.twitterDelegate finishWithAccount:account];
}

- (void)unhook {
  self.twitterDelegate = nil;
}

#pragma mark - Email
- (void)shareWithEmail:(NSDictionary*)article delegate:(id)delegate {
  [self shareWithEmail:article delegate:delegate debug:NO];
}

- (void)shareWithEmail:(NSDictionary *)article delegate:(id)delegate debug:(BOOL)debug {
  self.designatedDelegate = delegate;
  
  if ( debug ) {
    
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    [composer setSubject:@"This article looks funny!"];
  
    NSString *key = [article objectForKey:@"body"] ? [article objectForKey:@"body"] : [article objectForKey:@"summary"];
    NSString *body = [[FileManager shared] htmlPageFromBody:key
                                                    article:article];
#ifdef DEBUG

  
    NSError *error = nil;
  
    [composer setMessageBody:[NSString stringWithContentsOfFile:body
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error]
                    isHTML:NO];
    [composer setToRecipients:@[@"benhochberg@gmail.com"]];
#else
    [composer setMessageBody:@"Please tell us what's weird about this page"
                    isHTML:NO];
    
    NSString *articleID = [article objectForKey:@"id"];
    if ( !articleID ) {
      articleID = [NSDate stringFromDate:[NSDate date]
                              withFormat:@"mmddyyyyhhmm"];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"article_feedback_%@",articleID];
    
    [composer addAttachmentData:[NSData dataWithContentsOfFile:body]
                       mimeType:@"text/plain"
                       fileName:fileName];
    
    [composer setToRecipients:@[@"mobilefeedback@kpcc.org"]];

#endif
    
    composer.mailComposeDelegate = self;

  
    [[[Utilities del] viewController] presentViewController:composer animated:YES
                                               completion:^{
                                                 
                                               }];
  } else {
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    [composer setSubject:@"Check out this article from KPCC.org"];
    [composer setMessageBody:[[FileManager shared] formattedEmailForArticle:article]
                      isHTML:YES];
    composer.mailComposeDelegate = self;
    
    [[[Utilities del] viewController] presentViewController:composer animated:YES
                                                 completion:^{
                                                   
                                                 }];
  }
}


#pragma mark - MFMailComposer
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  
  if ( [[[Utilities del] viewController] shareDrawerOpen] ) {
    [[[Utilities del] viewController] closeShareDrawer];
  }
  
  [[[Utilities del] viewController] dismissViewControllerAnimated:YES
                                                       completion:^{
                                                         
                                                       }];
}


@end
