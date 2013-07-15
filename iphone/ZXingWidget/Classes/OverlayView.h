//
//  OverlayView.h
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol CancelDelegate;

@interface OverlayView : UIView {
    NSMutableArray *_points;
    UIButton *cancelButton;
    id<CancelDelegate> delegate;
    CGRect cropRect;
    NSString *displayedMessage;
    UIImageView *imageView;
    BOOL animating;
}

@property (nonatomic, retain) NSMutableArray*  points;
@property (nonatomic, assign) id<CancelDelegate> delegate;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, copy) NSString *displayedMessage;
@property (nonatomic, readonly)     UIImageView *imageView;


- (id)initWithFrame:(CGRect)theFrame;
- (void)setPoint:(CGPoint)point;
- (void)startAnimate;
- (void)stopAnimate;

@end

@protocol CancelDelegate <NSObject>
- (void)cancelled;
- (void)openLight;
- (void)closeLight;
@end
