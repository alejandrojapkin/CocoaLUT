//
//  LUTSizeValueTransformer.m
//  Pods
//
//  Created by Wil Gieseler on 3/6/14.
//
//

#import "LUTSizeValueTransformer.h"
#import "CocoaLUT.h"

@implementation LUTSizeValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if (!value) {
        return nil;
    }
    LUT *lut = (LUT *)value;
    NSString *outString;
    if(isLUT3D(lut)){
        outString = [NSString stringWithFormat:@"Size: %ld × %ld × %ld",
                               (long)[lut size],
                               (long)[lut size],
                               (long)[lut size]];
    }
    else{
        outString = [NSString stringWithFormat:@"Size: %ld", (long) [lut size]];
    }
    if ([lut size] > COCOALUT_MAX_CICOLORCUBE_SIZE) {
        outString = [NSString stringWithFormat:@"%@ (displaying at %i × %i × %i)",
                     outString,
                     COCOALUT_MAX_CICOLORCUBE_SIZE,
                     COCOALUT_MAX_CICOLORCUBE_SIZE,
                     COCOALUT_MAX_CICOLORCUBE_SIZE];
    }
    
    
    
    
    return outString;
}

@end
