//
//  MessageViewController.m
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "MessageViewController.h"
#import <MultiFormatReader.h>
#import "NSPostData.h"
#import <CoreLocation/CoreLocation.h>

@implementation MessageViewController
@synthesize webView;
@synthesize postData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"扫描结果";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.scrollView.scrollEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *urlString = [NSString stringWithFormat:@"http://m1.ampthon.com/m1.php?tag_id=%@&os=%@ %@&hardware=%@&loc=(%f,%f)&screen_size=(%dX%d)",self.postData.scanResult,self.postData.system,self.postData.version,self.postData.model,self.postData.latitude,self.postData.longitude,(NSInteger)[UIScreen mainScreen].bounds.size.width,(NSInteger)[UIScreen mainScreen].bounds.size.height];
    
    NSLog(@"%@",urlString);
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLRequest *reuqest = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:reuqest];
    
    self.resultLabel.text = self.postData.scanResult;

}

- (void)viewDidUnload {
    [self setResultLabel:nil];
    self.webView = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    [webView release];
    [postData release];
    [_resultLabel release];
	[super dealloc];
}

- (IBAction)reScan:(id)sender {
    ZXingWidgetController *widController = [[ZXingWidgetController alloc] initWithDelegate:self];
    MultiFormatReader* qrcodeReader = [[MultiFormatReader alloc] init];
    NSSet *readers = [[NSSet alloc] initWithObjects:qrcodeReader,nil];
    [qrcodeReader release];
    widController.readers = readers;
    [readers release];
    widController.soundToPlay =
    [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"beep-beep" ofType:@"aiff"]];
    [self presentModalViewController:widController animated:YES];
    [widController release];
    
}

- (IBAction)dismiss:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark ZXingDelegateMethods
- (void)zxingController:(ZXingWidgetController*)controller didScanResult:(NSString *)resultString
{
    NSLog(@"result = %@",resultString);
    self.resultLabel.text = resultString;
    
    postData.scanResult = resultString;
    postData.model = [UIDevice currentDevice].model;
    postData.system = [UIDevice currentDevice].systemName;
    postData.version = [UIDevice currentDevice].systemVersion;
    postData.latitude =  [[NSUserDefaults standardUserDefaults] doubleForKey:@"latitude"];
    postData.longitude = [[NSUserDefaults standardUserDefaults] doubleForKey:@"longitude"];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller
{
    [self dismissModalViewControllerAnimated:YES];
}
@end
