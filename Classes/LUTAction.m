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
                           actionName:[NSString stringWithFormat:@"Scale 0 to 1"]
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







@end
