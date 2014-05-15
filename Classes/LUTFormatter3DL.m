//
//  LUTFormatterCube.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTFormatter3DL.h"
@implementation LUTFormatter3DL

+ (LUT *)LUTFromLines:(NSArray *)lines {
    
    NSString *description;
    NSMutableDictionary *metadata;

    NSUInteger __block cubeSize = 0;
    NSUInteger  __block maxOutput = 0;
    
    NSUInteger cubeLinesStartIndex = findFirstLUTLineInLines(lines, @" ", 3, 0);
    
    if(cubeLinesStartIndex == -1){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }
    
    NSArray *headerLines = [lines subarrayWithRange:NSMakeRange(0, cubeLinesStartIndex)];
    
    NSDictionary *metadataAndDescription = [LUTMetadataFormatter metadataAndDescriptionFromLines:headerLines];
    metadata = [metadataAndDescription objectForKey:@"metadata"];
    description = [metadataAndDescription objectForKey:@"description"];
    
    BOOL isNuke3DL = NO;
    // Find the size
    for(NSString *line in headerLines) {
        if ([line rangeOfString:@"Mesh"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            
            NSInteger inputDepth = [components[1] integerValue];
            maxOutput = pow(2, [components[2] integerValue]) - 1;
            cubeSize = pow(2, inputDepth) + 1;
        }
        if ([line rangeOfString:@"#"].location == NSNotFound && [line rangeOfString:@"0"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
            
            maxOutput = [components[components.count - 1] intValue];
            cubeSize = components.count;
            isNuke3DL = YES;
        }
            
    }

    if (cubeSize == 0 || maxOutput == 0) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError" reason:@"Couldn't find LUT size or output depth in file" userInfo:nil];
        @throw exception;
    }
    
    

    LUT3D *lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
    NSUInteger currentCubeIndex = 0;
    for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {

        if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
            NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = [splitLine filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
            if (splitLine.count == 3) {

                // Valid cube line
                LUTColorValue redValue      = ((NSString *)splitLine[0]).doubleValue;
                LUTColorValue greenValue    = ((NSString *)splitLine[1]).doubleValue;
                LUTColorValue blueValue     = ((NSString *)splitLine[2]).doubleValue;

                LUTColor *color = [LUTColor colorFromIntegersWithMaxOutputValue:maxOutput red:redValue green:greenValue blue:blueValue];

                NSUInteger redIndex     = currentCubeIndex / (cubeSize * cubeSize);
				NSUInteger greenIndex   = (currentCubeIndex % (cubeSize * cubeSize)) / cubeSize;
				NSUInteger blueIndex    = currentCubeIndex % cubeSize;

                [lut setColor:color r:redIndex g:greenIndex b:blueIndex];

                currentCubeIndex++;
            }
        }
    }
    
    [lut setMetadata:metadata];
    [lut setDescription:description];

    return lut;

}

+ (NSString *)stringFromLUT:(LUT *)lut {

    return nil;

}

@end
