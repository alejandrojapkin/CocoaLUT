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
    NSString *outString = [NSString stringWithFormat:@"%ld × %ld × %ld",
                           (long) [value integerValue],
                           (long)[value integerValue],
                           (long)[value integerValue]];
    
    if ([value integerValue] > COCOALUT_MAX_CICOLORCUBE_SIZE) {
        outString = [NSString stringWithFormat:@"%@ (displaying at %i × %i × %i)",
                     outString,
                     COCOALUT_MAX_CICOLORCUBE_SIZE,
                     COCOALUT_MAX_CICOLORCUBE_SIZE,
                     COCOALUT_MAX_CICOLORCUBE_SIZE];
    }
    
    return outString;
}

@end
