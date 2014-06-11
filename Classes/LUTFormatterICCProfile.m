//
//  LUTFormatterICCProfile.m
//  Pods
//
//  Created by Greg Cotten on 6/10/14.
//
//

#import "LUTFormatterICCProfile.h"

@implementation LUTFormatterICCProfile

+ (LUT *)LUTFromData:(NSData *)data{
    LUT3D *lut = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];
    
    NSColorSpace *iccProfile = [[NSColorSpace alloc] initWithICCProfileData:data];
    
    [lut LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSColor *transformedColor = [[[lut colorAtR:r g:g b:b] NSColor] colorUsingColorSpace:iccProfile];
        [lut setColor:[LUTColor colorFromNSColor:transformedColor] r:r g:g b:b];
    }];
    
    return lut;
}

+ (NSString *)utiString{
    return @"com.apple.colorsync-profile";
}

@end
