//
//  LUTTransformer.h
//  Pods
//
//  Created by Wil Gieseler on 7/13/14.
//
//

#import <Foundation/Foundation.h>
#import "LUT.h"
#import "LUTRecipe.h"

@interface LUTTransformer : NSObject <LUTRecipeConvertible>

@property (strong) NSDictionary *parameters;

+ (instancetype)transformerWithParameters:(NSDictionary *)parameters;

+ (void)registerTransformer;

+ (NSString *)transformerName;
- (LUT *)LUTByTransformingLUT:(LUT *)lut;

@end
