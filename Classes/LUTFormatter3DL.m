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

    NSUInteger __block cubeSize = 0;
    NSUInteger __block meshLineIndex = 0;
    NSInteger  __block outputDepth = 0;

    // Find the size
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger i, BOOL *stop) {
        if ([line rangeOfString:@"Mesh"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            
            NSInteger inputDepth = [components[1] integerValue];
            outputDepth = [components[2] integerValue];
            cubeSize = pow(2, inputDepth) + 1;
            
            *stop = YES;
        }
        meshLineIndex++;
    }];

    if (cubeSize == 0) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError" reason:@"Couldn't find LUT size in file" userInfo:nil];
        @throw exception;
    }

    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:cubeSize];
    NSUInteger currentCubeIndex = 0;
    for (NSString *line in [lines subarrayWithRange:NSMakeRange(meshLineIndex + 1, lines.count - meshLineIndex - 1)]) {

        if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
            NSArray *splitLine = [line componentsSeparatedByString:@" "];
            if (splitLine.count == 3) {

                // Valid cube line
                LUTColorValue redValue      = ((NSString *)splitLine[0]).doubleValue;
                LUTColorValue greenValue    = ((NSString *)splitLine[1]).doubleValue;
                LUTColorValue blueValue     = ((NSString *)splitLine[2]).doubleValue;

                LUTColor *color = [LUTColor colorFromIntegersWithBitDepth:outputDepth red:redValue green:greenValue blue:blueValue];

                NSUInteger redIndex     = currentCubeIndex / (cubeSize * cubeSize);
				NSUInteger greenIndex   = (currentCubeIndex % (cubeSize * cubeSize)) / cubeSize;
				NSUInteger blueIndex    = currentCubeIndex % cubeSize;

                [lattice setColor:color r:redIndex g:greenIndex b:blueIndex];

                currentCubeIndex++;
            }
        }
    }

    return [LUT LUTWithLattice:lattice];

}

+ (NSString *)stringFromLUT:(LUT *)lut {

    return nil;

}

@end
