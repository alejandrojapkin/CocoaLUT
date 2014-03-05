//
//  LUT1D.h
//  Pods
//
//  Created by Greg Cotten and Wil Gieseler on 3/5/14.
//
//

#import <Foundation/Foundation.h>
#import "CocoaLUT.h"

@interface LUT1D : NSObject

+ (instancetype)LUT1DWithRedCurve:(NSArray *)redCurve greenCurve:(NSArray *)greenCurve blueCurve:(NSArray *)blueCurve;
- (instancetype)initWithRedCurve:(NSArray *)redCurve greenCurve:(NSArray *)greenCurve blueCurve:(NSArray *)blueCurve;
- (LUT *)lutOfSize:(NSUInteger)size;


@end
