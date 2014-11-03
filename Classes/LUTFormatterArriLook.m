//
//  LUTFormatterArriLook.m
//  Pods
//
//  Created by Greg Cotten on 5/16/14.
//
//

#import "LUTFormatterArriLook.h"
#import <XMLDictionary/XMLDictionary.h>



@implementation LUTFormatterArriLook

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromData:(NSData *)data{
    NSDictionary *xml = [NSDictionary dictionaryWithXMLData:data];

    if(![[xml attributes][@"version"] isEqualToString:@"1.0"]){
        @throw [NSException exceptionWithName:@"LUTFormatterArriLookParseError" reason:@"Arri Look Version not 1.0" userInfo:nil];
    }

    NSArray *toneMapLines = arrayWithComponentsSeperatedByNewlineAndWhitespaceWithEmptyElementsRemoved([[xml valueForKeyPath:@"ToneMapLut"] innerText]);

    NSMutableArray *curve1D = [NSMutableArray array];

    for (NSString *line in toneMapLines){
        if([line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].count > 1){
           @throw [NSException exceptionWithName:@"LUTFormatterArriLookParseError" reason:@"Tone Map Value invalid" userInfo:nil];
        }

        if(stringIsValidNumber(line) == NO){
            @throw [NSException exceptionWithName:@"LUTParserError" reason:[NSString stringWithFormat:@"NaN detected in LUT."] userInfo:nil];
        }

        [curve1D addObject:@((double)[line integerValue]/4095.0)];
    }

    if(curve1D.count !=  [[xml valueForKeyPath:@"ToneMapLut._rows"] integerValue]){
        @throw [NSException exceptionWithName:@"LUTFormatterArriLookParseError" reason:@"Number of tonemap lines != rows value!" userInfo:nil];
    }



    LUT1D *toneMapLUT = [LUT1D LUT1DWith1DCurve:curve1D lowerBound:0.0 upperBound:1.0];

    double saturation = [[xml valueForKeyPath:@"Saturation"] doubleValue];

    //NSLog(@"saturation %f", saturation);

    NSArray *printerLightSplitLine = arrayWithComponentsSeperatedByNewlineAndWhitespaceWithEmptyElementsRemoved([xml valueForKeyPath:@"PrinterLight"]);
    LUTColor *printerLight = [LUTColor colorWithRed:[printerLightSplitLine[0] doubleValue] green:[printerLightSplitLine[1] doubleValue] blue:[printerLightSplitLine[2] doubleValue]];

    //NSLog(@"PrinterLight %@", printerLight);

    NSArray *slopeSplitLine = arrayWithComponentsSeperatedByNewlineAndWhitespaceWithEmptyElementsRemoved([xml valueForKeyPath:@"SOPNode.Slope"]);
    double redSlope = [slopeSplitLine[0] doubleValue];
    double greenSlope = [slopeSplitLine[1] doubleValue];
    double blueSlope = [slopeSplitLine[2] doubleValue];

    NSArray *offsetSplitLine = arrayWithComponentsSeperatedByNewlineAndWhitespaceWithEmptyElementsRemoved([xml valueForKeyPath:@"SOPNode.Offset"]);
    double redOffset = [offsetSplitLine[0] doubleValue];
    double greenOffset = [offsetSplitLine[1] doubleValue];
    double blueOffset = [offsetSplitLine[2] doubleValue];

    NSArray *powerSplitLine = arrayWithComponentsSeperatedByNewlineAndWhitespaceWithEmptyElementsRemoved([xml valueForKeyPath:@"SOPNode.Power"]);
    double redPower = [powerSplitLine[0] doubleValue];
    double greenPower = [powerSplitLine[1] doubleValue];
    double bluePower = [powerSplitLine[2] doubleValue];

    //NSLog(@"slope %@\noffset %@\npower %@", slopeSplitLine, offsetSplitLine, powerSplitLine);

    LUT3D *lut3D = [LUT3D LUTIdentityOfSize:33 inputLowerBound:0.0 inputUpperBound:1.0];


    //apply in order: Saturation -> Printer Lights -> Tonemap -> SOP
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [lut3D colorAtR:r g:g b:b];
        //  AlexaWideGamut Luma from NPM: 0.291948669899 R + 0.823830265984 G + -0.115778935883 B
        color = [color colorByChangingSaturation:saturation usingLumaR:0.291948669899 lumaG:0.823830265984 lumaB:-0.115778935883];
        color = [color colorByAddingColor:printerLight];
        color = [toneMapLUT colorAtColor:color];
        color = [color colorByApplyingRedSlope:redSlope
                                     redOffset:redOffset
                                      redPower:redPower
                                    greenSlope:greenSlope
                                   greenOffset:greenOffset
                                    greenPower:greenPower
                                     blueSlope:blueSlope
                                    blueOffset:blueOffset
                                     bluePower:bluePower];

        [lut3D setColor:color r:r g:g b:b];
    }];

    lut3D.passthroughFileOptions = @{[self formatterID]:@{@"fileTypeVariant":@"Arri",
                                                          @"mixCurvesMethod":@(LUT1DSwizzleChannelsMethodAverageRGB),
                                                          @"lutSize":@4096}};

    return lut3D;
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    NSMutableString *string = [[NSMutableString alloc] init];

    [string appendString:@"<!-- ARRI Digital Camera Look File -->\n<!-- This XML format is used to import color settings into the camera(\"look file\")-->\n<adicam version=\"1.0\" camera=\"alexa\">\n\t<Saturation>\n\t\t1.000000\n\t</Saturation>\n\t<PrinterLight>\n\t\t0.000000 0.000000 0.000000\n\t</PrinterLight>\n\t<SOPNode>\n\t\t<Slope>1.000000 1.000000 1.000000</Slope>\n\t\t<Offset>0.000000 0.000000 0.000000</Offset>\n\t\t<Power>1.000000 1.000000 1.000000</Power>\n\t</SOPNode>\n\t<ToneMapLut rows=\"4096\" cols=\"1\">\n"];

    LUT1D *lut1D = (LUT1D *)lut;

    NSArray *redCurve = [lut1D rgbCurveArray][0];

    for (int i = 0; i < 4096; i++) {
        [string appendString:[NSString stringWithFormat:@"\t%i\n", (int)([redCurve[i] doubleValue]*4095.0)]];
    }

    [string appendString:@"\t</ToneMapLut>\n</adicam>"];

    return string;
}


+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType1D;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if ([super isValidReaderForURL:fileURL] == NO) {
        return NO;
    }
    NSDictionary *xml = [NSDictionary dictionaryWithXMLFile:[fileURL path]];
    if([[xml attributes][@"version"] isEqualToString:@"1.0"] || [[xml attributes][@"camera"] isEqualToString:@"alexa"]){
        return YES;
    }
    return NO;
}

+ (NSArray *)conformanceLUTActionsForLUT:(LUT *)lut options:(NSDictionary *)options{
    NSMutableArray *actions = [NSMutableArray arrayWithArray:[super conformanceLUTActionsForLUT:lut options:options]];

    if (actions == nil) {
        actions = [[NSMutableArray alloc] init];
    }

    NSDictionary *exposedOptions = options[[self formatterID]];

    LUT1DSwizzleChannelsMethod method = [[LUT1D LUT1DSwizzleChannelsMethods][exposedOptions[@"mixCurvesMethod"]] integerValue];

    [actions addObject:[LUTAction actionWithLUTBySwizzlingWithMethod:method]];

    return actions;
}

+ (NSDictionary *)constantConstraints{
    return @{@"inputBounds":@[@0, @1],
             @"outputBounds":@[@0, @1]};
}

+ (NSArray *)allOptions{

    NSDictionary *arriOptions =
    @{@"fileTypeVariant":@"Arri",
      @"mixCurvesMethod": [LUT1D LUT1DSwizzleChannelsMethods],
      @"lutSize":M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"4096": @(4096)}])};


    return @[arriOptions];
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant": @"Arri",
                                 @"mixCurvesMethod": @(LUT1DSwizzleChannelsMethodAverageRGB),
                                 @"lutSize":@4096};

    return @{[self formatterID]: dictionary};
}

+ (NSString *)formatterName{
    return @"Arri Look";
}

+ (NSString *)formatterID{
    return @"arriLook";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSString *)utiString{
    return @"public.xml";
}

+ (NSArray *)fileExtensions{
    return @[@"xml"];
}

@end
