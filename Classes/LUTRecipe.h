//
//  LUTRecipe.h
//  Pods
//
//  Created by Wil Gieseler on 7/13/14.
//
//

#import <Foundation/Foundation.h>

@interface LUTRecipe : NSObject

+ (instancetype)recipeWithActions:(NSDictionary *)actions;

// Serialization
- (NSData *)serializedRecipeWithError:(NSError **)error;
- (NSString *)serializedRecipeStringWithError:(NSError **)error;

@end
