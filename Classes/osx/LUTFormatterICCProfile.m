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



    if(!iccProfile || iccProfile.numberOfColorComponents != 3){
        @throw [NSException exceptionWithName:@"ICCReadError" reason:@"ICC Profile couldn't be read." userInfo:nil];
    }

    CGFloat *componentArray = malloc(sizeof(CGFloat)*3);
    [lut LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSColor *transformedColor = [[lut colorAtR:r g:g b:b].systemColor colorUsingColorSpace:iccProfile];

        [transformedColor getComponents:componentArray];
        [lut setColor:[LUTColor colorWithRed:componentArray[0] green:componentArray[1] blue:componentArray[2]] r:r g:g b:b];
    }];

    lut.passthroughFileOptions = @{[self formatterID]:@{}};

    return lut;
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

+ (NSString *)formatterName{
    return @"ICC Profile";
}

+ (NSString *)formatterID{
    return @"iccProfile";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return NO;
}

@end
