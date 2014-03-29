//
//  LUTProcessor.m
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import "LUTProcessor.h"

@interface LUTProcessor (){
    NSDate *_startTime;
    BOOL _calledCancelHandler;
}
@end

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
    _startTime = [NSDate date];
}

- (void)cancel {
    self.cancelled = YES;
    self.progressDescription = @"Canceling...";
}

- (void)completedWithLUT:(LUT *)lut {
    self.progress = 1;
    NSLog(@"-> Processor finished in %fs", -[_startTime timeIntervalSinceNow]);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completionHandler(lut);
    });
}

- (BOOL)checkCancellation {
    if (self.cancelled) {
        @synchronized(self) {
            if (!_calledCancelHandler) {
                [self didCancel];
                _calledCancelHandler = YES;
            }
        }
        return YES;
    }
    return NO;
}

- (void)didCancel {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cancelHandler();
    });
}

- (void)setProgress:(float)progress section:(int)section of:(int)sectionCount {
    self.progress = (progress / (float)sectionCount) + (((float)section - 1) / (float)sectionCount);
}

@end
