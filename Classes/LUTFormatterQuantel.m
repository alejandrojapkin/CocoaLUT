//
//  LUTFormatterQuantel.m
//  Pods
//
//  Created by Greg Cotten on 7/14/14.
//
//

#import "LUTFormatterQuantel.h"

@implementation LUTFormatterQuantel

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromLines:(NSArray *)lines{

    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];
    passthroughFileOptions[@"fileTypeVariant"] = @"Quantel";

    NSUInteger __block cubeSize = 0;
    NSUInteger  __block integerMaxOutput = 0;

    NSInteger cubeLinesStartIndex = findFirstLUTLineInLines(lines, @" ", 3, 0);

    if(cubeLinesStartIndex == -1){
        @throw [NSException exceptionWithName:@"3DLReadError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }

    NSArray *headerLines = [lines subarrayWithRange:NSMakeRange(0, cubeLinesStartIndex)];

    for(NSString *line in headerLines) {
        if ([line rangeOfString:@"max value"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            integerMaxOutput = [components[2] integerValue];
        }
        if ([line rangeOfString:@"vertices"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            cubeSize = [components[1] integerValue];
        }

    }

    if (cubeSize <= 0 || integerMaxOutput <= 0) {
        NSException *exception = [NSException exceptionWithName:@"QuantelReadError" reason:@"Size or Max Output invalid." userInfo:nil];
        @throw exception;
    }

    passthroughFileOptions[@"lutSize"] = @(cubeSize);
    passthroughFileOptions[@"integerMaxOutput"] = @(integerMaxOutput);



    LUT3D *lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
    NSUInteger currentCubeIndex = 0;
    for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {

        if (line.length > 0) {
            NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = arrayWithEmptyElementsRemoved(splitLine);
            if (splitLine.count == 3) {

                for(NSString *checkLine in splitLine){
                    if(stringIsValidNumber(checkLine) == NO){
                        @throw [NSException exceptionWithName:@"QuantelReadError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentCubeIndex+(int)cubeLinesStartIndex] userInfo:nil];
                    }
                }

                // Valid cube line
                LUTColorValue redValue      = ((NSString *)splitLine[0]).doubleValue;
                LUTColorValue greenValue    = ((NSString *)splitLine[1]).doubleValue;
                LUTColorValue blueValue     = ((NSString *)splitLine[2]).doubleValue;

                LUTColor *color = [LUTColor colorFromIntegersWithMaxOutputValue:integerMaxOutput red:redValue green:greenValue blue:blueValue];

                NSUInteger redIndex     = currentCubeIndex / (cubeSize * cubeSize);
				NSUInteger greenIndex   = (currentCubeIndex % (cubeSize * cubeSize)) / cubeSize;
				NSUInteger blueIndex    = currentCubeIndex % cubeSize;

                [lut setColor:color r:redIndex g:greenIndex b:blueIndex];
                
                currentCubeIndex++;
            }
        }
    }
    lut.passthroughFileOptions = @{[self formatterID]:passthroughFileOptions};
    return lut;
}

+(NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"QuantelWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }
    else{
        options = options[[self formatterID]];
    }



    //validate options


    NSUInteger integerMaxOutput;
    NSUInteger lutSize;

    integerMaxOutput = [options[@"integerMaxOutput"] integerValue];
    lutSize = [options[@"lutSize"] integerValue];


    NSMutableString *string = [NSMutableString stringWithFormat:@"max value %i\nvertices %i\n", (int)integerMaxOutput, (int)lutSize];

    [string appendString:@"blue is fastest changing\n"];
    [string appendString:@"red is slowest changing\n\n"];
    [string appendString:@"cube data\n"];
    [string appendString:@"R G B\n"];

    NSUInteger arrayLength = lutSize * lutSize * lutSize;
    for (int i = 0; i < arrayLength; i++) {
        int redIndex = i / (lutSize * lutSize);
        int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
        int blueIndex = i % lutSize;

        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];


        [string appendString:[NSString stringWithFormat:@"%i %i %i", (int)(color.red*(double)integerMaxOutput), (int)(color.green*(double)integerMaxOutput), (int)(color.blue*(double)integerMaxOutput)]];

        if(i != arrayLength - 1) {
            [string appendString:@"\n"];
        }
        
    }

    return string;
}


+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType3D;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if ([super isValidReaderForURL:fileURL] == NO) {
        return NO;
    }
    NSString *string = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:fileURL] encoding:NSUTF8StringEncoding];
    if([string rangeOfString:@"blue is fastest changing"].location != NSNotFound){
        return YES;
    }
    return NO;
}

+ (NSString *)formatterName{
    return @"Quantel 3D LUT";
}

+ (NSString *)formatterID{
    return @"quantel";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSString *)utiString{
    return @"public.text";
}

+ (NSArray *)fileExtensions{
    return @[@"txt"];
}

+ (NSArray *)allOptions{

    NSDictionary *options = @{@"fileTypeVariant":@"Quantel",
                              @"integerMaxOutput": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"12-bit": @(maxIntegerFromBitdepth(12))},
  @{@"16-bit": @(maxIntegerFromBitdepth(16))}]),
                              @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"17": @(17)},
                                                                                                 @{@"33": @(33)},
                                                                                                 @{@"65": @(65)}])};

    return @[options];
    
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant": @"Quantel",
                                 @"integerMaxOutput": @(maxIntegerFromBitdepth(16)),
                                 @"lutSize": @(33)};
    
    return @{[self formatterID]: dictionary};
}

@end
