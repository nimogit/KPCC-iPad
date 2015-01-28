//
//  DesignManager.m
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "DesignManager.h"
#import "global.h"
#import "SCPRNewsPageContainerController.h"
#import "SCPRNewsPageViewController.h"
#import "SCPRViewController.h"
#import "SCPRDeluxeDividerView.h"
#import "SCPRMasterRootViewController.h"

static DesignManager *singleton = nil;

@implementation DesignManager

+ (DesignManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      singleton = [[DesignManager alloc] init];
    }
  }
  return singleton;
}

- (UIImage*)imageForProgram:(NSDictionary *)program {
  NSString *programName = [program objectForKey:@"title"];
  programName = [Utilities titleize:programName];
  return [[[ContentManager shared] imageCache] objectForKey:programName];
}

/*************************************************************************/
// -- Developer Note --
//
// The <Turnable> protocol was one that I worked on in order to give a "Flipboard"-like transition in between articles. All it assumed
// was that the articles were aligned edge to edge in a UIScrollView and that their controllers adopted the protocol.
// It was deemed unnecessary to have a fancy transition of this nature, and truth-be-told it wasn't cool-looking enough in my opinion. Still, the code
// is here though hooking it back up won't exactly be trivial. Study the function carefully as there's some stuff in there that's kind of wonky.
// Take the concept of the "flaps". The flaps I put in there as a way to give each page a kind of 3-D "blocked" look. Similar to what happens when
// the screen flips over horizontally in the Podcasts app. They're not exactly required, but in case one is wondering what that's all about...

// The whole "ghost" concept is a result of trying to make the
// SingleArticleCollectionViewController interface work with this. Since the indicies and article frames never go above 2 or past 3*<width-of-article>
// a "virtual" or "ghost" frame and index were required in order for the calculations to take properly as the user is farther along in the list.
// Anyway, if it bears some interest one could look over this method.
//
- (void)turn:(id<Turnable>)turnable withValues:(NSDictionary *)changes {
  CGPoint offsetNew = [[changes objectForKey:@"new"] CGPointValue];
  CGPoint offsetOld = [[changes objectForKey:@"old"] CGPointValue];
  CGFloat pivotOld = offsetOld.x;
  CGFloat pivot = offsetNew.x;
  
  if ( pivotOld == pivot ) {
    return;
  }

  if ( [turnable leftFlap] ) {
    [turnable leftFlap].view.alpha = 1.0;
  }
  if ( [turnable rightFlap] ) {
    [turnable rightFlap].view.alpha = 1.0;
  }
  
  CGFloat anchorBottom = [turnable ghostFrame].size.width * [turnable ghostIndex];
  
  
  CGFloat diff = pivot - anchorBottom;
  
  if ( abs(diff) > [turnable ghostFrame].size.width ) {
    return;
  }
  
  if ( abs(diff) < [turnable ghostFrame].size.width ) {
    if ( diff < 0.0 ) {
      CGFloat newDiff = anchorBottom - pivot;
      CGFloat percent = newDiff / [turnable ghostFrame].size.width;
      
      CALayer *layer = [turnable bendableView].layer;
      CATransform3D tform = CATransform3DIdentity;
      tform.m34 = (-1.0*percent) / 1000;
      
      tform = CATransform3DRotate(tform, [Utilities degreesToRadians:90.0*percent],
                                  0.0, 1.0, 0.0);
      [layer setTransform:tform];
      
      
      if ( [turnable leftFlap] && [turnable rightFlap] ) {
        CATransform3D leftFlapTform = CATransform3DIdentity;
        leftFlapTform.m34 = -1.0 / 1000;
      
      
      
        leftFlapTform = CATransform3DRotate(leftFlapTform,[Utilities degreesToRadians:(1.0-percent)*-90.0],
                                          0.0, 1.0, 0.0);
      
        [turnable leftFlap].view.layer.transform = leftFlapTform;
        [turnable rightFlap].view.layer.transform = CATransform3DMakeRotation([Utilities degreesToRadians:-90.0],
                                                                      0.0, 1.0, 0.0);
      
      }
      
      CGFloat newPercent = tanf(newDiff / [turnable ghostFrame].size.width);
      
      [turnable shadowView].alpha = newPercent*1.0;
      return;
      
    }
  }
  
  CGFloat percent = diff / [turnable ghostFrame].size.width;
  CALayer *layer = [turnable bendableView].layer;
  CATransform3D tform = CATransform3DIdentity;
  tform.m34 = (-1.0*percent) / 1000;
  tform = CATransform3DRotate(tform, [Utilities degreesToRadians:90.0*percent],
                              0.0, -1.0, 0.0);
  [layer setTransform:tform];
  
  if ( [turnable leftFlap] && [turnable rightFlap] ) {
    CATransform3D rightFlapTform = CATransform3DIdentity;
    rightFlapTform.m34 = -1.0 / 1000;
    rightFlapTform = CATransform3DRotate(rightFlapTform,[Utilities degreesToRadians:(1.0-percent)*90.0],
                                       0.0, 1.0, 0.0);
  
    [turnable rightFlap].view.layer.transform = rightFlapTform;
    [turnable leftFlap].view.layer.transform = CATransform3DMakeRotation([Utilities degreesToRadians:-90.0],
                                                                 0.0, 1.0, 0.0);
  }
  [turnable shadowView].alpha = sinf(percent*1.0);
}


- (NSString*)aspectCodeForContentItem:(NSDictionary *)item quality:(AssetQuality)quality {
  NSDictionary *image = [Utilities imageObjectFromBlob:item
                                               quality:quality];
  
  CGFloat width = 4.0;
  CGFloat height = 3.0;
  if ( ![Utilities pureNil:[image objectForKey:@"width"]] ) {
   width = [[image objectForKey:@"width"] floatValue];
  }
  if ( ![Utilities pureNil:[image objectForKey:@"height"]] ) {
    height = [[image objectForKey:@"height"] floatValue];
  }
  if ( height == 0.0 || width == 0.0 ) {
    return @"Sq";
  }
  
  CGFloat margin = 0.1f;
  CGFloat ratio = width / height;
  if ( ratio == NAN ) {
    return @"Sq";
  }
  
  NSDictionary *matrix = @{ @"1.5" : @"32",
                            @"1.33333333" : @"43",
                            @".75" : @"23",
                            @".6666666667" : @"34",
                            @"1.0" : @"Sq",
                            @"1.7777778" : @"43_clip",
                            @"2.333333" : @"43_clip",
                            @".87" : @"34" };
  
  CGFloat diff = MAXFLOAT;
  NSString *closestGuess = @"";
  for ( NSString *key in [matrix allKeys] ) {
    CGFloat keyAsFloat = [key floatValue];
    
    if ( ratio <= keyAsFloat+margin && ratio >= keyAsFloat-margin ) {
      NSString *code = [matrix objectForKey:key];
      return code;
    } else {
      CGFloat diffCandidate = fabsf(keyAsFloat-ratio);
      if ( diffCandidate < diff ) {
        diff = diffCandidate;
        closestGuess = [matrix objectForKey:key];
      }
    }
  }

  //NSLog(@"Couldn't make sense of ratio %1.4f, Guessing %@",ratio,closestGuess);
  return closestGuess;
}

- (void)alignTopOf:(UIView *)thisView withView:(UIView *)thatView {
  id asID = (id)thisView;
  CGFloat diff = thisView.frame.origin.y - thatView.frame.origin.y;
  CGFloat tick = [asID isKindOfClass:[UILabel class]] ? 6.0 : 0.0;
  thisView.center = CGPointMake(thisView.center.x,thisView.center.y-diff-tick);
}

- (void)alignBottomOf:(UIView *)floatingView withView:(UIView *)anchoredView {
  floatingView.frame = CGRectMake(floatingView.frame.origin.x,
                                  anchoredView.frame.origin.y+anchoredView.frame.size.height-floatingView.frame.size.height,
                                  floatingView.frame.size.width,
                                  floatingView.frame.size.height);
}

- (void)alignLeftOf:(UIView *)floatingView withView:(UIView *)anchoredView {
  floatingView.frame = CGRectMake(anchoredView.frame.origin.x,
                                  floatingView.frame.origin.y,
                                  floatingView.frame.size.width,
                                  floatingView.frame.size.height);
}

- (void)alignRightOf:(UIView *)floatingView withView:(UIView *)anchoredView {
  floatingView.frame = CGRectMake(anchoredView.frame.origin.x+anchoredView.frame.size.width-floatingView.frame.size.width,
                                  floatingView.frame.origin.y,
                                  floatingView.frame.size.width,
                                  floatingView.frame.size.height);
}

- (void)alignVerticalCenterOf:(UIView *)floatingView withView:(UIView *)anchoredView {
  floatingView.center = CGPointMake(floatingView.center.x,
                                    anchoredView.center.y);
}

- (void)alignHorizontalCenterOf:(UIView *)floatingView withView:(UIView *)anchoredView {
  floatingView.center = CGPointMake(anchoredView.center.x,
                                    floatingView.center.y);
}

- (void)avoidNeighborFrame:(CGRect)frame withView:(UIView *)floatingView direction:(NeighborDirection)direction padding:(CGFloat)padding  {
  switch (direction) {
    case NeighborDirectionAbove:
      floatingView.frame = CGRectMake(floatingView.frame.origin.x,
                              frame.origin.y+frame.size.height+padding,
                              floatingView.frame.size.width,
                              floatingView.frame.size.height);
      break;
    case NeighborDirectionBelow:
      floatingView.frame = CGRectMake(floatingView.frame.origin.x,
                              frame.origin.y-padding-floatingView.frame.size.height,
                              floatingView.frame.size.width,
                              floatingView.frame.size.height);
      break;
    case NeighborDirectionToLeft:
      floatingView.frame = CGRectMake(frame.origin.x+frame.size.width+padding,
                              floatingView.frame.origin.y,
                              floatingView.frame.size.width,
                              floatingView.frame.size.height);
      break;
    case NeighborDirectionToRight:
      floatingView.frame = CGRectMake(frame.origin.x-floatingView.frame.size.width-padding,
                                      floatingView.frame.origin.y,
                                      floatingView.frame.size.width,
                                      floatingView.frame.size.height);
      break;
    default:
      break;
  }
}

- (void)avoidNeighbor:(UIView *)neighbor
             withView:(UIView*)view direction:(NeighborDirection)direction
              padding:(CGFloat)padding {

  [self avoidNeighborFrame:neighbor.frame
                  withView:view
                 direction:direction
                   padding:padding];
}

- (void)nudge:(UIView *)view direction:(NeighborDirection)direction amount:(CGFloat)amount {
  switch (direction) {
    case NeighborDirectionToLeft:
        view.center = CGPointMake(view.center.x-amount,
                                  view.center.y);
      break;
    case NeighborDirectionToRight:
      view.center = CGPointMake(view.center.x+amount,
                                view.center.y);
      break;
    case NeighborDirectionAbove:
      view.center = CGPointMake(view.center.x,
                                view.center.y-amount);
      break;
    case NeighborDirectionBelow:
      view.center = CGPointMake(view.center.x,
                                view.center.y+amount);
      break;
    case NeighborDirectionUnknown:
      break;
  }
}

- (NSArray*)typicalConstraints:(UIView *)view withTopOffset:(CGFloat)topOffset {
  return [self typicalConstraints:view withTopOffset:topOffset fullscreen:NO];
}

- (NSArray*)typicalConstraints:(UIView *)view withTopOffset:(CGFloat)topOffset fullscreen:(BOOL)fullscreen {
  
  [view setTranslatesAutoresizingMaskIntoConstraints:NO];
  NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"view" : view }];
  
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(%ld)-[view]-(0)-|",(long)topOffset]
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"view" : view }];
  
  
  NSMutableArray *total = [NSMutableArray new];
  
  
  [total addObjectsFromArray:hConstraints];
  [total addObjectsFromArray:vConstraints];
  
  return [NSArray arrayWithArray:total];
}

- (NSArray*)sizeContraintsForView:(UIView *)view {
  
  NSLayoutConstraint *hConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:view.frame.size.height];
  
  NSLayoutConstraint *wConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:view.frame.size.width];
  
  return @[ hConstraint, wConstraint ];
  
}

- (NSArray*)typicalConstraints:(UIView *)view {
  return [self typicalConstraints:view
                    withTopOffset:0.0];
}
- (NSLayoutConstraint*)snapView:(id)view toContainer:(id)container withTopOffset:(CGFloat)topOffset {
  return [self snapView:view toContainer:container withTopOffset:topOffset fullscreen:NO];
}

- (NSLayoutConstraint*)snapView:(id)view toContainer:(id)container withTopOffset:(CGFloat)topOffset fullscreen:(BOOL)fullscreen {
  UIView *v2u = nil;
  UIView *c2u = nil;
  if ( [view isKindOfClass:[UIView class]] ) {
    v2u = view;
  }
  if ( [view isKindOfClass:[UIViewController class]] ) {
    v2u = [(UIViewController*)view view];
  }
  if ( [container isKindOfClass:[UIView class]] ) {
    c2u = container;
  }
  if ( [container isKindOfClass:[UIViewController class]] ) {
    c2u = [(UIViewController*)container view];
  }
  [c2u addSubview:v2u];
  
  CGFloat expectedWidth = c2u.frame.size.width;
  CGFloat expectedHeight = c2u.frame.size.height;
  NSLog(@"Expected width : %1.1f",expectedWidth);
  NSLog(@"Expected height : %1.1f",expectedHeight);
  
  v2u.frame = CGRectMake(0.0, 0.0, expectedWidth,
                         expectedHeight);
  

  [v2u setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSArray *anchors = [self typicalConstraints:v2u withTopOffset:topOffset fullscreen:fullscreen];
  
  [c2u setTranslatesAutoresizingMaskIntoConstraints:NO];
  [c2u addConstraints:anchors];
  [c2u setNeedsUpdateConstraints];
  [c2u setNeedsLayout];
  [c2u layoutIfNeeded];
  
  /*if ( fullscreen ) {
    for ( NSLayoutConstraint *anchor in [c2u constraints] ) {
      if ( anchor.firstAttribute == NSLayoutAttributeBottom && anchor.secondAttribute == NSLayoutAttributeBottom ) {
        anchor.constant = 0.0;
      }
    }
  } else {
    for ( NSLayoutConstraint *anchor in [c2u constraints] ) {
      if ( anchor.firstAttribute == NSLayoutAttributeBottom && anchor.secondAttribute == NSLayoutAttributeBottom ) {
        anchor.constant = 0.0;
      }
    }
  }*/
  for ( NSLayoutConstraint *anchor in anchors ) {
    if ( anchor.firstAttribute == NSLayoutAttributeTop && anchor.secondAttribute == NSLayoutAttributeTop ) {
      return anchor;
    }
  }

  
  return nil;
  
}

- (void)touch:(NSArray *)views {
  for ( UIView *v in views ) {
    if ( [v respondsToSelector:@selector(updateConstraintsIfNeeded)] ) {
      [v setNeedsUpdateConstraints];
      [v setNeedsLayout];
      [v setNeedsDisplay];
      
      [v updateConstraintsIfNeeded];
      [v layoutIfNeeded];
    }
  }
}

- (NSLayoutConstraint*)snapView:(id)view toContainer:(id)container {
  return [self snapView:view
            toContainer:container
          withTopOffset:0.0];
}

- (void)snapCenteredView:(id)view toContainer:(id)container {
  UIView *v2u = nil;
  UIView *c2u = nil;
  if ( [view isKindOfClass:[UIView class]] ) {
    v2u = view;
  }
  if ( [view isKindOfClass:[UIViewController class]] ) {
    v2u = [(UIViewController*)view view];
  }
  if ( [container isKindOfClass:[UIView class]] ) {
    c2u = container;
  }
  if ( [container isKindOfClass:[UIViewController class]] ) {
    c2u = [(UIViewController*)container view];
  }
  

  
  [c2u addSubview:v2u];
  [v2u setTranslatesAutoresizingMaskIntoConstraints:NO];

  
  NSLayoutConstraint *hCenter = [NSLayoutConstraint constraintWithItem:v2u
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:c2u
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0
                                                              constant:0.0];
  
  NSLayoutConstraint *vCenter = [NSLayoutConstraint constraintWithItem:v2u
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:c2u
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                              constant:0.0];
  
  NSLayoutConstraint *aspectRatio = [NSLayoutConstraint constraintWithItem:v2u
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:v2u
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:v2u.frame.size.height/v2u.frame.size.width
                                                                  constant:0.0f];
  

  
  long spacer = 20.0/*(long)(c2u.frame.size.width-v2u.frame.size.width)/2.0*/;
  NSString *format = [NSString stringWithFormat:@"H:|-(%ld)-[view]-(%ld)-|",spacer,spacer];
  NSArray *horizontal = [NSLayoutConstraint constraintsWithVisualFormat:format
                                                                options:0
                                                                metrics:nil
                                                                  views:@{ @"view" : v2u }];

  NSMutableArray *total = [horizontal mutableCopy];
  [total addObject:hCenter];
  [total addObject:vCenter];
  
  [c2u setTranslatesAutoresizingMaskIntoConstraints:NO];
  [v2u addConstraint:aspectRatio];
  [c2u addConstraints:total];

  [c2u setNeedsUpdateConstraints];
  [v2u setNeedsUpdateConstraints];
  [c2u updateConstraintsIfNeeded];
  [v2u updateConstraintsIfNeeded];
  
  [v2u layoutIfNeeded];
  [c2u layoutIfNeeded];
  
  v2u.clipsToBounds = YES;
  
  [c2u printDimensionsWithIdentifier:@"Cloak Container"];
  [v2u printDimensionsWithIdentifier:@"Scrolling Assets"];
  
}

- (void)unelasticizeView:(UIView *)view {
  for ( UIView *sv in [view subviews] ) {
    [sv setTranslatesAutoresizingMaskIntoConstraints:NO];
  }
}

#pragma mark - Fonts
- (UIFont*)bodyFontBold:(CGFloat)size {
  return [UIFont fontWithName:@"PTSerif-Bold"
                         size:size];
}

- (UIFont*)bodyFontRegular:(CGFloat)size {
  return [UIFont fontWithName:@"PTSerif-Normal"
                         size:size];
}

- (UIFont*)headlineFontBold:(CGFloat)size {
  return [UIFont fontWithName:@"PTSans-Bold"
                         size:size];
}

- (UIFont*)headlineFontRegular:(CGFloat)size {
  return [UIFont fontWithName:@"PTSans-Normal"
                         size:size];
}

- (UIFont*)latoBold:(CGFloat)size {
  NSString *fontName = @"Lato-Bold";
  return [UIFont fontWithName:fontName
                              size:size];
}

- (UIFont*)sansBold:(CGFloat)size {
  NSString *fontName = @"PTSans-NarrowBold" ;
  return [UIFont fontWithName:fontName
                         size:size];
}

- (UIFont*)latoRegular:(CGFloat)size {
  NSString *fontName = @"Lato-Regular";
  return [UIFont fontWithName:fontName
                         size:size];
}

- (UIFont*)latoLight:(CGFloat)size {
  NSString *fontName = @"Lato-Light";
  return [UIFont fontWithName:fontName
                         size:size];
}

- (UIFont*)latoItalic:(CGFloat)size {
  NSString *fontName = @"Lato-LightItalic";
  return [UIFont fontWithName:fontName
                         size:size];
}

- (UIFont*)latoBoldItalic:(CGFloat)size {
  NSString *fontName = @"Lato-BoldItalic";
  return [UIFont fontWithName:fontName
                         size:size];
}

- (UIFont*)sansRegular:(CGFloat)size {
  NSString *fontName = @"PTSans-Narrow";
  return [UIFont fontWithName:fontName
                         size:size];
}

#pragma mark - View factory
- (UIView*)orangeTextHeaderWithText:(NSString *)text {
  return [self textHeaderWithText:text textColor:[[DesignManager shared] turquoiseCrystalColor:1.0]
                  backgroundColor:[UIColor whiteColor]];
}

- (UIView*)textHeaderWithText:(NSString *)text textColor:(UIColor*)color backgroundColor:(UIColor*)backgroundColor {
  return [self textHeaderWithText:text textColor:color backgroundColor:backgroundColor divider:YES];
}

- (UIView*)textHeaderWithText:(NSString *)text textColor:(UIColor *)color backgroundColor:(UIColor *)backgroundColor divider:(BOOL)divider {
  UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0.0,0.0,768.0,36.0)];
  header.backgroundColor = backgroundColor;
  UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0,0.0, 768.0, 36.0)];
  captionLabel.font = [UIFont systemFontOfSize:14.0];
  captionLabel.backgroundColor = [UIColor clearColor];
  captionLabel.textColor = color;
  [captionLabel titleizeText:[NSString stringWithFormat:@"                %@",text]
                        bold:NO];
  
  if ( divider ) {
    SCPRGrayLineView *glv = [[SCPRGrayLineView alloc] initWithFrame:CGRectMake(40.0, header.frame.size.height-3.0,
                                                                               header.frame.size.width-80.0,
                                                                               3.0)];
    glv.backgroundColor = [UIColor clearColor];
    glv.strokeColor = [[DesignManager shared] barelyThereColor];
    [header addSubview:glv];
  }
  
  [header addSubview:captionLabel];
  return header;
}

- (UIView*)deluxeHeaderWithText:(NSString *)text {
  NSArray *objs = [[NSBundle mainBundle] loadNibNamed:[self xibForPlatformWithName:@"SCPRDeluxeDividerView"]
                                                owner:nil
                                              options:nil];
  SCPRDeluxeDividerView *dv = [objs objectAtIndex:0];
  dv.backgroundColor = [self silverCurtainsColor];
  dv.textLabel.backgroundColor = [self silverCurtainsColor];
  dv.textLabel.textColor = [self charcoalColor];
  
  NSString *cookedString = [text uppercaseString];
  
  if ( [text rangeOfString:@":"].location != NSNotFound ) {
    NSMutableAttributedString *mAttr = [[NSMutableAttributedString alloc] initWithString:[text uppercaseString]];
    UIFont *boldFont = [UIFont fontWithName:@"Lato-Bold" size:dv.textLabel.font.pointSize];
    UIFont *regularFont = [UIFont fontWithName:@"Lato-Regular" size:dv.textLabel.font.pointSize];
  
    NSRange colonRange = [text rangeOfString:@":"];
    NSRange cooked = NSMakeRange(0, colonRange.location);
    NSRange secondPartCooked = NSMakeRange(colonRange.location, text.length-colonRange.location);

    [mAttr addAttribute:NSFontAttributeName value:boldFont range:cooked];
    [mAttr addAttribute:NSFontAttributeName value:regularFont range:secondPartCooked];
    
    if ([text rangeOfString:@"LATEST HEADLINES"].location != NSNotFound) {
      [mAttr addAttribute:NSForegroundColorAttributeName
                    value:self.sectionsBlueColor
                    range:NSMakeRange(colonRange.location + 1, text.length - colonRange.location - 1)];
    }
      
    dv.textLabel.attributedText = mAttr;
  } else {

    BOOL bold = NO;
    if ( [text rangeOfString:@"LATEST EDITION"].location != NSNotFound ) {
      bold = YES;
    }
    [dv.textLabel titleizeText:cookedString bold:bold];
  }

  CGSize s = [dv.textLabel.text sizeOfStringWithFont:dv.textLabel.font
                                   constrainedToSize:CGSizeMake(MAXFLOAT,dv.textLabel.frame.size.height)];
  dv.textLabel.frame = CGRectMake(dv.textLabel.frame.origin.x,
                                  dv.textLabel.frame.origin.y,
                                  s.width+20.0,
                                  dv.textLabel.frame.size.height);
  dv.textLabel.center = CGPointMake(dv.frame.size.width/2.0,
                                    dv.frame.size.height/2.0);
  
  return dv;
}

#pragma mark - Shadowing
- (void)applyBaseShadowTo:(UIView *)view {
  view.layer.shadowColor = [UIColor blackColor].CGColor;
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowOffset = CGSizeMake(0.0,1.0);
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.bounds];
  view.layer.shadowPath = shadowPath.CGPath;
}

- (void)applyTopShadowTo:(UIView *)view {
  view.layer.shadowColor = [UIColor blackColor].CGColor;
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowOffset = CGSizeMake(0.0,-1.0);
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.bounds];
  view.layer.shadowPath = shadowPath.CGPath;
}

- (void)applyLeftShadowTo:(UIView *)view {
  view.layer.shadowColor = [UIColor blackColor].CGColor;
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowOffset = CGSizeMake(-1.0,0.0);
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.bounds];
  view.layer.shadowPath = shadowPath.CGPath;
}

- (void)applyPerimeterShadowTo:(UIView *)view {
  view.layer.shadowColor = [UIColor blackColor].CGColor;
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowOffset = CGSizeMake(1.0,1.0);
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.bounds];
  view.layer.shadowPath = shadowPath.CGPath;
}

- (void)applyWhitePerimeterShadowTo:(UIView *)view {
  view.layer.shadowColor = [UIColor whiteColor].CGColor;
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowOffset = CGSizeMake(1.0,1.0);
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.bounds];
  view.layer.shadowPath = shadowPath.CGPath;
}

- (void)applyLeftOrangeShadowTo:(UIView *)view {
  view.layer.shadowColor = [self kpccDarkOrangeColor].CGColor;
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowOffset = CGSizeMake(-1.0,0.0);
}

#pragma mark - Label styling
- (void)applyHeadlineStyling:(UILabel *)label {
  label.textColor = [UIColor whiteColor];
  label.shadowColor = [self shadowColor];
  label.shadowOffset = CGSizeMake(0.0,1.0);
}

#pragma mark - Button styling
- (void)globalSetTitleTo:(NSString *)title forButton:(UIButton *)button {
  [button setTitle:title forState:UIControlStateNormal];
  [button setTitle:title forState:UIControlStateHighlighted];
  [button.titleLabel titleizeText:button.titleLabel.text bold:NO];
}

- (void)globalSetImageTo:(NSString *)image forButton:(UIButton *)button {
  if ([Utilities pureNil:image]) {
    [button setImage:nil forState:UIControlStateNormal];
    [button setImage:nil forState:UIControlStateHighlighted];
    return;
  }
  NSString *imgPath = [[NSBundle mainBundle] pathForResource:image ofType:@""];
  UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
  [button setImage:img forState:UIControlStateHighlighted];
  [button setImage:img forState:UIControlStateNormal];
}

- (void)globalSetTextColorTo:(UIColor *)color forButton:(UIButton *)button {
  [button setTitleColor:color forState:UIControlStateHighlighted];
  [button setTitleColor:color forState:UIControlStateNormal];
}

- (void)globalSetFontTo:(UIFont *)font forButton:(UIButton *)button {
  [button.titleLabel setFont:font];
}

#pragma mark - XIBs
/*************************************************************************************************************
 -- Developer Note --
 xibForPlatformWithName is a core piece of runtime functionality that is used throughout the app. It will decicde which resource to use
 based on the current idiom (iPad or iPhone) and the current orientation. Note a lack of the _iPad suffix on the resource name will imply
 "iPhone" as there is no concept of *_iPhone.xib. Lack of "Landscape" will imply portrait as there is no concept of *Portrait.xib
*/
- (NSString*)xibForPlatformWithName:(NSString *)root {
  NSString *orientation = @"";
  if ( [Utilities isLandscape] ) {
      orientation = @"Landscape";
  }
  if ( [Utilities isIpad] ) {
    NSString *s = [NSString stringWithFormat:@"%@_iPad%@",root,orientation];
    NSString *path = [[NSBundle mainBundle] pathForResource:s ofType:@"nib"];
    if ( ![Utilities pureNil:path] ) {
      return s;
    } else {
      s = [NSString stringWithFormat:@"%@_iPad",root];

      return s;
    }
  }
  return [NSString stringWithFormat:@"%@%@",root,orientation];
}

- (NSString*)xibit:(NSString *)root style:(NSInteger)style {
  // TODO: This is a hacky thing. If it's shared then figure out a good way to share between
  // templates
  if ( [root rangeOfString:@"Split"].location != NSNotFound ) {
    style = 0;
  }

  if ( [Utilities isIpad] ) {
    return [NSString stringWithFormat:@"%@%@_iPad",root,[NSNumber numberWithInt:style]];
  }
  return [NSString stringWithFormat:@"%@%@",root,[NSNumber numberWithInt:style]];
}

- (void)treatButton:(UIButton *)button withStyle:(ButtonStyle)style {
  switch (style) {
    case ButtonStyleUnknown:
    case ButtonStyleKPCCBlue:
    {
      [button setTitleShadowColor:[self shadowColor]
                         forState:UIControlStateNormal];
      [button setTitleShadowColor:[self shadowColor]
                         forState:UIControlStateHighlighted];
      [button setTitleColor:[UIColor whiteColor]
                   forState:UIControlStateHighlighted];
      [button setTitleColor:[UIColor whiteColor]
                   forState:UIControlStateNormal];
      
      UIImage *backgroundImage = nil;
      if ( button.frame.size.width > 200.0 ) {
        backgroundImage = [UIImage imageNamed:@"blue_kpcc_button_long.png"];
      }
      if ( button.frame.size.width > 90.0 && button.frame.size.width < 200.0 ) {
        backgroundImage = [UIImage imageNamed:@"blue_kpcc_button_short.png"];
      }
      if ( button.frame.size.width < 90.0 ) {
        backgroundImage = [UIImage imageNamed:@"blue_kpcc_button_micro.png"];
      }
      
      [button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
      [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
      break;
    }
  }
}

#pragma mark - Colors
- (UIColor*)puttingGreenColor:(CGFloat)alpha {
  return [UIColor colorWithRed:49.0/255.0
                         green:184.0/255.0
                          blue:125.0/255.0
                         alpha:alpha];
}

- (UIColor*)steamColor {
  return [UIColor colorWithRed:254.0/255.0
                         green:254.0/255.0
                          blue:254.0/255.0
                         alpha:0.5];
}

- (UIColor*)offwhiteColor {
  return [UIColor colorWithRed:254.0/255.0
                         green:254.0/255.0
                          blue:254.0/255.0
                         alpha:1.0];
}

- (UIColor*)turquoiseCrystalColor:(CGFloat)alpha {
  return [UIColor colorWithRed:0.0/255.0
                         green:168.0/255.0
                          blue:243.0/255.0
                         alpha:alpha];
}
- (UIColor*)slateColor:(CGFloat)alpha {
  return [UIColor colorWithRed:102.0/255.0
                         green:136.0/255.0
                          blue:158.0/255.0
                         alpha:alpha];
}
- (UIColor*)salmonColor:(CGFloat)alpha {
  return [UIColor colorWithRed:191.0/255.0
                         green:117.0/255.0
                          blue:99.0/255.0
                         alpha:alpha];
}

- (UIColor*)oliveColor:(CGFloat)alpha {
  return [UIColor colorWithRed:170.0/255.0
                         green:167.0/255.0
                          blue:112.0/255.0
                         alpha:alpha];
}

- (UIColor*)frostedWindowColor:(CGFloat)alpha {
  return [UIColor colorWithRed:240.0/255.0
                         green:240.0/255.0
                          blue:240.0/255.0
                         alpha:alpha];
}

- (UIColor*)vinylColor:(CGFloat)alpha {
  return [UIColor colorWithRed:61.0/255.0
                         green:61.0/255.0
                          blue:61.0/255.0
                         alpha:alpha];
}

- (UIColor*)lavendarColor:(CGFloat)alpha {
  return [UIColor colorWithRed:119.0/255.0
                         green:127.0/255.0
                          blue:170.0/255.0
                         alpha:alpha];
}

- (UIColor*)obsidianColor:(CGFloat)alpha {
  return [UIColor colorWithRed:12.0/255.0
                         green:16.0/255.0
                          blue:12.0/255.0
                         alpha:alpha];
}

- (UIColor*)aquaColor:(CGFloat)alpha {
  return [UIColor colorWithRed:117.0/193.0
                         green:193.0/255.0
                          blue:166.0/255.0
                         alpha:alpha];
}

- (UIColor*)shadowColor {
  return [UIColor colorWithRed:1.0/255.0
                         green:1.0/255.0
                          blue:1.0/255.0
                         alpha:0.5];
}

- (UIColor*)touchOfGrayColor {
  return [UIColor colorWithRed:246.0/255.0
                         green:248.0/255.0
                          blue:250.0/255.0
                         alpha:1.0];
}

- (UIColor*)barelyThereColor {
  return [UIColor colorWithRed:242.0/255.0
                         green:242.0/255.0
                          blue:242.0/255.0
                         alpha:1.0];
}

- (UIColor*)charcoalColor {
  return [UIColor colorWithRed:104.0/255.0
                         green:104.0/255.0
                          blue:104.0/255.0
                         alpha:1.0];
}

- (UIColor*)translucentCharcoalColor {
  return [UIColor colorWithRed:104.0/255.0
                         green:104.0/255.0
                          blue:104.0/255.0
                         alpha:0.66];
}

- (UIColor*)burnedCharcoalColor {
  return [UIColor colorWithRed:121.0/255.0
                         green:130.0/255.0
                          blue:133.0/255.0
                         alpha:1.0];
}

- (UIColor*)deepCharcoalColor {
  return [UIColor colorWithRed:48.0/255.0
                         green:48.0/255.0
                          blue:48.0/255.0
                         alpha:1.0];
}

- (UIColor*)darkoalColor {
  return [UIColor colorWithRed:82.0/255.0
                         green:82.0/255.0
                          blue:82.0/255.0
                         alpha:1.0];
}

- (UIColor*)consistentCharcolColor {
  return [UIColor colorWithRed:30.0/255.0
                         green:30.0/255.0
                          blue:30.0/255.0
                         alpha:1.0];
}

- (UIColor*)peachColor {
  return [UIColor colorWithRed:255.0/255.0
                         green:223.0/255.0
                          blue:144.0/255.0
                         alpha:1.0];
}

- (UIColor*)number3pencilColor {
  return [UIColor colorWithRed:88.0/255.0
                         green:88.0/255.0
                          blue:88.0/255.0
                         alpha:1.0];
}

- (UIColor*)number2pencilColor {
  return [UIColor colorWithRed:144.0/255.0
                         green:144.0/255.0
                          blue:144.0/255.0
                         alpha:1.0];
}

- (UIColor*)number1pencilColor {
  return [UIColor colorWithRed:217.0/255.0
                         green:217.0/255.0
                          blue:217.0/255.0
                         alpha:1.0];
}

- (UIColor*)transparentWhiteColor {
    return [UIColor colorWithRed:255.0/255.0
                                  green:255.0/255.0
                                   blue:255.0/255.0
                                  alpha:0.5];
}

- (UIColor*)kpccOrangeColor {
  return [self pumpkinColor];
}

- (UIColor*)kpccDarkOrangeColor {
  return [self pumpkinColor];
}

- (UIColor*)kpccButtonBlueTopRange {
  return [UIColor colorWithRed:25.0/255.0
                         green:125.0/255.0
                          blue:164.0/255.0
                         alpha:1.0];
}

- (UIColor*)kpccButtonBlueBtmRange {
  return [UIColor colorWithRed:25.0/255.0
                         green:125.0/255.0
                          blue:164.0/255.0
                         alpha:1.0];
}

- (UIColor*)uncorkedGreenColor {
  return [UIColor colorWithRed:86.0/255.0
                         green:186.0/255.0
                          blue:131.0/255.0
                         alpha:1.0];
}

- (UIColor*)uncorkedOrangeColor {
  return [UIColor colorWithRed:224.0/255.0
                         green:83.0/255.0
                          blue:39.0/255.0
                         alpha:1.0];
}

- (UIColor*)uncorkedPowderedBlueColor {
  return [UIColor colorWithRed:48.0/255.0
                         green:151.0/255.0
                          blue:216.0/255.0
                         alpha:1.0];
}

- (UIColor*)headlineTextColor {
  return [UIColor colorWithRed:68.0/255.0
                         green:68.0/255.0
                          blue:68.0/255.0
                         alpha:1.0];
}

- (UIColor*)bodyTextColor {
  return [UIColor colorWithRed:140.0/255.0
                         green:138.0/255.0
                          blue:138.0/255.0
                         alpha:1.0];
}

- (UIColor*)blockQuoteTextColor {
  return [UIColor colorWithRed:153.0/255.0
                         green:153.0/255.0
                          blue:153.0/255.0
                         alpha:1.0];
}

- (UIColor*)softBlueColor {
  return [UIColor colorWithRed:10.0/255.0
                         green:126.0/255.0
                          blue:170.0/255.0
                         alpha:1.0];
}

- (UIColor*)twitterBlueColor {
  return [UIColor colorWithRed:84.0/255.0
                         green:178.0/255.0
                          blue:216.0/255.0
                         alpha:1.0];
}

- (UIColor*)sectionsBlueColor {
  return [UIColor colorWithRed:0.0/255.0
                         green:185.0/255.0
                          blue:242.0/255.0
                         alpha:1.0];
}

- (UIColor*)pumpkinColor {
  return [UIColor colorWithRed:240.0/255.0
                         green:101.0/255.0
                          blue:0.0/255.0
                         alpha:1.0];
}

- (UIColor*)onyxColor {
  return [UIColor colorWithRed:36.0/255.0
                         green:41.0/255.0
                          blue:43.0/255.0
                         alpha:1.0];
}

- (UIColor*)polishedOnyxColor {
  return [UIColor colorWithRed:45.0/255.0
                         green:51.0/255.0
                          blue:52.0/255.0
                         alpha:1.0];
}

- (UIColor*)deepOnyxColor {
  return [UIColor colorWithRed:22.0/255.0
                         green:24.0/255.0
                          blue:25.0/255.0
                         alpha:1.0];
}

- (UIColor*)deepTranslucentOnyxColor {
  return [UIColor colorWithRed:22.0/255.0
                         green:24.0/255.0
                          blue:25.0/255.0
                         alpha:0.66];
}

- (UIColor*)gloomyCloudColor {
  return [UIColor colorWithRed:160.0/255.0
                         green:167.0/255.0
                          blue:169.0/255.0
                         alpha:1.0];
}

- (UIColor*)periwinkleColor {
  return [self turquoiseCrystalColor:1.0];
}

- (UIColor*)translucentPeriwinkleColor {
  return [UIColor colorWithRed:21.0/255.0
                         green:185.0/255.0
                          blue:243.0/255.0
                         alpha:0.77];
}

- (UIColor*)translucentSlateColor:(CGFloat)alpha {
  return [UIColor colorWithRed:64.0/255.0
                         green:70.0/255.0
                          blue:83.0/255.0
                         alpha:alpha];
}

- (UIColor*)tireColor {
  return [UIColor colorWithRed:25.0/255.0
                         green:30.0/255.0
                          blue:32.0/255.0
                         alpha:1.0];
}

- (UIColor*)clayColor {
  return [UIColor colorWithRed:108.0/255.0
                         green:117.0/255.0
                          blue:122.0/255.0
                         alpha:1.0];
}

- (UIColor*)lightClayColor {
  return [UIColor colorWithRed:206.0/255.0
                         green:216.0/255.0
                          blue:213.0/255.0
                         alpha:1.0];
}

- (UIColor*)silverliningColor {
  return [UIColor colorWithRed:204.0/255.0
                         green:209.0/255.0
                          blue:211.0/255.0
                         alpha:1.0];
}

- (UIColor*)silverTextColor {
  return [UIColor colorWithRed:174.0/255.0
                         green:182.0/255.0
                          blue:184.0/255.0
                         alpha:1.0];
}

- (UIColor*)silverCurtainsColor {
  return [UIColor colorWithRed:233.0/255.0
                         green:237.0/255.0
                          blue:238.0/255.0
                         alpha:1.0];
}

- (UIColor*)color:(NSArray *)rgb {
  if ( !rgb || [rgb count] != 3 ) {
    return [self silverliningColor];
  }
  
  CGFloat r = [[rgb objectAtIndex:0] floatValue];
  CGFloat g = [[rgb objectAtIndex:1] floatValue];
  CGFloat b = [[rgb objectAtIndex:2] floatValue];
  
  return [UIColor colorWithRed:r/255.0
                         green:g/255.0
                          blue:b/255.0
                         alpha:1.0];
  
}

- (UIColor*)queueCellIdleColor {
  return [self frostedWindowColor:0.77];
}

- (UIColor*)queueCellPlayingColor {
  return [self puttingGreenColor:0.88];
}

- (UIColor*)stratusCloudColor:(CGFloat)alpha {
  return [UIColor colorWithRed:246.0/255.0
                         green:248.0/255.0
                          blue:250.0/255.0
                         alpha:alpha];
}

- (UIColor*)doneGreenColor {
  return [UIColor colorWithRed:100/255.0
                         green:189.0/255.0
                          blue:89.0/255.0
                         alpha:1.0];
}

- (UIColor*)removeAllRedColor {
  return [UIColor colorWithRed:223.0/255.0
                         green:72.0/255.0
                          blue:61.0/255.0
                         alpha:1.0];
}

- (UIColor*)cancelBlackColor {
  return [UIColor colorWithRed:40.0/255.0
                         green:42.0/255.0
                          blue:44.0/255.0
                         alpha:1.0];
}

- (UIColor*)auburnColor {
  return [UIColor colorWithRed:246.0/255.0
                         green:98.0/255.0
                          blue:0.0/255.0
                         alpha:1.0];
}

- (UIColor*)kingCrimsonColor {
  return [UIColor colorWithRed:232.0/255.0
                         green:34.0/255.0
                          blue:32.0/255.0
                         alpha:1.0];
}

- (UIColor*)prettyRandomColor {
  
  CGFloat red = (arc4random() % 128 + ( arc4random() % 128 ))*1.0;
  CGFloat green = (arc4random() % 128 + ( arc4random() % 128 ))*1.0;
  CGFloat blue = (arc4random() % 128 + ( arc4random() % 128 ))*1.0;
  
  return [UIColor colorWithRed:red/255.0
                         green:green/255.0
                          blue:blue/255.0
                         alpha:1.0];
  
}

#pragma mark - Color functions
- (UIColor*)rainbowForIndex:(NSInteger)index {
  NSInteger mod = index % 4; // TODO: Dynamically change for topics
  UIColor *color = nil;
  switch (mod) {
    case 0:
      color = [self charcoalColor];
      break;
    case 1:
      color = [self uncorkedOrangeColor];
      break;
    case 2:
      color = [self uncorkedGreenColor];
      break;
    case 3:
      color = [self uncorkedPowderedBlueColor];
      break;
    default:
      break;
      
  }
  return color;
}

@end
