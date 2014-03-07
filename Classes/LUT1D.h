//
//  LUT1D.h
//  Pods
//
//  Created by Greg Cotten and Wil Gieseler on 3/5/14.
//
//

#import <Foundation/Foundation.h>
#import "CocoaLUT.h"

@class LUT;

/**
 *  A one-dimensional color lookup table that is represented by three tone curves.
 */
@interface LUT1D : NSObject

@property (readonly) NSArray *redCurve;
@property (readonly) NSArray *greenCurve;
@property (readonly) NSArray *blueCurve;

+ (instancetype)LUT1DWithRedCurve:(NSArray *)redCurve greenCurve:(NSArray *)greenCurve blueCurve:(NSArray *)blueCurve;
- (instancetype)initWithRedCurve:(NSArray *)redCurve greenCurve:(NSArray *)greenCurve blueCurve:(NSArray *)blueCurve;
- (LUT *)lutOfSize:(NSUInteger)size;
- (LUT1D *)LUT1DByResizingToSize:(NSUInteger)newSize;


@end
