//
//  LUTColorTransferFunction.m
//  Pods
//
//  Created by Greg Cotten on 4/3/14.
//
//

#import "LUTColorTransferFunction.h"
#include "math.h"

@interface LUTColorTransferFunction ()
    @property (copy)double (^redTransformedToLinear)( double red, double green, double blue );
    @property (copy)double (^greenTransformedToLinear)( double red, double green, double blue );
    @property (copy)double (^blueTransformedToLinear)( double red, double green, double blue );

    @property (copy)double (^redLinearToTransformed)( double red, double green, double blue );
    @property (copy)double (^greenLinearToTransformed)( double red, double green, double blue );
    @property (copy)double (^blueLinearToTransformed)( double red, double green, double blue );
@end

@implementation LUTColorTransferFunction

+(instancetype)LUTColorTransferFunctionWithGamma:(double)gamma{
    
    return [[[self class] alloc] initWithRedTransformedToLinearBlock:^double(double red, double green, double blue) {return pow(red, 1.0/gamma);}
                                       greenTransformedToLinearBlock:^double(double red, double green, double blue) {return pow(green, 1.0/gamma);}
                                        blueTransformedToLinearBlock:^double(double red, double green, double blue) {return pow(blue, 1.0/gamma);}
                                         redLinearToTransformedBlock:^double(double red, double green, double blue) {return pow(red, gamma);}
                                       greenLinearToTransformedBlock:^double(double red, double green, double blue) {return pow(green, gamma);}
                                        blueLinearToTransformedBlock:^double(double red, double green, double blue) {return pow(blue, gamma);}];
}

+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedExpressionString:(NSString *)redLinearToTransformedExpressionString
                                             greenLinearToTransformedExpressionString:(NSString *)greenLinearToTransformedExpressionString
                                              blueLinearToTransformedExpressionString:(NSString *)blueLinearToTransformedExpressionString
                                               redTransformedToLinearExpressionString:(NSString *)redTransformedToLinearExpressionStrin
                                             greenTransformedToLinearExpressionString:(NSString *)greenTransformedToLinearExpressionString
                                              blueTransformedToLinearExpressionString:(NSString *)blueTransformedToLinearExpressionString{
    return nil;
}


+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )redTransformedToLinearBlock
                                   greenLinearToTransformedExpressionBlock:( double ( ^ )( double red, double green, double blue ) )greenLinearToTransformedExpressionBlock
                                    blueLinearToTransformedExpressionBlock:( double ( ^ )( double red, double green, double blue ) )blueLinearToTransformedExpressionBlock
                                     redTransformedToLinearExpressionBlock:( double ( ^ )( double red, double green, double blue ) )redTransformedToLinearExpressionBlock
                                   greenTransformedToLinearExpressionBlock:( double ( ^ )( double red, double green, double blue ) )greenTransformedToLinearExpressionBlock
                           blueTransformedToLinearExpressionBlock:( double ( ^ )( double red, double green, double blue ) )blueTransformedToLinearExpressionBlock{
    return nil;
}

-(instancetype)initWithRedTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )redTransformedToLinearBlock
           greenTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )greenTransformedToLinearBlock
            blueTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )blueTransformedToLinearBlock
             redLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )redLinearToTransformedBlock
           greenLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )greenLinearToTransformedBlock
            blueLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )blueLinearToTransformedBlock{
    if (self = [super init]){
        self.redTransformedToLinear = redTransformedToLinearBlock;
        self.greenTransformedToLinear = greenTransformedToLinearBlock;
        self.blueTransformedToLinear = blueTransformedToLinearBlock;

        self.redLinearToTransformed = redLinearToTransformedBlock;
        self.greenLinearToTransformed = greenLinearToTransformedBlock;
        self.blueLinearToTransformed = blueLinearToTransformedBlock;
    }
    return self;
    
}

-(LUTColor *)transformedToLinearFromColor:(LUTColor *)transformedColor{
    double redTransformed = transformedColor.red;
    double greenTransformed = transformedColor.green;
    double blueTransformed = transformedColor.blue;
    
    return [LUTColor colorWithRed:self.redTransformedToLinear(redTransformed, greenTransformed, blueTransformed)
                            green:self.greenTransformedToLinear(redTransformed, greenTransformed, blueTransformed)
                             blue:self.blueTransformedToLinear(redTransformed, greenTransformed, blueTransformed)];
}

-(LUTColor *)linearToTransformedFromColor:(LUTColor *)linearColor{
    double redLinear = linearColor.red;
    double greenLinear = linearColor.green;
    double blueLinear = linearColor.blue;
    
    return [LUTColor colorWithRed:self.redLinearToTransformed(redLinear, greenLinear, blueLinear)
                            green:self.greenLinearToTransformed(redLinear, greenLinear, blueLinear)
                             blue:self.blueLinearToTransformed(redLinear, greenLinear, blueLinear)];
}

+ (LUT *)transformedLUTFromLUT:(LUT *)sourceLUT
          fromColorTransferFunction:(LUTColorTransferFunction *)sourceColorTransferFunction
            toColorTransferFunction:(LUTColorTransferFunction *)destinationColorTransferFunction{
    
    LUTLattice *transformedLattice = [[LUTLattice alloc] initWithSize:sourceLUT.lattice.size];
    
    LUTConcurrentCubeLoop(sourceLUT.lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *transformedColor = [LUTColorTransferFunction transformedColorFromColor:[sourceLUT.lattice colorAtR:r g:g b:b]
                                                               fromColorTransferFunction:sourceColorTransferFunction
                                                                 toColorTransferFunction:destinationColorTransferFunction];
        
        [transformedLattice setColor:transformedColor r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:transformedLattice];
}

+ (LUTColor *)transformedColorFromColor:(LUTColor *)sourceColor
                   fromColorTransferFunction:(LUTColorTransferFunction *)sourceColorTransferFunction
                     toColorTransferFunction:(LUTColorTransferFunction *)destinationColorTransferFunction{
    LUTColor *sourceLinear = [sourceColorTransferFunction transformedToLinearFromColor:sourceColor];
    return [destinationColorTransferFunction linearToTransformedFromColor:sourceLinear];
}

+ (NSDictionary *)knownColorTransferFunctions{
    NSDictionary *dict = @{@"Gamma 2.2": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:2.2],
                           @"Gamma 2.4": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:2.4],
                           @"Gamma 2.6": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:2.6],
                           @"Gamma 1.8": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:1.8],
                           @"Linear": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:1.0]
                           };
    return dict;
}

@end
