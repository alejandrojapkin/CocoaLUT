//
//  LUTFormatter.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTFormatter.h"

@implementation LUTFormatter

+ (LUT *)LUTFromFile:(NSURL *)fileURL {
    return [self LUTFromData:[NSData dataWithContentsOfURL:fileURL]];
}

+ (LUT *)LUTFromData:(NSData *)data {
    return [self LUTFromString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}

+ (LUT *)LUTFromString:(NSString *)string {
    return [self LUTFromLines:[string componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]];
}

+ (LUT *)LUTFromLines:(NSArray *)lines {
    [NSException raise:@"LUTFromLines is unimplemented" format:nil];
    return nil;
}

+ (NSData *)dataFromLUT:(LUT *)lut {
    return [[self stringFromLUT:lut] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

+ (NSString *)stringFromLUT:(LUT *)lut {
    [NSException raise:@"stringFromLUT is unimplemented" format:nil];
    return nil;
}


@end
