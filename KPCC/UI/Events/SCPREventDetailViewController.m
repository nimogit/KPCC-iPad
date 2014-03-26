//
//  SCPREventDetailViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREventDetailViewController.h"
#import "global.h"
#import "SCPRViewController.h"
#import "SCPRTweetCell.h"


@interface SCPREventDetailViewController ()

@end

@implementation SCPREventDetailViewController

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
  
  self.videoController.view.backgroundColor = [[DesignManager shared] number1pencilColor];
  self.liveTweetView.backgroundColor = [[DesignManager shared] number1pencilColor];
  self.eventDetailsView.backgroundColor = [[DesignManager shared] number1pencilColor];
  self.tweetButton.enabled = NO;
  self.twitterSpinner.alpha = 0.0;
  self.eventDateLabel.textColor = [[DesignManager shared] softBlueColor];
  self.eventTitleLabel.textColor = [[DesignManager shared] vinylColor:1.0];
  self.eventDescriptionLabel.textColor = [[DesignManager shared] vinylColor:1.0];
  
  self.doneButton.action = @selector(doneTapped:);
  
  self.twitterFeedTable.clipsToBounds = YES;
  self.twitterFeedTable.layer.cornerRadius = 4.0;
  self.twitterAccountLabel.textColor = [[DesignManager shared] vinylColor:1.0];
  [self.twitterAccountLabel emboss];
  
  [self.eventDateLabel emboss];
  [self.eventTitleLabel emboss];
  [self.eventDescriptionLabel emboss];
  
  [self.eventDateLabel snapText:[Utilities prettyStringFromRFCDateString:[self.event objectForKey:@"starts_at"]]
                           bold:NO
                  respectHeight:YES];
  
  [self.eventTitleLabel snapText:[self.event objectForKey:@"title"]
                            bold:YES
                   respectHeight:YES];
  
  [self.eventDescriptionLabel snapText:[self.event objectForKey:@"teaser"]
                                  bold:NO
                         respectHeight:YES];
  
  [[DesignManager shared] avoidNeighbor:self.eventTitleLabel
                               withView:self.eventDescriptionLabel
                              direction:NeighborDirectionAbove
                                padding:8.0];
  
  
  [self.hashtagLabel snapText:[self.event objectForKey:@"hashtag"]
                         bold:NO
                respectHeight:YES];
  
  self.noTwitterView.clipsToBounds = YES;
  self.noTwitterView.layer.cornerRadius = 4.0;
  self.noTwitterView.backgroundColor = [[DesignManager shared] twitterBlueColor];
  [self.noTwitterLabel extrude];
  
  [[DesignManager shared] applyPerimeterShadowTo:self.noTwitterView];
  
  self.tweetContentTextView.layer.cornerRadius = 4.0;
  self.tweetContentTextView.textColor = [[DesignManager shared] number2pencilColor];
  self.tweetContentTextView.text = kPlaceHolderString;
  
  self.remainingCharactersLabel.textColor = [[DesignManager shared] vinylColor:1.0];
  self.hashtagLabel.textColor = [[DesignManager shared] vinylColor:1.0];
  self.tweetContentTextView.delegate = self;
                                 
  self.connectWithTwitterButton.layer.borderColor = [[DesignManager shared] offwhiteColor].CGColor;
  self.connectWithTwitterButton.layer.borderWidth = 1.0;
  
  [self.connectWithTwitterButton setShadeColor:[[DesignManager shared] twitterBlueColor]];
  [[DesignManager shared] globalSetTitleTo:@"Connect with Twitter"
                                 forButton:self.connectWithTwitterButton];
  
  [self.remainingCharactersLabel emboss];
  [self.hashtagLabel emboss];
  
  if ( [[SocialManager shared] isAuthenticatedWithTwitter] || [[SocialManager shared] activeTwitterAccount] ) {
    [self twitterize];
  } else {
    [self untwitterize];
  }
  
  self.reloader = [[SCPRReloadViewController alloc] initWithNibName:@"SCPRReloadViewController"
                                                             bundle:nil];
  [self.reloader setupWithScroller:self.twitterFeedTable
                          delegate:self];
  
  self.fauxBar.frame = CGRectMake(0.0,self.view.frame.size.height,
                                  self.fauxBar.frame.size.width,
                                  self.fauxBar.frame.size.height);
  [self.view addSubview:self.fauxBar];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(untwitterize)
                                               name:@"logged_out"
                                             object:nil];
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  [[[Utilities del] globalTitleBar] morph:BarTypeModal container:self];
  
}

#pragma mark - Twitterizing
- (void)twitterize {
  
  if ( self.twitterTurnedOn ) {
    return;
  }
  
  self.tweetContentTextView.alpha = 1.0;
  self.tweetContentTextView.userInteractionEnabled = YES;
  self.tweetButton.enabled = NO;
  self.connectWithTwitterButton.alpha = 0.0;
  if ( !self.twitterAccount ) {
    self.twitterAccount = [[SocialManager shared] activeTwitterAccount];
    if ( !self.twitterAccount ) {
      NSString *twitterInfo = [[ContentManager shared].settings twitterInformation];
      NSDictionary *literal = (NSDictionary*)[twitterInfo JSONValue];
      [[SocialManager shared] accountObjectForScreenName:[literal objectForKey:@"screen_name"] delegate:self];
      return;
    }
  } else {
    [[SocialManager shared] setActiveTwitterAccount:self.twitterAccount];
  }
  
  [self.twitterAccountLabel snapText:[NSString stringWithFormat:@"@%@",[self.twitterAccount username]]
                                bold:NO
                       respectHeight:YES];
  
  [[SocialManager shared] queryTweetsWithHashtag:[self.event objectForKey:@"hashtag"]
                                       respondTo:self
                                     withAccount:self.twitterAccount];
  
  
  [UIView animateWithDuration:0.25 animations:^{
    self.noTwitterView.alpha = 0.0;
  } completion:^(BOOL finished) {
    [self killNoTwitter];
  }];
}

- (void)untwitterize {
  
  self.tweetButton.enabled = NO;
  self.twitterAccount = nil;
  self.twitterAccountLabel.text = @"";
  self.twitterFeedTable.delegate = nil;
  self.twitterFeedTable.dataSource = nil;
  self.tweetContentTextView.alpha = 0.5;
  self.tweetContentTextView.userInteractionEnabled = NO;
  self.noTwitterView.alpha = 0.0;
  self.noTwitterView.frame = self.twitterFeedTable.frame;
  [self.liveTweetView addSubview:self.noTwitterView];
  
  [UIView animateWithDuration:0.25 animations:^{
    self.connectWithTwitterButton.alpha = 1.0;
    self.noTwitterView.alpha = 1.0;
    self.twitterSpinner.alpha = 0.0;
  } completion:^(BOOL finished) {
    [self killTwitter];
  }];

}

- (void)killTwitter {
  self.twitterTurnedOn = NO;
}

- (void)killNoTwitter {
  self.twitterTurnedOn = YES;
  [self.noTwitterView removeFromSuperview];
}

#pragma mark - EventHandling
- (IBAction)doneTapped:(id)sender {
  [self.tweetContentTextView resignFirstResponder];
  
  [UIView animateWithDuration:0.25 animations:^{
    self.fauxBar.frame = CGRectMake(0.0,self.view.frame.size.height,
                                    self.fauxBar.frame.size.width,
                                    self.fauxBar.frame.size.height);
  }];
  
}

- (IBAction)tweetTapped:(id)sender {
  self.twitterIntent = TwitterIntentTweet;
  if ( self.twitterAccount ) {
    [[SocialManager shared] updateTwitterStatus:self.tweetContentTextView.text];
  } else {
    [[SocialManager shared] handleTwitterInteraction:self
                                    displayedInFrame:self.tweetButton.frame];
  }
}

- (IBAction)connectTapped:(id)sender {
  self.twitterIntent = TwitterIntentConnect;
  [Utilities animStart:self sel:@selector(bootRequest)];
  
  [UIView animateWithDuration:0.25 animations:^{
    self.connectWithTwitterButton.alpha = 0.0;
    [self.twitterSpinner startAnimating];
    self.twitterSpinner.alpha = 1.0;
  } completion:^(BOOL finished) {
    [self bootRequest];
  }];

  

}

- (void)bootRequest {
  [[SocialManager shared] handleTwitterInteraction:self
                                  displayedInFrame:self.connectWithTwitterButton.frame];
}

#pragma mark - UITextView
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if ( [text isEqualToString:@""] ) {
    if ( [self.tweetContentTextView.text length] <= 1 ) {
      self.tweetContentTextView.textColor = [[DesignManager shared] number2pencilColor];
      self.tweetContentTextView.text = kPlaceHolderString;
      [self.tweetContentTextView setSelectedRange:NSMakeRange(0, 0)];
      self.tweetButton.enabled = NO;
      [self countRemainingCharacters];
      return NO;
    }
    
    self.maxLength = NO;
    [self countRemainingCharacters];
    return YES;
  }
  
  textView.textColor = [[DesignManager shared] vinylColor:1.0];
  if ( [self.tweetContentTextView.text isEqualToString:kPlaceHolderString] ) {
    self.tweetContentTextView.text = text;
    [self countRemainingCharacters];
    self.tweetButton.enabled = YES;
    return NO;
  }
  
  if ( self.maxLength ) {
    return NO;
  }
  
  NSInteger length = [self countRemainingCharacters];
  if ( length <= 0 ) {
    self.maxLength = YES;
    self.tweetButton.enabled = YES;
    return NO;
  }
  
  self.tweetButton.enabled = YES;
  return YES;
}


- (void)textViewDidBeginEditing:(UITextView *)textView {
  
  [UIView animateWithDuration:0.25 animations:^{
    self.fauxBar.frame = CGRectMake(0.0,(self.view.frame.size.height*.66)-7.0,
                                    self.fauxBar.frame.size.width,
                                    self.fauxBar.frame.size.height);
  }];
  
  if ( [self.tweetContentTextView.text isEqualToString:kPlaceHolderString] ) {
    [self.tweetContentTextView setSelectedRange:NSMakeRange(0, 0)];
  }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  [self.mainScroller setContentOffset:CGPointMake(0.0, 0.0)
                             animated:YES];
}

- (NSInteger)countRemainingCharacters {
  NSInteger count = 140;
  if ( [self.tweetContentTextView.text isEqualToString:kPlaceHolderString] ) {
    count = 140;
  } else {
    count = count - [self.tweetContentTextView.text length];
  }
  
  self.remainingCharactersLabel.text = [NSString stringWithFormat:@"%d characters remaining",(int)count];
  return count;
}

#pragma mark - Reloadable
- (void)reload {
  [[SocialManager shared] queryTweetsWithHashtag:[self.event objectForKey:@"hashtag"]
                                       respondTo:self
                                     withAccount:self.twitterAccount];
}

- (NSString*)unfreezeKey {
  return @"loaded_hashtagged_tweets";
}

#pragma mark - Backable
- (void)backTapped {
  [[[Utilities del] viewController] displayPlayer];
  if ( self.resumeAudioOnExit ) {
    [[AudioManager shared] popSilence];
    [[AudioManager shared] startStream:nil];
  }
  
  self.reloader.observedScroller = nil;
  
  /*
  [[[Utilities del] globalTitleBar] morph:BarTypeDrawer
                                container:self];
  */
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Twitterable
- (void)currentAccountIdentified:(ACAccount *)account {
  self.twitterAccount = account;
  [self twitterize];
}

- (void)tweetsReceived:(NSDictionary *)data {
  
  NSArray *statuses = [data objectForKey:@"statuses"];
  self.tweets = statuses;
  self.twitterFeedTable.delegate = self;
  self.twitterFeedTable.dataSource = self;
  [self.twitterFeedTable reloadData];
  
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"loaded_hashtagged_tweets"
                                                      object:nil];
}

- (void)finishWithAccount:(ACAccount *)account {
  

  
  if ( self.twitterIntent == TwitterIntentConnect ) {
    
    self.twitterAccount = account;
    self.twitterTurnedOn = NO;
    [self twitterize];
    
  }
  if ( self.twitterIntent == TwitterIntentTweet ) {
    [[SocialManager shared] updateTwitterStatus:self.tweetContentTextView.text];
  }
  
  self.twitterIntent = TwitterIntentUnknown;
}

- (void)twitterAuthenticationFailed {
  
  [self untwitterize];
  
}

- (UIView*)twitterableView {
  return self.liveTweetView;
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.tweets count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSArray *cellObjects = [[NSBundle mainBundle] loadNibNamed:@"SCPRTweetCell"
                                                       owner:nil
                                                     options:nil];
  SCPRTweetCell *cell = (SCPRTweetCell*)[cellObjects objectAtIndex:0];
  return cell.frame.size.height;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSDictionary *tweet = [self.tweets objectAtIndex:indexPath.row];
  
  SCPRTweetCell *cell = [self.twitterFeedTable dequeueReusableCellWithIdentifier:@"tweet_cell"];
  if ( !cell ) {
    NSArray *cellObjects = [[NSBundle mainBundle] loadNibNamed:@"SCPRTweetCell"
                                                       owner:nil
                                                     options:nil];
    cell = (SCPRTweetCell*)[cellObjects objectAtIndex:0];
  }
  
  NSDictionary *user = [tweet objectForKey:@"user"];
  NSString *imageURL = [user objectForKey:@"profile_image_url"];
  [cell.twitterImageView loadImage:imageURL];
  
  NSString *sn = [NSString stringWithFormat:@"@%@",[user objectForKey:@"screen_name"]];
  [cell.screenNameLabel snapText:sn
                            bold:YES
                   respectHeight:YES];
  
  cell.tweetContentLabel.text = [tweet objectForKey:@"text"];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
