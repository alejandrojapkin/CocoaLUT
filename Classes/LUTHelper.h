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

CGSize CGSizeScaledToFitWithin(CGSize imageSize, CGSize targetSize);

/**
 *  Runs the passed block cubeSize ^ 3 times, iterating over each point on a cube of edge length `cubeSize`.
 */
void LUTConcurrentCubeLoop(NSUInteger cubeSize, void (^block)(NSUInteger r, NSUInteger g, NSUInteger b));

void LUTConcurrentRectLoop(NSUInteger width, NSUInteger height, void (^block)(NSUInteger x, NSUInteger y));

#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
void LUTNSImageLog(NSImage *image);
NSImage* LUTNSImageFromCIImage(CIImage *ciImage, BOOL useSoftwareRenderer);
#endif

@interface LUTHelper : NSObject

@end
