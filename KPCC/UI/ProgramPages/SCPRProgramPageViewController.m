//
//  SCPRProgramPageViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 4/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRProgramPageViewController.h"
#import "SCPRProgramCell.h"
#import "SCPRSegmentCell.h"
#import "SCPRTitlebarViewController.h"
#import "SCPRProgramAZViewController.h"
#import "SCPRExternalWebContentViewController.h"

#define kGradientSlipValue 78.0
#define kTableSlipValue 280.0
#define kTitleSlipValue 68.0

@interface SCPRProgramPageViewController ()

@end

@implementation SCPRProgramPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)mergeWithShow {
  
  
  if ( self.merged ) return;
  self.merged = YES;
  
  [self.programTitleLabel titleizeText:[self.programObject objectForKey:@"title"]
                                  bold:NO
                         respectHeight:YES];
  
  [self.programSubtitleLabel titleizeText:[NSString stringWithFormat:@"with %@",[self.programObject objectForKey:@"host"]]
                                     bold:NO
                            respectHeight:YES];
  
  
  self.dummyCell = [Utilities loadNib:@"SCPRProgramCell"];
  self.splashImage.alpha = 0.0;
  self.splashImage.clipsToBounds = YES;
  
  NSString *path = [[NSBundle mainBundle] pathForResource:[self imageNameForProgram]
                                                   ofType:@""];
  UIImage *splash = [UIImage imageWithContentsOfFile:path];
  self.splashImage.image = splash;
  
  /*[self.splashImage loadLocalImage:[self imageNameForProgram]
                           quietly:NO];*/
  
  BOOL spotlight = NO;
  if ( splash.size.width <= splash.size.height ) {
    spotlight = NO;
    self.splashImage.frame = CGRectMake(self.splashImage.frame.origin.x,
                                        self.splashImage.frame.origin.y,
                                        self.splashImage.frame.size.width,
                                        646.0);
  }
  
  
  
  self.episodeTable.tableFooterView = self.fillerFooterView;
  
  
  [self.descriptionLabel titleizeText:[Utilities unwebbifyString:[self.programObject objectForKey:@"description"]]
                                 bold:NO];
  
  [self.websiteLabel titleizeText:[self.programObject objectForKey:@"public_url"]
                                 bold:NO];
  
  [self.broadcastsAtLabel titleizeText:[self.programObject objectForKey:@"airtime"]
                             bold:NO];
  
  NSString *twitter = [self.programObject objectForKey:@"twitter_handle"];
  NSString *fmt = @"@%@";
  if ( [twitter length] > 0 ) {
    if ( [twitter characterAtIndex:0] == '@' ) {
      fmt = @"%@";
    }
    [self.twitterLabel titleizeText:[NSString stringWithFormat:fmt,twitter]
                               bold:YES];
  } else {
    self.twitterButton.alpha = 0.0;
    self.twitterLabel.alpha = 0.0;
  }

  
  [UIView animateWithDuration:0.44 animations:^{
    self.splashImage.alpha = 1.0;
    self.circleGradient.alpha = spotlight ? 1.0 : 1.0;
  }];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refresh)
                                               name:@"notify_listeners_of_queue_change"
                                             object:nil];
  
}

- (void)synthesizeShowData:(NSArray *)showData {
#ifdef USE_CLIENT_SORTING
  showData = [showData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    
    NSDictionary *d1 = (NSDictionary*)obj1;
    NSDictionary *d2 = (NSDictionary*)obj2;
    
    NSString *ad1 = [d1 objectForKey:@"air_date"];
    NSString *ad2 = [d2 objectForKey:@"air_date"];
    
    NSDate *date1 = [Utilities dateFromRFCString:ad1];
    NSDate *date2 = [Utilities dateFromRFCString:ad2];
    
    if ( [date1 earlierDate:date2] == date1 ) {
      return NSOrderedDescending;
    } else {
      return NSOrderedAscending;
    }
  }];
#endif
  
  NSMutableArray *revised = [[NSMutableArray alloc] init];
  for ( unsigned i = 0; i < [showData count]; i++ ) {
    NSDictionary *data = [showData objectAtIndex:i];
    NSArray *segments = [data objectForKey:@"segments"];
    BOOL nosegments = NO;
    if ( [Utilities pureNil:segments] ) {
      nosegments = YES;
    }
    
    BOOL noaudio = NO;
    NSArray *audio = [data objectForKey:@"audio"];
    if ( [Utilities pureNil:audio] ) {
      noaudio = YES;
    }
    
    if ( nosegments && noaudio ) {
      continue;
    }
    
    BOOL nosegaudio = NO;
    if ( noaudio ) {
      
      for ( NSDictionary *seg in segments ) {
        NSArray *segAudio = [seg objectForKey:@"audio"];
        if ( [Utilities pureNil:segAudio] || [segAudio count] == 0 ) {
          nosegaudio = YES;
          break;
        }
      }
    }
    
    if ( noaudio && nosegaudio ) {
      continue;
    }
    
    [revised addObject:data];
  }
  
  
  self.showData = [NSArray arrayWithArray:revised];
  self.episodeTable.delegate = self;
  self.episodeTable.dataSource = self;
  [self.episodeTable reloadData];
  
  [UIView animateWithDuration:0.33 animations:^{
    self.episodeTable.alpha = 1.0;
    [self.nativeSpinner stopAnimating];
    self.nativeSpinner.alpha = 0.0;
  } completion:^(BOOL finished) {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"spinner_appeared"
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"show_info_fetched"
                                                        object:self.programObject];
    
    self.mainScroller.userInteractionEnabled = YES;
    self.loaded = YES;
    
  }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  self.cellWithSegmentsHash = [[NSMutableDictionary alloc] init];
  self.nativeSpinner.alpha = 0.0;
  self.nativeSpinner.color = [[DesignManager shared] pumpkinColor];
  self.detailSeatView.alpha = 0.0;
  self.cloakView.alpha = 0.0;
  
  if ( [Utilities isLandscape] ) {
    self.episodeTable.backgroundColor = [UIColor clearColor];
  } else {
    self.episodeTable.backgroundColor = [UIColor blackColor];
  }
  
  self.swipeDownToReveal = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(reveal)];
  self.swipeUpToObscure = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(obscure)];
  
  self.episodeTable.separatorColor = [[DesignManager shared] touchOfGrayColor];
  self.splashImage.alpha = 0.0;
  self.circleGradient.alpha = 0.0;
  self.view.backgroundColor = [UIColor blackColor];
  self.segmentTableHash = [[NSMutableDictionary alloc] init];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(cleanup:)
                                               name:@"show_info_fetched"
                                             object:nil];
  

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  if ( self.populateOnAppearance ) {
    self.populateOnAppearance = NO;
    [self mergeWithShow];
    [self fetchShowInformation];
  }
  
  [[[Utilities del] globalTitleBar] applyClearBackground];
  [[[Utilities del] globalTitleBar] eraseDonateButton];
  
}

- (void)cleanup:(NSNotification*)note {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"show_info_fetched"
                                                object:nil];
  
  NSDictionary *po = [note object];
  if ( [[po objectForKey:@"title"] isEqualToString:[self.programObject objectForKey:@"title"]] ) {
    return;
  }
  
  self.episodeTable.dataSource = nil;
  self.episodeTable.delegate = nil;
  self.splashImage.image = nil;
  self.splashImage.alpha = 0.0;
  self.episodeTable.alpha = 0.0;
}

- (NSString*)imageNameForProgram {
  return [[ContentManager shared] imageNameForProgram:self.programObject];
}

- (void)fetchShowInformation {
  
  if ( self.loaded ) return;
  
  [self.nativeSpinner startAnimating];
  [UIView animateWithDuration:0.22 animations:^{
    self.nativeSpinner.alpha = 1.0;
  } completion:^(BOOL finished) {
    [self proceedWithFetch];
  }];
  
}

- (void)proceedWithFetch {
  
  //NSDictionary *cachedData = [[ContentManager shared].programCache objectForKey:[Utilities sha1:[self.programObject objectForKey:@"title"]]];
  /*if ( cachedData ) {
    NSLog(@"Cached program data being used...");
    [self handleProcessedContent:[cachedData objectForKey:@"meta"]
                           flags:nil];
  } else {*/
    [[NetworkManager shared] fetchContentForProgramPage:[self.programObject objectForKey:@"slug"]
                                              display:self];
  //}
}

#pragma mark - UITableView
- (NSInteger)calculateTagForIndexPath:(NSIndexPath *)indexPath {
  NSInteger count = 0;
  for ( unsigned i = 0; i < indexPath.section; i++ ) {
    count += [self tableView:self.episodeTable
       numberOfRowsInSection:i];
  }
  return count+indexPath.row+1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  if ( [self.showData count] == 0 ) {
    return 0;
  }
  
  if ( section == 0 ) {
    return 1;
  }
  
  return [self.showData count]-1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  SCPRProgramCell *cell = [self.episodeTable dequeueReusableCellWithIdentifier:@"episode_cell"];
  if ( !cell ) {
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                            xibForPlatformWithName:@"SCPRProgramCell"]
                                                     owner:nil
                                                   options:nil];
    cell = (SCPRProgramCell*)[objects objectAtIndex:0];
    cell.originalHeadlineFrame = cell.episodeTitleLabel.frame;
    cell.originalSegmentsLabelFrame = cell.numberOfSegmentsLabel.frame;
  }
  
  NSDictionary *obj = nil;
  NSInteger realIndex = 0;
  if ( indexPath.section == 0 ) {
    
    obj = [self.showData objectAtIndex:0];
    
    
  } else {
    
    realIndex = indexPath.row+1;
    obj = [self.showData objectAtIndex:indexPath.row+1];
  
  }
  
  if ( [[QueueManager shared] articleIsInQueue:obj] ) {
    if ( [[QueueManager shared] articleIsPlayingNow:obj] ) {
      [[DesignManager shared] globalSetImageTo:@"now_playing_button.png"
                                     forButton:cell.actionButton];
    } else {
      [[DesignManager shared] globalSetImageTo:@"in_queue_button.png"
                                   forButton:cell.actionButton];
    }
  } else {
    [[DesignManager shared] globalSetImageTo:@"play_now_button.png"
                                   forButton:cell.actionButton];
  }
  
  
  
  cell.spinner.alpha = 0.0;
  cell.spinner.color = [[DesignManager shared] periwinkleColor];
  cell.actionButton.alpha = 1.0;
  
  cell.clipsToBounds = YES;
  cell.parentController = self;
  
  NSString *titleStr = [obj objectForKey:@"title"];
  titleStr = [Utilities stripTrailingNewline:titleStr];
  titleStr = [Utilities unwebbifyString:titleStr];
  
  [cell.episodeTitleLabel titleizeText:titleStr
                                  bold:(indexPath.section == 0)
                         respectHeight:YES
   lighten:(indexPath.section != 0 )];
  
  BOOL noMainAudio = NO;
  NSArray *audioVector = [obj objectForKey:@"audio"];
  if ( [audioVector count] > 0 ) {
    NSDictionary *audioMeta = [audioVector objectAtIndex:0];
    
    id duration = [audioMeta objectForKey:@"duration"];
    if ( [Utilities pureNil:duration] ) {
      cell.episodeLengthLabel.alpha = 0.0;
      
      [[DesignManager shared] alignVerticalCenterOf:cell.episodeTitleLabel
                                           withView:cell.actionButton];
      
    } else {
    
      NSInteger ni = [[audioMeta objectForKey:@"duration"] intValue];
      if ( ni == 0 ) {
        cell.episodeLengthLabel.alpha = 0.0;
        
        [[DesignManager shared] alignVerticalCenterOf:cell.episodeTitleLabel
                                             withView:cell.actionButton];
      } else {
        [cell.episodeLengthLabel italicizeText:[Utilities formalStringFromSeconds:ni]
                                    bold:YES
                           respectHeight:YES];
      }
      
    }
    
    [cell.actionButton addTarget:cell
                          action:@selector(mainPlayRequested:)
                forControlEvents:UIControlEventTouchUpInside];
      
    cell.actionButton.tag = indexPath.section+indexPath.row;
    

  
  } else {
    noMainAudio = YES;
    cell.episodeLengthLabel.alpha = 0.0;
    cell.actionButton.alpha = 0.0;
  }
  
  cell.programEpisode = obj;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  NSArray *segments = [obj objectForKey:@"segments"];
  if ( [segments count] == 0 ) {
    cell.numberOfSegmentsLabel.alpha = 0.0;
    cell.showSegmentsButton.alpha = 0.0;
  } else {
    
    if ( noMainAudio ) {

      NSDictionary *segment = [segments objectAtIndex:0];
      
      if ( [[segment objectForKey:@"audio"] count] > 0 ) {
        cell.actionButton.alpha = 1.0;
      
        [cell.actionButton addTarget:cell
                            action:@selector(mainPlayRequested:)
                  forControlEvents:UIControlEventTouchUpInside];
        
        cell.actionButton.tag = indexPath.section+indexPath.row;
        /*
        NSMutableDictionary *mainProgram = [cell.programEpisode mutableCopy];
        NSArray *audio = [segment objectForKey:@"audio"];
        
        [mainProgram setObject:audio
                      forKey:@"audio"];
        cell.programEpisode = [NSDictionary dictionaryWithDictionary:mainProgram];
        NSMutableArray *mutableData = [self.showData mutableCopy];
        if ( [mutableData objectAtIndex:realIndex] && cell.programEpisode ) {
          [mutableData replaceObjectAtIndex:realIndex withObject:cell.programEpisode];
        }
        self.showData = [NSArray arrayWithArray:mutableData];
        
        NSInteger ni = [[[[segment objectForKey:@"audio"] objectAtIndex:0] objectForKey:@"duration"] intValue];
        if ( ni == 0 ) {
          cell.episodeLengthLabel.alpha = 0.0;
          
          [[DesignManager shared] alignVerticalCenterOf:cell.episodeTitleLabel
                                               withView:cell.actionButton];
        } else {
          cell.episodeLengthLabel.alpha = 1.0;
          [cell.episodeLengthLabel italicizeText:[Utilities formalStringFromSeconds:ni]
                                            bold:YES
                                   respectHeight:YES];
        }*/
        
        NSInteger totalTime = 0;
        BOOL nowPlaying = NO;
        BOOL inQueue = NO;
        for ( NSDictionary *segment in segments ) {
          
          if ( [[QueueManager shared] articleIsInQueue:segment] ) {
            inQueue = YES;
          }
          if ( [[QueueManager shared] articleIsPlayingNow:segment] ) {
            nowPlaying = YES;
          }
          NSInteger ni = [[[[segment objectForKey:@"audio"] objectAtIndex:0] objectForKey:@"duration"] intValue];
          totalTime += ni;
        }
        
        if ( nowPlaying ) {
          [[DesignManager shared] globalSetImageTo:@"now_playing_button.png"
                                         forButton:cell.actionButton];
        } else {
          if ( inQueue ) {
            [[DesignManager shared] globalSetImageTo:@"in_queue_button.png"
                                         forButton:cell.actionButton];
          } else {
            [[DesignManager shared] globalSetImageTo:@"play_now_button.png"
                                           forButton:cell.actionButton];
          }
        }
       
        if ( totalTime == 0 ) {
          cell.episodeLengthLabel.alpha = 0.0;
          
          [[DesignManager shared] alignVerticalCenterOf:cell.episodeTitleLabel
                                               withView:cell.actionButton];
        } else {
          cell.episodeLengthLabel.alpha = 1.0;
          [cell.episodeLengthLabel italicizeText:[Utilities formalStringFromSeconds:totalTime]
                                            bold:YES
                                   respectHeight:YES];
        }
        
      }
    }
    
    cell.numberOfSegmentsLabel.alpha = 1.0;
    cell.showSegmentsButton.alpha = 1.0;
    
    if ( [segments count] == 1 ) {
      cell.numberOfSegmentsLabel.alpha = 0.0;
      cell.showSegmentsButton.alpha = 0.0;
      /*cell.episodeTitleLabel.frame = CGRectMake(cell.episodeTitleLabel.frame.origin.x,
                                                cell.episodeTitleLabel.frame.origin.y,
                                                cell.episodeTitleLabel.frame.size.width+cell.numberOfSegmentsLabel.frame.size.width+28.0,
                                                cell.episodeTitleLabel.frame.size.height);*/
      [cell.episodeTitleLabel titleizeText:[obj objectForKey:@"title"]
                                      bold:(indexPath.section == 0)
                             respectHeight:YES
       lighten:(indexPath.section != 0)];
      
    } else {
      [cell.numberOfSegmentsLabel titleizeText:[NSString stringWithFormat:@"%d segments",[segments count]]
                                        bold:YES
                               respectHeight:YES];
    
      //cell.segmentsTable.dataSource = cell;
      //cell.segmentsTable.delegate = cell;
      cell.segments = segments;
    
      cell.showSegmentsButton.tag = [self calculateTagForIndexPath:indexPath];
      
      [self.segmentTableHash setObject:cell.segmentsTable
                                forKey:[NSString stringWithFormat:@"%d",cell.showSegmentsButton.tag]];
      [self.cellWithSegmentsHash setObject:cell
                                    forKey:[NSString stringWithFormat:@"%d",cell.showSegmentsButton.tag]];
      
      [cell.showSegmentsButton addTarget:self
                                action:@selector(toggleSegments:)
                      forControlEvents:UIControlEventTouchUpInside];
    }
  }

  [(SCPRProgramCell*)cell refresh];
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  

  SCPRProgramCell *cell = self.dummyCell;
  
  if ( [self calculateTagForIndexPath:indexPath] == [self.expandedCellTag intValue] ) {
    return cell.segmentsTable.frame.size.height+cell.frame.size.height;
  }
  
  return cell.frame.size.height;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *v = [Utilities loadNib:@"SCPRProgramCell"
                        objIndex:1];
  
  UILabel *textLabel = (UILabel*)[v viewWithTag:kHeaderLabelTag];
  if ( section == 0 ) {
    
    [textLabel thickerText:@"LATEST EPISODE"
                       bold:NO
              respectHeight:YES];
    textLabel.textColor = [[DesignManager shared] obsidianColor:1.0];
    [v addGestureRecognizer:self.swipeDownToReveal];
    self.topHeader = v;
    
  } else {
    [textLabel thickerText:@"RECENT EPISODES"
                       bold:NO
              respectHeight:YES];
    textLabel.textColor = [[DesignManager shared] number2pencilColor];
  }
  
  v.backgroundColor = [[DesignManager shared] stratusCloudColor:1.0];
  
  return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRProgramCell"]
                                                   owner:nil
                                                 options:nil];
  UIView *v = (SCPRProgramCell*)[objects objectAtIndex:1];
  return v.frame.size.height;
}

#pragma mark - UI and Event Handling
- (void)refresh {
  [self.episodeTable reloadData];
}

- (IBAction)playRequested:(id)sender {
  UIButton *btn = (UIButton*)sender;
  NSDictionary *show = [self.showData objectAtIndex:btn.tag];
  if ( [[QueueManager shared] articleIsInQueue:show] ) {
    [[QueueManager shared] playSpecificArticle:show];
    [[AnalyticsManager shared] logEvent:@"program_episode_played" withParameters:@{@"program_title" : [self.programObject objectForKey:@"title"]}];
  } else {
    
    NSString *titleized = [Utilities titleize:[self.programObject objectForKey:@"title"]];
    NSString *imageStr = [NSString stringWithFormat:@"small_%@_splash.jpg",titleized];
    
    if (![[AudioManager shared] isPlayingAnyAudio]) {
      [[AnalyticsManager shared] logEvent:@"program_episode_played" withParameters:@{@"program_title" : [self.programObject objectForKey:@"title"]}];
    }
    
    [[QueueManager shared] addToQueue:show
                                asset:imageStr
                      playImmediately:![[AudioManager shared] isPlayingAnyAudio]];    
  }
}

- (IBAction)toggleSegments:(id)sender {
  
  if ( self.expandedCellTag ) {
    SCPRProgramCell *oCell = [self.cellWithSegmentsHash objectForKey:[NSString stringWithFormat:@"%@",self.expandedCellTag]];
    if ( oCell ) {
      oCell.segmentsTable.dataSource = nil;
      oCell.segmentsTable.delegate = nil;
    }
  }
  
  UIButton *sb = (UIButton*)sender;
  if ( [self.expandedCellTag intValue] == sb.tag ) {
    self.expandedCellTag = nil;
  } else {
    self.expandedCellTag = [NSNumber numberWithInt:sb.tag];
  }
  
  if ( self.expandedCellTag ) {
    UITableView *segmentsTable = [self.segmentTableHash objectForKey:[NSString stringWithFormat:@"%@",self.expandedCellTag]];
    SCPRProgramCell *pCell = [self.cellWithSegmentsHash objectForKey:[NSString stringWithFormat:@"%@",self.expandedCellTag]];
    segmentsTable.delegate = pCell;
    segmentsTable.dataSource = pCell;
    [segmentsTable reloadData];
  }
  
  [self.episodeTable beginUpdates];
  [self.episodeTable endUpdates];
  
}

- (IBAction)buttonTapped:(id)sender {
  if ( sender == self.toggleTable ) {
    if ( self.revealing ) {
      [self obscure];
    } else {
      [self reveal];
    }
  }
  if ( sender == self.airtimeButton ) {
    
    [[[UIAlertView alloc] initWithTitle:@"Reminder"
                                message:@"Remind you when this program is about to begin?"
                               delegate:self
                      cancelButtonTitle:@"No Thanks"
                      otherButtonTitles:@"Please Do!", nil] show];
    
  }
  if ( sender == self.websiteButton ) {
    
    SCPRExternalWebContentViewController *scpr = [[SCPRExternalWebContentViewController alloc]
                                                  initWithNibName:[[DesignManager shared]
                                                                   xibForPlatformWithName:@"SCPRExternalWebContentViewController"]
                                                  bundle:nil];
    NSString *url = [self.programObject objectForKey:@"public_url"];
    NSURL *urlObj = [NSURL URLWithString:url];
    NSURLRequest *rq = [[NSURLRequest alloc] initWithURL:urlObj];
    scpr.view.frame = scpr.view.frame;
    
    [[Utilities del] cloakUIWithCustomView:scpr dismissible:YES
                                      push:40.0];
    [scpr prime:rq];
    
  }
  
  if ( sender == self.twitterButton ) {
    
    SCPRExternalWebContentViewController *scpr = [[SCPRExternalWebContentViewController alloc]
                                                  initWithNibName:[[DesignManager shared]
                                                                   xibForPlatformWithName:@"SCPRExternalWebContentViewController"]
                                                  bundle:nil];
    NSString *twurl = [self.programObject objectForKey:@"twitter_handle"];
    NSString *url = [NSString stringWithFormat:@"http://www.twitter.com/%@",twurl];
    NSURL *urlObj = [NSURL URLWithString:url];
    NSURLRequest *rq = [[NSURLRequest alloc] initWithURL:urlObj];
    scpr.view.frame = scpr.view.frame;
    
    [[Utilities del] cloakUIWithCustomView:scpr dismissible:YES
                                      push:40.0];
    [scpr prime:rq];
    
  }
}

- (void)reveal {

  
  if ( self.revealing ) {
    return;
  }
  
  if ( self.animationLock ) {
    return;
  }
  
  @synchronized(self) {
    self.toggleTable.userInteractionEnabled = NO;
  }
  
  CGFloat titleSlip = [Utilities isLandscape] ? 30.0 : kTitleSlipValue;
  
  [UIView animateWithDuration:0.43 animations:^{
    
    self.gradientImage.center = CGPointMake(self.gradientImage.center.x,
                                            self.gradientImage.center.y+kGradientSlipValue);
    self.tableSeat.center = CGPointMake(self.tableSeat.center.x,
                                           self.tableSeat.center.y+kTableSlipValue);
    
    self.showTitleView.center = CGPointMake(self.showTitleView.center.x,
                                            self.showTitleView.center.y+titleSlip);
    self.detailSeatView.alpha = 1.0;
    
  } completion:^(BOOL finished) {
    
    self.revealing = YES;
    self.toggleTable.userInteractionEnabled = YES;
    
  }];
  
  [[AnalyticsManager shared] logEvent:@"program_info"
                       withParameters:@{}];
}

- (void)obscure {

  
  if ( !self.revealing ) {
    return;
  }
  

  @synchronized(self) {
    self.toggleTable.userInteractionEnabled = NO;
  }
  
  CGFloat titleSlip = [Utilities isLandscape] ? 30.0 : kTitleSlipValue;
  
  [UIView animateWithDuration:0.33 animations:^{
    
    self.gradientImage.center = CGPointMake(self.gradientImage.center.x,
                                            self.gradientImage.center.y-kGradientSlipValue);
    self.tableSeat.center = CGPointMake(self.tableSeat.center.x,
                                           self.tableSeat.center.y-kTableSlipValue);
    self.showTitleView.center = CGPointMake(self.showTitleView.center.x,
                                            self.showTitleView.center.y-titleSlip);
    self.detailSeatView.alpha = 0.0;
    
  } completion:^(BOOL finished) {
    
    self.revealing = NO;
    self.toggleTable.userInteractionEnabled = YES;
    
  }];
}

#pragma mark - Backable
- (void)backTapped {
  SCPRProgramAZViewController *az = (SCPRProgramAZViewController*)self.parentAZPage;
  SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
  [tb morph:BarTypeProgramAtoZ container:nil];
  
  [az mergeWithToolbar];
  
  [self.navigationController popViewControllerAnimated:YES];
  
  if ( self.accessedFromAZ ) {
    [[ContentManager shared] popFromResizeVector];
  }
}

#pragma mark - Rotatable
- (void)handleRotationPre {
  if ( self.accessedFromAZ ) {
    [UIView animateWithDuration:0.15 animations:^{
      self.cloakView.alpha = 1.0;
    }];
  }
}

- (void)handleRotationPost {
  if ( self.accessedFromAZ ) {
    [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                      xibForPlatformWithName:@"SCPRProgramPageViewController"]
                                               owner:self
                                             options:nil];
    [self mergeWithShow];
    [self fetchShowInformation];
    [UIView animateWithDuration:0.15 animations:^{
      self.cloakView.alpha = 0.0;
    }];
  }
}

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if ( buttonIndex == 1 ) {
    [[ScheduleManager shared] addReminder:self.programObject
                           reminderType:ReminderTypeBeginningOfProgram];
  }
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  [[ContentManager shared] addProgramToCache:self.programObject data:content];
  [self synthesizeShowData:content];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"*** DEALLOCATING PROGRAM PAGE ***");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
