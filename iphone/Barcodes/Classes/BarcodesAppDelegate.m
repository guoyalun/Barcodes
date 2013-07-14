//
//  BarcodesAppDelegate.m
//  Barcodes
//
//  Created by Aaron on 13/22/06.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "BarcodesAppDelegate.h"
#import <CoreLocation/CoreLocation.h>

@implementation BarcodesAppDelegate

@synthesize window;
@synthesize viewController;

#pragma mark -
#pragma mark Application lifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    viewController = [[ZXMainViewController alloc] initWithNibName:@"ZXMainViewController" bundle:nil];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    window.rootViewController = nav;
    [window makeKeyAndVisible];

    [nav release];
  
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  /*
    Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
  /*
    Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
  */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
  /*
    Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
  */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
  /*
    Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  */
    [self setupLocationManager];
    
}


- (void)applicationWillTerminate:(UIApplication *)application {
  /*
    Called when the application is about to terminate.
    See also applicationDidEnterBackground:.
  */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
  /*
    Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
  */
}


- (void)dealloc {
    [window release];
    [viewController release];
    [locationManager release];
    [super dealloc];
}

- (void) setupLocationManager {
    if (locationManager) {
        [locationManager release];
        locationManager = nil;
    }
    locationManager = [[CLLocationManager alloc] init];
    if ([CLLocationManager locationServicesEnabled]) {
        NSLog( @"Starting CLLocationManager" );
        locationManager.delegate = self;
        locationManager.distanceFilter = 200;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
    } else {
        NSLog( @"Cannot Starting CLLocationManager" );
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误" message:@"请开启定位服务!!" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [[NSUserDefaults standardUserDefaults] setDouble:newLocation.coordinate.latitude forKey:@"latitude"];
    [[NSUserDefaults standardUserDefaults] setDouble:newLocation.coordinate.longitude forKey:@"longitude"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}




@end
