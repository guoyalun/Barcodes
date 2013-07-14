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
@synthesize receiveData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.title = @"首页";
    }
    return self;
}

      
- (IBAction)scan:(id)sender
{
      ZXingWidgetController *widController = [[ZXingWidgetController alloc] initWithDelegate:self];
      MultiFormatReader* qrcodeReader = [[MultiFormatReader alloc] init];
      NSSet *readers = [[NSSet alloc ] initWithObjects:qrcodeReader,nil];
      [qrcodeReader release];
      widController.readers = readers;
      [readers release];
      widController.soundToPlay =
      [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"beep-beep" ofType:@"aiff"]];
      [self presentModalViewController:widController animated:NO];
      [widController release];
}

- (void)dealloc
{
    [receiveData release];
    [super dealloc];
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
