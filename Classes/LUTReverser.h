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

+ (instancetype)reverserForLUT:(LUT *)lut;
- (LUT *)reversedLUT;

@end
