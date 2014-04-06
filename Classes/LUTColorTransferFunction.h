//
//  LUTColorTransferFunction.h
//  Pods
//
//  Created by Greg Cotten on 4/3/14.
//
//

#import <Foundation/Foundation.h>
#import <CocoaLUT.h>

@class LUTColor;


@interface LUTColorTransferFunction : NSObject
+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedExpressionString:(NSString *)redLinearToTransformedExpressionString
                                         greenLinearToTransformedExpressionString:(NSString *)greenLinearToTransformedExpressionString
                                          blueLinearToTransformedExpressionString:(NSString *)blueLinearToTransformedExpressionString
                                           redTransformedToLinearExpressionString:(NSString *)redTransformedToLinearExpressionStrin
                                         greenTransformedToLinearExpressionString:(NSString *)greenTransformedToLinearExpressionString
                                          blueTransformedToLinearExpressionString:(NSString *)blueTransformedToLinearExpressionString;


+(instancetype)LUTColorTransferFunctionWithRedTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )redTransformedToLinearBlock
                                         greenTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )greenTransformedToLinearBlock
                                          blueTransformedToLinearBlock:( double ( ^ )( double red, double green, double blue ) )blueTransformedToLinearBlock
                                           redLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )redLinearToTransformedBlock
                                         greenLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )greenLinearToTransformedBlock
                                          blueLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )blueLinearToTransformedBlock;

+(NSDictionary *)knownColorTransferFunctions;

+(instancetype)LUTColorTransferFunctionWithGamma:(double)gamma;

+(LUT *)transformedLUTFromLUT:(LUT *)sourceLUT
          fromColorTransferFunction:(LUTColorTransferFunction *)sourceColorTransferFunction
            toColorTransferFunction:(LUTColorTransferFunction *)destinationColorTransferFunction;

+(LUTColor *)transformedColorFromColor:(LUTColor *)sourceColor
                   fromColorTransferFunction:(LUTColorTransferFunction *)sourceColorTransferFunction
                     toColorTransferFunction:(LUTColorTransferFunction *)destinationColorTransferFunction;

-(LUTColor *)transformedToLinearFromColor:(LUTColor *)transformedColor;
-(LUTColor *)linearToTransformedFromColor:(LUTColor *)linearColor;

@end
