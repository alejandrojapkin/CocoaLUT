//
//  LUTFormatterResolveDAT.m
//  Pods
//
//  Created by Greg Cotten on 8/6/14.
//
//

#import "LUTFormatterResolveDAT.h"

@implementation LUTFormatterResolveDAT

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromLines:(NSArray *)lines{
    NSUInteger cubeLinesStartIndex = findFirstLUTLineInLines(lines, @" ", 3, 0);

    if(cubeLinesStartIndex == -1){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }

    NSArray *headerLines = [lines subarrayWithRange:NSMakeRange(0, cubeLinesStartIndex)];
    NSUInteger cubeSize = -1;
    for(NSString *untrimmedLine in headerLines){
        NSString *line = [untrimmedLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([line rangeOfString:@"#"].location == NSNotFound){
            if ([line rangeOfString:@"3DLUTSIZE"].location != NSNotFound) {
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if(splitLine.count == 2 && stringIsValidNumber(splitLine[1])){
                    cubeSize = [splitLine[1] integerValue];

                }
                else{
                    @throw [NSException exceptionWithName:@"CubeLUTParseError"
                                                   reason:@"Size parameter is invalid."
                                                 userInfo:nil];
                }
            }
        }
    }

    if (cubeSize == -1) {
        cubeSize = 33;
    }

    LUT3D *lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0 inputUpperBound:1];

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

                NSUInteger blueIndex = currentCubeIndex % cubeSize;
                NSUInteger greenIndex = ( (currentCubeIndex % (cubeSize * cubeSize)) / (cubeSize) );
                NSUInteger redIndex = currentCubeIndex / (cubeSize * cubeSize);

                [lut setColor:color r:redIndex g:greenIndex b:blueIndex];

                currentCubeIndex++;
            }
        }
    }
    if(currentCubeIndex < cubeSize*cubeSize*cubeSize){
        @throw [NSException exceptionWithName:@"CubeLUTParseError" reason:@"Incomplete data lines" userInfo:nil];
    }


    lut.passthroughFileOptions = @{[self formatterID]:@{@"fileTypeVariant": @"Resolve"}};

    return lut;
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    NSMutableString *string = [[NSMutableString alloc] init];



    NSUInteger lutSize = lut.size;
    NSUInteger arrayLength = lutSize * lutSize * lutSize;

    if (lutSize != 33) {
        [string appendString:[NSString stringWithFormat:@"3DLUTSIZE %i\n\n", (int)lutSize]];
    }
    //33 size LUTs don't use keyword "3DLUTSIZE"



    for (int i = 0; i < arrayLength; i++) {
        int blueIndex = i % lutSize;
        int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
        int redIndex = i / (lutSize * lutSize);

        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];

        [string appendString:[NSString stringWithFormat:@"%.6f %.6f %.6f", color.red, color.green, color.blue]];


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
    if (string == nil) {
        return NO;
    }
    if([string rangeOfString:@"3DLUTSIZE"].location != NSNotFound){
        return YES;
    }
    else{
        NSArray *lines = [string componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
        NSUInteger firstLUTLine = findFirstLUTLineInLinesWithWhitespaceSeparators(lines, 3, 0);
        if (firstLUTLine == 0) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)formatterName{
    return @"Resolve DAT 3D LUT";
}

+ (NSString *)formatterID{
    return @"resolveDAT";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSString *)utiString{
    return @"public.dat-lut";
}

+ (NSArray *)fileExtensions{
    return @[@"dat"];
}

+ (NSArray *)allOptions{

    NSDictionary *options = @{@"fileTypeVariant":@"Resolve"};

    return @[options];

}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant":@"Resolve"};
    
    return @{[self formatterID]: dictionary};
}

@end
