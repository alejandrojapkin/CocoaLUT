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
    @property (copy)LUTColor* (^transformedToLinearBlock)( double red, double green, double blue );
    @property (copy)LUTColor* (^linearToTransformedBlock)( double red, double green, double blue );

@end

@implementation LUTColorTransferFunction

-(instancetype)initWithTransformedToLinearBlock:( LUTColor* ( ^ )(double red, double green, double blue) )transformedToLinearBlock
                       linearToTransformedBlock:( LUTColor* ( ^ )(double red, double green, double blue) )linearToTransformedBlock{
    if (self = [super init]){
        self.transformedToLinearBlock = transformedToLinearBlock;
        self.linearToTransformedBlock = linearToTransformedBlock;
    }
    return self;
}

+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedExpressionString:(NSString *)redLinearToTransformedExpressionString
                                         greenLinearToTransformedExpressionString:(NSString *)greenLinearToTransformedExpressionString
                                          blueLinearToTransformedExpressionString:(NSString *)blueLinearToTransformedExpressionString
                                           redTransformedToLinearExpressionString:(NSString *)redTransformedToLinearExpressionString
                                         greenTransformedToLinearExpressionString:(NSString *)greenTransformedToLinearExpressionString
                                          blueTransformedToLinearExpressionString:(NSString *)blueTransformedToLinearExpressionString{
    return nil;
}

+(instancetype)LUTColorTransferFunctionWithTransformedToLinearBlock:( LUTColor* ( ^ )(double red, double green, double blue) )transformedToLinearBlock
                                           linearToTransformedBlock:( LUTColor* ( ^ )(double red, double green, double blue) )linearToTransformedBlock{
    return [[[self class] alloc] initWithTransformedToLinearBlock:transformedToLinearBlock
                                         linearToTransformedBlock:linearToTransformedBlock];
}

+(instancetype)LUTColorTransferFunctionWithTransformedToLinearBlock1D:( double ( ^ )(double value) )transformedToLinearBlock1D
                                           linearToTransformedBlock1D:( double ( ^ )(double value) )linearToTransformedBlock1D{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock:^LUTColor*(double red, double green, double blue) {
        return [LUTColor colorWithRed:transformedToLinearBlock1D(red)
                                green:transformedToLinearBlock1D(green)
                                 blue:transformedToLinearBlock1D(blue)];}
                                                                 linearToTransformedBlock:^LUTColor*(double red, double green, double blue) {
                                                                     return [LUTColor colorWithRed:linearToTransformedBlock1D(red)
                                                                                             green:linearToTransformedBlock1D(green)
                                                                                              blue:linearToTransformedBlock1D(blue)];}];
}

-(LUTColor *)transformedToLinearFromColor:(LUTColor *)transformedColor{
    return self.transformedToLinearBlock(transformedColor.red, transformedColor.green, transformedColor.blue);
}

-(LUTColor *)linearToTransformedFromColor:(LUTColor *)linearColor{
    return self.linearToTransformedBlock(linearColor.red, linearColor.green, linearColor.blue);
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
                           @"sRGB": [LUTColorTransferFunction sRGBTransferFunction],
                           @"AlexaLogC_V3 EI800": [LUTColorTransferFunction arriLogCV3TransferFunctionWithEI:800]
                           };
    return dict;
}

+(instancetype)LUTColorTransferFunctionWithGamma:(double)gamma{
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value) {
                                                                                            return pow(value, gamma);}
                                                                 linearToTransformedBlock1D:^double(double value) {
                                                                                        return pow(value, 1.0/gamma);}];
}

+ (instancetype)rec709TransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            return (value < .081) ? value/4.5 : pow((value+.099)/1.099, 2.2);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            return (value < .018) ? 4.5*value : 1.099*pow(value, 1.0/2.2) - .099;} ];
}

+ (instancetype)sRGBTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            return (value <= .04045) ? value/12.92 : pow((value+.055)/1.055, 2.4);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            return (value <= .0031308) ? 12.92*value : 1.055*pow(value, 1.0/2.4) - .055;}];
}

+ (instancetype)arriLogCV3TransferFunctionWithEI:(double)EI{
    //taken from ACES git repo
    //https://github.com/ampas/aces-dev/blob/master/transforms/ctl/idt/vendorSupplied/arri/alexa/v3_IDT_maker.py
    
    double nominalEI = 400.0;
    double blackSignal = 0.003907;
    double midGraySignal = 0.01;
    double encodingGain = 0.256598;
    double encodingOffset = 0.391007;
    
    double cut = 1.0 / 9.0;
    double slope = 1.0 / (cut * log(10));
    double offset = log10(cut) - slope * cut;
    double gain = EI / nominalEI;
    double gray = midGraySignal / gain;
    // The higher the EI, the lower the gamma
    double encGain = (log(EI/nominalEI)/log(2) * (0.89 - 1) / 3 + 1) * encodingGain;
    double encOffset = encodingOffset;
    double nz;
    for (int i = 0; i < 3; i++){
        nz = ((95.0 / 1023.0 - encOffset) / encGain - offset) / slope;
        encOffset = encodingOffset - log10(1 + nz) * encGain;
    }
    // Calculate some intermediate values
    double a = 1.0 / gray;
    double b = nz - blackSignal / gray;
    double e = slope * a * encGain;
    double f = encGain * (slope * b + offset) + encOffset;
    // Manipulations so we can return relative exposure
    double s = 4 / (0.18 * EI);
    double t = blackSignal;
    b = b + a * t;
    a = a * s;
    f = f + e * t;
    e = e * s;
    
    cut = (cut-b) / a;
    double c = encGain;
    double d = encOffset;
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            return (value > e * cut + f) ? (pow(10, (value - d) / c) - b) / a: (value - f) / e;}
        
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            return (value > cut) ? c * log10(a * value + b) + d: e * value + f;}];
}

@end
