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
    @property (copy) LUTColor* (^transformedToLinearBlock)( double red, double green, double blue );
    @property (copy) LUTColor* (^linearToTransformedBlock)( double red, double green, double blue );

@end

@implementation LUTColorTransferFunction

-(instancetype)copyWithZone:(NSZone *)zone{
    return [self.class LUTColorTransferFunctionWithTransformedToLinearBlock:[self.transformedToLinearBlock copy]
                                                   linearToTransformedBlock:[self.linearToTransformedBlock copy]
                                                                       name:[self.name copyWithZone:zone]];
}

-(instancetype)initWithTransformedToLinearBlock:( LUTColor* ( ^ )(double red, double green, double blue) )transformedToLinearBlock
                       linearToTransformedBlock:( LUTColor* ( ^ )(double red, double green, double blue) )linearToTransformedBlock
                                           name:(NSString *)name{
    if (self = [super init]){
        self.transformedToLinearBlock = transformedToLinearBlock;
        self.linearToTransformedBlock = linearToTransformedBlock;
        self.name = name;
    }
    return self;
}

+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedExpressionString:(NSString *)redLinearToTransformedExpressionString
                                         greenLinearToTransformedExpressionString:(NSString *)greenLinearToTransformedExpressionString
                                          blueLinearToTransformedExpressionString:(NSString *)blueLinearToTransformedExpressionString
                                           redTransformedToLinearExpressionString:(NSString *)redTransformedToLinearExpressionString
                                         greenTransformedToLinearExpressionString:(NSString *)greenTransformedToLinearExpressionString
                                          blueTransformedToLinearExpressionString:(NSString *)blueTransformedToLinearExpressionString
                                                                             name:(NSString *)name{
    return nil;
}

+(instancetype)LUTColorTransferFunctionWithTransformedToLinearBlock:( LUTColor* ( ^ )(double red, double green, double blue) )transformedToLinearBlock
                                           linearToTransformedBlock:( LUTColor* ( ^ )(double red, double green, double blue) )linearToTransformedBlock
                                                               name:(NSString *)name{
    return [[self alloc] initWithTransformedToLinearBlock:transformedToLinearBlock
                                         linearToTransformedBlock:linearToTransformedBlock
                                                     name:name];
}

+(instancetype)LUTColorTransferFunctionWithTransformedToLinearBlock1D:( double ( ^ )(double value) )transformedToLinearBlock1D
                                           linearToTransformedBlock1D:( double ( ^ )(double value) )linearToTransformedBlock1D
                                                                 name:(NSString *)name{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock:^LUTColor*(double red, double green, double blue) {
                                                                                            return [LUTColor colorWithRed:transformedToLinearBlock1D(red)
                                                                                                                    green:transformedToLinearBlock1D(green)
                                                                                                                     blue:transformedToLinearBlock1D(blue)];}
                                                                 linearToTransformedBlock:^LUTColor*(double red, double green, double blue) {
                                                                                            return [LUTColor colorWithRed:linearToTransformedBlock1D(red)
                                                                                                                    green:linearToTransformedBlock1D(green)
                                                                                                                     blue:linearToTransformedBlock1D(blue)];}
                                                                                     name:name];
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
    
    LUT *transformedLUT = [[sourceLUT class] LUTOfSize:[sourceLUT size] inputLowerBound:[sourceLUT inputLowerBound] inputUpperBound:[sourceLUT inputUpperBound]];
    
    [transformedLUT copyMetaPropertiesFromLUT:sourceLUT];
    
    [transformedLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *transformedColor = [LUTColorTransferFunction transformedColorFromColor:[sourceLUT colorAtR:r g:g b:b]
                                                               fromColorTransferFunction:sourceColorTransferFunction
                                                                 toColorTransferFunction:destinationColorTransferFunction];
        
        [transformedLUT setColor:transformedColor r:r g:g b:b];
    }];
    
    return transformedLUT;
    
}

+ (LUTColor *)transformedColorFromColor:(LUTColor *)sourceColor
                   fromColorTransferFunction:(LUTColorTransferFunction *)sourceColorTransferFunction
                     toColorTransferFunction:(LUTColorTransferFunction *)destinationColorTransferFunction{
    LUTColor *sourceLinear = [sourceColorTransferFunction transformedToLinearFromColor:sourceColor];
    return [destinationColorTransferFunction linearToTransformedFromColor:sourceLinear];
}

+ (NSArray *)knownColorTransferFunctions{
    
    return @[[self linearTransferFunction],
             [self cineonTransferFunction],
             [self redLogFilmTransferFunction],
             [self gammaTransferFunctionWithGamma:2.2],
             [self gammaTransferFunctionWithGamma:2.4],
             [self gammaTransferFunctionWithGamma:2.6],
             [self rec709TransferFunction],
             [self sRGBTransferFunction],
             [self alexaLogCV3TransferFunctionWithEI:800],
             [self sLog2TransferFunction],
             [self canonLogTransferFunction]];
}

+(instancetype)linearTransferFunction{
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value) {
        return value;}
                                                                 linearToTransformedBlock1D:^double(double value) {
                                                                     return value;}
                                                                                       name:@"Linear"];
}

+(instancetype)gammaTransferFunctionWithGamma:(double)gamma{
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value) {
                                                                                            if(gamma == 1.0){
                                                                                                return value;
                                                                                            }
                                                                                            return pow(value, gamma);}
                                                                 linearToTransformedBlock1D:^double(double value) {
                                                                                            if(gamma == 1.0){
                                                                                                return value;
                                                                                             }
                                                                                            return pow(value, 1.0/gamma);}
            name:[NSString stringWithFormat:@"Gamma %.1f", gamma]];
}

+ (instancetype)rec709TransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clamp(value, 0.0, 1.0);
                                                                                            return (value <= .081) ? value/4.5 : pow((value+.099)/1.099, 2.2);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double output = (value <= .018) ? 4.5*value : 1.099*pow(value, 1.0/2.2) - .099;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:@"Rec. 709"];
}

+ (instancetype)sRGBTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value <= .04045) ? value/12.92 : pow((value+.055)/1.055, 2.4);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double output = (value <= .0031308) ? 12.92*value : 1.055*pow(value, 1.0/2.4) - .055;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:@"sRGB"];
}

+ (instancetype)cineonTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                    value = clamp(value, 0.0, 1.0);
                                                                    return pow(10.0,(1023.0*value-685.0)/300.0)-.0108/(1-.0108);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     double output = (300.0*log(value+27.0/2473.0) + 685.0*log(10.0))/(1023.0*log(10.0));
                                                                     return clamp(output, 0.0, 1.0);}
                                                                                       name:@"Cineon"];
}

+ (instancetype)redLogFilmTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        value = clamp(value, 0.0, 1.0);
        return pow(10.0,(1023.0*value-685.0)/300.0)-.0108/(1-.0108);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     double output = (300.0*log(value+27.0/2473.0) + 685.0*log(10.0))/(1023.0*log(10.0));
                                                                     return clamp(output, 0.0, 1.0);}
                                                                                       name:@"REDLogFilm"];
}

+ (instancetype)JPLogTransferFunction{
    double pdxLinReference = .18;
    double pdxLogReference = 445.0;
    double pdxNegativeGamma = .6;
    double pdxDensityPerCodeValue = .002;
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                    value = clamp(value, 0.0, 1.0);
                                                                    return pow(10.0, (value*1023.0 - pdxLogReference)*pdxDensityPerCodeValue/pdxNegativeGamma) * pdxLinReference;}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     value = MAX( value, 1e-10 ) / pdxLinReference;
                                                                     double output = pdxLogReference +
                                                                     log10(value)*pdxNegativeGamma/pdxDensityPerCodeValue;
                                                                     return clamp(output/1023.0, 0.0, 1.0);}
                                                                                       name:@"JPLog"];
}

+ (instancetype)alexaLogCV3TransferFunctionWithEI:(double)EI{
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
    double encGain = (log(EI/nominalEI)/log(2.0) * (0.89 - 1.0) / 3.0 + 1.0) * encodingGain;
    double encOffset = encodingOffset;
    double nz;
    for (int i = 0; i < 3; i++){
        nz = ((95.0 / 1023.0 - encOffset) / encGain - offset) / slope;
        encOffset = encodingOffset - log10(1.0 + nz) * encGain;
    }
    // Calculate some intermediate values
    double a = 1.0 / gray;
    double b = nz - blackSignal / gray;
    double e = slope * a * encGain;
    double f = encGain * (slope * b + offset) + encOffset;
    // Manipulations so we can return relative exposure
    double s = 4.0 / (0.18 * EI);
    double t = blackSignal;
    b = b + a * t;
    a = a * s;
    f = f + e * t;
    e = e * s;
    
    cut = (cut-b) / a;
    double c = encGain;
    double d = encOffset;
    
    
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clamp(value, 0.0, 1.0);
                                                                                            return (value > e * cut + f) ? (pow(10.0, (value - d) / c) - b) / a: (value - f) / e;}
        
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double output = (value > cut) ? c * log10(a * value + b) + d: e * value + f;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:[NSString stringWithFormat:@"AlexaV3LogC EI %i", (int)EI]];
    
}

+ (instancetype)canonLogTransferFunction {
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clamp(value, 0.0, 1.0);
                                                                                            double valueAsIRE = (value*1023.0 - 64.0) / 876.0;
                                                                                            return (pow(10,(valueAsIRE-0.0730597)/0.529136)-1)/10.1596;}
            
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double valueAsIRE = .529136*log10(10.1596*value+1)+.0730597;
                                                                                            double output = (876.0*valueAsIRE + 64.0)/1023.0;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:@"CanonLog"];
}

//4096
+ (instancetype)sLog2TransferFunction {
    double b = 256.0;
    double ab = 360.0;
    double w = 3760.0;
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double valueAsInt = (4095.0*value);
                                                                                            return (valueAsInt >= ab) ? (219. * (pow(10., (((valueAsInt - b) / (w - b) - 0.616596 - 0.03) / 0.432699)) - 0.037584) / 155.) : ((( valueAsInt - b) / (w - b) - 0.030001222851889303) / 3.53881278538813) * 0.9;}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double valueAsInt = (int)(4095.0*value);
                                                                                            double transitionValue = (219. * (pow(10., (((ab - b) / (w - b) - 0.616596 - 0.03) / 0.432699)) - 0.037584) / 155.)*4095.;
                                                                                            return (valueAsInt >= transitionValue) ? b*(1.0 + (.0187919*w - .0187919*b)*log(22.0912*valueAsInt + 1.1731)) : b*(0.969999 - 3.93201*valueAsInt) + w*(3.93201*valueAsInt + .0300012);}
                                                                                       name:@"S-Log2"];
}

@end
