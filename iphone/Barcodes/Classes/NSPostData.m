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
@synthesize latitude;
@synthesize  longitude;

- (void)dealloc
{
    [scanResult release]; scanResult = nil;
    [model      release]; model      = nil;
    [system     release]; system     = nil;
    [version    release]; version    = nil;
    [super dealloc];
}


@end
