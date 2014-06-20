//
//  LUTFormatterCube.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTFormatterCube.h"

#import <RegExCategories/RegExCategories.h>

@implementation LUTFormatterCube

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromLines:(NSArray *)lines {
    NSMutableString __block *title = [NSMutableString stringWithString:@""];
    NSString *description;
    NSMutableDictionary *metadata;
    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];

    NSUInteger __block cubeSize = 0;
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    BOOL __block isLUT3D = NO;
    BOOL __block isLUT1D = NO;
    
    NSUInteger cubeLinesStartIndex = findFirstLUTLineInLines(lines, @" ", 3, 0);
    
    if(cubeLinesStartIndex == -1){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }
    
    NSArray *headerLines = [lines subarrayWithRange:NSMakeRange(0, cubeLinesStartIndex)];
    
    NSDictionary *metadataAndDescription = [LUTMetadataFormatter metadataAndDescriptionFromLines:headerLines];
    metadata = metadataAndDescription[@"metadata"];
    description = metadataAndDescription[@"description"];
    
    for(NSString *line in headerLines){
        NSString *titleMatch;
        if ([line rangeOfString:@"LUT_3D_SIZE"].location != NSNotFound) {
            isLUT3D = YES;
            NSString *sizeString = [line componentsSeparatedByString:@" "][1];
            cubeSize = sizeString.integerValue;
        }
        else if ([line rangeOfString:@"LUT_1D_SIZE"].location != NSNotFound) {
            isLUT1D = YES;
            NSString *sizeString = [line componentsSeparatedByString:@" "][1];
            cubeSize = sizeString.integerValue;
        }
        else if ([line rangeOfString:@"LUT_3D_INPUT_RANGE"].location != NSNotFound) {
            data[@"inputLowerBound"] = @([[line componentsSeparatedByString:@" "][1] doubleValue]);
            data[@"inputUpperBound"] = @([[line componentsSeparatedByString:@" "][2] doubleValue]);
        }
        else if ([line rangeOfString:@"LUT_1D_INPUT_RANGE"].location != NSNotFound) {
            data[@"inputLowerBound"] = @([[line componentsSeparatedByString:@" "][1] doubleValue]);
            data[@"inputUpperBound"] = @([[line componentsSeparatedByString:@" "][2] doubleValue]);
        }
        else if ((titleMatch = [line firstMatch:RX(@"(?<=TITLE \")[^\"]*(?=\")")])) {
            [title appendString:titleMatch];
        }
    }
    
    if (cubeSize == 0) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError" reason:@"Couldn't find LUT size in file" userInfo:nil];
        @throw exception;
    }
    
    if ((isLUT1D && isLUT3D) || (!isLUT1D && !isLUT3D)){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't figure out if 3D or 1D LUT" userInfo:nil];
    }
    
    
    
    LUT *lut;
    
    if(isLUT3D){
        if(data[@"inputLowerBound"] != nil){
            lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:[data[@"inputLowerBound"] doubleValue] inputUpperBound:[data[@"inputUpperBound"] doubleValue]];
            passthroughFileOptions[@"fileTypeVariant"] = @"Resolve";

        }
        else{
            //assume 0-1 input
            passthroughFileOptions[@"fileTypeVariant"] = @"Nuke";
            lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
        }
        
        NSUInteger currentCubeIndex = 0;
        for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {
            
            if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
                NSArray *splitLine = [line componentsSeparatedByString:@" "];
                if (splitLine.count == 3) {
                    for(NSString *checkLine in splitLine){
                        if(stringIsValidNumber(checkLine) == NO){
                            @throw [NSException exceptionWithName:@"LUTParserError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentCubeIndex+(int)cubeLinesStartIndex] userInfo:nil];
                        }
                    }
                    
                    // Valid cube line
                    LUTColorValue redValue = ((NSString *)splitLine[0]).doubleValue;
                    LUTColorValue greenValue = ((NSString *)splitLine[1]).doubleValue;
                    LUTColorValue blueValue = ((NSString *)splitLine[2]).doubleValue;
                    
                    LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];
                    
                    NSUInteger redIndex = currentCubeIndex % cubeSize;
                    NSUInteger greenIndex = ( (currentCubeIndex % (cubeSize * cubeSize)) / (cubeSize) );
                    NSUInteger blueIndex = currentCubeIndex / (cubeSize * cubeSize);
                    
                    [lut setColor:color r:redIndex g:greenIndex b:blueIndex];
                    
                    currentCubeIndex++;
                }
            }
        }
        if(currentCubeIndex < cubeSize*cubeSize*cubeSize){
            @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Incomplete data lines" userInfo:nil];
        }
    }
    else{
        //1D LUT
        if(data[@"inputLowerBound"] != nil){
            passthroughFileOptions[@"fileTypeVariant"] = @"Resolve";
            lut = [LUT1D LUTOfSize:cubeSize inputLowerBound:[data[@"inputLowerBound"] doubleValue] inputUpperBound:[data[@"inputUpperBound"] doubleValue]];
        }
        else{
            //assume 0-1 input
            passthroughFileOptions[@"fileTypeVariant"] = @"Nuke";
            lut = [LUT1D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
        }
        
        NSUInteger currentLineIndex = 0;
        for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {
            
            if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
                NSArray *splitLine = [line componentsSeparatedByString:@" "];
                if (splitLine.count == 3) {
                    
                    for(NSString *checkLine in splitLine){
                        if(stringIsValidNumber(checkLine) == NO){
                            @throw [NSException exceptionWithName:@"LUTParserError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentLineIndex+(int)cubeLinesStartIndex] userInfo:nil];
                        }
                    }
                    
                    // Valid cube line
                    LUTColorValue redValue = ((NSString *)splitLine[0]).doubleValue;
                    LUTColorValue greenValue = ((NSString *)splitLine[1]).doubleValue;
                    LUTColorValue blueValue = ((NSString *)splitLine[2]).doubleValue;
                    
                    LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];
                    
                    [lut setColor:color r:currentLineIndex g:currentLineIndex b:currentLineIndex];
                    
                    currentLineIndex++;
                }
            }
        }
        if(currentLineIndex < cubeSize){
            @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Incomplete data lines" userInfo:nil];
        }
    }

    [lut setTitle:title];
    lut.descriptionText = description;
    [lut setMetadata:metadata];
    lut.passthroughFileOptions = @{[self utiString]:passthroughFileOptions};

    return lut;
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"CubeWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }
    else{
        options = options[[self utiString]];
    }
    
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    NSUInteger lutSize = [lut size];
    
    if (lut.title && lut.title.length > 0) {
        [string appendString:[NSString stringWithFormat:@"TITLE \"%@\"\n", lut.title]];
    }
    
    
    //metadata and description write
    [string appendString: [LUTMetadataFormatter stringFromMetadata:lut.metadata description:lut.descriptionText]];
    [string appendString:@"\n"];
    
    if(isLUT1D(lut)){
        //maybe implement writing a CUBE as 1D here?
        [string appendString:[NSString stringWithFormat:@"LUT_1D_SIZE %i\n", (int)lutSize]];
        
        if (![options[@"fileTypeVariant"] isEqualToString:@"Nuke"]) {
            [string appendString:[NSString stringWithFormat:@"LUT_1D_INPUT_RANGE %.10f %.10f\n", [lut inputLowerBound], [lut inputUpperBound]]];
        }
        
        
        [string appendString:@"\n"];
        
        for (int i = 0; i < lutSize; i++){
            LUTColor *color = [lut colorAtR:i g:i b:i];
            [string appendString:[NSString stringWithFormat:@"%.10f %.10f %.10f", color.red, color.green, color.blue]];
            if(i != lutSize - 1) {
                [string appendString:@"\n"];
            }
        }
        
    }
    else if(isLUT3D(lut)){
        [string appendString:[NSString stringWithFormat:@"LUT_3D_SIZE %i\n", (int)lutSize]];
        
        if (![options[@"fileTypeVariant"] isEqualToString:@"Nuke"]) {
        [string appendString:[NSString stringWithFormat:@"LUT_3D_INPUT_RANGE %.6f %.6f\n", [lut inputLowerBound], [lut inputUpperBound]]];
        }
        
        [string appendString:@"\n"];
        
        NSUInteger arrayLength = lutSize * lutSize * lutSize;
        for (int i = 0; i < arrayLength; i++) {
            int redIndex = i % lutSize;
            int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
            int blueIndex = i / (lutSize * lutSize);
            
            LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];
            
            [string appendString:[NSString stringWithFormat:@"%.6f %.6f %.6f", color.red, color.green, color.blue]];
            
            if(i != arrayLength - 1) {
                [string appendString:@"\n"];
            }
            
        }
    }
    //but not for now
    
    return string;

}

+ (NSArray *)allOptions{
    
    NSDictionary *nukeOptions = @{@"fileTypeVariant":@"Nuke"};
    
    NSDictionary *resolveOptions = @{@"fileTypeVariant":@"Resolve"};
    
    return @[resolveOptions, nukeOptions];
}

+ (NSArray *)LUTActionsForLUT:(LUT *)lut options:(NSDictionary *)options{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[super LUTActionsForLUT:lut options:options]];
    //options are validated by superclass, no need to do that here.
    
    NSDictionary *exposedOptions = options[[self utiString]];
    if ([exposedOptions[@"fileTypeVariant"] isEqualToString:@"Nuke"]) {
        if(lut.inputLowerBound != 0 || lut.inputUpperBound != 1){
            [array addObject:[LUTAction actionWithLUTByChangingInputLowerBound:0 inputUpperBound:1]];
        }
    }
    
    return array.count == 0 ? nil : array;
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant": @"Resolve"};
    return @{[self utiString]:dictionary};
}



+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputTypeEither;
}

+ (NSString *)utiString{
    return @"com.blackmagicdesign.cube";
}

+ (NSArray *)fileExtensions{
    return @[@"cube"];
}

+ (NSString *)formatterName{
    return @"DaVinci Resolve Cube LUT";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSDictionary *)constantConstraints{
    return @{@"outputBounds":@[[NSNull null], [NSNull null]]};
}

@end
