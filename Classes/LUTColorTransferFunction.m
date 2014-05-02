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
    
    LUT *transformedLUT = [[sourceLUT class] LUTOfSize:[sourceLUT size] inputLowerBound:[sourceLUT inputLowerBound] inputUpperBound:[sourceLUT inputUpperBound]];
    
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

+ (M13OrderedDictionary *)knownColorTransferFunctions{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Linear": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:1.0]},
                                                                  @{@"Gamma 2.2": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:2.2]},
                                                                  @{@"Gamma 2.4": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:2.4]},
                                                                  @{@"Gamma 2.6": [LUTColorTransferFunction LUTColorTransferFunctionWithGamma:2.6]},
                                                                  @{@"Rec. 709": [LUTColorTransferFunction rec709TransferFunction]},
                                                                  @{@"sRGB": [LUTColorTransferFunction sRGBTransferFunction]},
                                                                  @{@"AlexaLogC_V3 EI800": [LUTColorTransferFunction arriLogCV3TransferFunctionWithEI:800]},
                                                                  @{@"Arri K1S1": [LUTColorTransferFunction arriK1S1VideoCurveWithMaxValue:55.080231]},
                                                                  @{@"S-Log2": [LUTColorTransferFunction sLog2TransferFunction]},
                                                                  @{@"CanonLog": [LUTColorTransferFunction canonLogTransferFunction]},
                                                                  @{@"BMD Film": [LUTColorTransferFunction bmdFilmTransferFunction]},
                                                                  ]);
}

+(instancetype)LUTColorTransferFunctionWithGamma:(double)gamma{
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value) {
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            if(gamma == 1.0){
                                                                                                return value;
                                                                                            }
                                                                                            return pow(value, gamma);}
                                                                 linearToTransformedBlock1D:^double(double value) {
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            if(gamma == 1.0){
                                                                                                return value;
                                                                                             }
                                                                                            return pow(value, 1.0/gamma);}];
}

+ (instancetype)rec709TransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value <= .081) ? value/4.5 : pow((value+.099)/1.099, 2.2);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value <= .018) ? 4.5*value : 1.099*pow(value, 1.0/2.2) - .099;} ];
}

+ (instancetype)sRGBTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value <= .04045) ? value/12.92 : pow((value+.055)/1.055, 2.4);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
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
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value > e * cut + f) ? (pow(10.0, (value - d) / c) - b) / a: (value - f) / e;}
        
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value > cut) ? c * log10(a * value + b) + d: e * value + f;}];
}

+ (instancetype)arriK1S1VideoCurveWithMaxValue:(double)maxValue{
    LUT1D *arriLogCToK1S1 = [LUTColorTransferFunction arriLogCToVideoK1S1];
    LUT1D *arriK1S1ToLogC = [LUTColorTransferFunction arriK1S1VideoToLogC];
    LUTColorTransferFunction *arriLogCV3TransferFunction = [LUTColorTransferFunction arriLogCV3TransferFunctionWithEI:800];
    
    //double minValueK1S1 = [arriLogCToK1S1 colorAtColor:[arriLogCV3TransferFunction linearToTransformedFromColor:[LUTColor colorWithRed:0 green:0 blue:0]]].red;
    double maxValueK1S1 = [arriLogCToK1S1 colorAtColor:[arriLogCV3TransferFunction linearToTransformedFromColor:[LUTColor colorWithRed:maxValue green:maxValue blue:maxValue]]].red;
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock:^LUTColor*(double red, double green, double blue) {
                                                                                            LUTColor *logColor = [arriK1S1ToLogC colorAtColor:[[LUTColor colorWithRed:red green:green blue:blue] contrastStretchWithCurrentMin:0.0 currentMax:1.0 finalMin:0.0 finalMax:maxValueK1S1]];
                                                                                            return [arriLogCV3TransferFunction transformedToLinearFromColor:logColor];}
                                                                 linearToTransformedBlock:^LUTColor*(double red, double green, double blue) {
                                                                                            LUTColor *logColor = [arriLogCV3TransferFunction linearToTransformedFromColor:[LUTColor colorWithRed:red green:green blue:blue]];
                                                                                            return [[arriLogCToK1S1 colorAtColor:logColor] contrastStretchWithCurrentMin:0.0 currentMax:maxValueK1S1 finalMin:0.0 finalMax:1.0];}];
    
}

+ (instancetype)bmdFilmTransferFunction {
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value <= 0.15) ? 0.286464*value : 0.13*(pow(10, 2.2987*value + -0.701) + -.22);}
            
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                             value = clampLowerBound(value, 0.0);
                                                                                             return (value <= 0.0286464) ? value/0.286464 : 0.18893*(log(384.62*value + 11.0) - .4341422747);}];
}

+ (instancetype)canonLogTransferFunction {
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double valueAsIRE = (value*1023.0 - 64.0) / 876.0;
                                                                                            return (pow(10,(valueAsIRE-0.0730597)/0.529136)-1)/10.1596;}
            
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double valueAsIRE = .529136*log10(10.1596*value+1)+.0730597;
                                                                                            return (876.0*valueAsIRE + 64.0)/1023.0;}];
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
                                                                                            return (valueAsInt >= transitionValue) ? b*(1.0 + (.0187919*w - .0187919*b)*log(22.0912*valueAsInt + 1.1731)) : b*(0.969999 - 3.93201*valueAsInt) + w*(3.93201*valueAsInt + .0300012);}];
}

+ (LUT1D *)arriLogCToVideoK1S1{
    NSArray *points = @[@(0.000000),@(0.011925),@(0.025187),@(0.040327),@(0.057887),@(0.078408),@(0.102434),@(0.130504),@(0.163160),@(0.203022),
                        @(0.252728),@(0.309158),@(0.369051),@(0.429382),@(0.489473),@(0.549180),@(0.608232),@(0.666355),@(0.723277),@(0.778726),
                        @(0.830911),@(0.874056),@(0.908517),@(0.935314),@(0.955469),@(0.970000),@(0.979930),@(0.986277),@(0.990064),@(0.992308),
                        @(0.994033),@(0.996256),@(1.000000)];
    return [LUT1D LUT1DWith1DCurve:points lowerBound:0.0 upperBound:1.0];
}

+ (LUT1D *)arriK1S1VideoToLogC{
    NSArray *points = @[@(0.000000),@(0.075550),@(0.132465),@(0.176763),@(0.212989),@(0.243760),@(0.270077),@(0.291737),@(0.310905),@(0.328646),
                        @(0.345526),@(0.361909),@(0.378070),@(0.394244),@(0.410465),@(0.426708),@(0.442991),@(0.459336),@(0.475764),@(0.492296),
                        @(0.508958),@(0.525775),@(0.542774),@(0.559987),@(0.577448),@(0.595199),@(0.613415),@(0.633629),@(0.657017),@(0.685196),
                        @(0.721721),@(0.778072),@(1.000000)];
    return [LUT1D LUT1DWith1DCurve:points lowerBound:0.0 upperBound:1.0];
}

@end
