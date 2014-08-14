//
//  LUTFormatterDaVinciDAVLUT.m
//  Pods
//
//  Created by Greg Cotten on 8/13/14.
//
//

#import "LUTFormatterDaVinciDAVLUT.h"

@implementation LUTFormatterDaVinciDAVLUT

+ (void)load{
    [super load];
}

+ (NSString *)formatterName{
    return @"DaVinci 3D LUT";
}

+ (NSString *)formatterID{
    return @"davinciDAVLUT";
}

+ (NSString *)utiString{
    return @"com.blackmagicdesign.davlut";
}

+ (NSArray *)fileExtensions{
    return @[@"davlut"];
}

@end
