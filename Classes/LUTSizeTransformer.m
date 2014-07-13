//
//  LUTSizeTransformer.m
//  Pods
//
//  Created by Wil Gieseler on 7/13/14.
//
//

#import "LUTSizeTransformer.h"

@implementation LUTSizeTransformer

+ (void)load {
    [self registerTransformer];
}

+ (NSString *)transformerName {
    return @"size";
}

- (LUT *)LUTByTransformingLUT:(LUT *)lut {
    return [lut LUTByResizingToSize: [self.parameters[@"size"] integerValue]];
}

@end
