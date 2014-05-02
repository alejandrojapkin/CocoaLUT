//
//  LUT1DGraphView.h
//  Pods
//
//  Created by Greg Cotten on 5/1/14.
//
//

#import <Cocoa/Cocoa.h>
#import "CocoaLUT.h"
#import <SAMCubicSpline/SAMCubicSpline.h>

@interface LUT1DGraphView : NSView

@property (strong, nonatomic) LUT *lut;

-(void)lutDidChange;

@end
