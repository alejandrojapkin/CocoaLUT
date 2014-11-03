//
//  LUTMetadataFormatter.m
//  Pods
//
//  Created by Greg Cotten on 5/14/14.
//
//

#import "LUTMetadataFormatter.h"
#import <M13OrderedDictionary/M13OrderedDictionary.h>

@implementation LUTMetadataFormatter

+ (NSDictionary *)metadataAndDescriptionFromLines:(NSArray *)lines{
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    NSMutableString *description = [NSMutableString stringWithString:@""];

    for(NSString *line in lines){
        if (line.length > 0 && [[line substringToIndex:1] isEqualToString:@"#"]) {
            NSString *comment;
            if (line.length > 2 && [[line substringToIndex:2] isEqualToString:@"# "]) {
                comment = [line substringFromIndex:2];
            }
            else {
                comment = [line substringFromIndex:1];
            }

            BOOL isKeyValue = NO;
            if ([comment rangeOfString:@":"].location != NSNotFound) {
                NSArray *split = [comment componentsSeparatedByString:@":"];
                if (split.count == 2) {
                    metadata[[split[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [split[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    isKeyValue = YES;
                }
            }

            if (!isKeyValue) {
                [description appendString:comment];
                [description appendString:@"\n"];
            }
        }
    }

    return @{@"metadata":metadata, @"description":description};
}

+ (NSString *)stringFromMetadata:(NSMutableDictionary *)metadata
                     description:(NSString *)description{

    NSMutableString *string = [NSMutableString stringWithString:@""];

    if (description && description.length > 0) {
        for (NSString *line in [description componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
            [string appendString:[NSString stringWithFormat:@"# %@\n", line]];
        }
        [string appendString:@"\n"];
    }

    if (metadata && metadata.count > 0) {
        for (NSString *key in metadata) {
            [string appendString:[NSString stringWithFormat:@"# %@: %@\n", key, metadata[key]]];
        }
    }

    return string;
}

@end
