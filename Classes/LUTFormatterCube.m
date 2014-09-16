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

    for(NSString *untrimmedLine in headerLines){
        NSString *titleMatch;
        NSString *line = [untrimmedLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([line rangeOfString:@"#"].location == NSNotFound){
            if ([line rangeOfString:@"LUT_3D_SIZE"].location != NSNotFound) {
                isLUT3D = YES;

                if (data[@"cubeSize"] != nil){
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Size parameter already once."
                                                 userInfo:nil];
                }

                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if(splitLine.count == 2 && stringIsValidNumber(splitLine[1])){
                    data[@"cubeSize"] = @([splitLine[1] integerValue]);

                }
                else{
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Size parameter is invalid."
                                                 userInfo:nil];
                }
            }
            else if ([line rangeOfString:@"LUT_1D_SIZE"].location != NSNotFound) {
                isLUT1D = YES;

                if (data[@"cubeSize"] != nil){
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Size parameter already once."
                                                 userInfo:nil];
                }

                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                if(splitLine.count == 2 && stringIsValidNumber(splitLine[1])){
                    data[@"cubeSize"] = @([splitLine[1] integerValue]);

                }
                else{
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Size parameter is invalid."
                                                 userInfo:nil];
                }
            }
            else if ([line rangeOfString:@"LUT_3D_INPUT_RANGE"].location != NSNotFound) {
                if (data[@"inputLowerBound"] != nil || data[@"inputUpperBound"] != nil){
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Input Bounds already defined."
                                                 userInfo:nil];
                }
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                if(splitLine.count == 3 && stringIsValidNumber(splitLine[1]) && stringIsValidNumber(splitLine[2])){
                    data[@"inputLowerBound"] = @([splitLine[1] doubleValue]);
                    data[@"inputUpperBound"] = @([splitLine[2] doubleValue]);

                    if ([splitLine[1] length] >= 14) {
                        passthroughFileOptions[@"fileTypeVariant"] = @"High Precision";
                    }
                    else{
                        passthroughFileOptions[@"fileTypeVariant"] = @"Resolve";
                    }
                }
                else{
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"INPUT_RANGE invalid."
                                                 userInfo:nil];
                }
            }
            else if ([line rangeOfString:@"LUT_1D_INPUT_RANGE"].location != NSNotFound) {

                if (data[@"inputLowerBound"] != nil || data[@"inputUpperBound"] != nil){
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Input Bounds already defined."
                                                 userInfo:nil];
                }
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                if(splitLine.count == 3 && stringIsValidNumber(splitLine[1]) && stringIsValidNumber(splitLine[2])){
                    data[@"inputLowerBound"] = @([splitLine[1] doubleValue]);
                    data[@"inputUpperBound"] = @([splitLine[2] doubleValue]);

                    if ([splitLine[1] length] >= 14) {
                        passthroughFileOptions[@"fileTypeVariant"] = @"High Precision";
                    }
                    else{
                        passthroughFileOptions[@"fileTypeVariant"] = @"Resolve";
                    }
                }
                else{
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"INPUT_RANGE invalid."
                                                 userInfo:nil];
                }


            }
            else if ([line rangeOfString:@"DOMAIN_MIN"].location != NSNotFound) {
                passthroughFileOptions[@"fileTypeVariant"] = @"Iridas/Adobe";
                if (data[@"inputLowerBound"] != nil){
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Input Bound already defined."
                                                 userInfo:nil];
                }
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if(splitLine.count == 4 && [splitLine[1] doubleValue] == [splitLine[2] doubleValue] && [splitLine[1] doubleValue] == [splitLine[3] doubleValue] && stringIsValidNumber(splitLine[1])){
                    data[@"inputLowerBound"] = @([splitLine[1] doubleValue]);
                }
                else{
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"DOMAIN_MIN invalid."
                                                 userInfo:nil];
                }


            }
            else if ([line rangeOfString:@"DOMAIN_MAX"].location != NSNotFound) {
                passthroughFileOptions[@"fileTypeVariant"] = @"Iridas/Adobe";
                if (data[@"inputUpperBound"] != nil){
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Input Bound already defined."
                                                 userInfo:nil];
                }
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if(splitLine.count == 4 && [splitLine[1] doubleValue] == [splitLine[2] doubleValue] && [splitLine[1] doubleValue] == [splitLine[3] doubleValue] && stringIsValidNumber(splitLine[1])){
                    data[@"inputUpperBound"] = @([splitLine[1] doubleValue]);
                }
                else{
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"DOMAIN_MAX invalid."
                                                 userInfo:nil];
                }

            }
            else if ((titleMatch = [line firstMatch:RX(@"(?<=TITLE \")[^\"]*(?=\")")])) {
                [title appendString:titleMatch];
            }
        }
    }


    NSUInteger cubeSize;

    if (data[@"cubeSize"] == nil) {
        NSException *exception = [NSException exceptionWithName:@"CubeLUTParseError" reason:@"Couldn't find LUT size in file" userInfo:nil];
        @throw exception;
    }
    else{
        cubeSize = [data[@"cubeSize"] integerValue];
    }

    if ((isLUT1D && isLUT3D) || (!isLUT1D && !isLUT3D)){
        @throw [NSException exceptionWithName:@"CubeLUTParseError" reason:@"Couldn't figure out if 3D or 1D LUT" userInfo:nil];
    }

    double inputLowerBound;
    double inputUpperBound;

    if(data[@"inputLowerBound"] == nil && data[@"inputUpperBound"] == nil){
        passthroughFileOptions[@"fileTypeVariant"] = @"Nuke";
        inputLowerBound = 0;
        inputUpperBound = 1;
    }
    else{
        inputLowerBound = [data[@"inputLowerBound"] doubleValue];
        inputUpperBound = [data[@"inputUpperBound"] doubleValue];
    }

    LUT *lut;

    if(isLUT3D){
        lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];

        NSUInteger currentCubeIndex = 0;
        for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {

            if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                splitLine = arrayWithEmptyElementsRemoved(splitLine);
                if (splitLine.count == 3) {
                    for(NSString *checkLine in splitLine){
                        if(stringIsValidNumber(checkLine) == NO){
                            @throw [NSException exceptionWithName:@"CubeLUTParseError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentCubeIndex+(int)cubeLinesStartIndex] userInfo:nil];
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
            @throw [NSException exceptionWithName:@"CubeLUTParseError" reason:@"Incomplete data lines" userInfo:nil];
        }
    }
    else{
        //1D LUT
        lut = [LUT1D LUTOfSize:cubeSize inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];

        NSUInteger currentLineIndex = 0;
        for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {

            if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (splitLine.count == 3) {

                    for(NSString *checkLine in splitLine){
                        if(stringIsValidNumber(checkLine) == NO){
                            @throw [NSException exceptionWithName:@"CubeLUTParseError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentLineIndex+(int)cubeLinesStartIndex] userInfo:nil];
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
            @throw [NSException exceptionWithName:@"CubeLUTParseError" reason:@"Incomplete data lines" userInfo:nil];
        }
    }

    [lut setTitle:title];
    lut.descriptionText = description;
    [lut setMetadata:metadata];
    lut.passthroughFileOptions = @{[self formatterID]:passthroughFileOptions};

    return lut;
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"CubeLUTWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }
    else{
        options = options[[self formatterID]];
    }

    NSMutableString *string = [NSMutableString stringWithString:@""];

    NSUInteger lutSize = [lut size];

    if (lut.title && lut.title.length > 0) {
        [string appendString:[NSString stringWithFormat:@"TITLE \"%@\"\r\n", lut.title]];
    }

    //metadata and description write
    [string appendString: [LUTMetadataFormatter stringFromMetadata:lut.metadata description:lut.descriptionText]];
    [string appendString:@"\r\n"];


    if(isLUT1D(lut)){
        //maybe implement writing a CUBE as 1D here?
        [string appendString:[NSString stringWithFormat:@"LUT_1D_SIZE %i\r\n", (int)lutSize]];
        NSString *formatString;

        if ([options[@"fileTypeVariant"] isEqualToString:@"High Precision"]) {
            [string appendString:[NSString stringWithFormat:@"LUT_1D_INPUT_RANGE %.12f %.12f\r\n", [lut inputLowerBound], [lut inputUpperBound]]];
            formatString = @"%.12f %.12f %.12f";
        }
        else if ([options[@"fileTypeVariant"] isEqualToString:@"Resolve"]) {
            [string appendString:[NSString stringWithFormat:@"LUT_1D_INPUT_RANGE %.6f %.6f\r\n", [lut inputLowerBound], [lut inputUpperBound]]];
            formatString = @"%.10f %.10f %.10f";
        }
        else if ([options[@"fileTypeVariant"] isEqualToString:@"Iridas/Adobe"]) {
            [string appendString:[NSString stringWithFormat:@"DOMAIN_MIN %f %f %f\r\n", [lut inputLowerBound], [lut inputLowerBound], [lut inputLowerBound]]];
            [string appendString:[NSString stringWithFormat:@"DOMAIN_MAX %f %f %f\r\n", [lut inputUpperBound], [lut inputUpperBound], [lut inputUpperBound]]];
            formatString = @"%.6f %.6f %.6f";
        }


        [string appendString:@"\r\n"];

        for (int i = 0; i < lutSize; i++){
            LUTColor *color = [lut colorAtR:i g:i b:i];

            [string appendString:[NSString stringWithFormat:formatString, color.red, color.green, color.blue]];

            if(i != lutSize - 1) {
                [string appendString:@"\r\n"];
            }
        }

    }
    else if(isLUT3D(lut)){
        [string appendString:[NSString stringWithFormat:@"LUT_3D_SIZE %i\r\n", (int)lutSize]];
        NSString *formatString;
        if ([options[@"fileTypeVariant"] isEqualToString:@"High Precision"]) {
            [string appendString:[NSString stringWithFormat:@"LUT_3D_INPUT_RANGE %.12f %.12f\r\n", [lut inputLowerBound], [lut inputUpperBound]]];
            formatString = @"%.12f %.12f %.12f";
        }
        else if ([options[@"fileTypeVariant"] isEqualToString:@"Resolve"]) {
            [string appendString:[NSString stringWithFormat:@"LUT_3D_INPUT_RANGE %.10f %.10f\r\n", [lut inputLowerBound], [lut inputUpperBound]]];
            formatString = @"%.10f %.10f %.10f";
        }
        else if ([options[@"fileTypeVariant"] isEqualToString:@"Iridas/Adobe"]) {
            [string appendString:[NSString stringWithFormat:@"DOMAIN_MIN %.6f %.6f %.6f\r\n", [lut inputLowerBound], [lut inputLowerBound], [lut inputLowerBound]]];
            [string appendString:[NSString stringWithFormat:@"DOMAIN_MAX %.6f %.6f %.6f\r\n", [lut inputUpperBound], [lut inputUpperBound], [lut inputUpperBound]]];

            formatString = @"%.6f %.6f %.6f";
        }

        [string appendString:@"\r\n"];

        NSUInteger arrayLength = lutSize * lutSize * lutSize;
        for (int i = 0; i < arrayLength; i++) {
            int redIndex = i % lutSize;
            int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
            int blueIndex = i / (lutSize * lutSize);

            LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];

            [string appendString:[NSString stringWithFormat:formatString, color.red, color.green, color.blue]];

            if(i != arrayLength - 1) {
                [string appendString:@"\r\n"];
            }

        }
    }
    //but not for now

    return string;

}

+ (NSArray *)allOptions{

    NSDictionary *nukeOptions = @{@"fileTypeVariant":@"Nuke"};

    NSDictionary *resolveOptions = @{@"fileTypeVariant":@"Resolve"};

    NSDictionary *iridasAdobeOptions = @{@"fileTypeVariant":@"Iridas/Adobe"};

    NSDictionary *highPrecisionOptions = @{@"fileTypeVariant":@"High Precision"};

    return @[resolveOptions, nukeOptions, iridasAdobeOptions, highPrecisionOptions];
}

+ (NSArray *)conformanceLUTActionsForLUT:(LUT *)lut options:(NSDictionary *)options{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[super conformanceLUTActionsForLUT:lut options:options]];
    //options are validated by superclass, no need to do that here.

    NSDictionary *exposedOptions = options[[self formatterID]];
    if ([exposedOptions[@"fileTypeVariant"] isEqualToString:@"Nuke"]) {
        if(lut.inputLowerBound != 0 || lut.inputUpperBound != 1){
            [array addObject:[LUTAction actionWithLUTByChangingInputLowerBound:0 inputUpperBound:1]];
        }
    }

    return array.count == 0 ? nil : array;
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant": @"Resolve"};
    return @{[self formatterID]:dictionary};
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

+ (NSString *)formatterID{
    return @"cube";
}

+ (NSString *)formatterName{
    return @"Cube LUT";
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
