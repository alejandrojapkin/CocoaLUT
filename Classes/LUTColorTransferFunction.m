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
    
    return [[[self class] alloc] initWithRedTransformedToLinearBlock:^double(double red, double green, double blue) {return pow(red, gamma);}
                                       greenTransformedToLinearBlock:^double(double red, double green, double blue) {return pow(green, gamma);}
                                        blueTransformedToLinearBlock:^double(double red, double green, double blue) {return pow(blue, gamma);}
                                         redLinearToTransformedBlock:^double(double red, double green, double blue) {return pow(red,  1.0/gamma);}
                                       greenLinearToTransformedBlock:^double(double red, double green, double blue) {return pow(green,  1.0/gamma);}
                                        blueLinearToTransformedBlock:^double(double red, double green, double blue) {return pow(blue,  1.0/gamma);}];
}



+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedExpressionString:(NSString *)redLinearToTransformedExpressionString
                                         greenLinearToTransformedExpressionString:(NSString *)greenLinearToTransformedExpressionString
                                          blueLinearToTransformedExpressionString:(NSString *)blueLinearToTransformedExpressionString
                                           redTransformedToLinearExpressionString:(NSString *)redTransformedToLinearExpressionString
                                         greenTransformedToLinearExpressionString:(NSString *)greenTransformedToLinearExpressionString
                                          blueTransformedToLinearExpressionString:(NSString *)blueTransformedToLinearExpressionString{
    return nil;
}


+(instancetype)LUTColorTransferFunctionWithRedTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )redTransformedToLinearBlock
                                         greenTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )greenTransformedToLinearBlock
                                          blueTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )blueTransformedToLinearBlock
                                           redLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )redLinearToTransformedBlock
                                         greenLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )greenLinearToTransformedBlock
                                          blueLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )blueLinearToTransformedBlock{
    
    return [[[self class] alloc] initWithRedTransformedToLinearBlock:redTransformedToLinearBlock
                                       greenTransformedToLinearBlock:greenTransformedToLinearBlock
                                        blueTransformedToLinearBlock:blueTransformedToLinearBlock
                                         redLinearToTransformedBlock:redLinearToTransformedBlock
                                       greenLinearToTransformedBlock:greenLinearToTransformedBlock
                                        blueLinearToTransformedBlock:blueLinearToTransformedBlock];
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
                           @"Linear": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:1.0],
                           @"Rec. 709": [LUTColorTransferFunction rec709TransferFunction],
                           @"sRGB": [LUTColorTransferFunction sRGBTransferFunction]
                           };
    return dict;
}

+ (instancetype)rec709TransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithRedTransformedToLinearBlock:^double(double red, double green, double blue)
                                                                                                {if(red < .081){return red/4.5;} else{return pow((red+.099)/1.099, 2.2);}}
                                                               greenTransformedToLinearBlock:^double(double red, double green, double blue)
                                                                                                {if(green < .081){return green/4.5;} else{return pow((green+.099)/1.099, 2.2);}}
                                                                blueTransformedToLinearBlock:^double(double red, double green, double blue)
                                                                                                {if(blue < .081){return blue/4.5;} else{return pow((blue+.099)/1.099, 2.2);}}
                                                                 redLinearToTransformedBlock:^double(double red, double green, double blue)
                                                                                                {if(red < .018){return 4.5*red;} else{return 1.099*pow(red, 1.0/2.2) - .099;}}
                                                               greenLinearToTransformedBlock:^double(double red, double green, double blue)
                                                                                                {if(green < .018){return 4.5*green;} else{return 1.099*pow(green, 1.0/2.2) - .099;}}
                                                                blueLinearToTransformedBlock:^double(double red, double green, double blue)
                                                                                                {if(blue < .018){return 4.5*blue;} else{return 1.099*pow(blue, 1.0/2.2) - .099;}} ];
}

+ (instancetype)sRGBTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithRedTransformedToLinearBlock:^double(double red, double green, double blue)
                                                                                                {if(red <= .04045){return red/12.92;} else{return pow((red+.055)/1.055, 2.4);}}
                                                               greenTransformedToLinearBlock:^double(double red, double green, double blue)
                                                                                                {if(green <= .04045){return green/12.92;} else{return pow((green+.055)/1.055, 2.4);}}
                                                                blueTransformedToLinearBlock:^double(double red, double green, double blue)
                                                                                                {if(blue <= .04045){return blue/12.92;} else{return pow((blue+.055)/1.055, 2.4);}}
                                                                 redLinearToTransformedBlock:^double(double red, double green, double blue)
                                                                                                {if(red <= .0031308){return 12.92*red;} else{return 1.055*pow(red, 1.0/2.4) - .055;}}
                                                               greenLinearToTransformedBlock:^double(double red, double green, double blue)
                                                                                                {if(green <= .0031308){return 12.92*green;} else{return 1.055*pow(green, 1.0/2.4) - .055;}}
                                                                blueLinearToTransformedBlock:^double(double red, double green, double blue)
                                                                                                {if(blue <= .0031308){return 12.92*blue;} else{return 1.055*pow(blue, 1.0/2.4) - .055;}} ];
}

@end
