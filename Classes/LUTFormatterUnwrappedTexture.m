//
//  LUTFormatterUnwrappedTexture.m
//  Pods
//
//  Created by Wil Gieseler on 3/30/14.
//
//

#import "LUTFormatterUnwrappedTexture.h"
#import "CocoaLUT.h"
#import "NSImage+OIIO.h"

@implementation LUTFormatterUnwrappedTexture

+ (void)load{
    [super load];
}

+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options {
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return UIImagePNGRepresentation([self imageFromLUT:lut]);
    # elif TARGET_OS_MAC
    return [[self imageFromLUT:lut] TIFFRepresentation];
    # endif
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (UIImage *)imageFromLUT:(LUT *)lut {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterUnwrappedTexture doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}
+ (LUT *)LUTFromImage:(UIImage *)image {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterUnwrappedTexture doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}
#elif TARGET_OS_MAC

+ (NSImage *)imageFromLUT:(LUT *)lut {
    
    LUT3D *lut3D = LUTAsLUT3D(lut, clampUpperBound([lut size], 64));
    
    CGFloat width  = [lut3D size] * [lut3D size];
    CGFloat height = [lut3D size];
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                   pixelsWide:width
                                                                   pixelsHigh:height
                                                                bitsPerSample:16
                                                              samplesPerPixel:3
                                                                     hasAlpha:NO
                                                                     isPlanar:NO
                                                               colorSpaceName:NSDeviceRGBColorSpace
                                                                  bytesPerRow:(width * (16 * 3)) / 8
                                                                 bitsPerPixel:16 * 3];
    
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSUInteger x = b * [lut3D size] + r;
        NSUInteger y = g;
        NSColor *color = [[lut3D colorAtR:r g:g b:b].systemColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        [imageRep setColor:color atX:x y:y];
    }];
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    return image;
}

+ (LUT *)LUTFromURL:(NSURL *)fileURL {
    if(![[self fileExtensions] containsObject:[fileURL pathExtension]]){
        [NSException exceptionWithName:@"UnwrappedTextureReadError"
                                reason:@"Invalid file extension." userInfo:nil];
    }
    NSMutableDictionary *passthroughFileOptions;
    NSImage *image;
    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
    image = [NSImage oiio_imageWithContentsOfURL:fileURL];
    #else
    image = [[NSImage alloc] initWithContentsOfURL:fileURL];
    #endif
    passthroughFileOptions[@"fileTypeVariant"] = [fileURL pathExtension].uppercaseString;
    if([image oiio_findOIIOImageRep] != nil){
        passthroughFileOptions[@"bit-Depth"] = @([image oiio_findOIIOImageRep].encodingType);
    }
    else{
        passthroughFileOptions[@"bit-Depth"] = @([(NSImageRep*)image.representations[0] bitsPerSample]);
    }
    
    if (image.size.width != image.size.height * image.size.height) {
        @throw [NSException exceptionWithName:@"UnwrappedTextureReadError"
                                                         reason:@"Image width must be the square of the image height." userInfo:nil];
    }
    
    LUT3D *lut3D = [LUT3D LUTOfSize:image.size.height inputLowerBound:0.0 inputUpperBound:1.0];

    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSUInteger x = b * [lut3D size] + r;
        NSUInteger y = g;
        [lut3D setColor:[LUTColor colorWithSystemColor:[imageRep colorAtX:x y:y]] r:r g:g b:b];
    }];
    lut3D.passthroughFileOptions = passthroughFileOptions;
    return lut3D;
}
#endif

+(BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if([super isValidReaderForURL:fileURL] == NO){
        return NO;
    }
    
    LUT *lut;
    @try {
        lut = [self LUTFromURL:fileURL];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception reading file: %@: %@", exception.name, exception);
        return NO;
    }
    return YES;
}

+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType3D;
}

+ (NSString *)utiString{
    return @"public.unwrapped-cube-lut";
}

+ (NSArray *)fileExtensions{
    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
    return @[@"tiff", @"tif", @"dpx"];
    #else
    return @[@"tiff", @"tif"];
    #endif
}

+ (NSString *)formatterName{
    return @"Unwrapped Cube Image 3D LUT";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSArray *)allOptions{
    M13OrderedDictionary *tiffBitDepthOrderedDict = [[M13OrderedDictionary alloc] initWithObjects:@[@"8-bit", @"16-bit"] pairedWithKeys:@[@(OIIOImageEncodingTypeUINT8), @(16)]];
    
    NSDictionary *tiffOptions =
    @{@"fileTypeVariant":@"TIFF",
      @"bit-Depth":tiffBitDepthOrderedDict};
    
    
    M13OrderedDictionary *dpxBitDepthOrderedDict = [[M13OrderedDictionary alloc] initWithObjects:@[@"10-bit", @"12-bit", @"16-bit"] pairedWithKeys:@[@(OIIOImageEncodingTypeUINT10), @(OIIOImageEncodingTypeUINT12), @(OIIOImageEncodingTypeUINT16)]];
    
    NSDictionary *dpxOptions =
    @{@"fileTypeVariant":@"DPX",
      @"bit-Depth":dpxBitDepthOrderedDict};
    
    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
    return @[dpxOptions, tiffOptions];
    #else
    return @[tiffOptions];
    #endif
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary;
    #if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
    dictionary = @{@"fileTypeVariant": @"DPX",
                   @"bit-Depth": @(OIIOImageEncodingTypeUINT10)};
    #else
    dictionary = @{@"fileTypeVariant": @"TIFF",
                   @"bit-Depth": @(16)};
    #endif
    return @{[self utiString]: dictionary};
}

@end
