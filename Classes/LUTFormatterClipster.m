//
//  LUTFormatterClipster.m
//  Pods
//
//  Created by Greg Cotten on 7/14/14.
//
//

#import "LUTFormatterClipster.h"
#import <XMLDictionary/XMLDictionary.h>

@implementation LUTFormatterClipster

+ (void)load{
    [super load];
}

+ (LUT *)LUTFromData:(NSData *)data{
    NSDictionary *xml = [NSDictionary dictionaryWithXMLData:data];

    NSArray *lutLines = arrayWithComponentsSeperatedByNewlineWithEmptyElementsRemoved(xml[@"values"]);

    NSString *title = [xml attributes][@"name"];
    NSUInteger cubeSize = [[xml attributes][@"N"] integerValue];
    NSUInteger bitDepth = [[xml attributes][@"BitDepth"] integerValue];

    NSUInteger integerMaxOutput = maxIntegerFromBitdepth(bitDepth);

    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];

    passthroughFileOptions[@"fileTypeVariant"] = @"Clipster";
    passthroughFileOptions[@"lutSize"] = @(cubeSize);
    passthroughFileOptions[@"integerMaxOutput"] = @(integerMaxOutput);



    LUT3D *lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];
    NSUInteger currentCubeIndex = 0;
    for (NSString *line in lutLines) {

        if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
            NSArray *splitLine = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = arrayWithEmptyElementsRemoved(splitLine);
            if (splitLine.count == 3) {

                for(NSString *checkLine in splitLine){
                    if(stringIsValidNumber(checkLine) == NO){
                        @throw [NSException exceptionWithName:@"3DLReadError" reason:[NSString stringWithFormat:@"NaN detected at line %i", (int)currentCubeIndex] userInfo:nil];
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


    lut.title = [title copy];
    lut.passthroughFileOptions = @{[self formatterID]:passthroughFileOptions};
    return lut;
}

+(NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"ClipsterWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }
    else{
        options = options[[self formatterID]];
    }



    //validate options


    NSUInteger integerMaxOutput;
    NSUInteger lutSize;

    integerMaxOutput = [options[@"integerMaxOutput"] integerValue];
    lutSize = [options[@"lutSize"] integerValue];

    NSUInteger bitDepth = (NSUInteger)(log(integerMaxOutput+1)/log(2));


    NSMutableString *xmlString = [NSMutableString stringWithFormat:@"<LUT3D name=\'%@\' N=\'%i\' BitDepth=\'%i\'>\n", lut.title, (int)lutSize, (int)bitDepth];

    NSUInteger arrayLength = lut.size * lut.size * lut.size;



    [xmlString appendString:@"<values>\n"];
    for (int i = 0; i < arrayLength; i++) {
        int redIndex = i / (lutSize * lutSize);
        int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
        int blueIndex = i % lutSize;

        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];


        [xmlString appendString:[NSString stringWithFormat:@"%i %i %i", (int)(color.red*(double)integerMaxOutput), (int)(color.green*(double)integerMaxOutput), (int)(color.blue*(double)integerMaxOutput)]];

        if(i != arrayLength - 1) {
            [xmlString appendString:@"\n"];
        }
        
    }
    [xmlString appendString:@"</values>\n"];
    [xmlString appendString:@"</LUT3D>"];
    return xmlString;
}


+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType3D;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if ([super isValidReaderForURL:fileURL] == NO) {
        return NO;
    }
    NSDictionary *xml = [NSDictionary dictionaryWithXMLFile:[fileURL path]];
    if([xml.nodeName isEqualToString:@"LUT3D"]){
        return YES;
    }
    return NO;
}

+ (NSString *)formatterName{
    return @"DVS Clipster 3D LUT";
}

+ (NSString *)formatterID{
    return @"clipster";
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
    return @[@"xml", @"txt"];
}

+ (NSArray *)allOptions{

    NSDictionary *options = @{@"fileTypeVariant":@"Clipster",
                              @"integerMaxOutput": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"16-bit": @(maxIntegerFromBitdepth(16))}]),
      @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"17": @(17)}])};

    return @[options];

}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant":@"Clipster",
                                 @"integerMaxOutput": @(maxIntegerFromBitdepth(16)),
                                 @"lutSize": @(17)};

    return @{[self formatterID]: dictionary};
}

@end
