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
    NSStringEncoding usedEncoding;
    NSError *error;
    NSString *string = [NSString stringWithContentsOfURL:fileURL usedEncoding:&usedEncoding error:&error];
    return [self LUTFromString:string];
}

+ (LUT *)LUTFromData:(NSData *)data {
    return [self LUTFromString:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
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
