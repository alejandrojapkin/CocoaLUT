//
//  LUTFormatterNucodaCMS.m
//  Pods
//
//  Created by Greg Cotten on 7/20/14.
//
//

#import "LUTFormatterNucodaCMS.h"

#import <RegExCategories/RegExCategories.h>

@implementation LUTFormatterNucodaCMS

+ (void)load{
    [super load];
}

+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    return [[self stringFromLUT:lut withOptions:options] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
}

+ (LUT *)LUTFromLines:(NSArray *)lines {
    lines = arrayWithEmptyElementsRemoved(lines);
    NSMutableString __block *title = [NSMutableString stringWithString:@""];
    NSString *description;
    NSMutableDictionary *metadata;
    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    NSUInteger cubeLinesStartIndex = findFirstLUTLineInLinesWithWhitespaceSeparators(lines, 3, 0);

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
            if ([line rangeOfString:@"NUCODA_3D_CUBE"].location != NSNotFound) {
                if (data[@"version"] != nil){
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"Version parameter read already once."
                                                 userInfo:nil];
                }

                NSArray *splitLine = arrayWithEmptyElementsRemoved([line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);

                if(splitLine.count == 2 && stringIsValidNumber(splitLine[1])){
                    if ([splitLine[1] integerValue] < 1 || [splitLine[1] integerValue] > 3) {
                        @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                       reason:@"Version must be 1, 2, or 3."
                                                     userInfo:nil];
                    }
                    data[@"version"] = @([splitLine[1] integerValue]);

                }
                else{
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"Version parameter is invalid."
                                                 userInfo:nil];
                }
            }
            if ([line rangeOfString:@"LUT_3D_SIZE"].location != NSNotFound) {
                if (data[@"lut3DSize"] != nil){
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"3D Size parameter read already once."
                                                 userInfo:nil];
                }

                data[@"useLUT3D"] = [NSNumber numberWithBool:YES];

                NSArray *splitLine = arrayWithEmptyElementsRemoved([line componentsSeparatedByString:@" "]);

                if(splitLine.count == 2 && stringIsValidNumber(splitLine[1])){
                    data[@"lut3DSize"] = @([splitLine[1] integerValue]);

                }
                else{
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"1D Size parameter is invalid."
                                                 userInfo:nil];
                }
            }
            else if ([line rangeOfString:@"LUT_1D_SIZE"].location != NSNotFound) {

                if (data[@"lut1DSize"] != nil){
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"1D Size parameter read already once."
                                                 userInfo:nil];
                }
                data[@"useLUT1D"] = [NSNumber numberWithBool:YES];
                NSArray *splitLine = arrayWithEmptyElementsRemoved([line componentsSeparatedByString:@" "]);

                if(splitLine.count == 2 && stringIsValidNumber(splitLine[1])){
                    data[@"lut1DSize"] = @([splitLine[1] integerValue]);

                }
                else{
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"Size parameter is invalid."
                                                 userInfo:nil];
                }
            }
            else if ([line rangeOfString:@"LUT_3D_INPUT_RANGE"].location != NSNotFound) {
                if (data[@"lut3DInputLowerBound"] != nil || data[@"lut3DInputUpperBound"] != nil){
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"3D Input Bounds already defined."
                                                 userInfo:nil];
                }
                NSArray *splitLine = arrayWithEmptyElementsRemoved([line componentsSeparatedByString:@" "]);

                if(splitLine.count == 3 && stringIsValidNumber(splitLine[1]) && stringIsValidNumber(splitLine[2])){
                    data[@"lut3DInputLowerBound"] = @([splitLine[1] doubleValue]);
                    data[@"lut3DInputUpperBound"] = @([splitLine[2] doubleValue]);
                }
                else{
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"3D INPUT_RANGE invalid."
                                                 userInfo:nil];
                }
            }
            else if ([line rangeOfString:@"LUT_1D_INPUT_RANGE"].location != NSNotFound) {
                if (data[@"lut1DInputLowerBound"] != nil || data[@"lut1DInputUpperBound"] != nil){
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"1D Input Bounds already defined."
                                                 userInfo:nil];
                }
                NSArray *splitLine = arrayWithEmptyElementsRemoved([line componentsSeparatedByString:@" "]);

                if(splitLine.count == 3 && stringIsValidNumber(splitLine[1]) && stringIsValidNumber(splitLine[2])){
                    data[@"lut1DInputLowerBound"] = @([splitLine[1] doubleValue]);
                    data[@"lut1DInputUpperBound"] = @([splitLine[2] doubleValue]);
                }
                else{
                    @throw [NSException exceptionWithName:@"NucodaLUTParseError"
                                                   reason:@"INPUT_RANGE invalid."
                                                 userInfo:nil];
                }


            }
            else if ((titleMatch = [line firstMatch:RX(@"(?<=TITLE \")[^\"]*(?=\")")])) {
                [title appendString:titleMatch];
            }
        }
    }

    BOOL use1D = data[@"useLUT1D"] == nil ? NO : [data[@"useLUT1D"] boolValue];
    BOOL use3D = data[@"useLUT3D"] == nil ? NO : [data[@"useLUT3D"] boolValue];

    NSUInteger nucodaVersion = [data[@"version"] integerValue];


    NSUInteger lut1DSize = data[@"lut1DSize"] == nil ? 0 : [data[@"lut1DSize"] integerValue];
    NSUInteger lut3DSize = data[@"lut3DSize"] == nil ? 0 : [data[@"lut3DSize"] integerValue];

    double lut1DInputLowerBound = 0;
    double lut1DInputUpperBound = 0;

    double lut3DInputLowerBound = 0;
    double lut3DInputUpperBound = 0;

    if (nucodaVersion == 1 || nucodaVersion == 2) {
        lut1DInputLowerBound = 0;
        lut1DInputUpperBound = 1;
        lut3DInputLowerBound = 0;
        lut3DInputUpperBound = 1;
    }
    if (nucodaVersion == 3) {
        if (use1D) {
            if (data[@"lut1DInputLowerBound"] == nil || data[@"lut1DInputUpperBound"] == nil) {
                @throw [NSException exceptionWithName:@"NucodaLUTParseError" reason:@"Couldn't find 1D Input Bounds" userInfo:nil];
            }
            lut1DInputLowerBound = [data[@"lut1DInputLowerBound"] doubleValue];
            lut1DInputUpperBound = [data[@"lut1DInputUpperBound"] doubleValue];
        }
        if (use3D) {
            if (data[@"lut3DInputLowerBound"] == nil || data[@"lut3DInputUpperBound"] == nil) {
                @throw [NSException exceptionWithName:@"NucodaLUTParseError" reason:@"Couldn't find 3D Input Bounds" userInfo:nil];
            }
            lut3DInputLowerBound = [data[@"lut3DInputLowerBound"] doubleValue];
            lut3DInputUpperBound = [data[@"lut3DInputUpperBound"] doubleValue];
        }
    }


    passthroughFileOptions[@"fileTypeVariant"] = [NSString stringWithFormat:@"Nucoda v%i", (int)nucodaVersion];

    NSArray *lutLines = [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)];

    LUT *outLUT;



    if (use1D && use3D) {
        LUT1D *lut1D = [LUT1D LUTOfSize:lut1DSize inputLowerBound:lut1DInputLowerBound inputUpperBound:lut1DInputUpperBound];
        LUT3D *lut3D = [LUT3D LUTOfSize:lut3DSize inputLowerBound:lut3DInputLowerBound inputUpperBound:lut3DInputUpperBound];


        NSArray *lut1DLines = [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lut1D.size)];
        NSArray *lut3DLines = [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex+lut1D.size, lutLines.count - lut1D.size)];

        lut1D = [self lut1DFromLines:lut1DLines blankLUT:lut1D];
        lut3D = [self lut3DFromLines:lut3DLines blankLUT:lut3D];

        if (nucodaVersion == 1) {
            //strange stuff
            lut1D = [lut1D LUTByRemappingValuesWithInputLow:0
                                                  inputHigh:lut3DSize
                                                  outputLow:0
                                                 outputHigh:1
                                                    bounded:NO];
        }
        passthroughFileOptions[@"lutType"] = @"Pre-LUT and LUT";
        outLUT = [lut1D LUTByCombiningWithLUT:lut3D];
    }
    else if(use1D && !use3D){
        //1D only
        LUT1D *lut1D = [LUT1D LUTOfSize:lut1DSize inputLowerBound:lut1DInputLowerBound inputUpperBound:lut1DInputUpperBound];

        NSArray *lut1DLines = [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lut1D.size)];
        passthroughFileOptions[@"lutType"] = @"No Pre-LUT";
        outLUT = [self lut1DFromLines:lut1DLines blankLUT:lut1D];

    }
    else if (!use1D && use3D){
        //3D only
        LUT3D *lut3D = [LUT3D LUTOfSize:lut3DSize inputLowerBound:lut3DInputLowerBound inputUpperBound:lut3DInputUpperBound];

        NSArray *lut3DLines = [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lut3D.size*lut3D.size*lut3D.size)];
        passthroughFileOptions[@"lutType"] = @"No Pre-LUT";
        outLUT = [self lut3DFromLines:lut3DLines blankLUT:lut3D];
    }
    

    outLUT.title = title;
    outLUT.descriptionText = description;
    outLUT.metadata = metadata;

    outLUT.passthroughFileOptions = @{[self formatterID]:passthroughFileOptions};

    return outLUT;
}

+ (BOOL)isDestructiveWithOptions:(NSDictionary *)options{
    options = options[[self formatterID]];
    if ([options[@"lutType"] isEqualToString:@"Pre-LUT and LUT"]) {
        return YES;
    }
    return NO;
}

+ (LUT1D *)lut1DFromLines:(NSArray *)lut1DLines blankLUT:(LUT1D *)blankLUT1D{
    LUT1D *lut1D = [blankLUT1D copy];
    NSUInteger currentLUTLineIndex = 0;
    for (NSString *line in lut1DLines) {
        if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
            NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = arrayWithEmptyElementsRemoved(splitLine);
            if (splitLine.count == 3) {
                for(NSString *checkLine in splitLine){
                    if(stringIsValidNumber(checkLine) == NO){
                        @throw [NSException exceptionWithName:@"NucodaLUTParseError" reason:[NSString stringWithFormat:@"NaN detected at 1D line %i", (int)currentLUTLineIndex] userInfo:nil];
                    }
                }

                // Valid cube line
                LUTColorValue redValue = ((NSString *)splitLine[0]).doubleValue;
                LUTColorValue greenValue = ((NSString *)splitLine[1]).doubleValue;
                LUTColorValue blueValue = ((NSString *)splitLine[2]).doubleValue;

                LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];



                [lut1D setColor:color r:currentLUTLineIndex g:currentLUTLineIndex b:currentLUTLineIndex];

                currentLUTLineIndex++;
            }
        }
    }
    if(currentLUTLineIndex < lut1D.size){
        @throw [NSException exceptionWithName:@"NucodaLUTParseError" reason:@"Incomplete data lines in 1D" userInfo:nil];
    }

    return lut1D;
}

+ (LUT3D *)lut3DFromLines:(NSArray *)lut3DLines blankLUT:(LUT3D *)blankLUT3D{
    LUT3D *lut3D = [blankLUT3D copy];
    NSUInteger currentLUTLineIndex = 0;
    for (NSString *line in lut3DLines) {
        if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
            NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = arrayWithEmptyElementsRemoved(splitLine);
            if (splitLine.count == 3) {
                for(NSString *checkLine in splitLine){
                    if(stringIsValidNumber(checkLine) == NO){
                        @throw [NSException exceptionWithName:@"NucodaLUTParseError" reason:[NSString stringWithFormat:@"NaN detected at 3D line %i", (int)currentLUTLineIndex] userInfo:nil];
                    }
                }

                // Valid cube line
                LUTColorValue redValue = ((NSString *)splitLine[0]).doubleValue;
                LUTColorValue greenValue = ((NSString *)splitLine[1]).doubleValue;
                LUTColorValue blueValue = ((NSString *)splitLine[2]).doubleValue;

                LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];

                NSUInteger redIndex = currentLUTLineIndex % lut3D.size;
                NSUInteger greenIndex = ( (currentLUTLineIndex % (lut3D.size * lut3D.size)) / (lut3D.size) );
                NSUInteger blueIndex = currentLUTLineIndex / (lut3D.size * lut3D.size);

                [lut3D setColor:color r:redIndex g:greenIndex b:blueIndex];

                currentLUTLineIndex++;
            }
        }
    }
    if(currentLUTLineIndex < lut3D.size){
        @throw [NSException exceptionWithName:@"NucodaLUTParseError" reason:@"Incomplete data lines in 3D" userInfo:nil];
    }

    return lut3D;
}


+ (NSString *)lutStringFromLUT:(LUT *)lut{
    NSMutableString *string = [[NSMutableString alloc] init];
    if (isLUT1D(lut)) {

        for (int i = 0; i < lut.size; i++) {
            LUTColor *color = [lut colorAtR:i g:i b:i];
            [string appendString:[NSString stringWithFormat:@"%.6f  %.6f  %.6f", color.red, color.green, color.blue]];
            if(i != lut.size - 1) {
                [string appendString:@"\n"];
            }
        }

        return string;
    }
    else{
        //it's 3D
        NSUInteger arrayLength = lut.size * lut.size * lut.size;
        for (int i = 0; i < arrayLength; i++) {
            int redIndex = i % lut.size;
            int greenIndex = ((i % (lut.size * lut.size)) / (lut.size) );
            int blueIndex = i / (lut.size * lut.size);

            LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];

            [string appendString:[NSString stringWithFormat:@"%.6f  %.6f  %.6f", color.red, color.green, color.blue]];

            if(i != arrayLength - 1) {
                [string appendString:@"\n"];
            }
            
        }

        return string;
    }
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"CubeLUTWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }
    else{
        options = options[[self formatterID]];
    }


    NSMutableString *string = [[NSMutableString alloc] init];

    //metadata and description write
    [string appendString: [LUTMetadataFormatter stringFromMetadata:lut.metadata description:lut.descriptionText]];
    [string appendString:@" \n"];

    NSUInteger nucodaVersion = 0;
    if ([options[@"fileTypeVariant"] isEqualToString:@"Nucoda v1"]) {
        nucodaVersion = 1;
    }
    else if ([options[@"fileTypeVariant"] isEqualToString:@"Nucoda v2"]) {
        nucodaVersion = 2;
    }
    else if ([options[@"fileTypeVariant"] isEqualToString:@"Nucoda v3"]) {
        nucodaVersion = 3;
    }

    [string appendString:[NSString stringWithFormat:@"NUCODA_3D_CUBE %i\n\n", (int)nucodaVersion]];

    if (lut.title && lut.title.length > 0) {
        [string appendString:[NSString stringWithFormat:@"TITLE \"%@\"\n\n", lut.title]];
    }

    if (isLUT1D(lut)) {
        [string appendString:[NSString stringWithFormat:@"LUT_1D_SIZE %i\n", (int)lut.size]];
        if (nucodaVersion == 3) {
            [string appendString:[NSString stringWithFormat:@"LUT_1D_INPUT_RANGE %.3f %.3f\n", lut.inputLowerBound, lut.inputUpperBound]];
        }
    }
    else{
        //3D
        [string appendString:[NSString stringWithFormat:@"LUT_3D_SIZE %i\n", (int)lut.size]];
        if (nucodaVersion == 3) {
            [string appendString:[NSString stringWithFormat:@"LUT_3D_INPUT_RANGE %.3f %.3f\n", lut.inputLowerBound, lut.inputUpperBound]];
        }
    }

    [string appendString:@"\n"];

    [string appendString:[self lutStringFromLUT:lut]];

    [string appendString:@"\n"];

    return string;
}

+ (NSArray *)allOptions{

    NSDictionary *v1Options = @{@"fileTypeVariant":@"Nucoda v1"};

    NSDictionary *v2Options = @{@"fileTypeVariant":@"Nucoda v2"};

    NSDictionary *v3Options = @{@"fileTypeVariant":@"Nucoda v3"};

    return @[v3Options, v2Options, v1Options];
}


+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant": @"Nucoda v3"};
    return @{[self formatterID]:dictionary};
}


+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputTypeEither;
}

+ (NSString *)utiString{
    return @"se.digitalvision.cms";
}

+ (NSArray *)fileExtensions{
    return @[@"cms"];
}

+ (NSString *)formatterID{
    return @"nucoda";
}

+ (NSString *)formatterName{
    return @"Nucoda CMS LUT";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}


@end
