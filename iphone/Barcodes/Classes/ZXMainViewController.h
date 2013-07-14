//
//  ZXMainViewController.h
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZXingWidgetController.h"

@interface ZXMainViewController : UIViewController <ZXingDelegate>
{
    NSMutableData *receiveData;
}

@property (nonatomic,retain) NSMutableData *receiveData;

- (IBAction)scan:(id)sender;

@end
