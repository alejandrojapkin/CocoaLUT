//
//  LUTFormatterCube.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTFormatterCube.h"
#import "LUTLattice.h"
#import "LUT.h"

#import <RegExCategories/RegExCategories.h>

@implementation LUTFormatterCube

+ (LUT *)LUTFromLines:(NSArray *)lines {
    
    NSMutableString __block *description = [NSMutableString stringWithString:@""];
    NSMutableString __block *title = [NSMutableString stringWithString:@""];
    NSMutableDictionary __block *metadata = [NSMutableDictionary dictionary];

    NSUInteger __block cubeSize = 0;
    NSUInteger __block sizeLineIndex = 0;
    
    // Find the size
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger i, BOOL *stop) {
        NSString *titleMatch;
        if ([line rangeOfString:@"LUT_3D_SIZE"].location != NSNotFound) {
            NSString *sizeString = [line componentsSeparatedByString:@" "][1];
            cubeSize = sizeString.integerValue;
            sizeLineIndex = i;
        }
        else if ((titleMatch = [line firstMatch:RX(@"(?<=TITLE \")[^\"]*(?=\")")])) {
            [title appendString:titleMatch];
        }
        else if (line.length > 0 && [[line substringToIndex:1] isEqualToString:@"#"]) {
            NSString *comment;
            if (line.length > 2 && [[line substringToIndex:2] isEqualToString:@"# "]) {
                comment = [line substringFromIndex:2];
            }
            else {
                comment = [line substringFromIndex:1];
            }
            
            BOOL isKeyValue = NO;
            if ([comment rangeOfString:@":"].location != NSNotFound) {
                NSArray *split = [comment componentsSeparatedByString:@":"];
                if (split.count == 2) {
                    metadata[[split[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [split[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    isKeyValue = YES;
                }
            }
            
            if (!isKeyValue) {
                [description appendString:comment];
                [description appendString:@"\n"];
            }
        }
    }];

    if (cubeSize == 0) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError" reason:@"Couldn't find LUT size in file" userInfo:nil];
        @throw exception;
    }

    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:cubeSize];

    NSUInteger currentCubeIndex = 0;
    for (NSString *line in [lines subarrayWithRange:NSMakeRange(sizeLineIndex + 1, lines.count - sizeLineIndex - 1)]) {

        if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
            NSArray *splitLine = [line componentsSeparatedByString:@" "];
            if (splitLine.count == 3) {

                // Valid cube line
                LUTColorValue redValue = ((NSString *)splitLine[0]).doubleValue;
                LUTColorValue greenValue = ((NSString *)splitLine[1]).doubleValue;
                LUTColorValue blueValue = ((NSString *)splitLine[2]).doubleValue;

                LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];

                NSUInteger redIndex = currentCubeIndex % cubeSize;
				NSUInteger greenIndex = ( (currentCubeIndex % (cubeSize * cubeSize)) / (cubeSize) );
				NSUInteger blueIndex = currentCubeIndex / (cubeSize * cubeSize);

                [lattice setColor:color r:redIndex g:greenIndex b:blueIndex];

                currentCubeIndex++;
            }
        }
    }
    
    LUT *lut = [LUT LUTWithLattice:lattice];

    lut.title = title;
    lut.description = description;
    lut.metadata = [metadata copy];

    return lut;
}

+ (NSString *)stringFromLUT:(LUT *)lut {
    
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    NSUInteger cubeSize = lut.lattice.size;
    
    if (lut.title && lut.title.length > 0) {
        [string appendString:[NSString stringWithFormat:@"TITLE \"%@\"\n", lut.title]];
    }
    
    [string appendString:@"\n"];
    
    if (lut.description && lut.description.length > 0) {
        for (NSString *line in [lut.description componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
            [string appendString:[NSString stringWithFormat:@"# %@\n", line]];
        }
    }
    
    [string appendString:@"\n"];
    
    if (lut.metadata && lut.metadata.count > 0) {
        for (NSString *key in lut.metadata) {
            [string appendString:[NSString stringWithFormat:@"# %@: %@\n", key, lut.metadata[key]]];
        }
        [string appendString:@"\n"];
    }

    [string appendString:[NSString stringWithFormat:@"LUT_3D_SIZE %i\n", (int)cubeSize]];
    
    [string appendString:@"\n"];

    NSUInteger arrayLength = cubeSize * cubeSize * cubeSize;
    for (int i = 0; i < arrayLength; i++) {
        int redIndex = i % cubeSize;
        int greenIndex = ((i % (cubeSize * cubeSize)) / (cubeSize) );
        int blueIndex = i / (cubeSize * cubeSize);
        
        LUTColor *color = [lut.lattice colorAtR:redIndex g:greenIndex b:blueIndex].clampedO1;

        [string appendString:[NSString stringWithFormat:@"%.6f %.6f %.6f", color.red, color.green, color.blue]];

        if(i != arrayLength - 1) {
            [string appendString:@"\n"];
        }

    }
    
    return string;

}

@end
