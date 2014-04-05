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


+(instancetype)LUTColorTransferFunctionWithRedLinearToTransformedBlock:( double ( ^ )( double red, double green, double blue ) )redTransformedToLinearBlock
                                  greenLinearToTransformedExpressionBlock:( double ( ^ )( double red, double green, double blue ) )greenLinearToTransformedExpressionBlock
                                   blueLinearToTransformedExpressionBlock:( double ( ^ )( double red, double green, double blue ) )blueLinearToTransformedExpressionBlock
                                    redTransformedToLinearExpressionBlock:( double ( ^ )( double red, double green, double blue ) )redTransformedToLinearExpressionBlock
                                  greenTransformedToLinearExpressionBlock:( double ( ^ )( double red, double green, double blue ) )greenTransformedToLinearExpressionBlock
                                   blueTransformedToLinearExpressionBlock:( double ( ^ )( double red, double green, double blue ) )blueTransformedToLinearExpressionBlock;

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
