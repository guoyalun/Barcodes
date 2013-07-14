//
//  ZXMainViewController.m
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "ZXMainViewController.h"
#import <MultiFormatReader.h>
#import "MessageViewController.h"
#import "NSPostData.h"
#import <CoreLocation/CoreLocation.h>

@implementation ZXMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.title = @"首页";
    }
    return self;
}

      
- (IBAction)scan:(id)sender
{
    CodeType type = QRCode;
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)sender;
        if (btn.tag == 100) {
            type = BarCode;
        }
    }
    
    ZXingWidgetController *zxingController = [[ZXingWidgetController alloc] initWithDelegate:self];
    zxingController.codeType = type;
    MultiFormatReader* qrcodeReader = [[[MultiFormatReader alloc] init] autorelease];
    zxingController.readers = [[[NSSet alloc] initWithObjects:qrcodeReader, nil] autorelease];
    zxingController.soundToPlay = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"beep-beep" ofType:@"aiff"]];
    [self presentModalViewController:zxingController animated:NO];
    [zxingController release];
}

#pragma mark -
#pragma mark ZXingDelegateMethods
- (void)zxingController:(ZXingWidgetController*)controller didScanResult:(NSString *)resultString
{
    
    NSLog(@"result = %@",resultString);
    
    [self dismissModalViewControllerAnimated:NO];

    NSPostData *postData = [[NSPostData alloc] init];
    postData.scanResult = resultString;
    postData.model = [UIDevice currentDevice].model;
    postData.system = [UIDevice currentDevice].systemName;
    postData.version = [UIDevice currentDevice].systemVersion;
    postData.latitude =  [[NSUserDefaults standardUserDefaults] doubleForKey:@"latitude"];
    postData.longitude = [[NSUserDefaults standardUserDefaults] doubleForKey:@"longitude"];
    
    MessageViewController *messageViewController = [[MessageViewController alloc] initWithNibName:@"Message" bundle:nil];
    messageViewController.postData = postData;
    [self.navigationController pushViewController:messageViewController animated:YES];
    [messageViewController release];
    [postData release];
    
    
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller
{
    [self dismissModalViewControllerAnimated:NO];
}

@end
