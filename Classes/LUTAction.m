//
//  LUTAction.m
//  Lattice
//
//  Created by Greg Cotten on 6/19/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "LUTAction.h"

@interface LUTAction ()

@property (strong) LUT* cachedInLUT;
@property (strong) LUT* cachedOutLUT;

@end

@implementation LUTAction

+(instancetype)actionWithBlock:(LUT *(^)(LUT *lut))actionBlock
                    actionName:(NSString *)actionName
                actionMetadata:(M13OrderedDictionary *)actionMetadata{
    return [[self alloc] initWithBlock:actionBlock actionName:actionName actionMetadata:actionMetadata];
}

+(instancetype)actionWithBypassBlockWithName:(NSString *)actionName{
    return [self actionWithBlock:^LUT *(LUT *lut) {
        return lut;
    }
                              actionName:actionName
                          actionMetadata:M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"Bypass"}])];
}

-(instancetype)initWithBlock:(LUT *(^)(LUT *lut))actionBlock
                  actionName:(NSString *)actionName
              actionMetadata:(M13OrderedDictionary *)actionMetadata{
    if(self = [super init]){
        self.actionBlock = actionBlock;
        self.actionName = actionName ? actionName : @"Untitled Action";
        if (actionMetadata == nil){
            @throw [NSException exceptionWithName:@"LUTActionInitError" reason:@"Action metadata must not be nil." userInfo:nil];
        }
        if (actionMetadata[@"id"] == nil){
            @throw [NSException exceptionWithName:@"LUTActionInitError" reason:@"Action metadata doesn't contain an ID." userInfo:nil];
        }
        self.actionMetadata = actionMetadata;
    }
    return self;
}

-(LUT *)LUTByUsingActionBlockOnLUT:(LUT *)lut{
    if(self.cachedInLUT != nil && self.cachedInLUT == lut){
        //NSLog(@"\"%@\" cached", self);
        [self.cachedOutLUT copyMetaPropertiesFromLUT:lut];
        return self.cachedOutLUT;
    }
    else{
        //NSLog(@"\"%@\" not cached", self);
        self.cachedInLUT = lut;
        self.cachedOutLUT = self.actionBlock(lut);
        [self.cachedOutLUT copyMetaPropertiesFromLUT:lut];
        return self.cachedOutLUT;
    }
}

-(NSString *)description{
    return [self.actionName stringByAppendingString:[NSString stringWithFormat:@": %@", [self actionDetails]]];
}

-(instancetype)copyWithZone:(NSZone *)zone{
    LUTAction *copiedAction = [LUTAction actionWithBlock:self.actionBlock actionName:[self.actionName copyWithZone:zone] actionMetadata:[self.actionMetadata copyWithZone:zone]];
    copiedAction.cachedInLUT = self.cachedInLUT;
    copiedAction.cachedOutLUT = self.cachedOutLUT;
    return copiedAction;
}

-(NSString *)actionDetails{
    NSString *outString = [NSString string];
    for(NSString *key in [self.actionMetadata allKeys]){
        if(![key isEqualToString:@"id"]){
            outString = [outString stringByAppendingString:[NSString stringWithFormat:@"\n%@: %@", key, self.actionMetadata[key]]];
        }
    }
    return outString;
}

+(instancetype)actionWithLUTBySwizzlingWithMethod:(LUT1DSwizzleChannelsMethod)method{

    M13OrderedDictionary *methods = [LUT1D LUT1DSwizzleChannelsMethods];

    NSString *methodName;
    for(NSString *key in methods.allKeys){
        if ([methods[key] isEqualToNumber:@(method)]) {
            methodName = key;
        }
    }

    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"MixCurves"},
                                                           @{@"method":methodName?:@"Unknown"}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        if (isLUT1D(lut)) {
            return [(LUT1D *)lut LUT1DBySwizzling1DChannelsWithMethod:method];
        }
        else{
            return [(LUT3D *)lut LUT3DBySwizzling1DChannelsWithMethod:method strictness:NO];

        }
    }
                           actionName:[NSString stringWithFormat:@"Mix Curves (%@)", methodName]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUT3DByConvertingColorTemperatureFromSourceColorSpace:(LUTColorSpace *)sourceColorSpace
                                                        sourceTransferFunction:(LUTColorTransferFunction *)sourceTransferFunction
                                                        sourceColorTemperature:(LUTColorSpaceWhitePoint *)sourceColorTemperature
                                                   destinationColorTemperature:(LUTColorSpaceWhitePoint *)destinationColorTemperature{

    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ConvertColorTemperature"},
                                                           @{@"sourceColorSpace": sourceColorSpace.name},
                                                           @{@"sourceTransferFunction": sourceTransferFunction.name},
                                                           @{@"sourceColorTemperature": sourceColorTemperature.name},
                                                           @{@"destinationColorTemperature": destinationColorTemperature.name}]);

    return [self actionWithBlock:^LUT *(LUT *lut) {
        return [LUTColorSpace convertColorTemperatureFromLUT3D:(LUT3D *)lut
                                              sourceColorSpace:sourceColorSpace
                                        sourceTransferFunction:sourceTransferFunction
                                        sourceColorTemperature:sourceColorTemperature
                                   destinationColorTemperature:destinationColorTemperature];
    }
                      actionName:[NSString stringWithFormat:@"Change Color Temperature"]
                  actionMetadata:actionMetadata];

}

+(instancetype)actionWithLUTByChangingInputLowerBound:(double)inputLowerBound
                                      inputUpperBound:(double)inputUpperBound{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ChangeInputBounds"},
                                                           @{@"inputLowerBound": @(inputLowerBound)},
                                                           @{@"inputUpperBound": @(inputUpperBound)}]);

    return [self actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByChangingInputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
    }
                              actionName:[NSString stringWithFormat:@"Change Input Bounds to [%.3f, %.3f]", inputLowerBound, inputUpperBound]
                          actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByClampingLowerBound:(double)lowerBound
                                      upperBound:(double)upperBound{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"Clamp"},
                                                           @{@"lowerBound": @(lowerBound)},
                                                           @{@"upperBound": @(upperBound)}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByClampingLowerBound:lowerBound upperBound:upperBound];
    }

                           actionName:[NSString stringWithFormat:@"Clamp LUT to [%.3f, %.3f]", lowerBound, upperBound]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByCombiningWithLUT:(LUT *)lutToCombine
                                        lutURL:(NSURL *)lutURL{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"Combine"},
                                                           @{@"lutPath": [lutURL path]}]);
    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByCombiningWithLUT:lutToCombine];
    }
                           actionName:[NSString stringWithFormat:@"Combine with LUT"]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByCombiningBehindWithLUT:(LUT *)lutToCombineBehind
                                              lutURL:(NSURL *)lutURL{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"CombineBehind"},
                                                           @{@"lutPath": [lutURL path]}]);
    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lutToCombineBehind LUTByCombiningWithLUT:lut];
    }
                           actionName:[NSString stringWithFormat:@"Combine Behind LUT"]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUT3DByApplyingColorMatrixColumnMajorM00:(double)m00
                                                              m01:(double)m01
                                                              m02:(double)m02
                                                              m10:(double)m10
                                                              m11:(double)m11
                                                              m12:(double)m12
                                                              m20:(double)m20
                                                              m21:(double)m21
                                                              m22:(double)m22{

    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ApplyColorMatrix"},
                                                           @{@"m00": @(m00)},
                                                           @{@"m01": @(m01)},
                                                           @{@"m02": @(m02)},
                                                           @{@"m10": @(m10)},
                                                           @{@"m11": @(m11)},
                                                           @{@"m12": @(m12)},
                                                           @{@"m20": @(m20)},
                                                           @{@"m21": @(m21)},
                                                           @{@"m22": @(m22)}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [(LUT3D *)lut LUT3DByApplyingColorMatrixColumnMajorM00:m00
                                                                  m01:m01
                                                                  m02:m02
                                                                  m10:m10
                                                                  m11:m11
                                                                  m12:m12
                                                                  m20:m20
                                                                  m21:m21
                                                                  m22:m22];
    }
                           actionName:[NSString stringWithFormat:@"Apply Color Matrix"]
                       actionMetadata:actionMetadata];

}


+(instancetype)actionWithLUTByRemappingValuesWithInputLow:(double)inputLow
                                                inputHigh:(double)inputHigh
                                                outputLow:(double)outputLow
                                               outputHigh:(double)outputHigh{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleOutput"},
                                                           @{@"inputLow": @(inputLow)},
                                                           @{@"inputHigh": @(inputHigh)},
                                                           @{@"outputLow": @(outputLow)},
                                                           @{@"outputHigh": @(outputHigh)}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByRemappingValuesWithInputLow:inputLow
                                           inputHigh:inputHigh
                                           outputLow:outputLow
                                          outputHigh:outputHigh
                                             bounded:NO];
    }
                                                actionName:[NSString stringWithFormat:@"Scale Output"]
                                            actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByRemappingValuesWithInputLowColor:(LUTColor *)inputLowColor
                                                     inputHigh:(LUTColor *)inputHighColor
                                                     outputLow:(LUTColor *)outputLowColor
                                                    outputHigh:(LUTColor *)outputHighColor{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleOutputRGB"},
                                                           @{@"inputLowColor": inputLowColor.rgbArray},
                                                           @{@"inputHighColor": inputHighColor.rgbArray},
                                                           @{@"outputLowColor": outputLowColor.rgbArray},
                                                           @{@"outputHighColor": outputHighColor.rgbArray}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByRemappingFromInputLowColor:inputLowColor
                                          inputHigh:inputHighColor
                                          outputLow:outputLowColor
                                         outputHigh:outputHighColor
                                            bounded:NO];
    }
                           actionName:[NSString stringWithFormat:@"Scale Output RGB"]
                       actionMetadata:actionMetadata];
}



+(instancetype)actionWithLUTByScalingTo01{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleTo01"}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByRemappingValuesWithInputLow:lut.minimumOutputValue
                                           inputHigh:lut.maximumOutputValue
                                           outputLow:0
                                          outputHigh:1
                                             bounded:NO];
    }
                           actionName:[NSString stringWithFormat:@"Scale Absolute 0 to 1"]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByScalingCurvesTo01{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleCurvesTo01"}]);
    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {

        LUT *usedLUT = isLUT1D(lut) ? lut : LUTAsLUT1D(lut, lut.size);
        return [lut LUTByRemappingValuesWithInputLow:usedLUT.minimumOutputValue
                                           inputHigh:usedLUT.maximumOutputValue
                                           outputLow:0
                                          outputHigh:1
                                             bounded:NO];


    }
                           actionName:[NSString stringWithFormat:@"Scale Curves 0 to 1"]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByScalingRGBTo01{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleRGBTo01"}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByRemappingFromInputLowColor:lut.minimumOutputColor
                                          inputHigh:lut.maximumOutputColor
                                          outputLow:[LUTColor colorWithRed:0 green:0 blue:0]
                                         outputHigh:[LUTColor colorWithRed:1 green:1 blue:1]
                                            bounded:NO];
    }
                           actionName:[NSString stringWithFormat:@"Scale Absolute RGB 0 to 1"]
                       actionMetadata:actionMetadata];
}



+(instancetype)actionWithLUTByScalingCurvesRGBTo01{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleCurvesRGBTo01"}]);
    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {

        LUT *usedLUT = isLUT1D(lut) ? lut : LUTAsLUT1D(lut, lut.size);
        return [lut LUTByRemappingFromInputLowColor:usedLUT.minimumOutputColor
                                          inputHigh:usedLUT.maximumOutputColor
                                          outputLow:[LUTColor colorWithRed:0 green:0 blue:0]
                                         outputHigh:[LUTColor colorWithRed:1 green:1 blue:1]
                                            bounded:NO];


    }
                           actionName:[NSString stringWithFormat:@"Scale Curves RGB 0 to 1"]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByScalingLegalToExtended{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleLegalToExtended"}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByRemappingValuesWithInputLow:LEGAL_LEVELS_MIN
                                           inputHigh:LEGAL_LEVELS_MAX
                                           outputLow:EXTENDED_LEVELS_MIN
                                          outputHigh:EXTENDED_LEVELS_MAX
                                             bounded:NO];
    }
                           actionName:[NSString stringWithFormat:@"Legal to Extended"]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByScalingExtendedToLegal{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ScaleExtendedToLegal"}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByRemappingValuesWithInputLow:EXTENDED_LEVELS_MIN
                                           inputHigh:EXTENDED_LEVELS_MAX
                                           outputLow:LEGAL_LEVELS_MIN
                                          outputHigh:LEGAL_LEVELS_MAX
                                             bounded:NO];
    }
                           actionName:[NSString stringWithFormat:@"Extended to Legal"]
                       actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByResizingToSize:(NSUInteger)size{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"Resize"},
                                                           @{@"size": @(size)}]);

    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByResizingToSize:size];
    }
                                              actionName:[NSString stringWithFormat:@"Resize to %i", (int)size]
                                          actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByOffsettingWithColor:(LUTColor *)color{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"Offset"},
                                                           @{@"redOffset": @(color.red)},
                                                           @{@"greenOffset": @(color.green)},
                                                           @{@"blueOffset": @(color.blue)}]);
    
    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByOffsettingWithColor:color];
    }
                           actionName:[NSString stringWithFormat:@"Offset with %@", [color stringFormattedWithFloatingPointLength:3]]
                       actionMetadata:actionMetadata];
}







@end
