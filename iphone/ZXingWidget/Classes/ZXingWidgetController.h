#include <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#include "Decoder.h"
#include "parsedResults/ParsedResult.h"
#include "OverlayView.h"

@protocol ZXingDelegate;

#if !TARGET_IPHONE_SIMULATOR
#define HAS_AVFF 1
#endif

@interface ZXingWidgetController : UIViewController<DecoderDelegate,
                                                    CancelDelegate,
                                                    UINavigationControllerDelegate
#if HAS_AVFF
                                                    , AVCaptureVideoDataOutputSampleBufferDelegate
#endif
                                                    > {
      NSSet *readers;
      ParsedResult *result;
      OverlayView *overlayView;
      SystemSoundID beepSound;
      BOOL showCancel;
      NSURL *soundToPlay;
      id<ZXingDelegate> delegate;
    #if HAS_AVFF
      AVCaptureSession *captureSession;
      AVCaptureVideoPreviewLayer *prevLayer;
    #endif
      BOOL decoding;
}

#if HAS_AVFF
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;
#endif
@property (nonatomic, retain ) NSSet *readers;
@property (nonatomic, assign) id<ZXingDelegate> delegate;
@property (nonatomic, retain) NSURL *soundToPlay;
@property (nonatomic, retain) ParsedResult *result;
@property (nonatomic, retain) OverlayView *overlayView;

- (id)initWithDelegate:(id<ZXingDelegate>)delegate;

- (BOOL)fixedFocus;

@end


@protocol ZXingDelegate <NSObject>

- (void)zxingController:(ZXingWidgetController*)controller didScanResult:(NSString *)result;
- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller;

@end
