#import "ZXingWidgetController.h"
#import "Decoder.h"
#import "NSString+HTML.h"
#import "ResultParser.h"
#import "ParsedResult.h"
#import "ResultAction.h"
#import "TwoDDecoderResult.h"
#include <sys/types.h>
#include <sys/sysctl.h>

#import <AVFoundation/AVFoundation.h>


#define CAMERA_SCALAR 1.12412 // scalar = (480 / (2048 / 480))
#define FIRST_TAKE_DELAY 1.0
#define ONE_D_BAND_HEIGHT 10.0

@interface ZXingWidgetController ()

- (void)initCapture;
- (void)stopCapture;

@end

@implementation ZXingWidgetController

#if HAS_AVFF
@synthesize captureSession;
@synthesize prevLayer;
#endif
@synthesize result, delegate, soundToPlay;
@synthesize overlayView;
@synthesize readers;
@synthesize codeType;


- (id)initWithDelegate:(id<ZXingDelegate>)scanDelegate
{
      if (self = [super init]) {
            self.delegate = scanDelegate;
            self.wantsFullScreenLayout = YES;
            beepSound = -1;
            decoding = NO;
      }
      
      return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.overlayView = [[[OverlayView alloc] initWithFrame:self.view.bounds] autorelease];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.overlayView.delegate = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self soundToPlay] != nil) {
            OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)[self soundToPlay], &beepSound);
            if (error != kAudioServicesNoError) {
                NSLog(@"Problem loading nearSound.caf");
            }
        }
    });
    [self initCapture];
    [self.view addSubview:overlayView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    decoding = YES;
    overlayView.imageView.hidden = YES;
    [overlayView startAnimate];
    [overlayView setPoints:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.overlayView removeFromSuperview];
    [self stopCapture];
}

- (void)dealloc {
    if (beepSound != (SystemSoundID)-1) {
        AudioServicesDisposeSystemSoundID(beepSound);
    }

    [self stopCapture];

    [result release];
    [soundToPlay release];
    [overlayView release];
    [readers release];
    [super dealloc];
}

- (void)cancelled {
      [self stopCapture];
      [[UIApplication sharedApplication] setStatusBarHidden:NO];
      
      if ([delegate respondsToSelector:@selector(zxingControllerDidCancel:)]) {
          [delegate zxingControllerDidCancel:self];
      }
}

- (void)openLight
{
    AVCaptureDevice* inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([inputDevice hasTorch]&&[inputDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
        [inputDevice lockForConfiguration:nil];
        inputDevice.torchMode = AVCaptureTorchModeOn;
        [inputDevice unlockForConfiguration];
    }
}
- (void)closeLight
{
    AVCaptureDevice* inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([inputDevice hasTorch]&&[inputDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
        [inputDevice lockForConfiguration:nil];
        inputDevice.torchMode = AVCaptureTorchModeOff;
        [inputDevice unlockForConfiguration];
    }
    
}


- (NSString *)getPlatform {
  size_t size;
  sysctlbyname("hw.machine", NULL, &size, NULL, 0);
  char *machine = malloc(size);
  sysctlbyname("hw.machine", machine, &size, NULL, 0);
  NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
  free(machine);
  return platform;
}

- (BOOL)fixedFocus {
  NSString *platform = [self getPlatform];
  if ([platform isEqualToString:@"iPhone1,1"] ||
      [platform isEqualToString:@"iPhone1,2"]) return YES;
  return NO;
}


- (CGImageRef)CGImageRotated90:(CGImageRef)imgRef
{
    CGFloat angleInRadians = -90 * (M_PI / 180);
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);

    CGRect imgRect = CGRectMake(0, 0, width, height);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL,
                                                 rotatedRect.size.width,
                                                 rotatedRect.size.height,
                                                 8,
                                                 0,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(bmContext, FALSE);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationNone);
    CGColorSpaceRelease(colorSpace);
    //      CGContextTranslateCTM(bmContext,
    //                                                +(rotatedRect.size.width/2),
    //                                                +(rotatedRect.size.height/2));
    CGContextScaleCTM(bmContext, rotatedRect.size.width/rotatedRect.size.height, 1.0);
    CGContextTranslateCTM(bmContext, 0.0, rotatedRect.size.height);
    CGContextRotateCTM(bmContext, angleInRadians);
    //      CGContextTranslateCTM(bmContext,
    //                                                -(rotatedRect.size.width/2),
    //                                                -(rotatedRect.size.height/2));
    CGContextDrawImage(bmContext, CGRectMake(0, 0,
                                           rotatedRect.size.width,
                                           rotatedRect.size.height),
                     imgRef);

    CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
    CFRelease(bmContext);
    [(id)rotatedImage autorelease];

    return rotatedImage;
}

- (CGImageRef)CGImageRotated180:(CGImageRef)imgRef
{
    CGFloat angleInRadians = M_PI;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 8,
                                                 0,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(bmContext, FALSE);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationNone);
    CGColorSpaceRelease(colorSpace);
    CGContextTranslateCTM(bmContext,
                        +(width/2),
                        +(height/2));
    CGContextRotateCTM(bmContext, angleInRadians);
    CGContextTranslateCTM(bmContext,
                        -(width/2),
                        -(height/2));
    CGContextDrawImage(bmContext, CGRectMake(0, 0, width, height), imgRef);

    CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
    CFRelease(bmContext);
    [(id)rotatedImage autorelease];

    return rotatedImage;
}

// DecoderDelegate methods

- (void)decoder:(Decoder *)decoder willDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset
{
//    NSLog(@"DecoderViewController MessageWhileDecodingWithDimensions: Decoding image (%.0fx%.0f) ...", image.size.width, image.size.height);
}

- (void)decoder:(Decoder *)decoder decodingImage:(UIImage *)image usingSubset:(UIImage *)subset
{
}

- (void)presentResultForString:(NSString *)resultString
{
    self.result = [ResultParser parsedResultForString:resultString];
    if (beepSound != (SystemSoundID)-1) {
        AudioServicesPlaySystemSound(beepSound);
    }

    NSLog(@"result string = %@", resultString);
}

- (void)presentResultPoints:(NSArray *)resultPoints
                   forImage:(UIImage *)image
                usingSubset:(UIImage *)subset
{
    // simply add the points to the image view
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:resultPoints];
    NSLog(@"points %@",mutableArray);
    if (mutableArray.count >= 3) {
        [overlayView setPoints:mutableArray];
    }
    [mutableArray release];
}

- (void)decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)twoDResult
{
    
//    overlayView.imageView.image = subset;
//    overlayView.imageView.hidden = NO;
    [overlayView stopAnimate];
    [overlayView.layer displayIfNeeded];

    [self presentResultForString:[twoDResult text]];
    [self presentResultPoints:[twoDResult points] forImage:image usingSubset:subset];
    // now, in a selector, call the delegate to give this overlay time to show the points
    [self performSelector:@selector(notifyDelegate:) withObject:[[twoDResult text] copy] afterDelay:1.0];
    decoder.delegate = nil;
}

- (void)notifyDelegate:(id)text
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if ([delegate respondsToSelector:@selector(zxingController:didScanResult:)]) {
        [delegate zxingController:self didScanResult:text];
    }
    [text release];
}

- (void)decoder:(Decoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason
{
    decoder.delegate = nil;
    [overlayView setPoints:nil];
}

- (void)decoder:(Decoder *)decoder foundPossibleResultPoint:(CGPoint)point
{
    [overlayView setPoint:point];
}

#pragma mark - 
#pragma mark AVFoundation

#include <sys/types.h>
#include <sys/sysctl.h>

- (void)initCapture
{
#if HAS_AVFF
      AVCaptureDevice* inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    if ([inputDevice hasFlash]&&[inputDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
//        [inputDevice lockForConfiguration:nil];
//        inputDevice.flashMode = AVCaptureFlashModeAuto;
//        [inputDevice unlockForConfiguration];
//    }
//    
//    if ([inputDevice hasTorch]&&[inputDevice isTorchModeSupported:AVCaptureTorchModeAuto]) {
//        [inputDevice lockForConfiguration:nil];
//        inputDevice.torchMode = AVCaptureTorchModeAuto;
//
//        if ([inputDevice isLowLightBoostSupported]) {
//            [inputDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
//        }
//        [inputDevice unlockForConfiguration];
//    }
//    if ([inputDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
//        [inputDevice lockForConfiguration:nil];
//        inputDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
//        [inputDevice unlockForConfiguration];
//    }
//    
//    if ([inputDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
//        [inputDevice lockForConfiguration:nil];
//        inputDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
//        [inputDevice unlockForConfiguration];
//    }
//    
//    if ([inputDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
//        [inputDevice lockForConfiguration:nil];
//        inputDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
//        [inputDevice unlockForConfiguration];
//
//    }
    
    
      AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
      AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init]; 
      captureOutput.alwaysDiscardsLateVideoFrames = YES; 
      [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
      NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
      NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
      NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
      [captureOutput setVideoSettings:videoSettings]; 
      self.captureSession = [[[AVCaptureSession alloc] init] autorelease];

      self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;

      [self.captureSession addInput:captureInput];
      [self.captureSession addOutput:captureOutput];

      [captureOutput release];

      if (!self.prevLayer) {
        self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
      }
      // NSLog(@"prev %p %@", self.prevLayer, self.prevLayer);
      self.prevLayer.frame = self.view.bounds;
      self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
      [self.view.layer addSublayer: self.prevLayer];

      [self.captureSession startRunning];
#endif
}

#if HAS_AVFF
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection 
{ 
      if (!decoding) {
        return;
      }
      CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
      /*Lock the image buffer*/
      CVPixelBufferLockBaseAddress(imageBuffer,0); 
      /*Get information about the image*/
      size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
      size_t width = CVPixelBufferGetWidth(imageBuffer); 
      size_t height = CVPixelBufferGetHeight(imageBuffer); 
        
      // NSLog(@"wxh: %lu x %lu", width, height);

      uint8_t* baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
      void* free_me = 0;
      if (true) { // iOS bug?
        uint8_t* tmp = baseAddress;
        int bytes = bytesPerRow*height;
        free_me = baseAddress = (uint8_t*)malloc(bytes);
        baseAddress[0] = 0xdb;
        memcpy(baseAddress,tmp,bytes);
      }

      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
      CGContextRef newContext =
          CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,
                                kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);

      CGImageRef capture = CGBitmapContextCreateImage(newContext); 
      CVPixelBufferUnlockBaseAddress(imageBuffer,0);
      free(free_me);

      CGContextRelease(newContext); 
      CGColorSpaceRelease(colorSpace);

      if (0) {
          CGRect cropRect = [overlayView cropRect];

          float height = CGImageGetHeight(capture);
          float width = CGImageGetWidth(capture);

          NSLog(@"%f %f", width, height);

          CGRect screen = UIScreen.mainScreen.bounds;
          float tmp = screen.size.width;
          screen.size.width = screen.size.height;;
          screen.size.height = tmp;

          cropRect.origin.x = (width-cropRect.size.width)/2;
          cropRect.origin.y = (height-cropRect.size.height)/2;

          NSLog(@"sb %@", NSStringFromCGRect(UIScreen.mainScreen.bounds));
          NSLog(@"cr %@", NSStringFromCGRect(cropRect));

          CGImageRef newImage = CGImageCreateWithImageInRect(capture, cropRect);
          CGImageRelease(capture);
          capture = newImage;
      }

      UIImage* scrn = [[[UIImage alloc] initWithCGImage:capture] autorelease];

      CGImageRelease(capture);

      Decoder* d = [[Decoder alloc] init];
      d.readers = readers;
      d.delegate = self;

      decoding = [d decodeImage:scrn] == YES ? NO : YES;

      [d release];

      if (decoding) {

        d = [[Decoder alloc] init];
        d.readers = readers;
        d.delegate = self;

        scrn = [[[UIImage alloc] initWithCGImage:scrn.CGImage
                                           scale:1.0
                                     orientation:UIImageOrientationLeft] autorelease];

        // NSLog(@"^ %@ %f", NSStringFromCGSize([scrn size]), scrn.scale);
        decoding = [d decodeImage:scrn] == YES ? NO : YES;
        [d release];
      }

}
#endif

- (void)stopCapture {
      decoding = NO;
    #if HAS_AVFF
      [captureSession stopRunning];
      AVCaptureInput* input = [captureSession.inputs objectAtIndex:0];
      [captureSession removeInput:input];
      AVCaptureVideoDataOutput* output = (AVCaptureVideoDataOutput*)[captureSession.outputs objectAtIndex:0];
      [captureSession removeOutput:output];
      [self.prevLayer removeFromSuperlayer];

      self.prevLayer = nil;
      self.captureSession = nil;
    #endif
}
@end
