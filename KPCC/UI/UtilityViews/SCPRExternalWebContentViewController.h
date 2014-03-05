//
//  SCPRExternalWebContentViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRFlatShadedButton.h"
#import "global.h"
#import "SCPRActivityIndicatorView.h"

@protocol ExternalWebContentDelegate <NSObject>

- (void)requestURILoaded:(NSString*)complete;

@end

@interface SCPRExternalWebContentViewController : UIViewController<UIWebViewDelegate,Cloakable,ContentProcessor,Backable,Deactivatable>

@property (nonatomic,strong) IBOutlet UIWebView *webContentView;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,strong) NSURLRequest *request;
@property (nonatomic,strong) IBOutlet SCPRFlatShadedButton *safariButton;
@property (nonatomic,strong) IBOutlet SCPRFlatShadedButton *readabilityButton;
@property (nonatomic,strong) IBOutlet UIButton *bensOffbrandButton;
@property (nonatomic,weak) id<ExternalWebContentDelegate> delegate;
@property (nonatomic,weak) id<ContentProcessor> supplementalContainer;

@property (nonatomic,strong) NSString *redirectPrefix;
@property (nonatomic,strong) IBOutlet UIView *cloakView;
@property (nonatomic,strong) IBOutlet UILabel *workingLabel;
@property (nonatomic,strong) NSString *deactivationToken;

@property BOOL expectsRedirectURI;
@property BOOL reducing;
@property BOOL reduced;
@property BOOL cleaningUp;
@property BOOL fromEditions;

@property (nonatomic,strong) id<Backable> backContainer;

- (IBAction)buttonTapped:(id)sender;
- (void)prime:(NSURLRequest*)request;

@end
