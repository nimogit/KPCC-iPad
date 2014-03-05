//
//  SCPRLinkedInShareViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/5/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRLinkedInShareViewController.h"
#import "global.h"
#import "SCPRViewController.h"
#import "SCPRImageView.h"



@interface SCPRLinkedInShareViewController ()

@end

@implementation SCPRLinkedInShareViewController

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
  
  self.view.clipsToBounds = YES;
  self.view.layer.cornerRadius = 5.0;
  self.shareContainerView.clipsToBounds = YES;
  self.shareContainerView.layer.cornerRadius = 4.0;
  self.shareCaptionLabel.textColor = [[DesignManager shared] charcoalColor];
  self.inputTextView.textColor = [[DesignManager shared] number3pencilColor];
  self.inputTextView.delegate = self;
  NSString *imgUrl = [Utilities extractImageURLFromBlob:self.article
                                                quality:AssetQualitySmall];
  
  NSString *title = [self.article objectForKey:@"short_title"] ? [self.article objectForKey:@"short_title"] : [self.article objectForKey:@"headline"];

  [self.articleImageView loadImage:imgUrl];
  
  [self.headlineLabel snapText:title
                          bold:NO
                 respectHeight:YES];
  
  
  self.inputTextView.text = kPlaceHolderString;
  self.successLabel.alpha = 0.0;
  [self.inputTextView becomeFirstResponder];
  
  // Do any additional setup after loading the view from its nib.
}

- (IBAction)shareTapped:(id)sender {
  
  [self.spinner startAnimating];
  [UIView animateWithDuration:0.25 animations:^{
    self.shareContainerView.alpha = 0.0;
    self.linkedInLogoView.alpha = 0.0;
  } completion:^(BOOL finished) {
    [self buttonFaded];
  }];
  
}

- (void)buttonFaded {
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(shareFinished:)
   name:@"share_finished"
   object:nil];
  
  if ( [self.inputTextView.text isEqualToString:kPlaceHolderString] ) {
    self.inputTextView.text = @"";
  }
  
  [[SocialManager shared] completeLinkedInShare:self.inputTextView.text];
}

- (void)shareFinished:(NSNotification*)note {
  
  NSNumber *result = [note object];
  if ( [result intValue] == 0 ) {
    [[[UIAlertView alloc] initWithTitle:@"Error Sharing"
                                message:@"Error posting to LinkedIn"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    [[Utilities del] uncloakUI];
    
  } else {
    self.successLabel.alpha = 1.0;
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(finish)
                                   userInfo:nil
                                    repeats:NO];
    
    return;
  }
  
  
}

- (void)finish {
  [[Utilities del] uncloakUI];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
  if ( [textView.text isEqualToString:kPlaceHolderString] ) {
    [textView setSelectedRange:NSMakeRange(0, 0)];
  }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if ( [text isEqualToString:@""] ) {
    if ( [textView.text length] == 1 ) {
      textView.textColor = [[DesignManager shared] number3pencilColor];
      textView.text = kPlaceHolderString;
      [textView setSelectedRange:NSMakeRange(0, 0)];
      return NO;
    }
  } else {
    if ( [textView.text isEqualToString:kPlaceHolderString] ) {
      textView.text = @"";
      textView.textColor = [[DesignManager shared] deepCharcoalColor];
    }
  }
  
  return YES;
}

#pragma mark - Cloakable
- (void)deactivate {
  
  SCPRViewController *scpr = [[Utilities del] viewController];
  if ( [scpr shareDrawerOpen] ) {
    [scpr toggleShareDrawer];
  }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
