//
//  LUTFormatterUnwrappedTexture.m
//  Pods
//
//  Created by Wil Gieseler on 3/30/14.
//
//

#import "LUTFormatterUnwrappedTexture.h"
#import "CocoaLUT.h"

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

+ (LUT *)LUTFromData:(NSData *)data {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [self LUTFromImage:[[UIImage alloc] initWithData:data]];
# elif TARGET_OS_MAC
    return [self LUTFromImage:[[NSImage alloc] initWithData:data]];
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

+ (LUT *)LUTFromImage:(NSImage *)image {
    if (image.size.width != image.size.height * image.size.height) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError"
                                                         reason:@"Image width must be the square of the image height." userInfo:nil];
        @throw exception;
    }
    
    LUT3D *lut3D = [LUT3D LUTOfSize:image.size.height inputLowerBound:0.0 inputUpperBound:1.0];

    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSUInteger x = b * [lut3D size] + r;
        NSUInteger y = g;
        [lut3D setColor:[LUTColor colorWithSystemColor:[imageRep colorAtX:x y:y]] r:r g:g b:b];
    }];

    return lut3D;
}
#endif

+(BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if([super isValidReaderForURL:fileURL] == NO){
        return NO;
    }
    
    LUT *lut;
    @try {
        lut = [[self class] LUTFromURL:fileURL];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception reading file: %@", exception);
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
    return @[@"tiff", @"tif", @"dpx", @"png"];
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

@end
