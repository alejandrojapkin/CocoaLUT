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
                                                                       name:[self.name copyWithZone:zone]
                                                                       type:self.transferFunctionType];
}

-(instancetype)initWithTransformedToLinearBlock:( LUTColor* ( ^ )(double red, double green, double blue) )transformedToLinearBlock
                       linearToTransformedBlock:( LUTColor* ( ^ )(double red, double green, double blue) )linearToTransformedBlock
                                           name:(NSString *)name
                                           type:(LUTColorTransferFunctionType)transferFunctionType{
    if (self = [super init]){
        self.transformedToLinearBlock = transformedToLinearBlock;
        self.linearToTransformedBlock = linearToTransformedBlock;
        self.name = name;
        self.transferFunctionType = transferFunctionType;
    }
    return self;
}



+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedExpressionString:(NSString *)redLinearToTransformedExpressionString
                                         greenLinearToTransformedExpressionString:(NSString *)greenLinearToTransformedExpressionString
                                          blueLinearToTransformedExpressionString:(NSString *)blueLinearToTransformedExpressionString
                                           redTransformedToLinearExpressionString:(NSString *)redTransformedToLinearExpressionString
                                         greenTransformedToLinearExpressionString:(NSString *)greenTransformedToLinearExpressionString
                                          blueTransformedToLinearExpressionString:(NSString *)blueTransformedToLinearExpressionString
                                                                             name:(NSString *)name
                                                                             type:(LUTColorTransferFunctionType)transferFunctionType{
    return nil;
}

+(instancetype)LUTColorTransferFunctionWithTransformedToLinearBlock:( LUTColor* ( ^ )(double red, double green, double blue) )transformedToLinearBlock
                                           linearToTransformedBlock:( LUTColor* ( ^ )(double red, double green, double blue) )linearToTransformedBlock
                                                               name:(NSString *)name
                                                               type:(LUTColorTransferFunctionType)transferFunctionType{
    return [[self alloc] initWithTransformedToLinearBlock:transformedToLinearBlock
                                         linearToTransformedBlock:linearToTransformedBlock
                                                     name:name
                                                     type:transferFunctionType];
}

+(instancetype)LUTColorTransferFunctionWithTransformedToLinearBlock1D:( double ( ^ )(double value) )transformedToLinearBlock1D
                                           linearToTransformedBlock1D:( double ( ^ )(double value) )linearToTransformedBlock1D
                                                                 name:(NSString *)name
                                                                 type:(LUTColorTransferFunctionType)transferFunctionType{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock:^LUTColor*(double red, double green, double blue) {
                                                                                            return [LUTColor colorWithRed:transformedToLinearBlock1D(red)
                                                                                                                    green:transformedToLinearBlock1D(green)
                                                                                                                     blue:transformedToLinearBlock1D(blue)];}
                                                                 linearToTransformedBlock:^LUTColor*(double red, double green, double blue) {
                                                                                            return [LUTColor colorWithRed:linearToTransformedBlock1D(red)
                                                                                                                    green:linearToTransformedBlock1D(green)
                                                                                                                     blue:linearToTransformedBlock1D(blue)];}
                                                                                     name:name
                                                                                     type:transferFunctionType];
}

-(LUTColor *)transformedToLinearFromColor:(LUTColor *)transformedColor{
    return self.transformedToLinearBlock(transformedColor.red, transformedColor.green, transformedColor.blue);
}

-(LUTColor *)linearToTransformedFromColor:(LUTColor *)linearColor{
    return self.linearToTransformedBlock(linearColor.red, linearColor.green, linearColor.blue);
}

-(BOOL)isCompatibleWithTransferFunction:(LUTColorTransferFunction *)transferFunction{
    return self.transferFunctionType == transferFunction.transferFunctionType || self.transferFunctionType == LUTColorTransferFunctionTypeAny || transferFunction.transferFunctionType == LUTColorTransferFunctionTypeAny;
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
             [self JPLogTransferFunction],
             [self redLogFilmTransferFunction],
             [self gammaTransferFunctionWithGamma:2.2],
             [self gammaTransferFunctionWithGamma:2.4],
             [self gammaTransferFunctionWithGamma:2.6],
             [self bt1886TransferFunction],
             [self sRGBTransferFunction],
             [self alexaLogCV3TransferFunctionWithEI:800],
             [self sLogTransferFunction],
             [self sLog2TransferFunction],
             [self sLog3TransferFunction],
             [self canonLogTransferFunction],
             [self bmdFilmTransferFunction],
             [self bmdFilm4KTransferFunction],
             [self vLogTransferFunction]];
}

+(instancetype)linearTransferFunction{

    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value) {
        return value;}
                                                                 linearToTransformedBlock1D:^double(double value) {
                                                                     return value;}
                                                                                       name:@"Linear"
                                                                                       type:LUTColorTransferFunctionTypeAny];
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
                                                                                       name:[NSString stringWithFormat:@"Gamma %g", gamma]
                                                                                       type:LUTColorTransferFunctionType01];
}

+ (instancetype)bt1886TransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clamp(value, 0.0, 1.0);
                                                                                            return (value <= .081) ? value/4.5 : pow((value+.099)/1.099, 2.2);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            double output = (value <= .018) ? 4.5*value : 1.099*pow(value, 1.0/2.2) - .099;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:@"BT.1886"
                                                                                       type:LUTColorTransferFunctionType01];
}

+ (instancetype)sRGBTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            return (value <= .04045) ? value/12.92 : pow((value+.055)/1.055, 2.4);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            value = clampLowerBound(value, 0.0);
                                                                                            double output = (value <= .0031308) ? 12.92*value : 1.055*pow(value, 1.0/2.4) - .055;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:@"sRGB"
                                                                                       type:LUTColorTransferFunctionType01];
}

+ (instancetype)cineonTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                    value = clamp(value, 0.0, 1.0);
                                                                    return pow(10.0,(1023.0*value-685.0)/300.0)-.0108/(1-.0108);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     double output = (300.0*log(value+27.0/2473.0) + 685.0*log(10.0))/(1023.0*log(10.0));
                                                                     return clamp(output, 0.0, 1.0);}
                                                                                       name:@"Cineon"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}

+ (instancetype)redLogFilmTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        value = clamp(value, 0.0, 1.0);
        return pow(10.0,(1023.0*value-685.0)/300.0)-.0108/(1-.0108);}
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     double output = (300.0*log(value+27.0/2473.0) + 685.0*log(10.0))/(1023.0*log(10.0));
                                                                     return clamp(output, 0.0, 1.0);}
                                                                                       name:@"REDLogFilm"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}

+ (instancetype)vLogTransferFunction{
    double cut1 = 0.01;
    double cut2 = 0.181;
    double b=0.00873;
    double c=0.241514;
    double d=0.598206;
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        value = clamp(value, 0.0, 1.0);
        if(value < cut2){
            return (value - 0.125) / 5.6;
        }
        else{
            return pow(10.0, ((value-d)/c)) - b;
        }
    }
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     double output;
                                                                     if (value < cut1) {
                                                                         output = 5.6*value + 0.125;
                                                                     }
                                                                     else{
                                                                         output = c*log10(value+b)+d;
                                                                     }
                                                                     return clamp(output, 0.0, 1.0);}
                                                                                       name:@"V-Log"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
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
                                                                                       name:@"JPLog"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
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

                                                                                            double output = (value > cut) ? c * log10(a * value + b) + d: e * value + f;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:[NSString stringWithFormat:@"AlexaV3LogC EI %i", (int)EI]
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];

}

+ (instancetype)canonLogTransferFunction {

    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
                                                                                            value = clamp(value, 0.0, 1.0);
                                                                                            double valueAsIRE = (value*1023.0 - 64.0) / 876.0;
                                                                                            return (pow(10,(valueAsIRE-0.0730597)/0.529136)-1)/10.1596;}

                                                                 linearToTransformedBlock1D:^double(double value){
                                                                                            double valueAsIRE = .529136*log10(10.1596*value+1)+.0730597;
                                                                                            double output = (876.0*valueAsIRE + 64.0)/1023.0;
                                                                                            return clamp(output, 0.0, 1.0);}
                                                                                       name:@"CanonLog"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}

+ (instancetype)sLogTransferFunction{
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        value = clamp(value, 0.0, 1.0);
        if(value >= 90.0/1023.0){
            return (pow(10.0, (((value*1023.0-64.0)/(940.0-64.0)-0.616596-0.03)/0.432699))-0.037584)*0.9;
        }
        else{
            return ((value*1023.0-64.0)/(940.0-64.0)-0.030001222851889303)/5.0*0.9;
        }
    }
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     double output;
                                                                     if(value >= 0.0000577055){
                                                                         output = .160916 * log(51.1606*value + 1.73054);
                                                                     }
                                                                     else{
                                                                         output = 0.0882513 + 4.75725*value;
                                                                     }
                                                                     return clamp(output, 0, 1);
                                                                 }

                                                                                       name:@"S-Log"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}


+ (instancetype)sLog2TransferFunction {
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        value = clamp(value, 0.0, 1.0);
        double valueAsInt = (1023.0*value);
        if (valueAsInt < 90.0/1023.0){
            return ((valueAsInt-64.0)/(940.0-64.0)-0.030001222851889303)/3.53881278538813*0.9;
        }
        else{
            return (219.0*(pow(10.0, (((valueAsInt-64.0)/(940.0-64.0)-0.616596-0.03)/0.432699))-0.037584)/155.0)*0.9;
        }
}
                                                                 linearToTransformedBlock1D:^double(double value){
         double output;
         if(value < -0.0261851){
             output = (3444.44*value+90.2811)/1023.0;
         }
         else{
             output = (164.617*log(1.73054+36.2095*value)) / 1023.0;
         }
         return clamp(output, 0, 1);
                                                                 }

                                                                                       name:@"S-Log2"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}

+ (instancetype)sLog3TransferFunction {
    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        value = clamp(value, 0.0, 1.0);
        if(value >= 171.2102946929 / 1023.0){
            return pow(10, ((value * 1023.0 - 420.0) / 261.5)) * (0.18 + 0.01) - .01;
        }
        else{
            return (value * 1023.0 - 95.0)*0.01125000 / (171.2102946929 - 95.0);
        }
    }
                                                                 linearToTransformedBlock1D:^double(double value){
                                                                     double output;
                                                                     if(value >= 0.01125000){
                                                                         output = (420.0 + log10((value + 0.01) / (0.18 + 0.01)) * 261.5) / 1023.0;
                                                                     }
                                                                     else{
                                                                         output = (value * (171.2102946929 - 95.0)/0.01125000 + 95.0) / 1023.0;
                                                                     }
                                                                     return clamp(output, 0, 1);
                                                                 }

                                                                                       name:@"S-Log3"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}

+ (NSBundle *)transferFunctionsLUTResourceBundle{
    static NSBundle *transferFunctionsBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transferFunctionsBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"TransferFunctionLUTs" withExtension:@"bundle"]];
    });

    return transferFunctionsBundle;
}

+ (NSURL *)lutFromBundleWithName:(NSString *)name extension:(NSString *)extension{
    return [[self.class transferFunctionsLUTResourceBundle] URLForResource:name withExtension:extension];
}

+ (instancetype)bmdFilmTransferFunction{
    static LUT1D *bmdFilmToLinear = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *lutURL = [self lutFromBundleWithName:@"BMDFilm_to_Linear" extension:@"cube"];
        bmdFilmToLinear = (LUT1D *)[LUT LUTFromURL:lutURL];
    });

    static LUT1D *linearToBMDFilm = nil;
    static dispatch_once_t onceToken2;
    dispatch_once(&onceToken2, ^{
        NSURL *lutURL = [self lutFromBundleWithName:@"Linear_to_BMDFilm" extension:@"cube"];
        linearToBMDFilm = (LUT1D *)[LUT LUTFromURL:lutURL];
    });

    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        return [bmdFilmToLinear colorAtColor:[LUTColor colorWithRed:value green:value blue:value]].red;
    }
                                                                 linearToTransformedBlock1D:^double(double value){
     return [linearToBMDFilm colorAtColor:[LUTColor colorWithRed:value green:value blue:value]].red;}

                                                                                       name:@"BMDFilm"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}

+ (instancetype)bmdFilm4KTransferFunction{
    static LUT1D *bmdFilm4KToLinear = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *lutURL = [self lutFromBundleWithName:@"BMDFilm4K_to_Linear" extension:@"cube"];
        bmdFilm4KToLinear = (LUT1D *)[LUT LUTFromURL:lutURL];
    });

    static LUT1D *linearToBMDFilm4K = nil;
    static dispatch_once_t onceToken2;
    dispatch_once(&onceToken2, ^{
        NSURL *lutURL = [self lutFromBundleWithName:@"Linear_to_BMDFilm4K" extension:@"cube"];
        linearToBMDFilm4K = (LUT1D *)[LUT LUTFromURL:lutURL];
    });


    return [LUTColorTransferFunction LUTColorTransferFunctionWithTransformedToLinearBlock1D:^double(double value){
        return [bmdFilm4KToLinear colorAtColor:[LUTColor colorWithRed:value green:value blue:value]].red;
    }
                                                                 linearToTransformedBlock1D:^double(double value){


                                                                     return [linearToBMDFilm4K colorAtColor:[LUTColor colorWithRed:value green:value blue:value]].red;}

                                                                                       name:@"BMDFilm4K"
                                                                                       type:LUTColorTransferFunctionTypeSceneLinear];
}

@end
