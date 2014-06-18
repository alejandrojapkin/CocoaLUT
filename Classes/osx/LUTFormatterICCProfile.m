//
//  LUTFormatterICCProfile.m
//  Pods
//
//  Created by Greg Cotten on 6/10/14.
//
//

#import "LUTFormatterICCProfile.h"

@implementation LUTFormatterICCProfile

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromData:(NSData *)data{
    LUT3D *lut = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];
    
    NSColorSpace *iccProfile = [[NSColorSpace alloc] initWithICCProfileData:data];
    
    [lut LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSColor *transformedColor = [[lut colorAtR:r g:g b:b].systemColor colorUsingColorSpace:iccProfile];
        [lut setColor:[LUTColor colorWithSystemColor:transformedColor] r:r g:g b:b];
    }];
    
    return lut;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if([[[self class] fileExtensions] containsObject:[fileURL pathExtension]]){
        return YES;
    }
    return NO;
}

+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputTypeNone;
}

+ (NSString *)utiString{
    return @"com.apple.colorsync-profile";
}

+ (NSArray *)fileExtensions{
    return @[@"icc", @"icm", @"pf", @"prof"];
}

@end
