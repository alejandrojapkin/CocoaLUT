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

+ (LUT *)LUTFromLines:(NSArray *)lines{
    return nil;
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

+(NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    NSMutableString *string;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterSpellOutStyle];

    NSString *sizeSpelledOut = [formatter stringFromNumber:@(lut.size)];

    if (isLUT3D(lut)) {
        string = [NSMutableString stringWithFormat:@"lookup of dimension third\nbreadth of %@\n", sizeSpelledOut];
    }
    else{
        //1D LUT
        string = [NSMutableString stringWithFormat:@"lookup of dimension first\nbreadth of %@\n", sizeSpelledOut];
    }
    if ([lut equalsIdentityLUT]) {
        [string appendString:@"all remains unchanging."];
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
