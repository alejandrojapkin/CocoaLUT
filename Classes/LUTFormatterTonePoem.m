//
//  LUTFormatterTonePoem.m
//  Pods
//
//  Created by Greg Cotten on 7/15/14.
//
//

#import "LUTFormatterTonePoem.h"

@implementation LUTFormatterTonePoem

+ (void)load{
    [super load];
}



//change this to KDTree
+(NSArray *)nameColorPairsFromXKCD{
    static NSArray *nameColorPairs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *pairs = [NSMutableArray array];
        NSURL *xkcdLookupURL = [self formatterResourceURLFromBundleWithName:@"LUTFormatterTonePoem_hexColorNameLookup_XKCD" extension:@"txt"];
        NSArray *xkcdLookupRaw = [[[NSString alloc] initWithData:[NSData dataWithContentsOfURL:xkcdLookupURL] encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];

        for(NSString *line in xkcdLookupRaw){
            if (line.length != 0) {
                NSArray *splitLine = [line componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                splitLine = arrayWithEmptyElementsRemoved(splitLine);
                if(splitLine.count == 2){
                    NSString *name = splitLine[0];
                    SystemColor *color = systemColorWithHexString(splitLine[1]);
                    [pairs addObject:@[name, [LUTColor colorWithSystemColor:color]]];
                }
            }
        }

        nameColorPairs = [NSArray arrayWithArray:pairs];
    });
    return nameColorPairs;
}

+(LUTColor *)colorFromName:(NSString *)name
               lookupArray:(NSArray *)lookupArray{
    for(NSArray *pair in lookupArray){
        if ([pair[0] isEqualToString:name]) {
            return pair[1];
        }
    }
    return nil;
}

//Change this to receive KDTree
+(NSArray *)closestNameColorMatchFromLookupArray:(NSArray *)lookupArray
                                           color:(LUTColor *)color{

    NSArray *closestMatch = nil;
    double closestDistance = 1000;
    for(int i = 0; i < lookupArray.count; i++){
        double distanceToColor = [(LUTColor *)lookupArray[i][1] distanceToColor:color];
        if (distanceToColor < closestDistance) {
            closestDistance = distanceToColor;
            closestMatch = lookupArray[i];
        }
    }
    return closestMatch;
}

+ (LUT *)LUTFromLines:(NSArray *)lines{


    NSUInteger cubeLinesStartIndex = -1;
    BOOL isLUT3D = NO;
    BOOL isLUT1D = NO;
    BOOL isIdentity = NO;

    double inputLowerBound = 0;
    double inputUpperBound = 0;

    NSUInteger lutSize = 0;

    for(int i = 0; i < lines.count; i++){
        NSString *lineString = lines[i];
        if ([lineString rangeOfString:@"third"].location != NSNotFound) {
            isLUT3D = YES;
        }
        if ([lineString rangeOfString:@"first"].location != NSNotFound) {
            isLUT1D = YES;
        }
        if ([lineString rangeOfString:@"breadth"].location != NSNotFound) {
            NSArray *splitLine = [lineString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = arrayWithEmptyElementsRemoved(splitLine);
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle: NSNumberFormatterSpellOutStyle];

            lutSize = [[formatter numberFromString:splitLine[2]] integerValue];
        }
        if ([lineString rangeOfString:@"all remain unchanging"].location != NSNotFound) {
            isIdentity = YES;
        }
        if ([lineString rangeOfString:@"encompasses"].location != NSNotFound) {
            NSArray *splitLine = [lineString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            splitLine = arrayWithEmptyElementsRemoved(splitLine);
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle: NSNumberFormatterSpellOutStyle];
            inputLowerBound = [[formatter numberFromString:splitLine[1]] doubleValue];
            inputUpperBound = [[formatter numberFromString:splitLine[3]] doubleValue];

        }
        if ([lineString rangeOfString:@"remains"].location != NSNotFound || [lineString rangeOfString:@"becomes"].location != NSNotFound){
            cubeLinesStartIndex = i;
            break;
        }
    }

    if(cubeLinesStartIndex == -1){
        @throw [NSException exceptionWithName:@"LUTParserError" reason:@"Couldn't find start of LUT data lines." userInfo:nil];
    }

    NSArray *cubeLines = [lines subarrayWithRange:NSMakeRange(cubeLinesStartIndex, lines.count-cubeLinesStartIndex)];

    if (isLUT3D && isLUT1D) {
        @throw [NSException exceptionWithName:@"LUTTonePoemParserError" reason:@"Can't be both LUT formats" userInfo:nil];
    }

    LUT *lut;

    if (isIdentity) {
        if (isLUT1D) {
            lut = [LUT1D LUTIdentityOfSize:lutSize inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
        }
        else{
            //LUT 3D
            lut = [LUT3D LUTIdentityOfSize:lutSize inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
        }
    }
    else{
        NSArray *lookupArray = [self nameColorPairsFromXKCD];
        if (isLUT1D) {
            lut = [LUT1D LUTOfSize:lutSize inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
            for (int i = 0; i < lutSize; i++){
                NSArray *splitLine = [cubeLines[i] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                [lut setColor:[self colorFromName:splitLine[2] lookupArray:lookupArray] r:i g:i b:i];
            }
        }
        else{
            lut = [LUT3D LUTOfSize:lutSize inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];

            NSUInteger currentCubeIndex = 0;
            for (NSString *line in cubeLines) {
                if (line.length > 0 && [line rangeOfString:@"#"].location == NSNotFound) {
                    NSArray *splitLine = [line componentsSeparatedByString:@" "];
                    NSUInteger redIndex = currentCubeIndex % lutSize;
                    NSUInteger greenIndex = ( (currentCubeIndex % (lutSize * lutSize)) / (lutSize) );
                    NSUInteger blueIndex = currentCubeIndex / (lutSize * lutSize);

                    [lut setColor:[self colorFromName:splitLine[2] lookupArray:lookupArray] r:redIndex g:greenIndex b:blueIndex];

                    currentCubeIndex++;
                }
            }
        }
    }

    lut.passthroughFileOptions = @{[self formatterID]: @{}};
    return lut;

}

+(NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    NSMutableString *string;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterSpellOutStyle];

    NSString *sizeSpelledOut = [formatter stringFromNumber:@(lut.size)];
    NSString *inputLowerBoundSpelledOut = [formatter stringFromNumber:@(lut.inputLowerBound)];
    NSString *inputUpperBoundSpelledOut = [formatter stringFromNumber:@(lut.inputUpperBound)];

    if (isLUT3D(lut)) {
        string = [NSMutableString stringWithFormat:@"lookup of dimension third\nbreadth of %@\nencompasses %@ to %@\n", sizeSpelledOut, inputLowerBoundSpelledOut, inputUpperBoundSpelledOut];
    }
    else{
        //1D LUT
        string = [NSMutableString stringWithFormat:@"lookup of dimension first\nbreadth of %@\nencompasses %@ to %@\n", sizeSpelledOut, inputLowerBoundSpelledOut, inputUpperBoundSpelledOut];
    }
    if ([lut equalsIdentityLUT]) {
        [string appendString:@"all remain unchanging."];
        return string;
    }
    [string appendString:@"fastest is red.\n\n"];

    NSArray *nameColorPairs = [self nameColorPairsFromXKCD];

    NSUInteger lutSize = lut.size;
    if (isLUT3D(lut)) {
        NSUInteger arrayLength = lutSize * lutSize * lutSize;
        for (int i = 0; i < arrayLength; i++) {
            int redIndex = i % lutSize;
            int greenIndex = ((i % (lutSize * lutSize)) / (lutSize) );
            int blueIndex = i / (lutSize * lutSize);

            LUTColor *identityColor = [lut identityColorAtR:redIndex g:greenIndex b:blueIndex];
            LUTColor *transformedColor = [lut colorAtR:redIndex g:greenIndex b:blueIndex];

            NSString *identityName = [self closestNameColorMatchFromLookupArray:nameColorPairs color:identityColor][0];
            NSString *transformedName = [self closestNameColorMatchFromLookupArray:nameColorPairs color:transformedColor][0];
            if ([identityName isEqualToString:transformedName]) {
                [string appendString:[NSString stringWithFormat:@"%@ remains %@", transformedName, transformedName]];
            }
            else{
                [string appendString:[NSString stringWithFormat:@"%@ becomes %@", identityName, transformedName]];
            }


            if(i != arrayLength - 1) {
                [string appendString:@"\n"];
            }
            
        }
    }
    else{
        //LUT1D
        NSUInteger arrayLength = lutSize;
        for (int i = 0; i < arrayLength; i++) {
            LUTColor *identityColor = [lut identityColorAtR:i g:i b:i];
            LUTColor *transformedColor = [lut colorAtR:i g:i b:i];

            NSString *identityName = [self closestNameColorMatchFromLookupArray:nameColorPairs color:identityColor][0];
            NSString *transformedName = [self closestNameColorMatchFromLookupArray:nameColorPairs color:transformedColor][0];

            [string appendString:[NSString stringWithFormat:@"%@ becomes %@", identityName, transformedName]];

            if(i != arrayLength - 1) {
                [string appendString:@"\n"];
            }
            
        }
    }




    return string;
}


+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputTypeEither;
}

+ (NSString *)formatterName{
    return @"Lattice Tone Poem LUT";
}

+ (NSString *)formatterID{
    return @"tonePoem";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSString *)utiString{
    return @"co.videovillage.tonepoem";
}

+ (NSArray *)fileExtensions{
    return @[@"tonepoem"];
}

@end
