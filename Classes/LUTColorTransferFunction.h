//
//  LUTColorTransferFunction.h
//  Pods
//
//  Created by Greg Cotten on 4/3/14.
//
//

#import <Foundation/Foundation.h>
#import "CocoaLUT.h"

@class LUTColor;

typedef NS_ENUM(NSInteger, LUTColorTransferFunctionType) {
    LUTColorTransferFunctionTypeSceneLinear,
    LUTColorTransferFunctionType01,
    LUTColorTransferFunctionTypeAny
};

@interface LUTColorTransferFunction : NSObject <NSCopying>

@property (strong) NSString *name;
@property (assign) LUTColorTransferFunctionType transferFunctionType;

+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedExpressionString:(NSString *)redLinearToTransformedExpressionString
                                         greenLinearToTransformedExpressionString:(NSString *)greenLinearToTransformedExpressionString
                                          blueLinearToTransformedExpressionString:(NSString *)blueLinearToTransformedExpressionString
                                           redTransformedToLinearExpressionString:(NSString *)redTransformedToLinearExpressionStrin
                                         greenTransformedToLinearExpressionString:(NSString *)greenTransformedToLinearExpressionString
                                          blueTransformedToLinearExpressionString:(NSString *)blueTransformedToLinearExpressionString
                                                                             name:(NSString *)name
                                                                             type:(LUTColorTransferFunctionType)transferFunctionType;

+(instancetype)LUTColorTransferFunctionWithTransformedToLinearBlock:( LUTColor* ( ^ )(double red, double green, double blue) )transformedToLinearBlock
                                           linearToTransformedBlock:( LUTColor* ( ^ )(double red, double green, double blue) )linearToTransformedBlock
                                                               name:(NSString *)name
                                                               type:(LUTColorTransferFunctionType)transferFunctionType;

+(NSArray *)knownColorTransferFunctions;

+(instancetype)linearTransferFunction;

+(instancetype)gammaTransferFunctionWithGamma:(double)gamma;

+(LUT *)transformedLUTFromLUT:(LUT *)sourceLUT
          fromColorTransferFunction:(LUTColorTransferFunction *)sourceColorTransferFunction
            toColorTransferFunction:(LUTColorTransferFunction *)destinationColorTransferFunction;

+(LUTColor *)transformedColorFromColor:(LUTColor *)sourceColor
                   fromColorTransferFunction:(LUTColorTransferFunction *)sourceColorTransferFunction
                     toColorTransferFunction:(LUTColorTransferFunction *)destinationColorTransferFunction;

-(LUTColor *)transformedToLinearFromColor:(LUTColor *)transformedColor;
-(LUTColor *)linearToTransformedFromColor:(LUTColor *)linearColor;

-(BOOL)isCompatibleWithTransferFunction:(LUTColorTransferFunction *)transferFunction;

@end
