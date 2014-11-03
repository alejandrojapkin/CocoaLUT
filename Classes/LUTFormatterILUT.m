//
//  LUTFormatterILUT.m
//  Pods
//
//  Created by Greg Cotten on 4/9/14.
//
//

#import "LUTFormatterILUT.h"

@implementation LUTFormatterILUT

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromLines:(NSArray *)lines {

    NSMutableArray *redCurve = [NSMutableArray array];
    NSMutableArray *greenCurve = [NSMutableArray array];
    NSMutableArray *blueCurve = [NSMutableArray array];



    NSMutableArray *trimmedLines = [NSMutableArray array];

    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(trimmedLine.length > 0){
            [trimmedLines addObject:trimmedLine];
        }
    }

    NSUInteger maxCodeValue = maxIntegerFromBitdepth(14);


    for (NSString *line in trimmedLines) {
        NSArray *splitLine = [line componentsSeparatedByString:@","];
        splitLine = arrayWithEmptyElementsRemoved(splitLine);
        for(NSString *checkLine in splitLine){
            if(stringIsValidNumber(checkLine) == NO){
                @throw [NSException exceptionWithName:@"LUTParserError" reason:[NSString stringWithFormat:@"NaN detected in LUT"] userInfo:nil];
            }
        }

        [redCurve addObject:@(nsremapint01([splitLine[0] integerValue], maxCodeValue))];
        [greenCurve addObject:@(nsremapint01([splitLine[1] integerValue], maxCodeValue))];
        [blueCurve addObject:@(nsremapint01([splitLine[2] integerValue], maxCodeValue))];
    }

    LUT1D *lut = [LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve lowerBound:0 upperBound:1];
    lut.passthroughFileOptions = @{[self formatterID]:@{}};
    return lut;
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {

    NSMutableString *string = [NSMutableString stringWithString:@""];

    LUT1D *lut1D = (LUT1D *)lut;

    NSUInteger maxIntegerOutput = maxIntegerFromBitdepth(14);
    for (int i = 0; i < pow(2, 14); i++){
        int red = (int)(clamp01([lut1D valueAtR:i])*(double)maxIntegerOutput);
        int green = (int)(clamp01([lut1D valueAtG:i])*(double)maxIntegerOutput);
        int blue = (int)(clamp01([lut1D valueAtB:i])*(double)maxIntegerOutput);
        [string appendString:[NSString stringWithFormat:@"%d,%d,%d,%d\n", red, green, blue, 0]];
    }

    return string;

}



+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType1D;
}

+ (NSArray *)allOptions{

    NSDictionary *options = @{@"fileTypeVariant":@"ILUT",
                              @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"16384": @(16384)}])};

    return @[options];

}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant":@"ILUT",
                                 @"lutSize": @(16384)};

    return @{[self formatterID]: dictionary};
}

+ (NSString *)utiString{
    return @"com.blackmagicdesign.ilut";
}

+ (NSArray *)fileExtensions{
    return @[@"ilut"];
}

+ (NSString *)formatterName{
    return @"Blackmagic Design 1D LUT";
}

+ (NSString *)formatterID{
    return @"ilut";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

@end
