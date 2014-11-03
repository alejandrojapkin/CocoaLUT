//
//  LUTHelper.h
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import <Foundation/Foundation.h>

#import "CocoaLUT.h"
#import "LUT1D.h"
#import "LUT3D.h"
#import <M13OrderedDictionary/M13OrderedDictionary.h>

@class LUT1D;
@class LUT3D;
typedef NS_ENUM(NSInteger, LUT1DExtractionMethod);


double contrastStretch(double value, double currentMin, double currentMax, double finalMin, double finalMax);
double clamp(double value, double min, double max);
double clamp01(double value);
double clampLowerBound(double value, double lowerBound);
double clampUpperBound(double value, double upperBound);
double remapint01(int value, int maxValue);
double nsremapint01(NSInteger value, NSInteger maxValue);
double remap(double value, double inputLow, double inputHigh, double outputLow, double outputHigh);
double remapNoError(double value, double inputLow, double inputHigh, double outputLow, double outputHigh);
BOOL outOfBounds(double value, double min, double max, BOOL inclusive);
double lerp1d(double beginning, double end, double value01);
double smootherstep(double beginning, double end, double percentage);
double smoothstep(double beginning, double end, double percentage);
float distancecalc(float x1, float y1, float z1, float x2, float y2, float z2);
void timer(NSString* name, void (^block)());

NSArray* indicesDoubleArray(double startValue, double endValue, int numIndices);
NSArray* indicesIntegerArray(int startValue, int endValue, int numIndices);
NSArray* indicesIntegerArrayLegacy(int startValue, int endValue, int numIndices);

double roundValueToNearest(double value, double nearestValue);
NSUInteger maxIntegerFromBitdepth(NSUInteger bitdepth);

NSArray* arrayWithEmptyElementsRemoved(NSArray *array);
NSArray* arrayWithComponentsSeperatedByWhitespaceWithEmptyElementsRemoved(NSString *string);
NSArray* arrayWithComponentsSeperatedByNewlineWithEmptyElementsRemoved(NSString *string);
NSArray* arrayWithComponentsSeperatedByNewlineAndWhitespaceWithEmptyElementsRemoved(NSString *string);
NSString* substringBetweenTwoStrings(NSString *originString, NSString *firstString, NSString *secondString);

NSInteger findFirstLUTLineInLines(NSArray *lines, NSString *seperator, int numValues, int startLine);
NSInteger findFirstLUTLineInLinesWithWhitespaceSeparators(NSArray *lines, int numValues, int startLine);

NSNumberFormatter* sharedNumberFormatter();
NSCharacterSet* sharedInvertedNumericCharacterSet();
BOOL stringIsValidNumber(NSString *string);

BOOL isLUT1D(LUT* lut);
BOOL isLUT3D(LUT* lut);
LUT1D* LUTAsLUT1D(LUT* lut, NSUInteger size);
LUT3D* LUTAsLUT3D(LUT* lut, NSUInteger size);

CGSize CGSizeProportionallyScaled(CGSize currentSize, CGSize targetSize);

M13OrderedDictionary* M13OrderedDictionaryFromOrderedArrayWithDictionaries(NSArray *array);
NSDictionary *NSDictionaryFromM13OrderedDictionary(M13OrderedDictionary *stupidDict);

/**
 *  Runs the passed block cubeSize ^ 3 times, iterating over each point on a cube of edge length `cubeSize`.
 */
void LUT3DConcurrentLoop(NSUInteger cubeSize, void (^block)(NSUInteger r, NSUInteger g, NSUInteger b));

void LUT1DLoop(NSUInteger size, void (^block)(NSUInteger index));

void LUTConcurrentRectLoop(NSUInteger width, NSUInteger height, void (^block)(NSUInteger x, NSUInteger y));

SystemColor* systemColorWithHexString(NSString* hexString);

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#elif TARGET_OS_MAC
void LUTNSImageLog(NSImage *image);
NSImage* LUTNSImageFromCIImage(CIImage *ciImage, BOOL useSoftwareRenderer);
#endif

@interface LUTHelper : NSObject


@end
