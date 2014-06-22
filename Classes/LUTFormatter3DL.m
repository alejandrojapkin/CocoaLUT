//
//  LUTFormatterCube.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTFormatter3DL.h"
@implementation LUTFormatter3DL

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromLines:(NSArray *)lines {
    
    NSString *description;
    NSMutableDictionary *metadata;
    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];

    NSUInteger __block cubeSize = 0;
    NSUInteger  __block integerMaxOutput = 0;
    
    NSUInteger cubeLinesStartIndex = findFirstLUTLineInLines(lines, @" ", 3, 0);
    
    if(cubeLinesStartIndex == -1){
        @throw [NSException exceptionWithName:@"3DLReadError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }
    
    NSArray *headerLines = [lines subarrayWithRange:NSMakeRange(0, cubeLinesStartIndex)];
    
    NSDictionary *metadataAndDescription = [LUTMetadataFormatter metadataAndDescriptionFromLines:headerLines];
    metadata = metadataAndDescription[@"metadata"];
    description = metadataAndDescription[@"description"];
    
    // Find the size
    for(NSString *line in headerLines) {
        if ([line rangeOfString:@"Mesh"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            NSInteger inputDepth = [components[1] integerValue];
            integerMaxOutput = pow(2, [components[2] integerValue]) - 1;
            cubeSize = pow(2, inputDepth) + 1;
            passthroughFileOptions[@"fileTypeVariant"] = @"Lustre";
            break;
        }
        if ([line rangeOfString:@"#"].location == NSNotFound && [line rangeOfString:@"0"].location != NSNotFound) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            components = arrayWithEmptyElementsRemoved(components);
            integerMaxOutput = [components[components.count - 1] intValue];
            cubeSize = components.count;
            passthroughFileOptions[@"fileTypeVariant"] = @"Nuke";
            break;
        }
            
    }

    if (cubeSize == 0 || integerMaxOutput == 0) {
        NSException *exception = [NSException exceptionWithName:@"3DLReadError" reason:@"LUT Size" userInfo:nil];
        @throw exception;
    }
    
    passthroughFileOptions[@"lutSize"] = @(cubeSize);
    passthroughFileOptions[@"integerMaxOutput"] = @(integerMaxOutput);
    
    

    LUT3D *lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
    NSUInteger currentCubeIndex = 0;
    for (NSString *line in [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count - cubeLinesStartIndex)]) {

        if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
            NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = arrayWithEmptyElementsRemoved(splitLine);
            if (splitLine.count == 3) {
                
                for(NSString *checkLine in splitLine){
                    if(stringIsValidNumber(checkLine) == NO){
                        @throw [NSException exceptionWithName:@"3DLReadError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentCubeIndex+(int)cubeLinesStartIndex] userInfo:nil];
                    }
                }

                // Valid cube line
                LUTColorValue redValue      = ((NSString *)splitLine[0]).doubleValue;
                LUTColorValue greenValue    = ((NSString *)splitLine[1]).doubleValue;
                LUTColorValue blueValue     = ((NSString *)splitLine[2]).doubleValue;

                LUTColor *color = [LUTColor colorFromIntegersWithMaxOutputValue:integerMaxOutput red:redValue green:greenValue blue:blueValue];

                NSUInteger redIndex     = currentCubeIndex / (cubeSize * cubeSize);
				NSUInteger greenIndex   = (currentCubeIndex % (cubeSize * cubeSize)) / cubeSize;
				NSUInteger blueIndex    = currentCubeIndex % cubeSize;

                [lut setColor:color r:redIndex g:greenIndex b:blueIndex];

                currentCubeIndex++;
            }
        }
    }
    
    if(currentCubeIndex < cubeSize*cubeSize*cubeSize){
        @throw [NSException exceptionWithName:@"3DLReadError" reason:@"Incomplete data lines" userInfo:nil];
    }
    
    [lut setMetadata:metadata];
    lut.descriptionText = description;
    [lut setPassthroughFileOptions:@{[self utiString]: passthroughFileOptions}];

    return lut;

}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"3DLWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }
    else{
        options = options[[self utiString]];
    }
    
    
    
    //validate options
    
    
    NSUInteger integerMaxOutput;
    NSString *fileTypeVariant;
    NSUInteger lutSize;
    
    
    fileTypeVariant = options[@"fileTypeVariant"];
    integerMaxOutput = [options[@"integerMaxOutput"] integerValue];
    lutSize = [options[@"lutSize"] integerValue];
    //----------------
    
    lut = [lut LUTByResizingToSize:lutSize];
    
    //lut = LUTAsLUT3D(lut, lutSize);
    
    [string appendString: [LUTMetadataFormatter stringFromMetadata:lut.metadata description:lut.descriptionText]];
    [string appendString:@"\n"];
    
    //write header
    if([fileTypeVariant isEqualToString:@"Nuke"]){
        [string appendString:[indicesIntegerArray(0, (int)integerMaxOutput, (int)lutSize) componentsJoinedByString:@" "]];
        [string appendString:@"\n"];
    }
    else if([fileTypeVariant isEqualToString:@"Lustre"]){
        double sizeToDepth = log2(lutSize-1);
        if(sizeToDepth != (int)sizeToDepth){
            NSException *exception = [NSException exceptionWithName:@"LUTFormatter3DLError" reason:@"Lustre lut size invalid. Size must be 2^x + 1" userInfo:nil];
            @throw exception;
            
        }
        [string appendString:@"3DMESH\n"];
        [string appendString:[NSString stringWithFormat:@"Mesh %d %d\n", (int)sizeToDepth, (int)log2(integerMaxOutput+1)]];
        [string appendString:[indicesIntegerArray(0, 1023, (int) lutSize) componentsJoinedByString:@" "]];
        [string appendString:@"\n"];
        
    }
    
    [string appendString:@"\n"];
    
   
    
    
    NSUInteger arrayLength = lutSize * lutSize * lutSize;
    
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterNoStyle;
    [numberFormatter setPaddingPosition:NSNumberFormatterPadBeforePrefix];
    
    [numberFormatter setFormatWidth: [NSString stringWithFormat:@"%d", (int)integerMaxOutput].length];
    [numberFormatter setPaddingCharacter:@""];
    for (int i = 0; i < arrayLength; i++) {
        int redIndex = i / (lutSize * lutSize);
        int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
        int blueIndex = i % lutSize;
        
        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];
        
        
        
        NSString *redFormatted = [numberFormatter stringFromNumber:@((int)(color.red*integerMaxOutput))];
        NSString *greenFormatted = [numberFormatter stringFromNumber:@((int)(color.green*integerMaxOutput))];
        NSString *blueFormatted = [numberFormatter stringFromNumber:@((int)(color.blue*integerMaxOutput))];
        
        [string appendString:[NSString stringWithFormat:@"%@ %@ %@", redFormatted, greenFormatted, blueFormatted]];
        
        if(i != arrayLength - 1) {
            [string appendString:@"\n"];
        }
        
    }
    
    return string;

}



+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType3D;
}

+ (NSString *)utiString{
    return @"com.autodesk.3dl";
}

+ (NSArray *)fileExtensions{
    return @[@"3dl"];
}

+ (NSString *)formatterName{
    return @"Nuke/Lustre 3D LUT";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSArray *)allOptions{
    
    NSDictionary *lustreOptions =
                @{@"fileTypeVariant":@"Lustre",
                  @"integerMaxOutput": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"12-bit": @(pow(2, 12) - 1)},
                                                                                              @{@"16-bit": @(pow(2, 16) - 1)}]),
                  @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"17": @(17)},
                                                                                     @{@"33": @(33)},
                                                                                     @{@"65": @(65)}])};
    
    NSDictionary *nukeOptions =
                @{@"fileTypeVariant":@"Nuke",
                  @"integerMaxOutput": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"12-bit": @(pow(2, 12) - 1)},
                                                                                              @{@"16-bit": @(pow(2, 16) - 1)}]),
                  @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"32": @(32)},
                                                                                     @{@"64": @(64)}])};
    
    return @[lustreOptions, nukeOptions];
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant": @"Nuke",
                                 @"integerMaxOutput": @((int)(pow(2, 16) - 1)),
                                 @"lutSize": @(32)};
    
    return @{[self utiString]: dictionary};
}



@end
