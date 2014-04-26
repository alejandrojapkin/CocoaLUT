//
//  LUTFormatterOLUT.m
//  Pods
//
//  Created by Greg Cotten on 3/5/14.
//
//

#import "LUTFormatterOLUT.h"


@implementation LUTFormatterOLUT

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
    
    NSUInteger maxCodeValue = pow(2,12) - 1;
    
    for (NSString *line in trimmedLines) {
        NSArray *splitLine = [line componentsSeparatedByString:@","];
        [redCurve addObject:@(nsremapint01([splitLine[0] integerValue], maxCodeValue))];
        [greenCurve addObject:@(nsremapint01([splitLine[1] integerValue], maxCodeValue))];
        [blueCurve addObject:@(nsremapint01([splitLine[2] integerValue], maxCodeValue))];
    }
    
    return [LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve lowerBound:0 upperBound:1];
}

+ (NSString *)stringFromLUT:(LUT *)lut {
    
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    LUT1D *lut1D = LUTAsLUT1D(lut, pow(2,12), LUT1DExtractionMethodUniqueRGB);
    
    
    for (int i = 0; i < pow(2,12); i++){
        int red = (int)(clamp01([lut1D valueAtR:i])*(double)pow(2,12));
        int green = (int)(clamp01([lut1D valueAtG:i])*(double)pow(2,12));
        int blue = (int)(clamp01([lut1D valueAtB:i])*(double)pow(2,12));
        [string appendString:[NSString stringWithFormat:@"%d,%d,%d,%d,%d,%d\n", red, green, blue, red, green, blue]];
    }
    
    return string;
    
}

@end
