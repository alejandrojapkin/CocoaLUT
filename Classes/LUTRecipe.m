//
//  LUTRecipe.m
//  Pods
//
//  Created by Wil Gieseler on 7/13/14.
//
//

#import "LUTRecipe.h"
#import "LUTAction.h"

@interface LUTRecipe ()
@property NSMutableArray *actions;
@end

@implementation LUTRecipe

+ (instancetype)recipeWithActions:(NSDictionary *)actions {
    LUTRecipe *recipe = [[LUTRecipe alloc] init];
    recipe.actions = [actions mutableCopy];
    return recipe;
}

- (NSDictionary *)serializableObject {
    NSMutableArray *formattedArray = [NSMutableArray array];
    for (LUTTransformer *transformer in self.actions) {
        [formattedArray addObject:[transformer recipeDictionary]];
    }
    return @{@"transformations" : formattedArray};
}

- (NSData *)serializedRecipeWithError:(NSError **)error {
    return [NSJSONSerialization dataWithJSONObject:self.serializableObject
                                           options:NSJSONWritingPrettyPrinted
                                             error:error];
}

- (NSString *)serializedRecipeStringWithError:(NSError **)error {
    return [[NSString alloc] initWithData:[self serializedRecipeWithError:error] encoding:NSUTF8StringEncoding];
}

@end
