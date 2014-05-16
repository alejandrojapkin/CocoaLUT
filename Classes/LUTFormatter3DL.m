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
    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];

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
    
    // Find the size
    for(NSString *line in headerLines) {
        if ([line rangeOfString:@"Mesh"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            NSInteger inputDepth = [components[1] integerValue];
            maxOutput = pow(2, [components[2] integerValue]) - 1;
            cubeSize = pow(2, inputDepth) + 1;
            [passthroughFileOptions setObject:@"Lustre" forKey:@"fileTypeVariant"];
            break;
        }
        if ([line rangeOfString:@"#"].location == NSNotFound && [line rangeOfString:@"0"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
            maxOutput = [components[components.count - 1] intValue];
            cubeSize = components.count;
            [passthroughFileOptions setObject:@"Nuke" forKey:@"fileTypeVariant"];
            break;
        }
            
    }

    if (cubeSize == 0 || maxOutput == 0) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError" reason:@"Couldn't find LUT size or output depth in file" userInfo:nil];
        @throw exception;
    }
    
    [passthroughFileOptions setObject:@(maxOutput) forKey:@"integerMaxOutput"];
    
    

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
    [lut setPassthroughFileOptions:passthroughFileOptions];

    return lut;

}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    [string appendString: [LUTMetadataFormatter stringFromMetadata:lut.metadata description:lut.description]];
    [string appendString:@"\n"];
    
    NSUInteger maxOutput;
    NSString *fileTypeVariant = options[@"fileTypeVariant"];
    
    if(options[@"integerMaxOutput"] == nil){
        maxOutput = [[[[self class] defaultOptions] objectForKey:@"integerMaxOutput"] integerValue];
    }
    else{
        maxOutput = [options[@"integerMaxOutput"] integerValue];
    }
    
    if(fileTypeVariant == nil){
        fileTypeVariant = [[[self class] defaultOptions] objectForKey:@"fileTypeVariant"];
        
    }
    
    if([fileTypeVariant isEqualToString:@"Nuke"]){
        [string appendString:[indicesIntegerArray(0, (int)maxOutput, (int)[lut size]) componentsJoinedByString:@" "]];
        [string appendString:@"\n"];
    }
    else if([fileTypeVariant isEqualToString:@"Lustre"]){
        double sizeToDepth = log2([lut size]-1);
        if(sizeToDepth != (int)sizeToDepth){
            NSException *exception = [NSException exceptionWithName:@"LUTFormatter3DLError" reason:@"Lustre lut size invalid. Size must be 2^x + 1" userInfo:nil];
            @throw exception;
            
        }
        [string appendString:@"3DMESH\n"];
        [string appendString:[NSString stringWithFormat:@"Mesh %d %d\n", (int)sizeToDepth, (int)log2(maxOutput+1)]];
        [string appendString:[indicesIntegerArray(0, 1023, (int) [lut size]) componentsJoinedByString:@" "]];
        [string appendString:@"\n"];
        
    }
    
    [string appendString:@"\n"];
    
   
    NSUInteger lutSize = [lut size];
    NSUInteger arrayLength = lutSize * lutSize * lutSize;
    
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterNoStyle;
    [numberFormatter setPaddingPosition:NSNumberFormatterPadBeforePrefix];
    
    [numberFormatter setFormatWidth: [NSString stringWithFormat:@"%d", (int)maxOutput].length];
    [numberFormatter setPaddingCharacter:@""];
    for (int i = 0; i < arrayLength; i++) {
        
        
        int redIndex = i / (lutSize * lutSize);
        int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
        int blueIndex = i % lutSize;
        
        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];
        
        
        
        NSString *redFormatted = [numberFormatter stringFromNumber:@((int)(color.red*maxOutput))];
        NSString *greenFormatted = [numberFormatter stringFromNumber:@((int)(color.green*maxOutput))];
        NSString *blueFormatted = [numberFormatter stringFromNumber:@((int)(color.blue*maxOutput))];
        
        [string appendString:[NSString stringWithFormat:@"%@ %@ %@", redFormatted, greenFormatted, blueFormatted]];
        
        if(i != arrayLength - 1) {
            [string appendString:@"\n"];
        }
        
    }
    
    
    return string;

}

+ (NSDictionary *)allOptions{
    return @{@"fileTypeVariant": @[@"Nuke", @"Lustre"]};
}

+ (NSDictionary *)defaultOptions{
    return @{@"fileTypeVariant": @"Nuke",
             @"integerMaxOutput": @((int)(pow(2, 16) - 1))};
}

@end
