//
//  LUTFormatterCube.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTFormatterCube.h"

#import <RegExCategories/RegExCategories.h>

@implementation LUTFormatterCube

+ (LUT *)LUTFromLines:(NSArray *)lines {
    
    NSMutableString __block *description = [NSMutableString stringWithString:@""];
    NSMutableString __block *title = [NSMutableString stringWithString:@""];
    NSMutableDictionary __block *metadata = [NSMutableDictionary dictionary];

    NSUInteger __block cubeSize = 0;
    NSUInteger __block sizeLineIndex = 0;
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    BOOL __block isLUT3D = NO;
    BOOL __block isLUT1D = NO;
    
    dispatch_apply([lines count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t index){
        NSString *line = lines[index];
        NSString *titleMatch;
        if ([line rangeOfString:@"LUT_3D_SIZE"].location != NSNotFound) {
            isLUT3D = YES;
            NSString *sizeString = [line componentsSeparatedByString:@" "][1];
            cubeSize = sizeString.integerValue;
            sizeLineIndex = index;
        }
        else if ([line rangeOfString:@"LUT_1D_SIZE"].location != NSNotFound) {
            isLUT1D = YES;
            NSString *sizeString = [line componentsSeparatedByString:@" "][1];
            cubeSize = sizeString.integerValue;
            sizeLineIndex = index;
        }
        else if ([line rangeOfString:@"LUT_3D_INPUT_RANGE"].location != NSNotFound) {
            [data setObject:@([[line componentsSeparatedByString:@" "][1] doubleValue]) forKey:@"inputLowerBound"];
            [data setObject:@([[line componentsSeparatedByString:@" "][2] doubleValue]) forKey:@"inputUpperBound"];
        }
        else if ([line rangeOfString:@"LUT_1D_INPUT_RANGE"].location != NSNotFound) {
            [data setObject:@([[line componentsSeparatedByString:@" "][1] doubleValue]) forKey:@"inputLowerBound"];
            [data setObject:@([[line componentsSeparatedByString:@" "][2] doubleValue]) forKey:@"inputUpperBound"];
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
    });
    
    if (cubeSize == 0) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError" reason:@"Couldn't find LUT size in file" userInfo:nil];
        @throw exception;
    }
    
    if ((isLUT1D && isLUT3D) || (!isLUT1D && !isLUT3D)){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't figure out if 3D or 1D LUT" userInfo:nil];
    }
    
    NSUInteger cubeLinesStartIndex = findFirstLUTLineInLines(lines, @" ", 3, (int)sizeLineIndex+1);
    
    LUT *lut;
    
    if(isLUT3D){
        if([data objectForKey:@"inputLowerBound"] != nil){
            lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:[[data objectForKey:@"inputLowerBound"] doubleValue] inputUpperBound:[[data objectForKey:@"inputUpperBound"] doubleValue]];
        }
        else{
            //assume 0-1 input
            lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
        }
        
        NSUInteger currentCubeIndex = 0;
        for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {
            
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
                    
                    [lut setColor:color r:redIndex g:greenIndex b:blueIndex];
                    
                    currentCubeIndex++;
                }
            }
        }
    }
    else{
        //1D LUT
        if([data objectForKey:@"inputLowerBound"] != nil){
            lut = [LUT1D LUTOfSize:cubeSize inputLowerBound:[[data objectForKey:@"inputLowerBound"] doubleValue] inputUpperBound:[[data objectForKey:@"inputUpperBound"] doubleValue]];
        }
        else{
            //assume 0-1 input
            lut = [LUT1D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
        }
        
        NSUInteger currentLineIndex = 0;
        for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {
            
            if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
                NSArray *splitLine = [line componentsSeparatedByString:@" "];
                if (splitLine.count == 3) {
                    
                    // Valid cube line
                    LUTColorValue redValue = ((NSString *)splitLine[0]).doubleValue;
                    LUTColorValue greenValue = ((NSString *)splitLine[1]).doubleValue;
                    LUTColorValue blueValue = ((NSString *)splitLine[2]).doubleValue;
                    
                    LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];
                    
                    [lut setColor:color r:currentLineIndex g:currentLineIndex b:currentLineIndex];
                    
                    currentLineIndex++;
                }
            }
        }
    }
    
    
    

    


    [lut setTitle:title];
    [lut setDescription:description];
    [[lut metadata] setValuesForKeysWithDictionary:metadata];

    return lut;
}

+ (NSString *)stringFromLUT:(LUT *)lut {
    
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    NSUInteger lutSize = [lut size];
    
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
    
    
    if(isLUT1D(lut)){
        //maybe implement writing a CUBE as 1D here?
        [string appendString:[NSString stringWithFormat:@"LUT_1D_SIZE %i\n", (int)lutSize]];
        
        [string appendString:[NSString stringWithFormat:@"LUT_1D_INPUT_RANGE %.10f %.10f\n", [lut inputLowerBound], [lut inputUpperBound]]];
        
        [string appendString:@"\n"];
        
        for (int i = 0; i < lutSize; i++){
            LUTColor *color = [lut colorAtR:i g:i b:i];
            [string appendString:[NSString stringWithFormat:@"%.10f %.10f %.10f", color.red, color.green, color.blue]];
            if(i != lutSize - 1) {
                [string appendString:@"\n"];
            }
        }
        
    }
    else if(isLUT3D(lut)){
        [string appendString:[NSString stringWithFormat:@"LUT_3D_SIZE %i\n", (int)lutSize]];
        
        [string appendString:[NSString stringWithFormat:@"LUT_3D_INPUT_RANGE %.6f %.6f\n", [lut inputLowerBound], [lut inputUpperBound]]];
        
        [string appendString:@"\n"];
        
        NSUInteger arrayLength = lutSize * lutSize * lutSize;
        for (int i = 0; i < arrayLength; i++) {
            int redIndex = i % lutSize;
            int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
            int blueIndex = i / (lutSize * lutSize);
            
            LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];
            
            [string appendString:[NSString stringWithFormat:@"%.6f %.6f %.6f", color.red, color.green, color.blue]];
            
            if(i != arrayLength - 1) {
                [string appendString:@"\n"];
            }
            
        }
    }
    //but not for now
    
    
    
    

    
    
    return string;

}

@end
