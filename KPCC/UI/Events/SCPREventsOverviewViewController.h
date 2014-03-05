//
//  SCPREventsOverviewViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "SCPRViewController.h"

@interface SCPREventsOverviewViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) IBOutlet UITableView *eventsTable;
@property (nonatomic,strong) NSMutableArray *eventsList;
@property (nonatomic,strong) NSMutableArray *futureEvents;
@property (nonatomic,strong) id pushedEvent;
@property (nonatomic,strong) NSDictionary *featuredEvent;
@property (nonatomic,strong) NSTimer *carouselTimer;


// Header
@property (nonatomic,strong) IBOutlet UIView *featuredHeaderView;
@property (nonatomic,strong) IBOutlet UIView *featuredInformationView;
@property (nonatomic,strong) IBOutlet UILabel *featuredDateLabel;
@property (nonatomic,strong) IBOutlet UILabel *featuredTitleLabel;
@property (nonatomic,strong) IBOutlet UILabel *featuredTeaserLabel;
@property (nonatomic,strong) IBOutlet UIImageView *featuredSplashImageView;
@property (nonatomic,strong) IBOutlet UILabel *featuredCaptionLabel;
@property NSInteger carouselPointer;

- (void)primeHeader;
- (void)sourceWithList:(NSArray*)eventsContent;
- (void)disarmCarousel;

@end
