//
//  LUTMetadataFormatter.h
//  Pods
//
//  Created by Greg Cotten on 5/14/14.
//
//

#import <Foundation/Foundation.h>


@interface LUTMetadataFormatter : NSObject

+ (NSDictionary *)metadataAndDescriptionFromLines:(NSArray *)lines;

+ (NSString *)stringFromMetadata:(NSMutableDictionary *)metadata
                     description:(NSString *)description;

@end
