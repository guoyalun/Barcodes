//
//  NSPostData.m
//  Barcodes
//
//  Created by 郭亚伦 on 1/29/13.
//
//

#import "NSPostData.h"

@implementation NSPostData
@synthesize scanResult;
@synthesize model;
@synthesize system;
@synthesize version;
@synthesize ipAddress;
@synthesize current;
@synthesize latitude;
@synthesize  longitude;

- (void)dealloc
{
    [scanResult release]; scanResult = nil;
    [model      release]; model      = nil;
    [system     release]; system     = nil;
    [version    release]; version    = nil;
    [ipAddress  release]; ipAddress  = nil;
    [current    release]; current    = nil;
    [super dealloc];
}


@end
