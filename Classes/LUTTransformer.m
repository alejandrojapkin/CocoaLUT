//
//  LUTTransformer.m
//  Pods
//
//  Created by Wil Gieseler on 7/13/14.
//
//

#import "LUTTransformer.h"

static NSMutableDictionary *allTransformers;

@implementation LUTTransformer

+ (void)load {
    if (self == [LUTTransformer class]) {
        allTransformers = [[NSMutableDictionary alloc] init];
    }
}

+ (void)registerTransformer {
    allTransformers[self.transformerName] = self;
}

+ (NSString *)transformerName {
    @throw [NSException exceptionWithName:@"Unimplemented Transformer"
                                   reason:@"You forgot to subclass this transformer!" userInfo:nil];
    return nil;
}

+ (instancetype)fromRecipeDictionary:(NSDictionary *)dictionary {
    Class klass = allTransformers[dictionary[@"transformer"]];
    LUTTransformer *transformer = [[klass alloc] init];
    transformer.parameters = dictionary[@"parameters"];
    return transformer;
}

+ (instancetype)transformerWithParameters:(NSDictionary *)parameters {
    LUTTransformer *transformer = [[self.class alloc] init];
    transformer.parameters = parameters;
    return transformer;
}

- (NSDictionary *)recipeDictionary {
    return @{@"transformer": self.class.transformerName, @"parameters": self.parameters};
}

- (LUT *)LUTByTransformingLUT:(LUT *)lut {
    @throw [NSException exceptionWithName:@"Unimplemented Transformer"
                                   reason:@"You forgot to subclass this transformer!" userInfo:nil];
    return nil;
}

@end
