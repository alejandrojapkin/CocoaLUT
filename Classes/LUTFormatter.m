//
//  LUTFormatter.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTFormatter.h"

#if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
#import "NSImage+OIIO.h"
#endif

@implementation LUTFormatter

+ (LUT *)LUTFromFile:(NSURL *)fileURL {
    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
    if([@[@"dpx"] containsObject:fileURL.pathExtension.lowercaseString]){
        return [self LUTFromData:[[NSImage oiio_forceImageWithContentsOfURL:fileURL] TIFFRepresentation]];
    }
    #endif
    return [self LUTFromData:[NSData dataWithContentsOfURL:fileURL]];
    
}

+ (LUT *)LUTFromData:(NSData *)data {
    return [self LUTFromString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}

+ (LUT *)LUTFromString:(NSString *)string {
    return [self LUTFromLines:[string componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]];
}

+ (LUT *)LUTFromLines:(NSArray *)lines {
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    return [[self stringFromLUT:lut withOptions:options] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSDictionary *)allOptions {
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSDictionary *)defaultOptions{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSString *)utiString{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSArray *)fileExtensions{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

@end
