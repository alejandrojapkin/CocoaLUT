//
//  LUTColorTransferFunction.m
//  Pods
//
//  Created by Greg Cotten on 4/3/14.
//
//

#import "LUTColorTransferFunction.h"
#include "math.h"

#import <SAMCubicSpline/SAMCubicSpline.h>

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
                           @"AlexaLogC_V3 EI800": [LUTColorTransferFunction arriLogCV3TransferFunctionWithEI:800],
                           @"AlexaLogC_V3 EI400": [LUTColorTransferFunction arriLogCV3TransferFunctionWithEI:400],
                           @"S-Log2": [LUTColorTransferFunction sLog2TransferFunction],
                           @"CanonLog": [LUTColorTransferFunction canonLogTransferFunction],
                           @"BMD Film": [LUTColorTransferFunction bmdFilmTransferFunction]};
    
    return dict;
}

+(instancetype)LUTColorTransferFunctionWithGamma:(double)gamma{
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value) {
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return pow(value, gamma);}
                                                                 linearToTransformedBlock1D:^double(double value) {
                                                                                            value = clampLowerBound(value, 0.0);
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

+ (instancetype)arriK1S1TransferFunction {
    SAMCubicSpline *transformedToLinearSpline = [[SAMCubicSpline alloc]initWithPoints:[LUTColorTransferFunction arriK1S1ToLinearDataPoints]];
    SAMCubicSpline *linearToTransformedSpline = [[SAMCubicSpline alloc]initWithPoints:[LUTColorTransferFunction linearToArriK1S1DataPoints]];
    
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return [transformedToLinearSpline interpolate:value];}
            
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                             value = clampLowerBound(value, 0.0);
                                                                                            return [linearToTransformedSpline interpolate:value];}];
}
        

+ (NSArray *)arriK1S1ToLinearDataPoints {
#if TARGET_OS_IPHONE
    return @[[NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0f)],
      [NSValue valueWithCGPoint:CGPointMake(0.00671140939597f, 0.0f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0134228187919f, 0.0f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0201342281879f, 0.0f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0268456375839f, 0.0f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0335570469799f, 0.0f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0402684563758f, 0.0f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0469798657718f, 0.002122f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0536912751678f, 0.004399f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0604026845638f, 0.006676f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0671140939597f, 0.008606f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0738255033557f, 0.010379f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0805369127517f, 0.012214f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0872483221477f, 0.014217f)],
      [NSValue valueWithCGPoint:CGPointMake(0.0939597315436f, 0.016394f)],
      [NSValue valueWithCGPoint:CGPointMake(0.10067114094f, 0.018333f)],
      [NSValue valueWithCGPoint:CGPointMake(0.107382550336f, 0.020418f)],
      [NSValue valueWithCGPoint:CGPointMake(0.114093959732f, 0.02266f)],
      [NSValue valueWithCGPoint:CGPointMake(0.120805369128f, 0.025071f)],
      [NSValue valueWithCGPoint:CGPointMake(0.127516778523f, 0.027511f)],
      [NSValue valueWithCGPoint:CGPointMake(0.134228187919f, 0.029855f)],
      [NSValue valueWithCGPoint:CGPointMake(0.140939597315f, 0.032348f)],
      [NSValue valueWithCGPoint:CGPointMake(0.147651006711f, 0.034999f)],
      [NSValue valueWithCGPoint:CGPointMake(0.154362416107f, 0.037819f)],
      [NSValue valueWithCGPoint:CGPointMake(0.161073825503f, 0.040497f)],
      [NSValue valueWithCGPoint:CGPointMake(0.167785234899f, 0.043195f)],
      [NSValue valueWithCGPoint:CGPointMake(0.174496644295f, 0.046038f)],
      [NSValue valueWithCGPoint:CGPointMake(0.181208053691f, 0.049036f)],
      [NSValue valueWithCGPoint:CGPointMake(0.187919463087f, 0.052159f)],
      [NSValue valueWithCGPoint:CGPointMake(0.194630872483f, 0.054886f)],
      [NSValue valueWithCGPoint:CGPointMake(0.201342281879f, 0.057733f)],
      [NSValue valueWithCGPoint:CGPointMake(0.208053691275f, 0.060706f)],
      [NSValue valueWithCGPoint:CGPointMake(0.214765100671f, 0.063811f)],
      [NSValue valueWithCGPoint:CGPointMake(0.221476510067f, 0.066899f)],
      [NSValue valueWithCGPoint:CGPointMake(0.228187919463f, 0.069882f)],
      [NSValue valueWithCGPoint:CGPointMake(0.234899328859f, 0.072982f)],
      [NSValue valueWithCGPoint:CGPointMake(0.241610738255f, 0.076203f)],
      [NSValue valueWithCGPoint:CGPointMake(0.248322147651f, 0.079549f)],
      [NSValue valueWithCGPoint:CGPointMake(0.255033557047f, 0.082829f)],
      [NSValue valueWithCGPoint:CGPointMake(0.261744966443f, 0.086162f)],
      [NSValue valueWithCGPoint:CGPointMake(0.268456375839f, 0.089614f)],
      [NSValue valueWithCGPoint:CGPointMake(0.275167785235f, 0.093192f)],
      [NSValue valueWithCGPoint:CGPointMake(0.281879194631f, 0.096882f)],
      [NSValue valueWithCGPoint:CGPointMake(0.288590604027f, 0.100532f)],
      [NSValue valueWithCGPoint:CGPointMake(0.295302013423f, 0.104308f)],
      [NSValue valueWithCGPoint:CGPointMake(0.302013422819f, 0.108214f)],
      [NSValue valueWithCGPoint:CGPointMake(0.308724832215f, 0.112254f)],
      [NSValue valueWithCGPoint:CGPointMake(0.315436241611f, 0.116378f)],
      [NSValue valueWithCGPoint:CGPointMake(0.322147651007f, 0.120569f)],
      [NSValue valueWithCGPoint:CGPointMake(0.328859060403f, 0.1249f)],
      [NSValue valueWithCGPoint:CGPointMake(0.335570469799f, 0.129374f)],
      [NSValue valueWithCGPoint:CGPointMake(0.342281879195f, 0.133998f)],
      [NSValue valueWithCGPoint:CGPointMake(0.348993288591f, 0.138725f)],
      [NSValue valueWithCGPoint:CGPointMake(0.355704697987f, 0.143593f)],
      [NSValue valueWithCGPoint:CGPointMake(0.362416107383f, 0.14862f)],
      [NSValue valueWithCGPoint:CGPointMake(0.369127516779f, 0.153813f)],
      [NSValue valueWithCGPoint:CGPointMake(0.375838926174f, 0.159177f)],
      [NSValue valueWithCGPoint:CGPointMake(0.38255033557f, 0.164721f)],
      [NSValue valueWithCGPoint:CGPointMake(0.389261744966f, 0.170447f)],
      [NSValue valueWithCGPoint:CGPointMake(0.395973154362f, 0.176362f)],
      [NSValue valueWithCGPoint:CGPointMake(0.402684563758f, 0.182471f)],
      [NSValue valueWithCGPoint:CGPointMake(0.409395973154f, 0.18879f)],
      [NSValue valueWithCGPoint:CGPointMake(0.41610738255f, 0.195327f)],
      [NSValue valueWithCGPoint:CGPointMake(0.422818791946f, 0.20208f)],
      [NSValue valueWithCGPoint:CGPointMake(0.429530201342f, 0.209056f)],
      [NSValue valueWithCGPoint:CGPointMake(0.436241610738f, 0.216262f)],
      [NSValue valueWithCGPoint:CGPointMake(0.442953020134f, 0.223713f)],
      [NSValue valueWithCGPoint:CGPointMake(0.44966442953f, 0.231413f)],
      [NSValue valueWithCGPoint:CGPointMake(0.456375838926f, 0.239367f)],
      [NSValue valueWithCGPoint:CGPointMake(0.463087248322f, 0.247584f)],
      [NSValue valueWithCGPoint:CGPointMake(0.469798657718f, 0.256075f)],
      [NSValue valueWithCGPoint:CGPointMake(0.476510067114f, 0.264866f)],
      [NSValue valueWithCGPoint:CGPointMake(0.48322147651f, 0.273947f)],
      [NSValue valueWithCGPoint:CGPointMake(0.489932885906f, 0.28333f)],
      [NSValue valueWithCGPoint:CGPointMake(0.496644295302f, 0.293023f)],
      [NSValue valueWithCGPoint:CGPointMake(0.503355704698f, 0.303056f)],
      [NSValue valueWithCGPoint:CGPointMake(0.510067114094f, 0.313442f)],
      [NSValue valueWithCGPoint:CGPointMake(0.51677852349f, 0.324174f)],
      [NSValue valueWithCGPoint:CGPointMake(0.523489932886f, 0.335262f)],
      [NSValue valueWithCGPoint:CGPointMake(0.530201342282f, 0.346718f)],
      [NSValue valueWithCGPoint:CGPointMake(0.536912751678f, 0.358607f)],
      [NSValue valueWithCGPoint:CGPointMake(0.543624161074f, 0.370903f)],
      [NSValue valueWithCGPoint:CGPointMake(0.55033557047f, 0.38361f)],
      [NSValue valueWithCGPoint:CGPointMake(0.557046979866f, 0.396741f)],
      [NSValue valueWithCGPoint:CGPointMake(0.563758389262f, 0.410327f)],
      [NSValue valueWithCGPoint:CGPointMake(0.570469798658f, 0.424441f)],
      [NSValue valueWithCGPoint:CGPointMake(0.577181208054f, 0.43903f)],
      [NSValue valueWithCGPoint:CGPointMake(0.58389261745f, 0.454109f)],
      [NSValue valueWithCGPoint:CGPointMake(0.590604026846f, 0.469696f)],
      [NSValue valueWithCGPoint:CGPointMake(0.597315436242f, 0.485874f)],
      [NSValue valueWithCGPoint:CGPointMake(0.604026845638f, 0.502662f)],
      [NSValue valueWithCGPoint:CGPointMake(0.610738255034f, 0.520019f)],
      [NSValue valueWithCGPoint:CGPointMake(0.61744966443f, 0.537964f)],
      [NSValue valueWithCGPoint:CGPointMake(0.624161073826f, 0.556517f)],
      [NSValue valueWithCGPoint:CGPointMake(0.630872483221f, 0.575857f)],
      [NSValue valueWithCGPoint:CGPointMake(0.637583892617f, 0.595883f)],
      [NSValue valueWithCGPoint:CGPointMake(0.644295302013f, 0.616593f)],
      [NSValue valueWithCGPoint:CGPointMake(0.651006711409f, 0.638012f)],
      [NSValue valueWithCGPoint:CGPointMake(0.657718120805f, 0.660217f)],
      [NSValue valueWithCGPoint:CGPointMake(0.664429530201f, 0.683381f)],
      [NSValue valueWithCGPoint:CGPointMake(0.671140939597f, 0.707346f)],
      [NSValue valueWithCGPoint:CGPointMake(0.677852348993f, 0.732141f)],
      [NSValue valueWithCGPoint:CGPointMake(0.684563758389f, 0.757792f)],
      [NSValue valueWithCGPoint:CGPointMake(0.691275167785f, 0.784523f)],
      [NSValue valueWithCGPoint:CGPointMake(0.697986577181f, 0.812338f)],
      [NSValue valueWithCGPoint:CGPointMake(0.704697986577f, 0.841128f)],
      [NSValue valueWithCGPoint:CGPointMake(0.711409395973f, 0.870927f)],
      [NSValue valueWithCGPoint:CGPointMake(0.718120805369f, 0.90177f)],
      [NSValue valueWithCGPoint:CGPointMake(0.724832214765f, 0.934118f)],
      [NSValue valueWithCGPoint:CGPointMake(0.731543624161f, 0.967659f)],
      [NSValue valueWithCGPoint:CGPointMake(0.738255033557f, 1.002393f)],
      [NSValue valueWithCGPoint:CGPointMake(0.744966442953f, 1.038361f)],
      [NSValue valueWithCGPoint:CGPointMake(0.751677852349f, 1.075765f)],
      [NSValue valueWithCGPoint:CGPointMake(0.758389261745f, 1.114994f)],
      [NSValue valueWithCGPoint:CGPointMake(0.765100671141f, 1.155641f)],
      [NSValue valueWithCGPoint:CGPointMake(0.771812080537f, 1.197758f)],
      [NSValue valueWithCGPoint:CGPointMake(0.778523489933f, 1.241397f)],
      [NSValue valueWithCGPoint:CGPointMake(0.785234899329f, 1.287329f)],
      [NSValue valueWithCGPoint:CGPointMake(0.791946308725f, 1.335456f)],
      [NSValue valueWithCGPoint:CGPointMake(0.798657718121f, 1.38537f)],
      [NSValue valueWithCGPoint:CGPointMake(0.805369127517f, 1.437136f)],
      [NSValue valueWithCGPoint:CGPointMake(0.812080536913f, 1.490823f)],
      [NSValue valueWithCGPoint:CGPointMake(0.818791946309f, 1.552345f)],
      [NSValue valueWithCGPoint:CGPointMake(0.825503355705f, 1.616795f)],
      [NSValue valueWithCGPoint:CGPointMake(0.832214765101f, 1.683905f)],
      [NSValue valueWithCGPoint:CGPointMake(0.838926174497f, 1.753785f)],
      [NSValue valueWithCGPoint:CGPointMake(0.845637583893f, 1.82983f)],
      [NSValue valueWithCGPoint:CGPointMake(0.852348993289f, 1.917931f)],
      [NSValue valueWithCGPoint:CGPointMake(0.859060402685f, 2.010252f)],
      [NSValue valueWithCGPoint:CGPointMake(0.865771812081f, 2.106995f)],
      [NSValue valueWithCGPoint:CGPointMake(0.872483221477f, 2.208372f)],
      [NSValue valueWithCGPoint:CGPointMake(0.879194630872f, 2.328569f)],
      [NSValue valueWithCGPoint:CGPointMake(0.885906040268f, 2.464155f)],
      [NSValue valueWithCGPoint:CGPointMake(0.892617449664f, 2.607604f)],
      [NSValue valueWithCGPoint:CGPointMake(0.89932885906f, 2.759372f)],
      [NSValue valueWithCGPoint:CGPointMake(0.906040268456f, 2.919941f)],
      [NSValue valueWithCGPoint:CGPointMake(0.912751677852f, 3.140359f)],
      [NSValue valueWithCGPoint:CGPointMake(0.919463087248f, 3.379131f)],
      [NSValue valueWithCGPoint:CGPointMake(0.926174496644f, 3.636002f)],
      [NSValue valueWithCGPoint:CGPointMake(0.93288590604f, 3.912346f)],
      [NSValue valueWithCGPoint:CGPointMake(0.939597315436f, 4.262257f)],
      [NSValue valueWithCGPoint:CGPointMake(0.946308724832f, 4.772008f)],
      [NSValue valueWithCGPoint:CGPointMake(0.953020134228f, 5.342589f)],
      [NSValue valueWithCGPoint:CGPointMake(0.959731543624f, 5.98126f)],
      [NSValue valueWithCGPoint:CGPointMake(0.96644295302f, 6.696145f)],
      [NSValue valueWithCGPoint:CGPointMake(0.973154362416f, 9.318853f)],
      [NSValue valueWithCGPoint:CGPointMake(0.979865771812f, 14.532387f)],
      [NSValue valueWithCGPoint:CGPointMake(0.986577181208f, 22.659746f)],
      [NSValue valueWithCGPoint:CGPointMake(0.993288590604f, 35.329456f)],
      [NSValue valueWithCGPoint:CGPointMake(1.0f, 55.080227f)]];
#else
    return @[[NSValue valueWithPoint:CGPointMake(0.0f, 0.0f)],
      [NSValue valueWithPoint:CGPointMake(0.00671140939597f, 0.0f)],
      [NSValue valueWithPoint:CGPointMake(0.0134228187919f, 0.0f)],
      [NSValue valueWithPoint:CGPointMake(0.0201342281879f, 0.0f)],
      [NSValue valueWithPoint:CGPointMake(0.0268456375839f, 0.0f)],
      [NSValue valueWithPoint:CGPointMake(0.0335570469799f, 0.0f)],
      [NSValue valueWithPoint:CGPointMake(0.0402684563758f, 0.0f)],
      [NSValue valueWithPoint:CGPointMake(0.0469798657718f, 0.002122f)],
      [NSValue valueWithPoint:CGPointMake(0.0536912751678f, 0.004399f)],
      [NSValue valueWithPoint:CGPointMake(0.0604026845638f, 0.006676f)],
      [NSValue valueWithPoint:CGPointMake(0.0671140939597f, 0.008606f)],
      [NSValue valueWithPoint:CGPointMake(0.0738255033557f, 0.010379f)],
      [NSValue valueWithPoint:CGPointMake(0.0805369127517f, 0.012214f)],
      [NSValue valueWithPoint:CGPointMake(0.0872483221477f, 0.014217f)],
      [NSValue valueWithPoint:CGPointMake(0.0939597315436f, 0.016394f)],
      [NSValue valueWithPoint:CGPointMake(0.10067114094f, 0.018333f)],
      [NSValue valueWithPoint:CGPointMake(0.107382550336f, 0.020418f)],
      [NSValue valueWithPoint:CGPointMake(0.114093959732f, 0.02266f)],
      [NSValue valueWithPoint:CGPointMake(0.120805369128f, 0.025071f)],
      [NSValue valueWithPoint:CGPointMake(0.127516778523f, 0.027511f)],
      [NSValue valueWithPoint:CGPointMake(0.134228187919f, 0.029855f)],
      [NSValue valueWithPoint:CGPointMake(0.140939597315f, 0.032348f)],
      [NSValue valueWithPoint:CGPointMake(0.147651006711f, 0.034999f)],
      [NSValue valueWithPoint:CGPointMake(0.154362416107f, 0.037819f)],
      [NSValue valueWithPoint:CGPointMake(0.161073825503f, 0.040497f)],
      [NSValue valueWithPoint:CGPointMake(0.167785234899f, 0.043195f)],
      [NSValue valueWithPoint:CGPointMake(0.174496644295f, 0.046038f)],
      [NSValue valueWithPoint:CGPointMake(0.181208053691f, 0.049036f)],
      [NSValue valueWithPoint:CGPointMake(0.187919463087f, 0.052159f)],
      [NSValue valueWithPoint:CGPointMake(0.194630872483f, 0.054886f)],
      [NSValue valueWithPoint:CGPointMake(0.201342281879f, 0.057733f)],
      [NSValue valueWithPoint:CGPointMake(0.208053691275f, 0.060706f)],
      [NSValue valueWithPoint:CGPointMake(0.214765100671f, 0.063811f)],
      [NSValue valueWithPoint:CGPointMake(0.221476510067f, 0.066899f)],
      [NSValue valueWithPoint:CGPointMake(0.228187919463f, 0.069882f)],
      [NSValue valueWithPoint:CGPointMake(0.234899328859f, 0.072982f)],
      [NSValue valueWithPoint:CGPointMake(0.241610738255f, 0.076203f)],
      [NSValue valueWithPoint:CGPointMake(0.248322147651f, 0.079549f)],
      [NSValue valueWithPoint:CGPointMake(0.255033557047f, 0.082829f)],
      [NSValue valueWithPoint:CGPointMake(0.261744966443f, 0.086162f)],
      [NSValue valueWithPoint:CGPointMake(0.268456375839f, 0.089614f)],
      [NSValue valueWithPoint:CGPointMake(0.275167785235f, 0.093192f)],
      [NSValue valueWithPoint:CGPointMake(0.281879194631f, 0.096882f)],
      [NSValue valueWithPoint:CGPointMake(0.288590604027f, 0.100532f)],
      [NSValue valueWithPoint:CGPointMake(0.295302013423f, 0.104308f)],
      [NSValue valueWithPoint:CGPointMake(0.302013422819f, 0.108214f)],
      [NSValue valueWithPoint:CGPointMake(0.308724832215f, 0.112254f)],
      [NSValue valueWithPoint:CGPointMake(0.315436241611f, 0.116378f)],
      [NSValue valueWithPoint:CGPointMake(0.322147651007f, 0.120569f)],
      [NSValue valueWithPoint:CGPointMake(0.328859060403f, 0.1249f)],
      [NSValue valueWithPoint:CGPointMake(0.335570469799f, 0.129374f)],
      [NSValue valueWithPoint:CGPointMake(0.342281879195f, 0.133998f)],
      [NSValue valueWithPoint:CGPointMake(0.348993288591f, 0.138725f)],
      [NSValue valueWithPoint:CGPointMake(0.355704697987f, 0.143593f)],
      [NSValue valueWithPoint:CGPointMake(0.362416107383f, 0.14862f)],
      [NSValue valueWithPoint:CGPointMake(0.369127516779f, 0.153813f)],
      [NSValue valueWithPoint:CGPointMake(0.375838926174f, 0.159177f)],
      [NSValue valueWithPoint:CGPointMake(0.38255033557f, 0.164721f)],
      [NSValue valueWithPoint:CGPointMake(0.389261744966f, 0.170447f)],
      [NSValue valueWithPoint:CGPointMake(0.395973154362f, 0.176362f)],
      [NSValue valueWithPoint:CGPointMake(0.402684563758f, 0.182471f)],
      [NSValue valueWithPoint:CGPointMake(0.409395973154f, 0.18879f)],
      [NSValue valueWithPoint:CGPointMake(0.41610738255f, 0.195327f)],
      [NSValue valueWithPoint:CGPointMake(0.422818791946f, 0.20208f)],
      [NSValue valueWithPoint:CGPointMake(0.429530201342f, 0.209056f)],
      [NSValue valueWithPoint:CGPointMake(0.436241610738f, 0.216262f)],
      [NSValue valueWithPoint:CGPointMake(0.442953020134f, 0.223713f)],
      [NSValue valueWithPoint:CGPointMake(0.44966442953f, 0.231413f)],
      [NSValue valueWithPoint:CGPointMake(0.456375838926f, 0.239367f)],
      [NSValue valueWithPoint:CGPointMake(0.463087248322f, 0.247584f)],
      [NSValue valueWithPoint:CGPointMake(0.469798657718f, 0.256075f)],
      [NSValue valueWithPoint:CGPointMake(0.476510067114f, 0.264866f)],
      [NSValue valueWithPoint:CGPointMake(0.48322147651f, 0.273947f)],
      [NSValue valueWithPoint:CGPointMake(0.489932885906f, 0.28333f)],
      [NSValue valueWithPoint:CGPointMake(0.496644295302f, 0.293023f)],
      [NSValue valueWithPoint:CGPointMake(0.503355704698f, 0.303056f)],
      [NSValue valueWithPoint:CGPointMake(0.510067114094f, 0.313442f)],
      [NSValue valueWithPoint:CGPointMake(0.51677852349f, 0.324174f)],
      [NSValue valueWithPoint:CGPointMake(0.523489932886f, 0.335262f)],
      [NSValue valueWithPoint:CGPointMake(0.530201342282f, 0.346718f)],
      [NSValue valueWithPoint:CGPointMake(0.536912751678f, 0.358607f)],
      [NSValue valueWithPoint:CGPointMake(0.543624161074f, 0.370903f)],
      [NSValue valueWithPoint:CGPointMake(0.55033557047f, 0.38361f)],
      [NSValue valueWithPoint:CGPointMake(0.557046979866f, 0.396741f)],
      [NSValue valueWithPoint:CGPointMake(0.563758389262f, 0.410327f)],
      [NSValue valueWithPoint:CGPointMake(0.570469798658f, 0.424441f)],
      [NSValue valueWithPoint:CGPointMake(0.577181208054f, 0.43903f)],
      [NSValue valueWithPoint:CGPointMake(0.58389261745f, 0.454109f)],
      [NSValue valueWithPoint:CGPointMake(0.590604026846f, 0.469696f)],
      [NSValue valueWithPoint:CGPointMake(0.597315436242f, 0.485874f)],
      [NSValue valueWithPoint:CGPointMake(0.604026845638f, 0.502662f)],
      [NSValue valueWithPoint:CGPointMake(0.610738255034f, 0.520019f)],
      [NSValue valueWithPoint:CGPointMake(0.61744966443f, 0.537964f)],
      [NSValue valueWithPoint:CGPointMake(0.624161073826f, 0.556517f)],
      [NSValue valueWithPoint:CGPointMake(0.630872483221f, 0.575857f)],
      [NSValue valueWithPoint:CGPointMake(0.637583892617f, 0.595883f)],
      [NSValue valueWithPoint:CGPointMake(0.644295302013f, 0.616593f)],
      [NSValue valueWithPoint:CGPointMake(0.651006711409f, 0.638012f)],
      [NSValue valueWithPoint:CGPointMake(0.657718120805f, 0.660217f)],
      [NSValue valueWithPoint:CGPointMake(0.664429530201f, 0.683381f)],
      [NSValue valueWithPoint:CGPointMake(0.671140939597f, 0.707346f)],
      [NSValue valueWithPoint:CGPointMake(0.677852348993f, 0.732141f)],
      [NSValue valueWithPoint:CGPointMake(0.684563758389f, 0.757792f)],
      [NSValue valueWithPoint:CGPointMake(0.691275167785f, 0.784523f)],
      [NSValue valueWithPoint:CGPointMake(0.697986577181f, 0.812338f)],
      [NSValue valueWithPoint:CGPointMake(0.704697986577f, 0.841128f)],
      [NSValue valueWithPoint:CGPointMake(0.711409395973f, 0.870927f)],
      [NSValue valueWithPoint:CGPointMake(0.718120805369f, 0.90177f)],
      [NSValue valueWithPoint:CGPointMake(0.724832214765f, 0.934118f)],
      [NSValue valueWithPoint:CGPointMake(0.731543624161f, 0.967659f)],
      [NSValue valueWithPoint:CGPointMake(0.738255033557f, 1.002393f)],
      [NSValue valueWithPoint:CGPointMake(0.744966442953f, 1.038361f)],
      [NSValue valueWithPoint:CGPointMake(0.751677852349f, 1.075765f)],
      [NSValue valueWithPoint:CGPointMake(0.758389261745f, 1.114994f)],
      [NSValue valueWithPoint:CGPointMake(0.765100671141f, 1.155641f)],
      [NSValue valueWithPoint:CGPointMake(0.771812080537f, 1.197758f)],
      [NSValue valueWithPoint:CGPointMake(0.778523489933f, 1.241397f)],
      [NSValue valueWithPoint:CGPointMake(0.785234899329f, 1.287329f)],
      [NSValue valueWithPoint:CGPointMake(0.791946308725f, 1.335456f)],
      [NSValue valueWithPoint:CGPointMake(0.798657718121f, 1.38537f)],
      [NSValue valueWithPoint:CGPointMake(0.805369127517f, 1.437136f)],
      [NSValue valueWithPoint:CGPointMake(0.812080536913f, 1.490823f)],
      [NSValue valueWithPoint:CGPointMake(0.818791946309f, 1.552345f)],
      [NSValue valueWithPoint:CGPointMake(0.825503355705f, 1.616795f)],
      [NSValue valueWithPoint:CGPointMake(0.832214765101f, 1.683905f)],
      [NSValue valueWithPoint:CGPointMake(0.838926174497f, 1.753785f)],
      [NSValue valueWithPoint:CGPointMake(0.845637583893f, 1.82983f)],
      [NSValue valueWithPoint:CGPointMake(0.852348993289f, 1.917931f)],
      [NSValue valueWithPoint:CGPointMake(0.859060402685f, 2.010252f)],
      [NSValue valueWithPoint:CGPointMake(0.865771812081f, 2.106995f)],
      [NSValue valueWithPoint:CGPointMake(0.872483221477f, 2.208372f)],
      [NSValue valueWithPoint:CGPointMake(0.879194630872f, 2.328569f)],
      [NSValue valueWithPoint:CGPointMake(0.885906040268f, 2.464155f)],
      [NSValue valueWithPoint:CGPointMake(0.892617449664f, 2.607604f)],
      [NSValue valueWithPoint:CGPointMake(0.89932885906f, 2.759372f)],
      [NSValue valueWithPoint:CGPointMake(0.906040268456f, 2.919941f)],
      [NSValue valueWithPoint:CGPointMake(0.912751677852f, 3.140359f)],
      [NSValue valueWithPoint:CGPointMake(0.919463087248f, 3.379131f)],
      [NSValue valueWithPoint:CGPointMake(0.926174496644f, 3.636002f)],
      [NSValue valueWithPoint:CGPointMake(0.93288590604f, 3.912346f)],
      [NSValue valueWithPoint:CGPointMake(0.939597315436f, 4.262257f)],
      [NSValue valueWithPoint:CGPointMake(0.946308724832f, 4.772008f)],
      [NSValue valueWithPoint:CGPointMake(0.953020134228f, 5.342589f)],
      [NSValue valueWithPoint:CGPointMake(0.959731543624f, 5.98126f)],
      [NSValue valueWithPoint:CGPointMake(0.96644295302f, 6.696145f)],
      [NSValue valueWithPoint:CGPointMake(0.973154362416f, 9.318853f)],
      [NSValue valueWithPoint:CGPointMake(0.979865771812f, 14.532387f)],
      [NSValue valueWithPoint:CGPointMake(0.986577181208f, 22.659746f)],
      [NSValue valueWithPoint:CGPointMake(0.993288590604f, 35.329456f)],
      [NSValue valueWithPoint:CGPointMake(1.0f, 55.080227f)]];
#endif
}

+ (NSArray *)linearToArriK1S1DataPoints {
#if TARGET_OS_IPHONE
    return @[[NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0f)],
             [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.00671140939597f)],
             [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0134228187919f)],
             [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0201342281879f)],
             [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0268456375839f)],
             [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0335570469799f)],
             [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0402684563758f)],
             [NSValue valueWithCGPoint:CGPointMake(0.002122f, 0.0469798657718f)],
             [NSValue valueWithCGPoint:CGPointMake(0.004399f, 0.0536912751678f)],
             [NSValue valueWithCGPoint:CGPointMake(0.006676f, 0.0604026845638f)],
             [NSValue valueWithCGPoint:CGPointMake(0.008606f, 0.0671140939597f)],
             [NSValue valueWithCGPoint:CGPointMake(0.010379f, 0.0738255033557f)],
             [NSValue valueWithCGPoint:CGPointMake(0.012214f, 0.0805369127517f)],
             [NSValue valueWithCGPoint:CGPointMake(0.014217f, 0.0872483221477f)],
             [NSValue valueWithCGPoint:CGPointMake(0.016394f, 0.0939597315436f)],
             [NSValue valueWithCGPoint:CGPointMake(0.018333f, 0.10067114094f)],
             [NSValue valueWithCGPoint:CGPointMake(0.020418f, 0.107382550336f)],
             [NSValue valueWithCGPoint:CGPointMake(0.02266f, 0.114093959732f)],
             [NSValue valueWithCGPoint:CGPointMake(0.025071f, 0.120805369128f)],
             [NSValue valueWithCGPoint:CGPointMake(0.027511f, 0.127516778523f)],
             [NSValue valueWithCGPoint:CGPointMake(0.029855f, 0.134228187919f)],
             [NSValue valueWithCGPoint:CGPointMake(0.032348f, 0.140939597315f)],
             [NSValue valueWithCGPoint:CGPointMake(0.034999f, 0.147651006711f)],
             [NSValue valueWithCGPoint:CGPointMake(0.037819f, 0.154362416107f)],
             [NSValue valueWithCGPoint:CGPointMake(0.040497f, 0.161073825503f)],
             [NSValue valueWithCGPoint:CGPointMake(0.043195f, 0.167785234899f)],
             [NSValue valueWithCGPoint:CGPointMake(0.046038f, 0.174496644295f)],
             [NSValue valueWithCGPoint:CGPointMake(0.049036f, 0.181208053691f)],
             [NSValue valueWithCGPoint:CGPointMake(0.052159f, 0.187919463087f)],
             [NSValue valueWithCGPoint:CGPointMake(0.054886f, 0.194630872483f)],
             [NSValue valueWithCGPoint:CGPointMake(0.057733f, 0.201342281879f)],
             [NSValue valueWithCGPoint:CGPointMake(0.060706f, 0.208053691275f)],
             [NSValue valueWithCGPoint:CGPointMake(0.063811f, 0.214765100671f)],
             [NSValue valueWithCGPoint:CGPointMake(0.066899f, 0.221476510067f)],
             [NSValue valueWithCGPoint:CGPointMake(0.069882f, 0.228187919463f)],
             [NSValue valueWithCGPoint:CGPointMake(0.072982f, 0.234899328859f)],
             [NSValue valueWithCGPoint:CGPointMake(0.076203f, 0.241610738255f)],
             [NSValue valueWithCGPoint:CGPointMake(0.079549f, 0.248322147651f)],
             [NSValue valueWithCGPoint:CGPointMake(0.082829f, 0.255033557047f)],
             [NSValue valueWithCGPoint:CGPointMake(0.086162f, 0.261744966443f)],
             [NSValue valueWithCGPoint:CGPointMake(0.089614f, 0.268456375839f)],
             [NSValue valueWithCGPoint:CGPointMake(0.093192f, 0.275167785235f)],
             [NSValue valueWithCGPoint:CGPointMake(0.096882f, 0.281879194631f)],
             [NSValue valueWithCGPoint:CGPointMake(0.100532f, 0.288590604027f)],
             [NSValue valueWithCGPoint:CGPointMake(0.104308f, 0.295302013423f)],
             [NSValue valueWithCGPoint:CGPointMake(0.108214f, 0.302013422819f)],
             [NSValue valueWithCGPoint:CGPointMake(0.112254f, 0.308724832215f)],
             [NSValue valueWithCGPoint:CGPointMake(0.116378f, 0.315436241611f)],
             [NSValue valueWithCGPoint:CGPointMake(0.120569f, 0.322147651007f)],
             [NSValue valueWithCGPoint:CGPointMake(0.1249f, 0.328859060403f)],
             [NSValue valueWithCGPoint:CGPointMake(0.129374f, 0.335570469799f)],
             [NSValue valueWithCGPoint:CGPointMake(0.133998f, 0.342281879195f)],
             [NSValue valueWithCGPoint:CGPointMake(0.138725f, 0.348993288591f)],
             [NSValue valueWithCGPoint:CGPointMake(0.143593f, 0.355704697987f)],
             [NSValue valueWithCGPoint:CGPointMake(0.14862f, 0.362416107383f)],
             [NSValue valueWithCGPoint:CGPointMake(0.153813f, 0.369127516779f)],
             [NSValue valueWithCGPoint:CGPointMake(0.159177f, 0.375838926174f)],
             [NSValue valueWithCGPoint:CGPointMake(0.164721f, 0.38255033557f)],
             [NSValue valueWithCGPoint:CGPointMake(0.170447f, 0.389261744966f)],
             [NSValue valueWithCGPoint:CGPointMake(0.176362f, 0.395973154362f)],
             [NSValue valueWithCGPoint:CGPointMake(0.182471f, 0.402684563758f)],
             [NSValue valueWithCGPoint:CGPointMake(0.18879f, 0.409395973154f)],
             [NSValue valueWithCGPoint:CGPointMake(0.195327f, 0.41610738255f)],
             [NSValue valueWithCGPoint:CGPointMake(0.20208f, 0.422818791946f)],
             [NSValue valueWithCGPoint:CGPointMake(0.209056f, 0.429530201342f)],
             [NSValue valueWithCGPoint:CGPointMake(0.216262f, 0.436241610738f)],
             [NSValue valueWithCGPoint:CGPointMake(0.223713f, 0.442953020134f)],
             [NSValue valueWithCGPoint:CGPointMake(0.231413f, 0.44966442953f)],
             [NSValue valueWithCGPoint:CGPointMake(0.239367f, 0.456375838926f)],
             [NSValue valueWithCGPoint:CGPointMake(0.247584f, 0.463087248322f)],
             [NSValue valueWithCGPoint:CGPointMake(0.256075f, 0.469798657718f)],
             [NSValue valueWithCGPoint:CGPointMake(0.264866f, 0.476510067114f)],
             [NSValue valueWithCGPoint:CGPointMake(0.273947f, 0.48322147651f)],
             [NSValue valueWithCGPoint:CGPointMake(0.28333f, 0.489932885906f)],
             [NSValue valueWithCGPoint:CGPointMake(0.293023f, 0.496644295302f)],
             [NSValue valueWithCGPoint:CGPointMake(0.303056f, 0.503355704698f)],
             [NSValue valueWithCGPoint:CGPointMake(0.313442f, 0.510067114094f)],
             [NSValue valueWithCGPoint:CGPointMake(0.324174f, 0.51677852349f)],
             [NSValue valueWithCGPoint:CGPointMake(0.335262f, 0.523489932886f)],
             [NSValue valueWithCGPoint:CGPointMake(0.346718f, 0.530201342282f)],
             [NSValue valueWithCGPoint:CGPointMake(0.358607f, 0.536912751678f)],
             [NSValue valueWithCGPoint:CGPointMake(0.370903f, 0.543624161074f)],
             [NSValue valueWithCGPoint:CGPointMake(0.38361f, 0.55033557047f)],
             [NSValue valueWithCGPoint:CGPointMake(0.396741f, 0.557046979866f)],
             [NSValue valueWithCGPoint:CGPointMake(0.410327f, 0.563758389262f)],
             [NSValue valueWithCGPoint:CGPointMake(0.424441f, 0.570469798658f)],
             [NSValue valueWithCGPoint:CGPointMake(0.43903f, 0.577181208054f)],
             [NSValue valueWithCGPoint:CGPointMake(0.454109f, 0.58389261745f)],
             [NSValue valueWithCGPoint:CGPointMake(0.469696f, 0.590604026846f)],
             [NSValue valueWithCGPoint:CGPointMake(0.485874f, 0.597315436242f)],
             [NSValue valueWithCGPoint:CGPointMake(0.502662f, 0.604026845638f)],
             [NSValue valueWithCGPoint:CGPointMake(0.520019f, 0.610738255034f)],
             [NSValue valueWithCGPoint:CGPointMake(0.537964f, 0.61744966443f)],
             [NSValue valueWithCGPoint:CGPointMake(0.556517f, 0.624161073826f)],
             [NSValue valueWithCGPoint:CGPointMake(0.575857f, 0.630872483221f)],
             [NSValue valueWithCGPoint:CGPointMake(0.595883f, 0.637583892617f)],
             [NSValue valueWithCGPoint:CGPointMake(0.616593f, 0.644295302013f)],
             [NSValue valueWithCGPoint:CGPointMake(0.638012f, 0.651006711409f)],
             [NSValue valueWithCGPoint:CGPointMake(0.660217f, 0.657718120805f)],
             [NSValue valueWithCGPoint:CGPointMake(0.683381f, 0.664429530201f)],
             [NSValue valueWithCGPoint:CGPointMake(0.707346f, 0.671140939597f)],
             [NSValue valueWithCGPoint:CGPointMake(0.732141f, 0.677852348993f)],
             [NSValue valueWithCGPoint:CGPointMake(0.757792f, 0.684563758389f)],
             [NSValue valueWithCGPoint:CGPointMake(0.784523f, 0.691275167785f)],
             [NSValue valueWithCGPoint:CGPointMake(0.812338f, 0.697986577181f)],
             [NSValue valueWithCGPoint:CGPointMake(0.841128f, 0.704697986577f)],
             [NSValue valueWithCGPoint:CGPointMake(0.870927f, 0.711409395973f)],
             [NSValue valueWithCGPoint:CGPointMake(0.90177f, 0.718120805369f)],
             [NSValue valueWithCGPoint:CGPointMake(0.934118f, 0.724832214765f)],
             [NSValue valueWithCGPoint:CGPointMake(0.967659f, 0.731543624161f)],
             [NSValue valueWithCGPoint:CGPointMake(1.002393f, 0.738255033557f)],
             [NSValue valueWithCGPoint:CGPointMake(1.038361f, 0.744966442953f)],
             [NSValue valueWithCGPoint:CGPointMake(1.075765f, 0.751677852349f)],
             [NSValue valueWithCGPoint:CGPointMake(1.114994f, 0.758389261745f)],
             [NSValue valueWithCGPoint:CGPointMake(1.155641f, 0.765100671141f)],
             [NSValue valueWithCGPoint:CGPointMake(1.197758f, 0.771812080537f)],
             [NSValue valueWithCGPoint:CGPointMake(1.241397f, 0.778523489933f)],
             [NSValue valueWithCGPoint:CGPointMake(1.287329f, 0.785234899329f)],
             [NSValue valueWithCGPoint:CGPointMake(1.335456f, 0.791946308725f)],
             [NSValue valueWithCGPoint:CGPointMake(1.38537f, 0.798657718121f)],
             [NSValue valueWithCGPoint:CGPointMake(1.437136f, 0.805369127517f)],
             [NSValue valueWithCGPoint:CGPointMake(1.490823f, 0.812080536913f)],
             [NSValue valueWithCGPoint:CGPointMake(1.552345f, 0.818791946309f)],
             [NSValue valueWithCGPoint:CGPointMake(1.616795f, 0.825503355705f)],
             [NSValue valueWithCGPoint:CGPointMake(1.683905f, 0.832214765101f)],
             [NSValue valueWithCGPoint:CGPointMake(1.753785f, 0.838926174497f)],
             [NSValue valueWithCGPoint:CGPointMake(1.82983f, 0.845637583893f)],
             [NSValue valueWithCGPoint:CGPointMake(1.917931f, 0.852348993289f)],
             [NSValue valueWithCGPoint:CGPointMake(2.010252f, 0.859060402685f)],
             [NSValue valueWithCGPoint:CGPointMake(2.106995f, 0.865771812081f)],
             [NSValue valueWithCGPoint:CGPointMake(2.208372f, 0.872483221477f)],
             [NSValue valueWithCGPoint:CGPointMake(2.328569f, 0.879194630872f)],
             [NSValue valueWithCGPoint:CGPointMake(2.464155f, 0.885906040268f)],
             [NSValue valueWithCGPoint:CGPointMake(2.607604f, 0.892617449664f)],
             [NSValue valueWithCGPoint:CGPointMake(2.759372f, 0.89932885906f)],
             [NSValue valueWithCGPoint:CGPointMake(2.919941f, 0.906040268456f)],
             [NSValue valueWithCGPoint:CGPointMake(3.140359f, 0.912751677852f)],
             [NSValue valueWithCGPoint:CGPointMake(3.379131f, 0.919463087248f)],
             [NSValue valueWithCGPoint:CGPointMake(3.636002f, 0.926174496644f)],
             [NSValue valueWithCGPoint:CGPointMake(3.912346f, 0.93288590604f)],
             [NSValue valueWithCGPoint:CGPointMake(4.262257f, 0.939597315436f)],
             [NSValue valueWithCGPoint:CGPointMake(4.772008f, 0.946308724832f)],
             [NSValue valueWithCGPoint:CGPointMake(5.342589f, 0.953020134228f)],
             [NSValue valueWithCGPoint:CGPointMake(5.98126f, 0.959731543624f)],
             [NSValue valueWithCGPoint:CGPointMake(6.696145f, 0.96644295302f)],
             [NSValue valueWithCGPoint:CGPointMake(9.318853f, 0.973154362416f)],
             [NSValue valueWithCGPoint:CGPointMake(14.532387f, 0.979865771812f)],
             [NSValue valueWithCGPoint:CGPointMake(22.659746f, 0.986577181208f)],
             [NSValue valueWithCGPoint:CGPointMake(35.329456f, 0.993288590604f)],
             [NSValue valueWithCGPoint:CGPointMake(55.080227f, 1.0f)]];
#else
    return @[[NSValue valueWithPoint:CGPointMake(0.0f, 0.0f)],
             [NSValue valueWithPoint:CGPointMake(0.0f, 0.00671140939597f)],
             [NSValue valueWithPoint:CGPointMake(0.0f, 0.0134228187919f)],
             [NSValue valueWithPoint:CGPointMake(0.0f, 0.0201342281879f)],
             [NSValue valueWithPoint:CGPointMake(0.0f, 0.0268456375839f)],
             [NSValue valueWithPoint:CGPointMake(0.0f, 0.0335570469799f)],
             [NSValue valueWithPoint:CGPointMake(0.0f, 0.0402684563758f)],
             [NSValue valueWithPoint:CGPointMake(0.002122f, 0.0469798657718f)],
             [NSValue valueWithPoint:CGPointMake(0.004399f, 0.0536912751678f)],
             [NSValue valueWithPoint:CGPointMake(0.006676f, 0.0604026845638f)],
             [NSValue valueWithPoint:CGPointMake(0.008606f, 0.0671140939597f)],
             [NSValue valueWithPoint:CGPointMake(0.010379f, 0.0738255033557f)],
             [NSValue valueWithPoint:CGPointMake(0.012214f, 0.0805369127517f)],
             [NSValue valueWithPoint:CGPointMake(0.014217f, 0.0872483221477f)],
             [NSValue valueWithPoint:CGPointMake(0.016394f, 0.0939597315436f)],
             [NSValue valueWithPoint:CGPointMake(0.018333f, 0.10067114094f)],
             [NSValue valueWithPoint:CGPointMake(0.020418f, 0.107382550336f)],
             [NSValue valueWithPoint:CGPointMake(0.02266f, 0.114093959732f)],
             [NSValue valueWithPoint:CGPointMake(0.025071f, 0.120805369128f)],
             [NSValue valueWithPoint:CGPointMake(0.027511f, 0.127516778523f)],
             [NSValue valueWithPoint:CGPointMake(0.029855f, 0.134228187919f)],
             [NSValue valueWithPoint:CGPointMake(0.032348f, 0.140939597315f)],
             [NSValue valueWithPoint:CGPointMake(0.034999f, 0.147651006711f)],
             [NSValue valueWithPoint:CGPointMake(0.037819f, 0.154362416107f)],
             [NSValue valueWithPoint:CGPointMake(0.040497f, 0.161073825503f)],
             [NSValue valueWithPoint:CGPointMake(0.043195f, 0.167785234899f)],
             [NSValue valueWithPoint:CGPointMake(0.046038f, 0.174496644295f)],
             [NSValue valueWithPoint:CGPointMake(0.049036f, 0.181208053691f)],
             [NSValue valueWithPoint:CGPointMake(0.052159f, 0.187919463087f)],
             [NSValue valueWithPoint:CGPointMake(0.054886f, 0.194630872483f)],
             [NSValue valueWithPoint:CGPointMake(0.057733f, 0.201342281879f)],
             [NSValue valueWithPoint:CGPointMake(0.060706f, 0.208053691275f)],
             [NSValue valueWithPoint:CGPointMake(0.063811f, 0.214765100671f)],
             [NSValue valueWithPoint:CGPointMake(0.066899f, 0.221476510067f)],
             [NSValue valueWithPoint:CGPointMake(0.069882f, 0.228187919463f)],
             [NSValue valueWithPoint:CGPointMake(0.072982f, 0.234899328859f)],
             [NSValue valueWithPoint:CGPointMake(0.076203f, 0.241610738255f)],
             [NSValue valueWithPoint:CGPointMake(0.079549f, 0.248322147651f)],
             [NSValue valueWithPoint:CGPointMake(0.082829f, 0.255033557047f)],
             [NSValue valueWithPoint:CGPointMake(0.086162f, 0.261744966443f)],
             [NSValue valueWithPoint:CGPointMake(0.089614f, 0.268456375839f)],
             [NSValue valueWithPoint:CGPointMake(0.093192f, 0.275167785235f)],
             [NSValue valueWithPoint:CGPointMake(0.096882f, 0.281879194631f)],
             [NSValue valueWithPoint:CGPointMake(0.100532f, 0.288590604027f)],
             [NSValue valueWithPoint:CGPointMake(0.104308f, 0.295302013423f)],
             [NSValue valueWithPoint:CGPointMake(0.108214f, 0.302013422819f)],
             [NSValue valueWithPoint:CGPointMake(0.112254f, 0.308724832215f)],
             [NSValue valueWithPoint:CGPointMake(0.116378f, 0.315436241611f)],
             [NSValue valueWithPoint:CGPointMake(0.120569f, 0.322147651007f)],
             [NSValue valueWithPoint:CGPointMake(0.1249f, 0.328859060403f)],
             [NSValue valueWithPoint:CGPointMake(0.129374f, 0.335570469799f)],
             [NSValue valueWithPoint:CGPointMake(0.133998f, 0.342281879195f)],
             [NSValue valueWithPoint:CGPointMake(0.138725f, 0.348993288591f)],
             [NSValue valueWithPoint:CGPointMake(0.143593f, 0.355704697987f)],
             [NSValue valueWithPoint:CGPointMake(0.14862f, 0.362416107383f)],
             [NSValue valueWithPoint:CGPointMake(0.153813f, 0.369127516779f)],
             [NSValue valueWithPoint:CGPointMake(0.159177f, 0.375838926174f)],
             [NSValue valueWithPoint:CGPointMake(0.164721f, 0.38255033557f)],
             [NSValue valueWithPoint:CGPointMake(0.170447f, 0.389261744966f)],
             [NSValue valueWithPoint:CGPointMake(0.176362f, 0.395973154362f)],
             [NSValue valueWithPoint:CGPointMake(0.182471f, 0.402684563758f)],
             [NSValue valueWithPoint:CGPointMake(0.18879f, 0.409395973154f)],
             [NSValue valueWithPoint:CGPointMake(0.195327f, 0.41610738255f)],
             [NSValue valueWithPoint:CGPointMake(0.20208f, 0.422818791946f)],
             [NSValue valueWithPoint:CGPointMake(0.209056f, 0.429530201342f)],
             [NSValue valueWithPoint:CGPointMake(0.216262f, 0.436241610738f)],
             [NSValue valueWithPoint:CGPointMake(0.223713f, 0.442953020134f)],
             [NSValue valueWithPoint:CGPointMake(0.231413f, 0.44966442953f)],
             [NSValue valueWithPoint:CGPointMake(0.239367f, 0.456375838926f)],
             [NSValue valueWithPoint:CGPointMake(0.247584f, 0.463087248322f)],
             [NSValue valueWithPoint:CGPointMake(0.256075f, 0.469798657718f)],
             [NSValue valueWithPoint:CGPointMake(0.264866f, 0.476510067114f)],
             [NSValue valueWithPoint:CGPointMake(0.273947f, 0.48322147651f)],
             [NSValue valueWithPoint:CGPointMake(0.28333f, 0.489932885906f)],
             [NSValue valueWithPoint:CGPointMake(0.293023f, 0.496644295302f)],
             [NSValue valueWithPoint:CGPointMake(0.303056f, 0.503355704698f)],
             [NSValue valueWithPoint:CGPointMake(0.313442f, 0.510067114094f)],
             [NSValue valueWithPoint:CGPointMake(0.324174f, 0.51677852349f)],
             [NSValue valueWithPoint:CGPointMake(0.335262f, 0.523489932886f)],
             [NSValue valueWithPoint:CGPointMake(0.346718f, 0.530201342282f)],
             [NSValue valueWithPoint:CGPointMake(0.358607f, 0.536912751678f)],
             [NSValue valueWithPoint:CGPointMake(0.370903f, 0.543624161074f)],
             [NSValue valueWithPoint:CGPointMake(0.38361f, 0.55033557047f)],
             [NSValue valueWithPoint:CGPointMake(0.396741f, 0.557046979866f)],
             [NSValue valueWithPoint:CGPointMake(0.410327f, 0.563758389262f)],
             [NSValue valueWithPoint:CGPointMake(0.424441f, 0.570469798658f)],
             [NSValue valueWithPoint:CGPointMake(0.43903f, 0.577181208054f)],
             [NSValue valueWithPoint:CGPointMake(0.454109f, 0.58389261745f)],
             [NSValue valueWithPoint:CGPointMake(0.469696f, 0.590604026846f)],
             [NSValue valueWithPoint:CGPointMake(0.485874f, 0.597315436242f)],
             [NSValue valueWithPoint:CGPointMake(0.502662f, 0.604026845638f)],
             [NSValue valueWithPoint:CGPointMake(0.520019f, 0.610738255034f)],
             [NSValue valueWithPoint:CGPointMake(0.537964f, 0.61744966443f)],
             [NSValue valueWithPoint:CGPointMake(0.556517f, 0.624161073826f)],
             [NSValue valueWithPoint:CGPointMake(0.575857f, 0.630872483221f)],
             [NSValue valueWithPoint:CGPointMake(0.595883f, 0.637583892617f)],
             [NSValue valueWithPoint:CGPointMake(0.616593f, 0.644295302013f)],
             [NSValue valueWithPoint:CGPointMake(0.638012f, 0.651006711409f)],
             [NSValue valueWithPoint:CGPointMake(0.660217f, 0.657718120805f)],
             [NSValue valueWithPoint:CGPointMake(0.683381f, 0.664429530201f)],
             [NSValue valueWithPoint:CGPointMake(0.707346f, 0.671140939597f)],
             [NSValue valueWithPoint:CGPointMake(0.732141f, 0.677852348993f)],
             [NSValue valueWithPoint:CGPointMake(0.757792f, 0.684563758389f)],
             [NSValue valueWithPoint:CGPointMake(0.784523f, 0.691275167785f)],
             [NSValue valueWithPoint:CGPointMake(0.812338f, 0.697986577181f)],
             [NSValue valueWithPoint:CGPointMake(0.841128f, 0.704697986577f)],
             [NSValue valueWithPoint:CGPointMake(0.870927f, 0.711409395973f)],
             [NSValue valueWithPoint:CGPointMake(0.90177f, 0.718120805369f)],
             [NSValue valueWithPoint:CGPointMake(0.934118f, 0.724832214765f)],
             [NSValue valueWithPoint:CGPointMake(0.967659f, 0.731543624161f)],
             [NSValue valueWithPoint:CGPointMake(1.002393f, 0.738255033557f)],
             [NSValue valueWithPoint:CGPointMake(1.038361f, 0.744966442953f)],
             [NSValue valueWithPoint:CGPointMake(1.075765f, 0.751677852349f)],
             [NSValue valueWithPoint:CGPointMake(1.114994f, 0.758389261745f)],
             [NSValue valueWithPoint:CGPointMake(1.155641f, 0.765100671141f)],
             [NSValue valueWithPoint:CGPointMake(1.197758f, 0.771812080537f)],
             [NSValue valueWithPoint:CGPointMake(1.241397f, 0.778523489933f)],
             [NSValue valueWithPoint:CGPointMake(1.287329f, 0.785234899329f)],
             [NSValue valueWithPoint:CGPointMake(1.335456f, 0.791946308725f)],
             [NSValue valueWithPoint:CGPointMake(1.38537f, 0.798657718121f)],
             [NSValue valueWithPoint:CGPointMake(1.437136f, 0.805369127517f)],
             [NSValue valueWithPoint:CGPointMake(1.490823f, 0.812080536913f)],
             [NSValue valueWithPoint:CGPointMake(1.552345f, 0.818791946309f)],
             [NSValue valueWithPoint:CGPointMake(1.616795f, 0.825503355705f)],
             [NSValue valueWithPoint:CGPointMake(1.683905f, 0.832214765101f)],
             [NSValue valueWithPoint:CGPointMake(1.753785f, 0.838926174497f)],
             [NSValue valueWithPoint:CGPointMake(1.82983f, 0.845637583893f)],
             [NSValue valueWithPoint:CGPointMake(1.917931f, 0.852348993289f)],
             [NSValue valueWithPoint:CGPointMake(2.010252f, 0.859060402685f)],
             [NSValue valueWithPoint:CGPointMake(2.106995f, 0.865771812081f)],
             [NSValue valueWithPoint:CGPointMake(2.208372f, 0.872483221477f)],
             [NSValue valueWithPoint:CGPointMake(2.328569f, 0.879194630872f)],
             [NSValue valueWithPoint:CGPointMake(2.464155f, 0.885906040268f)],
             [NSValue valueWithPoint:CGPointMake(2.607604f, 0.892617449664f)],
             [NSValue valueWithPoint:CGPointMake(2.759372f, 0.89932885906f)],
             [NSValue valueWithPoint:CGPointMake(2.919941f, 0.906040268456f)],
             [NSValue valueWithPoint:CGPointMake(3.140359f, 0.912751677852f)],
             [NSValue valueWithPoint:CGPointMake(3.379131f, 0.919463087248f)],
             [NSValue valueWithPoint:CGPointMake(3.636002f, 0.926174496644f)],
             [NSValue valueWithPoint:CGPointMake(3.912346f, 0.93288590604f)],
             [NSValue valueWithPoint:CGPointMake(4.262257f, 0.939597315436f)],
             [NSValue valueWithPoint:CGPointMake(4.772008f, 0.946308724832f)],
             [NSValue valueWithPoint:CGPointMake(5.342589f, 0.953020134228f)],
             [NSValue valueWithPoint:CGPointMake(5.98126f, 0.959731543624f)],
             [NSValue valueWithPoint:CGPointMake(6.696145f, 0.96644295302f)],
             [NSValue valueWithPoint:CGPointMake(9.318853f, 0.973154362416f)],
             [NSValue valueWithPoint:CGPointMake(14.532387f, 0.979865771812f)],
             [NSValue valueWithPoint:CGPointMake(22.659746f, 0.986577181208f)],
             [NSValue valueWithPoint:CGPointMake(35.329456f, 0.993288590604f)],
             [NSValue valueWithPoint:CGPointMake(55.080227f, 1.0f)]];
#endif
}


@end
