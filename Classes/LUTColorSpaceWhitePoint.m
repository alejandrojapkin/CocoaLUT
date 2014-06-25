//
//  LUTWhitePoint.m
//  Pods
//
//  Created by Greg Cotten on 6/24/14.
//
//

#import "LUTColorSpaceWhitePoint.h"

@implementation LUTColorSpaceWhitePoint

- (instancetype)initWithWhiteChromaticityX:(double)whiteChromaticityX
                        whiteChromaticityY:(double)whiteChromaticityY
                                      name:(NSString *)name{
    if(self = [super init]){
        self.whiteChromaticityX = whiteChromaticityX;
        self.whiteChromaticityY = whiteChromaticityY;
        self.name = name;
    }
    return self;
}

+ (instancetype)whitePointWithWhiteChromaticityX:(double)whiteChromaticityX
                              whiteChromaticityY:(double)whiteChromaticityY
                                            name:(NSString *)name{
    return [[[self class] alloc] initWithWhiteChromaticityX:whiteChromaticityX
                                         whiteChromaticityY:whiteChromaticityY
                                                       name:name];
}

+ (NSArray *)knownWhitePoints{
    NSArray *allKnownWhitePoints = @[[self d65WhitePoint],
                                  [self d60WhitePoint],
                                  [self d55WhitePoint],
                                  [self p3WhitePoint],
                                  [self alexaWideGamutWhitePoint],
                                  [self xyzWhitePoint]];
    
    return allKnownWhitePoints;
}

- (instancetype)copyWithZone:(NSZone *)zone{
    return [self.class whitePointWithWhiteChromaticityX:self.whiteChromaticityX
                                     whiteChromaticityY:self.whiteChromaticityY
                                                   name:[self.name copyWithZone:zone]];
}

+ (instancetype)d65WhitePoint{
    return [self whitePointWithWhiteChromaticityX:0.31271
                               whiteChromaticityY:0.32902
                                             name:@"D65"];
}

+ (instancetype)d60WhitePoint{
    return [self whitePointWithWhiteChromaticityX:0.32168
                               whiteChromaticityY:0.33767
                                             name:@"D60"];
}

+ (instancetype)d55WhitePoint{
    return [self whitePointWithWhiteChromaticityX:0.33242
                               whiteChromaticityY:0.34743
                                             name:@"D55"];
}

+ (instancetype)p3WhitePoint{
    return [self whitePointWithWhiteChromaticityX:.314
                               whiteChromaticityY:.351
                                             name:@"P3"];
}

+ (instancetype)alexaWideGamutWhitePoint{
    return [self whitePointWithWhiteChromaticityX:0.31271
                               whiteChromaticityY:0.32902
                                             name:@"Alexa Wide Gamut"];
}

+ (instancetype)xyzWhitePoint{
    return [self whitePointWithWhiteChromaticityX:1.0/3.0
                               whiteChromaticityY:1.0/3.0
                                             name:@"XYZ"];
}




@end
