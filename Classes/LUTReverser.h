//
//  LUTReverser.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/16/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LUT.h"
#import "KDTree.h"

@interface LUTReverser : NSObject

@property (strong) LUT *lut;
@property (strong) NSString *progressDescription;
@property (assign) float progress;

+ (instancetype)reverserForLUT:(LUT *)lut;
- (void)reverseLUTWithCompletionHandler:(void(^)(LUT *reversedLUT))completionHandler;

@end
