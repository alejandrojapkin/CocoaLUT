//
//  LUTFormatterImageBased.m
//  Pods
//
//  Created by Greg Cotten on 6/23/14.
//
//

#import "LUTFormatterImageBased.h"
#import "M13OrderedDictionary.h"

@implementation LUTFormatterImageBased

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterCMSTestPattern doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}

+ (UIImage *)imageFromLUT:(LUT *)lut
                 bitdepth:(NSUInteger)bitdepth {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterCMSTestPattern doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}
+ (LUT *)LUTFromImage:(UIImage *)image {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterCMSTestPattern doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}

#elif TARGET_OS_MAC

+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"ImageBasedWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }

    NSDictionary *exposedOptions = options[[self formatterID]];
//
//    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
//    if([exposedOptions[@"fileTypeVariant"] isEqualToString:@"DPX"]){
//        NSString *tempFileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"file.dpx"];
//        NSURL *tempFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName]];
//
//        OIIOImageEncodingType oiioEncodingType = [exposedOptions[@"bitDepth"] integerValue];
//
//        BOOL writeSuccess = [[self imageFromLUT:lut] oiio_forceWriteToURL:tempFileURL encodingType:oiioEncodingType];
//        if(!writeSuccess){
//            @throw [NSException exceptionWithName:@"ImageBasedReadError"
//                                           reason:[NSString stringWithFormat:@"OIIO failed to write the file with options: %@.", options] userInfo:nil];
//        }
//        else{
//            NSData *data = [NSData dataWithContentsOfURL:tempFileURL];
//            [[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:nil];
//            return data;
//        }
//    }
//    #endif

    return [[self imageFromLUT:lut bitdepth:[exposedOptions[@"bitDepth"] integerValue]] TIFFRepresentation];
}

+(LUT *)LUTFromURL:(NSURL *)fileURL{
    if(![[self fileExtensions] containsObject:[fileURL pathExtension].lowercaseString]){
        @throw [NSException exceptionWithName:@"ImageBasedReadError"
                                       reason:@"Invalid file extension." userInfo:nil];

    }
    NSMutableDictionary *passthroughFileOptions = [NSMutableDictionary dictionary];
    NSImage *image;
//    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
//    image = [NSImage oiio_imageWithContentsOfURL:fileURL];
//    if([image oiio_findOIIOImageRep] != nil){
//        passthroughFileOptions[@"bitDepth"] = @([image oiio_findOIIOImageRep].encodingType);
//    }
//    else{
//        passthroughFileOptions[@"bitDepth"] = @([(NSImageRep*)image.representations[0] bitsPerSample]);
//    }
//    #else
    image = [[NSImage alloc] initWithContentsOfURL:fileURL];
    passthroughFileOptions[@"bitDepth"] = @([(NSImageRep*)image.representations[0] bitsPerSample]);
  //  #endif

    NSString *fileTypeVariant = [fileURL pathExtension].uppercaseString;

    if([fileTypeVariant isEqualToString:@"TIF"]){
        fileTypeVariant = @"TIFF";
    }

    passthroughFileOptions[@"fileTypeVariant"] = fileTypeVariant;


    LUT *lut = [self LUTFromImage:image];
    lut.passthroughFileOptions = @{[self formatterID] : passthroughFileOptions};
    return lut;
}

+ (NSImage *)imageFromLUT:(LUT *)lut bitdepth:(NSUInteger)bitdepth{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (LUT *)LUTFromImage:(NSImage *)image{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

#endif

+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType3D;
}

+ (NSArray *)fileExtensions{
 //   #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
  //  return @[@"tiff", @"tif", @"dpx"];
  //  #else
    return @[@"tiff", @"tif"];
  //  #endif
}

+ (BOOL)canRead{
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return NO;
    #elif TARGET_OS_MAC
    return YES;
    #endif
}

+ (BOOL)canWrite{
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return NO;
    #elif TARGET_OS_MAC
    return YES;
    #endif
}

+ (NSDictionary *)constantConstraints{
    return @{@"outputBounds":@[@0, @1],
             @"lutSize":@[@2, @64]};
}

+ (NSArray *)allOptions{
    M13OrderedDictionary *tiffBitDepthOrderedDict = [[M13OrderedDictionary alloc] initWithObjects:@[@(16),@(8)] pairedWithKeys:@[@"16-bit", @"8-bit"]];

    NSDictionary *tiffOptions =
    @{@"fileTypeVariant":@"TIFF",
      @"bitDepth":tiffBitDepthOrderedDict};

//    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
//    M13OrderedDictionary *dpxBitDepthOrderedDict = [[M13OrderedDictionary alloc] initWithObjects:@[@(OIIOImageEncodingTypeUINT10), @(OIIOImageEncodingTypeUINT12), @(OIIOImageEncodingTypeUINT16)] pairedWithKeys:@[@"10-bit", @"12-bit", @"16-bit"]];
//
//    NSDictionary *dpxOptions =
//    @{@"fileTypeVariant":@"DPX",
//      @"bitDepth":dpxBitDepthOrderedDict};
//    return @[dpxOptions, tiffOptions];
//    #else
    return @[tiffOptions];
//    #endif
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary;
//    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
//    dictionary = @{@"fileTypeVariant": @"DPX",
//                   @"bitDepth": @(OIIOImageEncodingTypeUINT10)};
//    #else
    dictionary = @{@"fileTypeVariant": @"TIFF",
                   @"bitDepth": @(16)};
//#endif
    return @{[self formatterID]: dictionary};
}

+ (NSString *)utiString{
    return @"public.image";
}


@end
