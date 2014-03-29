//
//  LUTProcessor.h
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import <Foundation/Foundation.h>
#import "LUT.h"

@interface LUTProcessor : NSObject {
}

@property (strong) LUT *lut;
@property (strong) NSString *progressDescription;
@property (strong) void (^completionHandler)(LUT *reversedLUT);
@property (strong) void (^cancelHandler)();
@property (assign, atomic) float progress;
@property (assign) BOOL cancelled;

+ (instancetype)processorForLUT:(LUT *)lut
              completionHandler:(void(^)(LUT *reversedLUT))completionHandler
                  cancelHandler:(void(^)())cancelHandler;

- (void)cancel;

// For Subclasses
- (void)process;
- (void)completedWithLUT:(LUT *)lut;
- (BOOL)checkCancellation;
- (void)didCancel;
- (void)setProgress:(float)progress section:(int)section of:(int)sectionCount;

@end
