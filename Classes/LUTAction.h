//
//  LUTAction.h
//  Lattice
//
//  Created by Greg Cotten on 6/19/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CocoaLUT.h"
#import "LUTColorSpace.h"

@interface LUTAction : NSObject <NSCopying>

@property (copy) LUT* (^actionBlock)(LUT*);
@property (strong) NSString *actionName;
@property (strong) M13OrderedDictionary *actionMetadata;


+(instancetype)actionWithBlock:(LUT *(^)(LUT *lut))actionBlock
                    actionName:(NSString *)actionName
                actionMetadata:(M13OrderedDictionary *)metadata;

+(instancetype)actionWithBypassBlockWithName:(NSString *)actionName;

-(LUT *)LUTByUsingActionBlockOnLUT:(LUT *)lut;

-(NSString *)actionDetails;

+(instancetype)actionWithLUTByChangingInputLowerBound:(double)inputLowerBound
                                      inputUpperBound:(double)inputUpperBound;

+(instancetype)actionWithLUTByClampingLowerBound:(double)lowerBound
                                      upperBound:(double)upperBound;

+(instancetype)actionWithLUT3DByConvertingColorTemperatureFromSourceColorSpace:(LUTColorSpace *)sourceColorSpace
                                                        sourceTransferFunction:(LUTColorTransferFunction *)sourceTransferFunction
                                                        sourceColorTemperature:(LUTColorSpaceWhitePoint *)sourceColorTemperature
                                                   destinationColorTemperature:(LUTColorSpaceWhitePoint *)destinationColorTemperature;

+(instancetype)actionWithLUTByRemappingValuesWithInputLow:(double)inputLow
                                                inputHigh:(double)inputHigh
                                                outputLow:(double)outputLow
                                               outputHigh:(double)outputHigh;

+(instancetype)actionWithLUTByRemappingValuesWithInputLowColor:(LUTColor *)inputLowColor
                                                     inputHigh:(LUTColor *)inputHighColor
                                                     outputLow:(LUTColor *)outputLowColor
                                                    outputHigh:(LUTColor *)outputHighColor;

+(instancetype)actionWithLUTByCombiningWithLUT:(LUT *)lutToCombine
                                        lutURL:(NSURL *)lutURL;

+(instancetype)actionWithLUTByScalingLegalToExtended;

+(instancetype)actionWithLUTByScalingExtendedToLegal;

+(instancetype)actionWithLUTByScalingTo01;
+(instancetype)actionWithLUTByScalingRGBTo01;

+(instancetype)actionWithLUTByScalingCurvesTo01;
+(instancetype)actionWithLUTByScalingCurvesRGBTo01;

+(instancetype)actionWithLUTByResizingToSize:(NSUInteger)size;

@end
