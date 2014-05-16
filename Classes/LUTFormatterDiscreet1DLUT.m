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
    
    NSString *description;
    NSMutableDictionary *metadata;
    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];
    
    NSMutableArray *redCurve = [NSMutableArray array];
    NSMutableArray *greenCurve = [NSMutableArray array];
    NSMutableArray *blueCurve = [NSMutableArray array];
    
    
    
    NSMutableArray *trimmedLines = [NSMutableArray array];
    int integerMaxOutput = -1;
    int lutSize = -1;
    
    NSUInteger lutLinesStartIndex = findFirstLUTLineInLines(lines, @"", 1, 0);
    
    if(lutLinesStartIndex == -1){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }
    
    NSArray *headerLines = [lines subarrayWithRange:NSMakeRange(0, lutLinesStartIndex)];
    
    NSDictionary *metadataAndDescription = [LUTMetadataFormatter metadataAndDescriptionFromLines:headerLines];
    metadata = [metadataAndDescription objectForKey:@"metadata"];
    description = [metadataAndDescription objectForKey:@"description"];
    
    //trim for lut values only and grab the max code value
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(trimmedLine.length > 0 && [trimmedLine rangeOfString:@"#"].location == NSNotFound && [trimmedLine rangeOfString:@"LUT"].location == NSNotFound){
            [trimmedLines addObject:trimmedLine];
        }
        if([trimmedLine rangeOfString:@"Scale"].location != NSNotFound){
            integerMaxOutput = [[trimmedLine componentsSeparatedByString:@":"][1] intValue];
            passthroughFileOptions[@"integerMaxOutput"] = @(integerMaxOutput);
        }
        if([trimmedLine rangeOfString:@"LUT"].location != NSNotFound){
            lutSize = [[trimmedLine componentsSeparatedByString:@" "][2] intValue];
        }
    }
    
    
    //get red values
    for (int i = 0; i < lutSize; i++) {
        [redCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], integerMaxOutput))];
    }
    //get green values
    for (int i = lutSize; i < 2*lutSize; i++) {
        [greenCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], integerMaxOutput))];
    }
    //get blue values
    for (int i = 2*lutSize; i < 3*lutSize; i++) {
        [blueCurve addObject:@(nsremapint01([trimmedLines[i] integerValue], integerMaxOutput))];
    }
    
    LUT1D *lut = [LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve lowerBound:0.0 upperBound:1.0];
    [lut setMetadata:metadata];
    [lut setDescription:description];
    [lut setPassthroughFileOptions:@{@"com.discreet.lut": passthroughFileOptions}];
    return lut;
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    options = options[@"com.discreet.lut"];
    NSMutableString *string = [NSMutableString stringWithString:@""];
    
    NSUInteger integerMaxOutput;
    
    if(options[@"integerMaxOutput"] == nil){
        integerMaxOutput = [[[[self class] defaultOptions] objectForKey:@"integerMaxOutput"] integerValue];
    }
    else{
        integerMaxOutput = [options[@"integerMaxOutput"] integerValue];
    }
    
    [string appendString:[NSString stringWithFormat:@"#\n# Discreet LUT file\n#\tChannels: 3\n# Input Samples: %d\n# Ouput Scale: %d\n#\n# Exported from CocoaLUT\n#\nLUT: 3 %d\n", (int)[lut size], (int)integerMaxOutput, (int)[lut size]]];
    
    LUT1D *lut1D = LUTAsLUT1D(lut, [lut size]);

    
    //write red
    for (int i = 0; i < 1024; i++) {
        [string appendString:[NSString stringWithFormat:@"%d\n", (int)([lut1D valueAtR:i]*(double)integerMaxOutput) ]];
    }
    //write green
    for (int i = 0; i < 1024; i++) {
        [string appendString:[NSString stringWithFormat:@"%d\n", (int)([lut1D valueAtG:i]*(double)integerMaxOutput) ]];
    }
    //write blue
    for (int i = 0; i < 1024; i++) {
        [string appendString:[NSString stringWithFormat:@"%d\n", (int)([lut1D valueAtB:i]*(double)integerMaxOutput) ]];
    }
    
    return string;
    
}

+ (NSDictionary *)allOptions{
    
    NSDictionary *discreetOptions =
    @{@"integerMaxOutput": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"12-bit": @(pow(2, 12) - 1)},
                                                                                  @{@"16-bit": @(pow(2, 16) - 1)}])};
    
    return @{@"Discreet": discreetOptions};
}

+ (NSDictionary *)defaultOptions{
    return @{@"integerMaxOutput": @((int)(pow(2, 12) - 1))};
}


@end
