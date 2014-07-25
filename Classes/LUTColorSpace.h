//
//  LUTColorSpace.h
//  Pods
//
//  Created by Greg Cotten on 4/2/14.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "CocoaLUT.h"
#import "LUTColorSpaceWhitePoint.h"

@class LUTColorTransferFunction;

@interface LUTColorSpace : NSObject <NSCopying>

@property (strong) LUTColorSpaceWhitePoint *defaultWhitePoint;
@property (assign) double redChromaticityX;
@property (assign) double redChromaticityY;
@property (assign) double greenChromaticityX;
@property (assign) double greenChromaticityY;
@property (assign) double blueChromaticityX;
@property (assign) double blueChromaticityY;

@property (assign) BOOL forcesNPM;
@property (assign) double forwardFootlambertCompensation;

@property (assign) GLKMatrix3 npm;

@property (strong) NSString *name;


+ (instancetype)LUTColorSpaceWithDefaultWhitePoint:(LUTColorSpaceWhitePoint *)whitePoint
                                  redChromaticityX:(double)redChromaticityX
                                  redChromaticityY:(double)redChromaticityY
                                greenChromaticityX:(double)greenChromaticityX
                                greenChromaticityY:(double)greenChromaticityY
                                 blueChromaticityX:(double)blueChromaticityX
                                 blueChromaticityY:(double)blueChromaticityY
                                              name:(NSString *)name;

+ (instancetype)LUTColorSpaceWithNPM:(GLKMatrix3)npm
                                name:(NSString *)name;

+ (LUT3D *)convertLUT3D:(LUT3D *)lut fromColorSpace:(LUTColorSpace *)sourceColorSpace
             whitePoint:(LUTColorSpaceWhitePoint *)sourceWhitePoint
           toColorSpace:(LUTColorSpace *)destinationColorSpace
             whitePoint:(LUTColorSpaceWhitePoint *)destinationWhitePoint
         bradfordMatrix:(BOOL)useBradfordMatrix;

+ (LUT3D *)convertColorTemperatureFromLUT3D:(LUT3D *)lut
                           sourceColorSpace:(LUTColorSpace *)sourceColorSpace
                     sourceTransferFunction:(LUTColorTransferFunction *)sourceTransferFunction
                     sourceColorTemperature:(LUTColorSpaceWhitePoint *)sourceColorTemperature
                destinationColorTemperature:(LUTColorSpaceWhitePoint *)destinationColorTemperature;

+ (GLKMatrix3)transformationMatrixFromColorSpace:(LUTColorSpace *)sourceColorSpace
                                      whitePoint:(LUTColorSpaceWhitePoint *)sourceWhitePoint
                                    toColorSpace:(LUTColorSpace *)destinationColorSpace
                                      whitePoint:(LUTColorSpaceWhitePoint *)destinationWhitePoint
                                  bradfordMatrix:(BOOL)useBradfordMatrix;

+ (GLKMatrix3)npmFromColorSpace:(LUTColorSpace *)colorSpace
                     whitePoint:(LUTColorSpaceWhitePoint *)whitePoint;

+ (NSArray *)knownColorSpaces;

+ (instancetype)rec709ColorSpace;
+ (instancetype)adobeRGBColorSpace;
+ (instancetype)dciP3ColorSpace;
+ (instancetype)rec2020ColorSpace;
+ (instancetype)alexaWideGamutColorSpace;
+ (instancetype)sGamut3CineColorSpace;
+ (instancetype)sGamutColorSpace;
+ (instancetype)acesGamutColorSpace;
+ (instancetype)dciXYZColorSpace;
+ (instancetype)xyzColorSpace;




@end
