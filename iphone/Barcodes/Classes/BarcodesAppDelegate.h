//
//  BarcodesAppDelegate.h
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ZXMainViewController.h"

@interface BarcodesAppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>
{
    UIWindow *window;
    ZXMainViewController *viewController;
    
    CLLocationManager *locationManager;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) ZXMainViewController *viewController;

@end

