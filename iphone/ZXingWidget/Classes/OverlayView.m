//
//  OverlayView.m
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "OverlayView.h"
#import "UIView+TKGeometry.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kPadding = 10;

@interface OverlayView()

@property (nonatomic,retain) UIButton *cancelButton;
@property (nonatomic,retain) UIButton *lightButton;
@property (nonatomic,retain) UIView   *cropView;
@property (nonatomic,retain) UIView   *indicatorView;
@end


@implementation OverlayView

@synthesize delegate;
@synthesize points = _points;
@synthesize cancelButton;
@synthesize lightButton;
@synthesize cropRect;
@synthesize cropView;
@synthesize displayedMessage;
@synthesize imageView;

- (id) initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];

        CGFloat rectSize = self.frame.size.width - kPadding * 2;
        cropRect = CGRectMake(kPadding, (self.frame.size.height - rectSize) / 2, rectSize, rectSize);
        
        self.cropView = [[[UIView alloc] initWithFrame:cropRect] autorelease];
        cropView.backgroundColor = [UIColor clearColor];
        cropView.layer.borderColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1].CGColor;
        cropView.layer.borderWidth = 2;
        [self addSubview:cropView];
      
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancelButton setTitle:@"返回" forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancelButton];
        
        
        self.lightButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [lightButton setTitle:@"开灯" forState:UIControlStateNormal];
        [lightButton addTarget:self action:@selector(toggleLight:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:lightButton];

        
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake(kPadding, (self.frame.size.height) / 2, rectSize, 1)];
        _indicatorView.backgroundColor = [UIColor redColor];
        _indicatorView.hidden = YES;
        [self addSubview:_indicatorView];
        
        imageView = [[UIImageView alloc] initWithFrame:cropRect];
        imageView.hidden = YES;
        imageView.clipsToBounds = YES;
        [self addSubview:imageView];
        
        animating = NO;
        self.displayedMessage = @"扫描中...";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize theSize = CGSizeMake(100, 50);
    cancelButton.frame = CGRectMake(50, cropRect.origin.y + cropRect.size.height + 30, theSize.width, theSize.height);
    lightButton.frame = CGRectMake(200, cropRect.origin.y + cropRect.size.height + 30, theSize.width, theSize.height);
}

#define kTextMargin 10

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:29/255.f alpha:0.65].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetMinY(cropRect)-20));
    
    CGContextFillRect(context, CGRectMake(0, CGRectGetMaxY(cropRect)+20, CGRectGetWidth(rect), CGRectGetMaxY(rect)- CGRectGetMaxY(cropRect)-20));

    CGFloat white[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    CGContextSetFillColor(context, white);
    [self.displayedMessage drawInRect:CGRectMake(0, 40, CGRectGetWidth(rect), CGRectGetMinY(cropRect)-20) withFont:[UIFont systemFontOfSize:18] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];

    
	if( nil != _points ) {
		CGFloat blue[4] = {0.0f, 1.0f, 0.0f, 1.0f};
		CGContextSetStrokeColor(context, blue);
		CGContextSetFillColor(context, blue);
        CGRect smallSquare = CGRectMake(0, 0, 10, 10);
        for( NSValue* value in _points ) {
            CGPoint point = [self map:[value CGPointValue]];
            smallSquare.origin = CGPointMake(cropRect.origin.x + point.x - smallSquare.size.width / 2,cropRect.origin.y + point.y - smallSquare.size.height / 2);
            [self drawRect:smallSquare inContext:context];
        }
	}
}

- (void)startAnimate
{
    animating = YES;
    _indicatorView.yOrigin = CGRectGetMinY(cropRect);
    _indicatorView.hidden = NO;
    [UIView beginAnimations:@"123" context:nil];
    [UIView setAnimationDuration:2.5];
    [UIView setAnimationRepeatAutoreverses:YES];
    [UIView setAnimationRepeatCount:NSIntegerMax];
    _indicatorView.yOrigin =  CGRectGetMaxY(cropRect);
    [UIView commitAnimations];
    
    self.cropView.alpha = 1;
    [UIView beginAnimations:@"456" context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationRepeatAutoreverses:YES];
    [UIView setAnimationRepeatCount:NSIntegerMax];
    self.cropView.alpha = 0.1;
    [UIView commitAnimations];


}

- (void)stopAnimate
{
    animating = NO;
    _indicatorView.hidden = YES;
    self.cropView.layer.borderColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1].CGColor;

    
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (animating) {
        [self startAnimate];
    } else {
        [self stopAnimate];
    }
    [lightButton setTitle:@"开灯" forState:UIControlStateNormal];
    
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_points release];
    [displayedMessage release];
    [cancelButton release];
    [lightButton release];
    [_indicatorView release];
    [cropView release];
    [imageView release];
    [super dealloc];
}


- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context {
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
    CGContextStrokePath(context);
}

- (CGPoint)map:(CGPoint)point
{
    CGPoint center;
    center.x = cropRect.size.width/2;
    center.y = cropRect.size.height/2;
    float x = point.x - center.x;
    float y = point.y - center.y;
    int rotation = 90;
    switch(rotation) {
        case 0:
            point.x = x;
            point.y = y;
            break;
        case 90:
            point.x = -y;
            point.y = x;
            break;
        case 180:
            point.x = -x;
            point.y = -y;
            break;
        case 270:
            point.x = y;
            point.y = -x;
            break;
    }
    point.x = point.x + center.x + kPadding*3;
    point.y = point.y + center.y - CGRectGetMinY(cropRect);
    return point;

}

/////////////////////////////////////////////////////////////////////////////////
- (void) setPoints:(NSMutableArray*)pnts
{
    [pnts retain];
    [_points release];
    _points = pnts;
	
    if (pnts != nil) {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    }
    [self setNeedsDisplay];
}

- (void) setPoint:(CGPoint)point {
    if (!_points) {
        _points = [[NSMutableArray alloc] init];
    }
    if (_points.count > 3) {
        [_points removeObjectAtIndex:0];
    }
    [_points addObject:[NSValue valueWithCGPoint:point]];
    [self setNeedsDisplay];
}

- (void)cancel:(id)sender
{
	if ([delegate respondsToSelector:@selector(cancelled)]) {
		[delegate cancelled];
	}
}

- (void)toggleLight:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    if ([[btn titleForState:UIControlStateNormal] isEqualToString:@"开灯"]) {
        if ([delegate respondsToSelector:@selector(openLight)]) {
            [delegate openLight];
        }
        [btn setTitle:@"关灯" forState:UIControlStateNormal];
    } else {
        if ([delegate respondsToSelector:@selector(closeLight)]) {
            [delegate closeLight];
        }
        [btn setTitle:@"开灯" forState:UIControlStateNormal];
    }
    
}


@end
