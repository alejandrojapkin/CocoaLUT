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

- (GLKVector3)tristimulusValues{
    double capY = 1.0;
    double capX = (capY/self.whiteChromaticityY) * self.whiteChromaticityX;
    double capZ = (capY/self.whiteChromaticityY) * (1.0 - self.whiteChromaticityX - self.whiteChromaticityY);
    return GLKVector3Make(capX, capY, capZ);
}

+ (NSArray *)knownWhitePoints{
    NSArray *allKnownWhitePoints = @[[self d65WhitePoint],
                                     [self d60WhitePoint],
                                     [self d55WhitePoint],
                                     [self d50WhitePoint],
                                     [self dciWhitePoint],
                                     [self xyzWhitePoint]];

    return allKnownWhitePoints;
}

+ (NSArray *)knownColorTemperatureWhitePoints{
    return @[[self whitePointFromColorTemperature:2900 customName:@"Incandescent (2900K)"],
             [self whitePointFromColorTemperature:3200 customName:@"Tungsten (3200K)"],
             [self whitePointFromColorTemperature:4400 customName:@"Mixed (4400K)"],
             [self whitePointFromColorTemperature:5600 customName:@"Daylight (5600K)"]];
}



- (instancetype)copyWithZone:(NSZone *)zone{
    return [self.class whitePointWithWhiteChromaticityX:self.whiteChromaticityX
                                     whiteChromaticityY:self.whiteChromaticityY
                                                   name:[self.name copyWithZone:zone]];
}

//http://en.wikipedia.org/wiki/Planckian_locus#Approximation
+ (instancetype)whitePointFromColorTemperature:(double)colorTemperature{
    if (colorTemperature < 1667 || colorTemperature > 25000) {
        return nil;
    }
    else{
        //calculate x
        double xC;
        if (colorTemperature >= 1667 && colorTemperature <= 4000) {
            xC = -0.2661239*(pow(10, 9)/pow(colorTemperature, 3)) - 0.2343580*(pow(10, 6)/pow(colorTemperature, 2)) + 0.8776956*(pow(10, 3)/colorTemperature) + 0.179910;
        }
        else{
            //temp > 4000 and <= 25000
            xC = -3.0258469*(pow(10, 9)/pow(colorTemperature, 3)) + 2.1070379*(pow(10, 6)/pow(colorTemperature, 2)) + 0.2226347*(pow(10, 3)/colorTemperature) + 0.240390;
        }

        //calculate y
        double yC;

        if (colorTemperature >= 1667 && colorTemperature <= 2222) {
            yC = -1.1063814*pow(xC, 3) - 1.34811020*pow(xC, 2) + 2.18555832*xC - 0.20219683;
        }
        else if (colorTemperature > 2222 && colorTemperature <= 4000){
            yC = -0.9549476*pow(xC, 3) - 1.37418593*pow(xC, 2) + 2.09137015*xC - 0.16748867;
        }
        else{
            //temp > 4000 and <= 25000
            yC = 3.0817580*pow(xC, 3) - 5.87338670*pow(xC, 2) + 3.75112997*xC - 0.37001483;
        }

        return [self whitePointWithWhiteChromaticityX:xC
                                   whiteChromaticityY:yC
                                                 name:[NSString stringWithFormat:@"%iK", (int)colorTemperature]];
    }
}

+ (instancetype)whitePointFromColorTemperature:(double)colorTemperature
                                    customName:(NSString *)name{
    LUTColorSpaceWhitePoint *wp = [self whitePointFromColorTemperature:colorTemperature];
    wp.name = name;
    return wp;
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

+ (instancetype)d50WhitePoint{
    return [self whitePointWithWhiteChromaticityX:0.34567
                               whiteChromaticityY:0.35850
                                             name:@"D50"];
}

+ (instancetype)dciWhitePoint{
    return [self whitePointWithWhiteChromaticityX:.314
                               whiteChromaticityY:.351
                                             name:@"DCI White"];
}

+ (instancetype)xyzWhitePoint{
    return [self whitePointWithWhiteChromaticityX:1.0/3.0
                               whiteChromaticityY:1.0/3.0
                                             name:@"XYZ White"];
}





@end
