//
//  LUTHelper.h
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import <Foundation/Foundation.h>

#import "CocoaLUT.h"

double clamp(double value, double min, double max);
double clamp01(double value);
double remapint01(int value, int maxValue);
double nsremapint01(NSInteger value, NSInteger maxValue);
double lerp1d(double beginning, double end, double value01);
float distancecalc(float x1, float y1, float z1, float x2, float y2, float z2);
void timer(NSString* name, void (^block)());

@interface LUTHelper : NSObject

@end
