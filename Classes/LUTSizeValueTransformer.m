//
//  LUTSizeValueTransformer.m
//  Pods
//
//  Created by Wil Gieseler on 3/6/14.
//
//

#import "LUTSizeValueTransformer.h"

@implementation LUTSizeValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue
:(id)value {
    return (value == nil) ? nil : [NSString stringWithFormat:@"%ld × %ld × %ld", (long) [value integerValue], (long)[value integerValue], (long)[value integerValue]];
}

@end
