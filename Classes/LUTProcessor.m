//
//  LUTProcessor.m
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import "LUTProcessor.h"

@implementation LUTProcessor

+ (instancetype)processorForLUT:(LUT *)lut
              completionHandler:(void(^)(LUT *reversedLUT))completionHandler
                  cancelHandler:(void(^)())cancelHandler {
    LUTProcessor *r = [[self alloc] init];
    [r setLut:lut];
    [r setCancelHandler:cancelHandler];
    [r setCompletionHandler:completionHandler];
    return r;
}

- (void)process {
    
}

- (void)cancel {
    _cancelled = YES;
}

- (void)completedWithLUT:(LUT *)lut {
    self.progress = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completionHandler(lut);
    });
}

- (BOOL)checkCancellation {
    if (_cancelled) {
        self.cancelHandler();
        return YES;
    }
    return NO;
}

@end
