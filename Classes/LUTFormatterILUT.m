//
//  LUTFormatterILUT.m
//  Pods
//
//  Created by Greg Cotten on 4/9/14.
//
//

#import "LUTFormatterILUT.h"

@implementation LUTFormatterILUT
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
        
        NSUInteger maxCodeValue = pow(2,14) - 1;
        
        for (NSString *line in trimmedLines) {
            NSArray *splitLine = [line componentsSeparatedByString:@","];
            [redCurve addObject:@(nsremapint01([splitLine[0] integerValue], maxCodeValue))];
            [greenCurve addObject:@(nsremapint01([splitLine[1] integerValue], maxCodeValue))];
            [blueCurve addObject:@(nsremapint01([splitLine[2] integerValue], maxCodeValue))];
        }
        
        return [[LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve] lutOfSize:64];
    }

+ (NSString *)stringFromLUT:(LUT *)lut {
    
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    LUT1D *lut1D = [[lut LUT1D] LUT1DByResizingToSize:pow(2,14)];
    
    for (int i = 0; i < pow(2,14); i++){
        int red = (int)([lut1D.redCurve[i] doubleValue]*(double)pow(2,14));
        int green = (int)([lut1D.greenCurve[i] doubleValue]*(double)pow(2,14));
        int blue = (int)([lut1D.blueCurve[i] doubleValue]*(double)pow(2,14));
        [string appendString:[NSString stringWithFormat:@"%d,%d,%d,%d\n", red, green, blue, 0]];
    }
    
    return string;
    
}
@end
