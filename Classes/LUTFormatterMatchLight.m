//
//  LUTFormatterMatchLight.m
//  Pods
//
//  Created by Greg Cotten on 1/2/15.
//
//

#import "LUTFormatterMatchLight.h"

@implementation LUTFormatterMatchLight

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromLines:(NSArray *)lines{
    NSUInteger lut1DStartIndex = findFirstLUTLineInLinesWithWhitespaceSeparators(lines, 3, 0);
    
    if(lut1DStartIndex == NSNotFound){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }
    
    NSUInteger lut1DSize = NSNotFound;
    NSUInteger lut3DSize = NSNotFound;
    NSUInteger lut3DStartIndex = NSNotFound;
    
    for(int i = 0; i < lines.count; i++){
        NSString *line = [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *splitLine = arrayWithComponentsSeperatedByWhitespaceWithEmptyElementsRemoved(line);
        
        if([line rangeOfString:@"lutS"].location != NSNotFound){
            lut1DSize = [splitLine[2] integerValue];
        }
        else if([line rangeOfString:@"cubeS"].location != NSNotFound){
            lut3DSize = [splitLine[2] integerValue];
        }
        else if ([line rangeOfString:@"# CUBE"].location != NSNotFound) {
            lut3DStartIndex = findFirstLUTLineInLinesWithWhitespaceSeparators(lines, 3, i);
            break;
        }
    }
    
    if(lut1DSize == NSNotFound || lut3DSize == NSNotFound || lut3DStartIndex == NSNotFound){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't find LUT sizes." userInfo:nil];
    }
    
    NSArray *lut1DLines = [lines subarrayWithRange:NSMakeRange(lut1DStartIndex, lut1DSize)];
    NSArray *lut3DLines = [lines subarrayWithRange:NSMakeRange(lut3DStartIndex, lut3DSize*lut3DSize*lut3DSize)];
    
    LUT1D *lut1D = [LUT1D LUTIdentityOfSize:lut1DSize inputLowerBound:0 inputUpperBound:1];
    LUT3D *lut3D = [LUT3D LUTIdentityOfSize:lut3DSize inputLowerBound:0 inputUpperBound:1];
    
    NSUInteger currentLut1DIndex = 0;
    for (NSString *line in lut1DLines) {
        NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        splitLine = arrayWithEmptyElementsRemoved(splitLine);
        if (splitLine.count == 3) {
            
            for(NSString *checkLine in splitLine){
                if(stringIsValidNumber(checkLine) == NO){
                    @throw [NSException exceptionWithName:@"MatchLightReadError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentLut1DIndex+(int)lut3DStartIndex] userInfo:nil];
                }
            }
            
            // Valid cube line
            LUTColorValue redValue      = ((NSString *)splitLine[0]).doubleValue/(double)(lut3DSize-1);
            LUTColorValue greenValue    = ((NSString *)splitLine[1]).doubleValue/(double)(lut3DSize-1);
            LUTColorValue blueValue     = ((NSString *)splitLine[2]).doubleValue/(double)(lut3DSize-1);
            
            LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];
            
            [lut1D setColor:color r:currentLut1DIndex g:currentLut1DIndex b:currentLut1DIndex];
            
            currentLut1DIndex++;
            
        }
    }
    
    NSUInteger currentCubeIndex = 0;
    for (NSString *line in lut3DLines) {
        NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        splitLine = arrayWithEmptyElementsRemoved(splitLine);
        if (splitLine.count == 3) {
            
            for(NSString *checkLine in splitLine){
                if(stringIsValidNumber(checkLine) == NO){
                    @throw [NSException exceptionWithName:@"MatchLightReadError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentCubeIndex+(int)lut3DStartIndex] userInfo:nil];
                }
            }
            
            // Valid cube line
            LUTColorValue redValue      = ((NSString *)splitLine[0]).doubleValue;
            LUTColorValue greenValue    = ((NSString *)splitLine[1]).doubleValue;
            LUTColorValue blueValue     = ((NSString *)splitLine[2]).doubleValue;
            
            LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];
            
            NSUInteger redIndex     = currentCubeIndex / (lut3DSize * lut3DSize);
            NSUInteger greenIndex   = (currentCubeIndex % (lut3DSize * lut3DSize)) / lut3DSize;
            NSUInteger blueIndex    = currentCubeIndex % lut3DSize;
            
            [lut3D setColor:color r:redIndex g:greenIndex b:blueIndex];
            
            currentCubeIndex++;
            
        }
    }
    
    LUT *lut = [lut1D LUTByCombiningWithLUT:lut3D];
    
    lut.passthroughFileOptions = @{[self formatterID]:@{@"fileTypeVariant":@"MatchLight"}};
    
    return lut;
    
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if(![super isValidReaderForURL:fileURL]){
        return NO;
    }
    NSString *string = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    if ([string rangeOfString:@"lutS"].location != NSNotFound && [string rangeOfString:@"cubeS"].location != NSNotFound) {
        return YES;
    }
    else{
        return NO;
    }
}

+ (NSArray *)fileExtensions{
    return @[@"mlc"];
}

+ (NSString *)formatterName{
    return @"LightIllusion MatchLight 3D LUT";
}

+ (NSString *)formatterID{
    return @"matchLight";
}

+ (NSString *)utiString{
    return @"com.lightillusion.mlc";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return NO;
}

+ (NSArray *)allOptions{
    
    NSDictionary *matchLightOptions = @{@"fileTypeVariant":@"MatchLight"};
    
    return @[matchLightOptions];
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant": @"MatchLight"};
    return @{[self formatterID]:dictionary};
}

@end
