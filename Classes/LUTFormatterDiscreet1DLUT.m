//
//  LUTFormatterDiscreet1DLUT.m
//  Pods
//
//  Created by Greg Cotten on 3/5/14.
//
//

#import "LUTFormatterDiscreet1DLUT.h"

@implementation LUTFormatterDiscreet1DLUT

+ (LUT *)LUTFromLines:(NSArray *)lines {
    
    NSMutableArray *redCurve = [NSMutableArray array];
    NSMutableArray *greenCurve = [NSMutableArray array];
    NSMutableArray *blueCurve = [NSMutableArray array];
    
    
    
    NSMutableArray *trimmedLines = [NSMutableArray array];
    int maxCodeValue = -1;
    int indices = -1;
    
    //trim for lut values only and grab the max code value
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(trimmedLine.length > 0 && [trimmedLine rangeOfString:@"#"].location == NSNotFound && [trimmedLine rangeOfString:@"LUT"].location == NSNotFound){
            [trimmedLines addObject:trimmedLine];
        }
        if([trimmedLine rangeOfString:@"Scale"].location != NSNotFound){
            maxCodeValue = [[trimmedLine componentsSeparatedByString:@":"][1] intValue];
        }
        if([trimmedLine rangeOfString:@"LUT"].location != NSNotFound){
            indices = [[trimmedLine componentsSeparatedByString:@" "][2] intValue];
        }
    }
    
    
    //get red values
    for (int i = 0; i < indices; i++) {
        [redCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], maxCodeValue))];
    }
    //get green values
    for (int i = indices; i < 2*indices; i++) {
        [greenCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], maxCodeValue))];
    }
    //get blue values
    for (int i = 2*indices; i < 3*indices; i++) {
        [blueCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], maxCodeValue))];
    }
    
    return [[LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve lowerBound:0.0 upperBound:1.0] lutOfSize:33];
}

+ (NSString *)stringFromLUT:(LUT *)lut {
    
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    [string appendString:[NSString stringWithFormat:@"#\n# Discreet LUT file\n#\tChannels: 3\n# Input Samples: 1024\n# Ouput Scale: 4095\n#\n# Exported from CocoaLUT\n#\nLUT: 3 1024\n"]];
    
    LUT1D *lut1D = [[lut LUT1D] LUT1DByResizingToSize:1024];

    
    //write red
    for (int i = 0; i < 1024; i++) {
        [string appendString:[NSString stringWithFormat:@"%d\n", (int)(clamp01([lut1D.redCurve[i] doubleValue])*4095.0) ]];
    }
    //write green
    for (int i = 0; i < 1024; i++) {
        [string appendString:[NSString stringWithFormat:@"%d\n", (int)(clamp01([lut1D.greenCurve[i] doubleValue])*4095.0) ]];
    }
    //write blue
    for (int i = 0; i < 1024; i++) {
        [string appendString:[NSString stringWithFormat:@"%d\n", (int)(clamp01([lut1D.blueCurve[i] doubleValue])*4095.0) ]];
    }
    
    return string;
    
}




@end
