//
//  LUT.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUT.h"
#import "CocoaLUT.h"
#import "LUTFormatter.h"


@interface LUT ()
@end

@implementation LUT

- (instancetype)init {
    if (self = [super init]) {
        self.metadata = [NSMutableDictionary dictionary];
        self.passthroughFileOptions = @{};
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        
        self.metadata = [aDecoder decodeObjectForKey:@"metadata"];
        self.passthroughFileOptions = [aDecoder decodeObjectForKey:@"passthroughFileOptions"];
        self.size = [aDecoder decodeIntegerForKey:@"size"];
        self.inputLowerBound = [aDecoder decodeDoubleForKey:@"inputLowerBound"];
        self.inputUpperBound = [aDecoder decodeDoubleForKey:@"inputUpperBound"];
        
        if(self.inputLowerBound >= self.inputUpperBound){
            @throw [NSException exceptionWithName:@"LUTCreationError" reason:@"Input Lower Bound >= Input Upper Bound" userInfo:nil];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.metadata forKey:@"metadata"];
    [aCoder encodeObject:self.passthroughFileOptions forKey:@"passthroughFileOptions"];
    [aCoder encodeInteger:self.size forKey:@"size"];
    [aCoder encodeDouble:self.inputLowerBound forKey:@"inputLowerBound"];
    [aCoder encodeDouble:self.inputUpperBound forKey:@"inputUpperBound"];
}

- (instancetype)initWithSize:(NSUInteger)size
             inputLowerBound:(double)inputLowerBound
             inputUpperBound:(double)inputUpperBound{
    if (self = [super init]) {
        if(inputLowerBound >= inputUpperBound){
            @throw [NSException exceptionWithName:@"LUTCreationError" reason:@"Input Lower Bound >= Input Upper Bound" userInfo:nil];
        }
        self.metadata = [NSMutableDictionary dictionary];
        self.passthroughFileOptions = [NSDictionary dictionary];
        self.size = size;
        self.inputLowerBound = inputLowerBound;
        self.inputUpperBound = inputUpperBound;
    }
    return self;
}

+ (instancetype)LUTFromURL:(NSURL *)url {
    LUTFormatter *formatter = [LUTFormatter LUTFormatterValidForReadingURL:url];
    if(formatter == nil){
        return nil;
    }
    return [[formatter class] LUTFromURL:url];
}

+ (instancetype)LUTFromData:(NSData *)data formatterID:(NSString *)formatterID
{
    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:formatterID];
    if(formatter == nil){
        return nil;
    }
    return [[formatter class] LUTFromData:data];
}

+ (instancetype)LUTFromDataRepresentation:(NSData *)data{
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (NSData *)dataRepresentation{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (BOOL)writeToURL:(NSURL *)url
        atomically:(BOOL)atomically
       formatterID:(NSString *)formatterID
           options:(NSDictionary *)options
        conformLUT:(BOOL)conformLUT{
    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:formatterID];

    //validation
    if(formatter == nil){
        NSLog(@"Formatter not found for ID \"%@\".", formatterID);
        return NO;
    }
    if([[formatter class] isValidWriterForLUTType:self] == NO){
        NSLog(@"%@ is not a valid writer for LUT (%@) with options: %@.", [[formatter class] formatterName], self, options);
        return NO;
    }
    if (options == nil) {
        options = [[formatter class] defaultOptions];
    }

    //----

    NSArray *actionsForConformance = [[formatter class] conformanceLUTActionsForLUT:self options:options];

    if (actionsForConformance.count != 0 && conformLUT == NO) {
        NSMutableString *conformanceInfo = [[NSMutableString alloc] init];
        for (int i = 0; i < actionsForConformance.count; i++) {
            [conformanceInfo appendString:((LUTAction *)actionsForConformance[0]).actionName];
            if (i+1 != actionsForConformance.count) {
                [conformanceInfo appendString:@"\n"];
            }
        }
        NSLog(@"LUT requires conformance before saving. Info:\n%@", conformanceInfo);
        return NO;
    }
    LUT *outputLUT = [self copy];
    for(LUTAction *action in actionsForConformance){
        outputLUT = [action LUTByUsingActionBlockOnLUT:outputLUT];
    }

    NSData *lutData = [outputLUT dataFromLUTWithFormatterID:formatterID options:options];

    if (lutData == nil) {
        NSLog(@"Formatter couldn't create data from LUT.");
        return NO;
    }

    return [lutData writeToURL:url atomically:atomically];
}

- (NSData *)dataFromLUTWithFormatterID:(NSString *)formatterID
                               options:(NSDictionary *)options{
    LUTFormatter *formatter = [LUTFormatter LUTFormatterWithID:formatterID];

    if (options == nil) {
        NSLog(@"Options can't be nil.");
        return nil;
    }
    if(formatter == nil){
        NSLog(@"Formatter can't be nil.");
        return nil;
    }
    else if([[formatter class] isValidWriterForLUTType:self] == NO){
        NSLog(@"%@ is not a valid writer for LUT (%@) with options: %@.", [[formatter class] formatterName], self, options);
        return nil;
    }
    else{
        return [[formatter class] dataFromLUT:self withOptions:options];
    }

}

+ (instancetype)LUTOfSize:(NSUInteger)size
          inputLowerBound:(double)inputLowerBound
          inputUpperBound:(double)inputUpperBound{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (instancetype)LUTIdentityOfSize:(NSUInteger)size
                  inputLowerBound:(double)inputLowerBound
                  inputUpperBound:(double)inputUpperBound{
    LUT *identityLUT = [self LUTOfSize:size inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];

    [identityLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [identityLUT setColor:[identityLUT identityColorAtR:r g:g b:b] r:r g:g b:b];
    }];

    return identityLUT;
}

- (void)copyMetaPropertiesFromLUT:(LUT *)lut{
    self.title = [lut.title copy];
    self.descriptionText = [lut.descriptionText copy];
    self.metadata = [lut.metadata mutableCopy];
    self.passthroughFileOptions = [lut.passthroughFileOptions copy];
}

- (void)LUTLoopWithBlock:(void (^)(size_t r, size_t g, size_t b))block{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}


- (instancetype)LUTByResizingToSize:(NSUInteger)newSize {
    if (newSize == [self size]) {
        return [self copy];
    }
    LUT *resizedLUT = [[self class] LUTOfSize:newSize inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];

    [resizedLUT copyMetaPropertiesFromLUT:self];

    double ratio = ((double)self.size - 1.0) / ((double)newSize - 1.0);

    [resizedLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtInterpolatedR:clampUpperBound(r * ratio, self.size-1.0) g:clampUpperBound(g * ratio, self.size-1.0) b:clampUpperBound(b * ratio, self.size-1.0)];
        [resizedLUT setColor:color r:r g:g b:b];
    }];

    return resizedLUT;
}

- (instancetype)LUTByClampingLowerBound:(double)lowerBound
                             upperBound:(double)upperBound{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] clampedWithLowerBound:lowerBound upperBound:upperBound] r:r g:g b:b];
    }];

    return newLUT;
}

- (instancetype)LUTByClampingLowerBoundOnly:(double)lowerBound{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] clampedWithLowerBoundOnly:lowerBound] r:r g:g b:b];
    }];

    return newLUT;
}

- (instancetype)LUTByClampingUpperBoundOnly:(double)upperBound{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] clampedWithUpperBoundOnly:upperBound] r:r g:g b:b];
    }];

    return newLUT;
}

- (instancetype)LUTByOffsettingWithColor:(LUTColor *)offsetColor{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] colorByAddingColor:offsetColor] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (instancetype)LUTByRemappingValuesWithInputLow:(double)inputLow
                                       inputHigh:(double)inputHigh
                                       outputLow:(double)outputLow
                                      outputHigh:(double)outputHigh
                                         bounded:(BOOL)bounded{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] remappedFromInputLow:inputLow
                                                               inputHigh:inputHigh
                                                               outputLow:outputLow
                                                              outputHigh:outputHigh
                                                                 bounded:bounded] r:r g:g b:b];
    }];

    return newLUT;

}

- (instancetype)LUTByRemappingFromInputLowColor:(LUTColor *)inputLowColor
                                      inputHigh:(LUTColor *)inputHighColor
                                      outputLow:(LUTColor *)outputLowColor
                                     outputHigh:(LUTColor *)outputHighColor
                                        bounded:(BOOL)bounded{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] colorByRemappingFromInputLowColor:inputLowColor
                                                                            inputHigh:inputHighColor
                                                                            outputLow:outputLowColor
                                                                           outputHigh:outputHighColor
                                                                              bounded:bounded] r:r g:g b:b];
    }];

    return newLUT;
    
}

- (instancetype)LUTByChangingStrength:(double)strength{
    if(strength > 1.0){
        @throw [NSException exceptionWithName:@"ChangeStrengthError" reason:[NSString stringWithFormat:@"You can't set the strength of the LUT past 1.0 (%f)", strength] userInfo:nil];
    }
    if(strength == 1.0){
        return [self copy];
    }
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self identityColorAtR:r g:g b:b] lerpTo:[self colorAtR:r g:g b:b] amount:strength] r:r g:g b:b];
    }];

    return newLUT;
}

- (instancetype)LUTByCombiningWithLUT:(LUT *)otherLUT {
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (instancetype)LUTByChangingInputLowerBound:(double)inputLowerBound
                             inputUpperBound:(double)inputUpperBound{
    if(inputLowerBound == [self inputLowerBound] && inputUpperBound == [self inputUpperBound]){
        return [self copy];
    }

    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *identityColor = [newLUT identityColorAtR:r g:g b:b];
        [newLUT setColor:[self colorAtColor:identityColor] r:r g:g b:b];
    }];

    return newLUT;
}

- (instancetype)LUTByInvertingColor{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:self.inputLowerBound inputUpperBound:self.inputUpperBound];
    [newLUT copyMetaPropertiesFromLUT:self];

    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *startColor = [self colorAtR:r g:g b:b];
        [newLUT setColor:[startColor colorByInvertingColorWithMinimumValue:0 maximumValue:1] r:r g:g b:b];
    }];

    return newLUT;
}

- (LUTColor *)identityColorAtR:(double)redPoint g:(double)greenPoint b:(double)bluePoint{
    double red = remap(redPoint, 0, [self size] - 1, [self inputLowerBound], [self inputUpperBound]);
    double green = remap(greenPoint, 0, [self size] - 1, [self inputLowerBound], [self inputUpperBound]);
    double blue = remap(bluePoint, 0, [self size] - 1, [self inputLowerBound], [self inputUpperBound]);
    return [LUTColor colorWithRed:red green:green blue:blue];
}

- (LUTColor *)colorAtColor:(LUTColor *)color{
    color = [color clampedWithLowerBound:[self inputLowerBound] upperBound:[self inputUpperBound]];
    double redRemappedInterpolatedIndex = remap(color.red, [self inputLowerBound], [self inputUpperBound], 0, [self size]-1);
    double greenRemappedInterpolatedIndex = remap(color.green, [self inputLowerBound], [self inputUpperBound], 0, [self size]-1);
    double blueRemappedInterpolatedIndex = remap(color.blue, [self inputLowerBound], [self inputUpperBound], 0, [self size]-1);

    return [self colorAtInterpolatedR:clamp(redRemappedInterpolatedIndex, 0, self.size-1)
                                    g:clamp(greenRemappedInterpolatedIndex, 0, self.size-1)
                                    b:clamp(blueRemappedInterpolatedIndex, 0, self.size-1)];
}

- (LUTColor *)colorAtR:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (LUTColor *)colorAtInterpolatedR:(double)redPoint g:(double)greenPoint b:(double)bluePoint{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (void)setColor:(LUTColor *)color r:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (LUTColor *)maximumOutputColor{
    LUTColor *start = [self colorAtR:0 g:0 b:0];
    __block double maxRed = start.red;
    __block double maxGreen = start.green;
    __block double maxBlue = start.blue;

    [self LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtR:r g:g b:b];
        if(color.red > maxRed){
            maxRed = color.red;
        }
        if(color.green > maxGreen){
            maxGreen = color.green;
        }
        if(color.blue > maxBlue){
            maxBlue = color.blue;
        }
    }];
    return [LUTColor colorWithRed:maxRed green:maxGreen blue:maxBlue];
}

- (LUTColor *)minimumOutputColor{
    LUTColor *start = [self colorAtR:0 g:0 b:0];
    __block double minRed = start.red;
    __block double minGreen = start.green;
    __block double minBlue = start.blue;

    [self LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtR:r g:g b:b];
        if(color.red < minRed){
            minRed = color.red;
        }
        if(color.green < minGreen){
            minGreen = color.green;
        }
        if(color.blue < minBlue){
            minBlue = color.blue;
        }
    }];
    return [LUTColor colorWithRed:minRed green:minGreen blue:minBlue];
}

- (double)maximumOutputValue{
    __block double maxValue = [self colorAtR:0 g:0 b:0].red;
    [self LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtR:r g:g b:b];
        if(color.red > maxValue){
            maxValue = color.red;
        }
        if(color.green > maxValue){
            maxValue = color.green;
        }
        if(color.blue > maxValue){
            maxValue = color.blue;
        }
    }];
    return maxValue;
}

- (double)minimumOutputValue{
    __block double minValue = [self colorAtR:0 g:0 b:0].red;
    [self LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtR:r g:g b:b];
        if(color.red < minValue){
            minValue = color.red;
        }
        if(color.green < minValue){
            minValue = color.green;
        }
        if(color.blue < minValue){
            minValue = color.blue;
        }
    }];
    return minValue;
}


//000

- (bool)equalsIdentityLUT{
    return [self equalsLUT:[[self class] LUTIdentityOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]]];
}

- (bool)equalsLUT:(LUT *)comparisonLUT{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (bool)equalsLUTEssence:(LUT *)comparisonLUT
             compareType:(bool)compareType
             compareSize:(bool)compareSize
      compareInputBounds:(bool)compareInputBounds{
    if (compareType && ((isLUT1D(self) && !isLUT1D(comparisonLUT)) || (isLUT3D(self) && !isLUT3D(comparisonLUT)))) {
        return NO;
    }
    if (compareSize && self.size != comparisonLUT.size) {
        return NO;
    }
    if (compareInputBounds && (self.inputLowerBound != comparisonLUT.inputLowerBound || self.inputUpperBound != comparisonLUT.inputUpperBound)) {
        return NO;
    }
    return YES;
}

// http://en.wikipedia.org/wiki/Symmetric_mean_absolute_percentage_error
- (LUTColor *)symetricalMeanAbsolutePercentageError:(LUT *)comparisonLUT{
    if (![self equalsLUTEssence:comparisonLUT
                    compareType:YES
                    compareSize:YES
             compareInputBounds:YES]) {
        return [LUTColor colorWithRed:1000000 green:1000000 blue:1000000];
    }
    double redAbsoluteError = 0.0;
    double greenAbsoluteError = 0.0;
    double blueAbsoluteError = 0.0;
    
    double redAdd = 0.0;
    double greenAdd = 0.0;
    double blueAdd = 0.0;
    
    double numPoints;
    
    if (isLUT3D(self)) {
        numPoints = self.size*self.size*self.size;
        for (int r = 0; r < self.size; r++) {
            for (int g = 0; g < self.size; g++) {
                for (int b = 0; b < self.size; b++) {
                    LUTColor *selfColor = [self colorAtR:r g:g b:b];
                    LUTColor *comparisonColor = [comparisonLUT colorAtR:r g:g b:b];
                    
                    redAdd = fabs(selfColor.red - comparisonColor.red)/(selfColor.red + comparisonColor.red);
                    greenAdd = fabs(selfColor.green - comparisonColor.green)/(selfColor.green + comparisonColor.green);
                    blueAdd = fabs(selfColor.blue - comparisonColor.blue)/(selfColor.blue + comparisonColor.blue);
                    
                    redAbsoluteError += !isfinite(redAdd) ? 0 : redAdd;
                    greenAbsoluteError += !isfinite(greenAdd) ? 0 : greenAdd;
                    blueAbsoluteError += !isfinite(blueAdd) ? 0 : blueAdd;
                }
            }
        }
    }
    else{
        //LUT1D
        numPoints = self.size*3;
        for (int x = 0; x < self.size; x++) {
            LUTColor *selfColor = [self colorAtR:x g:x b:x];
            LUTColor *comparisonColor = [comparisonLUT colorAtR:x g:x b:x];
            
            redAdd = fabs(selfColor.red - comparisonColor.red)/(selfColor.red + comparisonColor.red);
            greenAdd = fabs(selfColor.green - comparisonColor.green)/(selfColor.green + comparisonColor.green);
            blueAdd = fabs(selfColor.blue - comparisonColor.blue)/(selfColor.blue + comparisonColor.blue);
            
            redAbsoluteError += !isfinite(redAdd) ? 0 : redAdd;
            greenAbsoluteError += !isfinite(greenAdd) ? 0 : greenAdd;
            blueAbsoluteError += !isfinite(blueAdd) ? 0 : blueAdd;
        }
        
    }
    
    
    
    
    return [LUTColor colorWithRed:redAbsoluteError/numPoints green:greenAbsoluteError/numPoints blue:blueAbsoluteError/numPoints];
}

- (LUTColor *)averageAbsoluteError:(LUT *)comparisonLUT{
    if (![self equalsLUTEssence:comparisonLUT
                    compareType:YES
                    compareSize:YES
             compareInputBounds:YES]) {
        return [LUTColor colorWithRed:1000000 green:1000000 blue:1000000];
    }
    double redError = 0.0;
    double greenError = 0.0;
    double blueError = 0.0;
    
    double numPoints;
    
    if (isLUT3D(self)) {
        numPoints = self.size*self.size*self.size;
        for (int r = 0; r < self.size; r++) {
            for (int g = 0; g < self.size; g++) {
                for (int b = 0; b < self.size; b++) {
                    LUTColor *selfColor = [self colorAtR:r g:g b:b];
                    LUTColor *comparisonColor = [comparisonLUT colorAtR:r g:g b:b];
                    
                    LUTColor *diff = [selfColor colorBySubtractingColor:comparisonColor];
                    LUTColor *absDiff = [LUTColor colorWithRed:fabs(diff.red) green:fabs(diff.green) blue:fabs(diff.blue)];
                    
                    redError += !isfinite(absDiff.red) ? 0 : absDiff.red;
                    greenError += !isfinite(absDiff.green) ? 0 : absDiff.green;
                    blueError += !isfinite(absDiff.blue) ? 0 : absDiff.blue;
                }
            }
        }
    }
    else{
        numPoints = self.size*3;
        for (int x = 0; x < self.size; x++) {
            LUTColor *selfColor = [self colorAtR:x g:x b:x];
            LUTColor *comparisonColor = [comparisonLUT colorAtR:x g:x b:x];
            
            LUTColor *diff = [selfColor colorBySubtractingColor:comparisonColor];
            LUTColor *absDiff = [LUTColor colorWithRed:fabs(diff.red) green:fabs(diff.green) blue:fabs(diff.blue)];
            
            redError += !isfinite(absDiff.red) ? 0 : absDiff.red;
            greenError += !isfinite(absDiff.green) ? 0 : absDiff.green;
            blueError += !isfinite(absDiff.blue) ? 0 : absDiff.blue;
        }
        
    }
    
    return [LUTColor colorWithRed:redError/numPoints green:greenError/numPoints blue:blueError/numPoints];
}


- (LUTColor *)maximumAbsoluteError:(LUT *)comparisonLUT{
    if (![self equalsLUTEssence:comparisonLUT
                    compareType:YES
                    compareSize:YES
             compareInputBounds:YES]) {
        return [LUTColor colorWithRed:1000000 green:1000000 blue:1000000];
    }
    double redMaxError = 0.0;
    double greenMaxError = 0.0;
    double blueMaxError = 0.0;
    
    if (isLUT3D(self)) {
        for (int r = 0; r < self.size; r++) {
            for (int g = 0; g < self.size; g++) {
                for (int b = 0; b < self.size; b++) {
                    LUTColor *selfColor = [self colorAtR:r g:g b:b];
                    LUTColor *comparisonColor = [comparisonLUT colorAtR:r g:g b:b];
                    
                    LUTColor *diff = [selfColor colorBySubtractingColor:comparisonColor];
                    
                    if (fabs(diff.red) > redMaxError) {
                        redMaxError = fabs(diff.red);
                    }
                    if (fabs(diff.green) > greenMaxError) {
                        greenMaxError = fabs(diff.green);
                    }
                    if (fabs(diff.blue) > blueMaxError) {
                        blueMaxError = fabs(diff.blue);
                    }
                }
            }
        }
    }
    else{
        for (int x = 0; x < self.size; x++) {
            LUTColor *selfColor = [self colorAtR:x g:x b:x];
            LUTColor *comparisonColor = [comparisonLUT colorAtR:x g:x b:x];
            
            LUTColor *diff = [selfColor colorBySubtractingColor:comparisonColor];
            
            if (fabs(diff.red) > redMaxError) {
                redMaxError = fabs(diff.red);
            }
            if (fabs(diff.green) > greenMaxError) {
                greenMaxError = fabs(diff.green);
            }
            if (fabs(diff.blue) > blueMaxError) {
                blueMaxError = fabs(diff.blue);
            }
        }
        
    }
    
    return [LUTColor colorWithRed:redMaxError green:greenMaxError blue:blueMaxError];
}



- (id)copyWithZone:(NSZone *)zone {
    LUT *copiedLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [copiedLUT setMetadata:[[self metadata] mutableCopyWithZone:zone]];
    copiedLUT.descriptionText = [[self descriptionText] mutableCopyWithZone:zone];
    [copiedLUT setTitle:[[self title] mutableCopyWithZone:zone]];
    [copiedLUT setPassthroughFileOptions:[[self passthroughFileOptions] mutableCopyWithZone:zone]];
    return copiedLUT;
}

- (CIFilter *)coreImageFilterWithCurrentColorSpace {
    CIFilter *filter;
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    filter = [self coreImageFilterWithColorSpace:colorspace];
    #elif TARGET_OS_MAC
    //good for render, not good for viewing
    filter = [self coreImageFilterWithColorSpace:colorspace];
    //good for viewing, not good for render
    //return [self coreImageFilterWithColorSpace:[[[NSScreen mainScreen] colorSpace] CGColorSpace]];
    #endif
    //CGColorSpaceRelease(colorspace);
    return filter;
}

- (CIFilter *)coreImageFilterWithColorSpace:(CGColorSpaceRef)colorSpace {
    NSUInteger sizeOfColorCubeFilter = clamp([self size], 0, COCOALUT_MAX_CICOLORCUBE_SIZE);
    LUT3D *used3DLUT = LUTAsLUT3D(self, sizeOfColorCubeFilter);//[LUTAsLUT3D(self, sizeOfColorCubeFilter) LUTByChangingInputLowerBound:0.0 inputUpperBound:1.0];
    
    if (used3DLUT.inputUpperBound - used3DLUT.inputLowerBound != 1.0 && used3DLUT.inputUpperBound - used3DLUT.inputLowerBound < 2.0) {
        used3DLUT = [used3DLUT LUTByChangingInputLowerBound:0 inputUpperBound:1];
    }

    size_t size = [used3DLUT size];
    size_t cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *) malloc (cubeDataSize);

    [used3DLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *transformedColor = [used3DLUT colorAtR:r g:g b:b];

        size_t offset = 4*(b*size*size + g*size + r);

        cubeData[offset]   = (float)transformedColor.red;
        cubeData[offset+1] = (float)transformedColor.green;
        cubeData[offset+2] = (float)transformedColor.blue;
        cubeData[offset+3] = 1.0f;
    }];

    NSData *data = [NSData dataWithBytesNoCopy:cubeData length:cubeDataSize freeWhenDone:YES];

    CIFilter *colorCube;
    if (colorSpace) {
        colorCube = [CIFilter filterWithName:@"CIColorCubeWithColorSpace"];
        [colorCube setValue:(__bridge id)(colorSpace) forKey:@"inputColorSpace"];
    }
    else {
        colorCube = [CIFilter filterWithName:@"CIColorCube"];
    }
    [colorCube setValue:@(size) forKey:@"inputCubeDimension"];
    [colorCube setValue:data forKey:@"inputCubeData"];
    
    return colorCube;
}

- (CIImage *)processCIImage:(CIImage *)image {
    CIFilter *filter = [self coreImageFilterWithCurrentColorSpace];
    [filter setValue:image forKey:@"inputImage"];
    return [filter valueForKey:@"outputImage"];
}

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR) && defined(COCOAPODS_POD_AVAILABLE_GPUImage)

- (GPUImageCocoaLUTFilter *)GPUImageCocoaLUTFilter {
    return [[GPUImageCocoaLUTFilter alloc] initWithLUT:self];
}

#endif

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (UIImage *)processUIImage:(UIImage *)image withColorSpace:(CGColorSpaceRef)colorSpace {
    return [[UIImage alloc] initWithCIImage:[self processCIImage:image.CIImage]];
}
#elif TARGET_OS_MAC

- (NSImage *)processNSImage:(NSImage *)image
                 renderPath:(LUTImageRenderPath)renderPath {

    if (renderPath == LUTImageRenderPathCoreImage || renderPath == LUTImageRenderPathCoreImageSoftware) {
        NSImageRep *firstRep = [image.representations firstObject];

        if (![firstRep isKindOfClass:[NSBitmapImageRep class]]) {
            return nil;
        }

        CIImage *inputCIImage = [[CIImage alloc] initWithBitmapImageRep:(NSBitmapImageRep *)firstRep];
        CIImage *outputCIImage = [self processCIImage:inputCIImage];
        return LUTNSImageFromCIImage(outputCIImage, renderPath == LUTImageRenderPathCoreImageSoftware);
    }
    else if (renderPath == LUTImageRenderPathDirect) {
        return [self processNSImageDirectly:image];
    }

    return nil;
}

- (NSImage *)processNSImageDirectly:(NSImage *)image {

    NSBitmapImageRep *inImageRep = [image representations][0];


    int nchannels = 3;
    int bps = 16;
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                         pixelsWide:image.size.width
                                                                         pixelsHigh:image.size.height
                                                                      bitsPerSample:bps
                                                                    samplesPerPixel:nchannels
                                                                           hasAlpha:NO
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSDeviceRGBColorSpace
                                                                        bytesPerRow:(image.size.width * (bps * nchannels)) / 8
                                                                       bitsPerPixel:bps * nchannels];

    for (int x = 0; x < image.size.width; x++) {
        for (int y = 0; y < image.size.height; y++) {

            LUTColor *lutColor = [LUTColor colorWithSystemColor:[inImageRep colorAtX:x y:y]];
            LUTColor *transformedColor =[self colorAtColor:lutColor];
            [imageRep setColor:transformedColor.systemColor atX:x y:y];

        }
    }

    NSImage* outImage = [[NSImage alloc] initWithSize:image.size];
    [outImage addRepresentation:imageRep];
    return outImage;
}
#endif

@end
