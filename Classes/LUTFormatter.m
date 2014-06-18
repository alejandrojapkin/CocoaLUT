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

static NSMutableArray *allFormatters;

@implementation LUTFormatter

+ (void)load{
    if ([self class] == [LUTFormatter class]) {
        allFormatters = [[NSMutableArray alloc] init];
    }
    else{
        [allFormatters addObject:[self class]];
    }
}

+ (LUTFormatter *)LUTFormatterForUTIString:(NSString *)utiString{
    for(LUTFormatter *formatter in allFormatters){
        if([[[formatter class] utiString] isEqualToString:utiString])
            return formatter;
    }
    return nil;
}

+ (NSArray *)LUTFormattersForFileExtension:(NSString *)fileExtension{
    NSMutableArray *formatters = [NSMutableArray array];
    for(LUTFormatter *formatter in allFormatters){
        if([[[formatter class] fileExtensions] indexOfObject:fileExtension] != NSNotFound){
            [formatters addObject:formatter];
        }
    
    }
    return [NSArray arrayWithArray:formatters];
}

+ (LUTFormatter *)LUTFormatterValidForURL:(NSURL *)fileURL{
    NSArray *formatters = [[self class] LUTFormattersForFileExtension:[fileURL pathExtension]];
    for(LUTFormatter* formatter in formatters){
        if([[formatter class] isValidReaderForURL:fileURL]){
            return formatter;
        }
    }
    return nil;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if([fileURL checkResourceIsReachableAndReturnError:nil] == NO){
        return NO;
    }
    if([[[self class] fileExtensions] containsObject:[fileURL pathExtension]]){
        return YES;
    }
    return NO;
}

+ (BOOL)isValidWriterForLUT:(LUT *)lut{
    if([[self class] outputType] == LUTFormatterOutputTypeEither){
        return YES;
    }
    else if(isLUT1D(lut) && [[self class] outputType] == LUTFormatterOutputType1D){
        return YES;
    }
    else if(isLUT3D(lut) && [[self class] outputType] == LUTFormatterOutputType3D){
        return YES;
    }
    return NO;
}

+ (LUT *)LUTFromURL:(NSURL *)fileURL {
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

+ (LUTFormatterOutputType)outputType{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSArray *)allOptions {
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
