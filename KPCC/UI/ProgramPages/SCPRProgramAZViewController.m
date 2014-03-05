//
//  SCPRProgramAZViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/25/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRProgramAZViewController.h"
#import "SCPRProgramPlateView.h"
#import "global.h"
#import "SCPRViewController.h"
#import "SCPRProgramPageViewController.h"

@interface SCPRProgramAZViewController ()

@end

@implementation SCPRProgramAZViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
  
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  /*[self stretch];*/
  
  self.programPickerView.showsVerticalScrollIndicator = NO;
  
  if ( [Utilities isIOS7] ) {
    self.programPickerView.center = CGPointMake(self.programPickerView.center.x,
                                                self.programPickerView.center.y+40.0);
    self.programPickerView.frame = CGRectMake(self.programPickerView.frame.origin.x,
                                              self.programPickerView.frame.origin.y,
                                              self.programPickerView.frame.size.width,
                                              self.programPickerView.frame.size.height-20.0);
  } else {
    self.programPickerView.frame = CGRectMake(self.programPickerView.frame.origin.x,
                                              self.programPickerView.frame.origin.y+40.0,
                                              self.programPickerView.frame.size.width,
                                              self.programPickerView.frame.size.height-40.0);
  }
  
  if ( self.shill )
    return;
  
  self.cellPool = [[NSMutableDictionary alloc] init];
  self.autoAddItems = [[NSMutableDictionary alloc] init];
  
  self.view.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  
  NSArray *objectDmy = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRProgramPlateView"]
                                                   owner:nil
                                                 options:nil];
  
  SCPRProgramPlateView *dummyPlate = (SCPRProgramPlateView*)[objectDmy objectAtIndex:0];
  self.originalTitleFrameSize = dummyPlate.titleLabel.frame;
  
  NSString *userJson = [[ContentManager shared].settings favoriteProgramsAsJson];
  NSMutableArray *favorites = (NSMutableArray*)[userJson JSONValue];
  
  self.checkedItems = [[NSMutableDictionary alloc] init];
  for ( NSDictionary *favorite in favorites ) {
    [self.checkedItems setObject:favorite forKey:[favorite objectForKey:@"slug"]];
    Scheduler *scheduler = [[ContentManager shared] findSchedulerForProgram:[favorite objectForKey:@"slug"]];
    if ( scheduler ) {
      [self.autoAddItems setObject:@1
                            forKey:[favorite objectForKey:@"slug"]];
    } else {
      [self.autoAddItems setObject:@0
                            forKey:[favorite objectForKey:@"slug"]];
    }
  }
  self.originalHashValue = [self hashForCurrentlyChecked];
  [self checkToEnableDoneButton];
  
  
  self.programs = [[ContentManager shared] sortedProgramList];
  
  /*for ( NSDictionary *dict in self.programs ) {
    NSString *pn = [[ContentManager shared] imageNameForProgram:dict];
    NSString *small = [NSString stringWithFormat:@"small_%@",pn];
    [[ContentManager shared] writeImageDirectlyIntoCache:small];
  }*/
  
  NSString *json = [self.programs JSONRepresentation];
  self.programs = [NSMutableArray arrayWithArray:[[ContentManager shared] minimizedProgramFavorites:json]];
  self.programPickerView.dataSource = self;
  self.programPickerView.delegate = self;
  

  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                            xibForPlatformWithName:@"SCPRProgramPlateView"]
                                                     owner:nil
                                                   options:nil];
  SCPRProgramPlateView *plate = (SCPRProgramPlateView*)[objects objectAtIndex:0];
  [self.flowController setItemSize:CGSizeMake(plate.frame.size.width,
                                              plate.frame.size.height)];

  
  UINib *nib = [UINib nibWithNibName:[[DesignManager shared]
                                      xibForPlatformWithName:@"SCPRProgramPlateView"] bundle:[NSBundle mainBundle]];
  
  [self.programPickerView registerNib:nib forCellWithReuseIdentifier:@"plate_cell"];
  
  
  [self mergeWithToolbar];
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  [self.programPickerView.collectionViewLayout invalidateLayout];
  [self.programPickerView invalidateIntrinsicContentSize];
  
}

- (void)unplug {
  [[ContentManager shared] popFromResizeVector];
}

#pragma mark - Event Handling
- (IBAction)doneTapped:(id)sender {
  
  
  if ( self.editMode ) {
    if ( ![self.originalHashValue isEqualToString:[self hashForCurrentlyChecked]] ) {
      NSMutableArray *mutableValues = [self.checkedItems.allValues mutableCopy];
      [mutableValues sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *d1 = (NSDictionary*)obj1;
        NSDictionary *d2 = (NSDictionary*)obj2;
      
        NSString *s1 = [d1 objectForKey:@"title"];
        NSString *s2 = [d2 objectForKey:@"title"];
      
        return (NSComparisonResult)[s1 localizedCaseInsensitiveCompare:s2];
      }];
    
      if ( [mutableValues count] > 12 ) {
        [[AnalyticsManager shared] logEvent:@"user_has_large_number_of_favorites"
                             withParameters:@{ @"count" : [NSString stringWithFormat:@"%d",[mutableValues count]] }];
      }
      
      NSString *asJson = [mutableValues JSONRepresentation];
      [[ContentManager shared].settings setFavoriteProgramsAsJson:asJson];
      [[ContentManager shared] forceSettingsWithParse];
    }
  
    [[Utilities del] showTitleBar];
  
    self.editMode = NO;
    if ( [self.checkedItems count] == 0 ) {
      
      NSString *text = [Utilities isIpad] ? @"ADD FAVORITES" : @"ADD";
      [[DesignManager shared] globalSetTitleTo:text
                                     forButton:self.saveButton];
      [[DesignManager shared] globalSetImageTo:@"icon-add-favorites.png"
                                     forButton:self.saveButton];
    } else {
      
      NSString *text = [Utilities isIpad] ? @"EDIT FAVORITES" : @"EDIT";
      [[DesignManager shared] globalSetTitleTo:text
                                     forButton:self.saveButton];
      [[DesignManager shared] globalSetImageTo:@"icon-edit-favorites.png"
                                     forButton:self.saveButton];
    }
    
    [self.saveButton setContentEdgeInsets:UIEdgeInsetsMake(0,0,0,0)];
    
    [[DesignManager shared] globalSetTextColorTo:[UIColor whiteColor]
                                       forButton:self.saveButton];
    
    NSMutableArray *processQueue = [[NSMutableArray alloc] init];
    for ( NSString *slug in [self.autoAddItems allKeys] ) {
      NSNumber *n = [self.autoAddItems objectForKey:slug];
      if ( n && [n intValue] == 1 ) {
        Scheduler *sch = [[ContentManager shared] findSchedulerForProgram:slug];
        if ( !sch ) {
          [[ContentManager shared] createSchedulerForProgram:slug];
        }
        [processQueue addObject:slug];
      } else {
        [[ContentManager shared] destroySchedulerForProgram:slug];
      }
    }
    
    [Utilities primeTitlebarWithText:@"ALL PROGRAMS"
                        shareEnabled:NO
                           container:nil];
    
#ifndef STUB_AUTOADD
    [[ScheduleManager shared] syncLatestPrograms:processQueue];
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"favorites_modified"
                                                        object:nil];

  } else {
    
    self.editMode = YES;
    [[DesignManager shared] globalSetTitleTo:@"SAVE" forButton:self.saveButton];

    [[DesignManager shared] globalSetImageTo:@"icon-save-favorites.png"
                                   forButton:self.saveButton];
    
    CGFloat offset = 45.0;
    UIEdgeInsets og = [[[Utilities del] globalTitleBar] originalEditButtonInsets];
    [self.saveButton setContentEdgeInsets:UIEdgeInsetsMake(og.top, og.left+offset, og.bottom, og.right)];
    
    [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] turquoiseCrystalColor:1.0]
                                       forButton:self.saveButton];
    
    [Utilities primeTitlebarWithText:@"Tap programs to add favorites" shareEnabled:NO container:nil];
    
  }
  
  for ( UICollectionViewCell *cell in [self.programPickerView visibleCells] ) {
    [(SCPRProgramPlateView*)cell updateSelf];
  }

}

- (void)mergeWithToolbar {
  self.saveButton = [[[Utilities del] globalTitleBar] editButton];
  
  [self.saveButton addTarget:self
                      action:@selector(doneTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  
  
  if ( [self.checkedItems count] == 0 ) {
    NSString *text = [Utilities isIpad] ? @"ADD FAVORITES" : @"ADD";
    [[DesignManager shared] globalSetTitleTo:text
                                   forButton:self.saveButton];
    [[DesignManager shared] globalSetImageTo:@"icon-add-favorites.png"
                                   forButton:self.saveButton];
  } else {
    NSString *text = [Utilities isIpad] ? @"EDIT FAVORITES" : @"EDIT";
    [[DesignManager shared] globalSetTitleTo:text
                                   forButton:self.saveButton];
    [[DesignManager shared] globalSetImageTo:@"icon-edit-favorites.png"
                                   forButton:self.saveButton];
  }
  
  [[DesignManager shared] globalSetTextColorTo:[UIColor whiteColor]
                                     forButton:self.saveButton];
  
}

#pragma mark - Utility
- (UIImage*)imageForProgram:(NSDictionary *)program {
  return [[DesignManager shared] imageForProgram:program];  
}

- (NSString*)hashForCurrentlyChecked {
  
  NSString *base = @"empty";
  for ( NSDictionary *d in [self.checkedItems allValues] ) {
    base = [base stringByAppendingString:[d objectForKey:@"title"]];
  }
  
  return [Utilities sha1:base];
}

- (void)checkToEnableDoneButton {

}



#pragma mark - CollectionView
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return [self.programs count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  
  SCPRProgramPlateView *plate = (SCPRProgramPlateView*)[self.programPickerView dequeueReusableCellWithReuseIdentifier:@"plate_cell"
                                                                                  forIndexPath:indexPath];
  if ( !plate ) {
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                            xibForPlatformWithName:@"SCPRProgramPlateView"]
                                                     owner:nil
                                                   options:nil];
    plate = (SCPRProgramPlateView*)[objects objectAtIndex:0];
    plate.frame = plate.frame;
 
  }
  
  
  plate.parentController = self;
  
  NSDictionary *program = [self.programs objectAtIndex:indexPath.row];
  
  [plate primeWithProgram:program];
  
  if ( [self.checkedItems objectForKey:[program objectForKey:@"slug"]] ) {
    [plate favoriteUI:YES];
  } else {
    [plate favoriteUI:NO];
  }
  
#ifndef STUB_AUTOADD
  if ( [[self.autoAddItems objectForKey:[program objectForKey:@"slug"]] intValue] == 1 ) {
    [plate primeAutoAdd:YES];
  } else {
    [plate primeAutoAdd:NO];
  }
#endif
  
  plate.cellIndex = indexPath.row;
  
  return plate;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  if ( self.editMode ) {
    NSDictionary *program = [self.programs objectAtIndex:indexPath.row];
    
    if ( [self.checkedItems objectForKey:[program objectForKey:@"slug"]] ) {
      [self.checkedItems removeObjectForKey:[program objectForKey:@"slug"]];
    } else {
      [self.checkedItems setObject:program forKey:[program objectForKey:@"slug"]];
      [[AnalyticsManager shared] logEvent:@"program_favorited" withParameters:@{@"program_title" : [program objectForKey:@"title"]}];
    }    
    
    [self.programPickerView reloadItemsAtIndexPaths:@[indexPath]];
    [self checkToEnableDoneButton];
    
  } else {
    NSDictionary *program = [self.programs objectAtIndex:indexPath.row];
    SCPRProgramPageViewController *ppvc = [[SCPRProgramPageViewController alloc]
                                           initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRProgramPageViewController"]
                                           bundle:nil];
    ppvc.programObject = [[ContentManager shared] maximizedProgramForMinimized:program];
    ppvc.parentAZPage = self;
    ppvc.accessedFromAZ = YES;
    self.pushedProgram = ppvc;
    
    [[ContentManager shared] pushToResizeVector:ppvc];
    
    [[[Utilities del] globalTitleBar] morph:BarTypeProgramSingle container:ppvc];
    [self.navigationController pushViewController:ppvc
                                         animated:YES];

    [[AnalyticsManager shared] logEvent:@"program_viewed" withParameters:@{@"program_title" : [program objectForKey:@"title"]}];
    
    if ( ![Utilities isIOS7] ) {
      [ppvc mergeWithShow];
      [ppvc fetchShowInformation];
    } else {
      ppvc.populateOnAppearance = YES;
    }
  }
}

#pragma mark - Rotatable
- (void)handleRotationPost {
  
  SCPRProgramAZViewController *dummy = [[SCPRProgramAZViewController alloc]
                                        initWithNibName:[[DesignManager shared]
                                                         xibForPlatformWithName:@"SCPRProgramAZViewController"]
                                        bundle:nil];
  dummy.shill = YES;
  dummy.view.frame = dummy.view.frame;
  
  [UIView animateWithDuration:0.22 animations:^{
    self.programPickerView.frame = dummy.programPickerView.frame;
  } completion:^(BOOL finished) {
    //[self.programPickerView.collectionViewLayout invalidateLayout];
  }];
  

}

- (void)handleRotationPre {
  [self.programPickerView invalidateIntrinsicContentSize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
