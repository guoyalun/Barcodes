//
//  MessageViewController.h
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "NSPostData.h"
#import "ZXingWidgetController.h"

@interface MessageViewController : UIViewController <UIWebViewDelegate,ZXingDelegate>
{
      NSPostData *postData;
}

@property (nonatomic,retain) IBOutlet UILabel *resultLabel;
@property (nonatomic,retain) IBOutlet UIWebView *webView;
@property (nonatomic,retain) NSPostData *postData;

- (IBAction)reScan:(id)sender;
- (IBAction)dismiss:(id)sender;

@end

