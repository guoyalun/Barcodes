//
//  NSPostData.h
//  Barcodes
//
//  Created by 郭亚伦 on 1/29/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@interface NSPostData : NSObject
{
    NSString *scanResult;
    NSString *model;
    NSString *system;
    NSString *version;
    CLLocationDegrees latitude;
    CLLocationDegrees longitude;
}
@property (nonatomic,retain) NSString *scanResult;
@property (nonatomic,retain) NSString *model;
@property (nonatomic,retain) NSString *system;
@property (nonatomic,retain) NSString *version;
@property (nonatomic,assign) CLLocationDegrees latitude;
@property (nonatomic,assign) CLLocationDegrees longitude;

@end
