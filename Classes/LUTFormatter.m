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
    if (self == [LUTFormatter class]) {
        allFormatters = [[NSMutableArray alloc] init];
    }
    else{
        [allFormatters addObject:self];
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

+ (LUTFormatter *)LUTFormatterValidForReadingURL:(NSURL *)fileURL{
    NSArray *formatters = [self LUTFormattersForFileExtension:[fileURL pathExtension]];
    for(LUTFormatter* formatter in formatters){
        if([[formatter class] isValidReaderForURL:fileURL]){
            return formatter;
        }
    }
    return nil;
}

+ (NSArray *)LUTFormattersValidForWritingLUTType:(LUT *)lut{
    NSMutableArray *array = [NSMutableArray array];
    for(LUTFormatter* formatter in allFormatters){
        if([[formatter class] isValidWriterForLUTType:lut]){
            [array addObject:formatter];
        }
    }
    return array;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if ([self canRead] == NO) {
        return NO;
    }
    if([fileURL checkResourceIsReachableAndReturnError:nil] == NO){
        return NO;
    }
    if([[self fileExtensions] containsObject:[fileURL pathExtension]]){
        return YES;
    }
    return NO;
}

+ (BOOL)isValidWriterForLUTType:(LUT *)lut{
    if([self canWrite] == NO){
        return NO;
    }
    if([self outputType] == LUTFormatterOutputTypeEither){
        return YES;
    }
    else if(isLUT1D(lut) && [self outputType] == LUTFormatterOutputType1D){
        return YES;
    }
    else if(isLUT3D(lut) && [self outputType] == LUTFormatterOutputType3D){
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

//structure is NSArray(of the variants)->NSDictionaries(of the variants options)->Strings or NSDictionaries with the option name or dicts of names:value
+ (NSArray *)allOptions {
    return nil;
}

+ (NSDictionary *)defaultOptions{
    return nil;
}

+ (BOOL)optionsAreValid:(NSDictionary *)options{
    NSDictionary *defaultOptionsExposed = [self defaultOptions][[self utiString]];
    NSDictionary *optionsExposed = options[[self utiString]];
    if(optionsExposed == nil && defaultOptionsExposed == nil){
        return YES;
    }
    else if(optionsExposed != nil && defaultOptionsExposed == nil){
        return NO;
    }
    else if(optionsExposed == nil && defaultOptionsExposed != nil){
        return NO;
    }
    else if(optionsExposed != nil && defaultOptionsExposed != nil){
        
        NSArray *allOptions = [self allOptions];
        
        NSDictionary *allOptionsOfSameFileTypeVariant;
        
        for(NSDictionary *optionDict in allOptions){
            if ([optionDict[@"fileTypeVariant"] isEqualToString:optionsExposed[@"fileTypeVariant"]]) {
                allOptionsOfSameFileTypeVariant = optionDict;
            }
        }
        
        if(allOptionsOfSameFileTypeVariant == nil){
            return NO;
        }
        
        for(NSString *key in [optionsExposed allKeys]){
            //NSLog(@"%@", allOptionsOfSameFileTypeVariant[key]);
            if(allOptionsOfSameFileTypeVariant[key] == nil && [[(M13OrderedDictionary *)allOptionsOfSameFileTypeVariant[key] allObjects] indexOfObject:optionsExposed[key]] == NSNotFound){
                    return NO;
            }

        }
        return YES;
        
    }
    return NO;
}

+ (NSString *)utiString{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSArray *)fileExtensions{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSString *)formatterName{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSString *)fullName{
    NSMutableString *extensionsString = [[NSMutableString alloc] initWithString:@"("];
    NSArray *fileExtensions = [self fileExtensions];
    
    for(int i = 0; i < fileExtensions.count; i++){
        [extensionsString appendString:[@"." stringByAppendingString:fileExtensions[i]]];
        if(i + 1 < fileExtensions.count){
            [extensionsString appendString:@", "];
        }
    }
    [extensionsString appendString:@")"];
    return [NSString stringWithFormat:@"%@ %@", [self formatterName], extensionsString];
}

+ (LUTFormatterRole)formatterRole{
    if([self canRead] == YES && [self canWrite] == YES){
        return LUTFormatterRoleReadAndWrite;
    }
    else if([self canRead] == YES && [self canWrite] == NO){
        return LUTFormatterRoleReadOnly;
    }
    else if([self canRead] == NO && [self canWrite] == YES){
        return LUTFormatterRoleWriteOnly;
    }
    return LUTFormatterRoleNone;
}

+ (BOOL)canRead{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (BOOL)canWrite{
     @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (NSDictionary *)constantConstraints{
    return @{@"inputBounds":@[@0, @1],
             @"outputBounds":@[[NSNull null], [NSNull null]]};
}

+ (NSArray *)LUTActionsForLUT:(LUT *)lut options:(NSDictionary *)options{
    NSMutableArray *arrayOfActions = [NSMutableArray array];
    
    if(![self optionsAreValid:options]){
       @throw [NSException exceptionWithName:@"LUTActionsForLUTError" reason:[NSString stringWithFormat:@"Provided options don't pass the spec: %@", options] userInfo:nil];
    }
    
    NSDictionary *exposedOptions = options == nil ? nil : options[[self utiString]];
    NSDictionary *formatterConstantConstraints = [self constantConstraints];
    
    if(formatterConstantConstraints != nil){
        if(formatterConstantConstraints[@"inputBounds"] != nil){
            NSArray *array = formatterConstantConstraints[@"inputBounds"];
            if(array[0] != [NSNull null] && array[1] != [NSNull null]){
                if(lut.inputLowerBound != [array[0] doubleValue] || lut.inputUpperBound != [array[1] doubleValue]){
                    [arrayOfActions addObject:[LUTAction actionWithLUTByChangingInputLowerBound:[array[0] doubleValue] inputUpperBound:[array[1] doubleValue]]];
                }
            }
            else if(array[0] == [NSNull null] && array[1] != [NSNull null]){
                //strange setup, bro
                if(lut.inputUpperBound != [array[1] doubleValue]){
                    [arrayOfActions addObject:[LUTAction actionWithLUTByChangingInputLowerBound:lut.inputLowerBound inputUpperBound:[array[1] doubleValue]]];
                }
            }
            else if(array[0] != [NSNull null] && array[1] == [NSNull null]){
                //strange setup, bro
                if(lut.inputLowerBound != [array[0] doubleValue]){
                    [arrayOfActions addObject:[LUTAction actionWithLUTByChangingInputLowerBound:[array[0] doubleValue] inputUpperBound:lut.inputUpperBound]];
                }
            }
        }
        if(formatterConstantConstraints[@"outputBounds"] != nil){
            NSArray *array = formatterConstantConstraints[@"outputBounds"];
            if(array[0] != [NSNull null] && array[1] != [NSNull null]){
                if(lut.minimumOutputValue != [array[0] doubleValue] || lut.maximumOutputValue != [array[1] doubleValue]){
                    [arrayOfActions addObject:[LUTAction actionWithLUTByClampingLowerBound:[array[0] doubleValue] upperBound:[array[1] doubleValue]]];
                }
            }
            else if(array[0] == [NSNull null] && array[1] != [NSNull null]){
                //strange setup, bro
                if(lut.maximumOutputValue != [array[1] doubleValue]){
                    [arrayOfActions addObject:[LUTAction actionWithLUTByClampingLowerBound:lut.minimumOutputValue upperBound:[array[1] doubleValue]]];
                }
            }
            else if(array[0] != [NSNull null] && array[1] == [NSNull null]){
                //strange setup, bro
                if(lut.minimumOutputValue != [array[0] doubleValue]){
                    [arrayOfActions addObject:[LUTAction actionWithLUTByClampingLowerBound:[array[0] doubleValue] upperBound:lut.maximumOutputValue]];
                }
            }
        }
    }
    
    if(exposedOptions != nil){
        if(exposedOptions[@"lutSize"] != nil){
            NSInteger resizeSize = [exposedOptions[@"lutSize"] integerValue];
            if(resizeSize != lut.size){
                [arrayOfActions addObject:[LUTAction actionWithLUTByResizingToSize:resizeSize]];
            }
        }
    }

    if(arrayOfActions.count == 0){
        return nil;
    }
    else{
        return arrayOfActions;
    }
}

@end
