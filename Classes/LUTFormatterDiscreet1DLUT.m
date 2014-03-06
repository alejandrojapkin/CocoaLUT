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
    NSUInteger maxCodeValue = -1;
    
    //trim for lut values only and grab the max code value
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(trimmedLine.length > 0 && [trimmedLine rangeOfString:@"#"].location == NSNotFound && [trimmedLine rangeOfString:@"LUT"].location == NSNotFound){
            [trimmedLines addObject:trimmedLine];
        }
        if([trimmedLine rangeOfString:@"LUT"].location != NSNotFound){
            maxCodeValue = [[trimmedLine componentsSeparatedByString:@" "][2] integerValue];
        }
    }
    
    
    //get red values
    for (int i = 0; i < maxCodeValue; i++) {
        [redCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], maxCodeValue))];
    }
    //get green values
    for (int i = maxCodeValue; i < 2*maxCodeValue; i++) {
        [greenCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], maxCodeValue))];
    }
    
    for (int i = 2*maxCodeValue; i < 3*maxCodeValue; i++) {
        [blueCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], maxCodeValue))];
    }
    
    return [[LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve] lutOfSize:33];
}

@end
