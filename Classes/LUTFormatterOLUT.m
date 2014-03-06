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
    
    NSUInteger maxCodeValue = trimmedLines.count - 1;
    
    for (NSString *line in trimmedLines) {
        NSArray *splitLine = [line componentsSeparatedByString:@","];
        [redCurve addObject:@(nsremapint01([splitLine[0] integerValue], maxCodeValue))];
        [greenCurve addObject:@(nsremapint01([splitLine[1] integerValue], maxCodeValue))];
        [blueCurve addObject:@(nsremapint01([splitLine[2] integerValue], maxCodeValue))];
    }
    
    return [[LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve] lutOfSize:33];
}

@end
