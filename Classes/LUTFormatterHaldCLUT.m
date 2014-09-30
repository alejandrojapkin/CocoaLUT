//
//  LUTFormatterHaldCLUT.m
//  Pods
//
//  Created by Greg Cotten on 9/12/14.
//
//

#import "LUTFormatterHaldCLUT.h"
#import "CocoaLUT.h"
#if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
#import "NSImage+OIIO.h"
#endif

@implementation LUTFormatterHaldCLUT

+ (void)load{
    [super load];
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

//maybe implement someday

#elif TARGET_OS_MAC

+(LUT *)LUTFromURL:(NSURL *)fileURL{
    LUT *lut = [super LUTFromURL:fileURL];
    if (!lut) {
        return nil;
    }
    else{
        NSMutableDictionary *exposedPassthroughOptions = [lut.passthroughFileOptions[[self formatterID]] mutableCopy];
        exposedPassthroughOptions[@"lutSize"] = @(lut.size);
        lut.passthroughFileOptions = @{[self formatterID] : [NSDictionary dictionaryWithDictionary:exposedPassthroughOptions]};
        return lut;
    }
}

+ (NSImage *)imageFromLUT:(LUT *)lut
                 bitdepth:(NSUInteger)bitdepth {

    LUT3D *lut3D = (LUT3D *)lut;

    if (sqrt(lut3D.size) != (double)((int)sqrt(lut3D.size))) {
        @throw [NSException exceptionWithName:@"HaldCLUTWriteError"
                                       reason:@"LUT size must be a whole number when square-rooted." userInfo:nil];
    }

    CGFloat width  = sqrt(lut3D.size * lut3D.size * lut3D.size);
    CGFloat height = width;

    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                         pixelsWide:width
                                                                         pixelsHigh:height
                                                                      bitsPerSample:bitdepth
                                                                    samplesPerPixel:3
                                                                           hasAlpha:NO
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSDeviceRGBColorSpace
                                                                        bytesPerRow:(width * (bitdepth * 3)) / 8
                                                                    bitsPerPixel:bitdepth * 3];

    int cubeIndex = 0;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int redIndex = cubeIndex % lut3D.size;
            int greenIndex = (cubeIndex % (lut3D.size * lut3D.size)) / (lut3D.size);
            int blueIndex = cubeIndex / (lut3D.size * lut3D.size);

            NSColor *color = [[lut3D colorAtR:redIndex g:greenIndex b:blueIndex].systemColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
            [imageRep setColor:color atX:x y:y];

            cubeIndex++;
        }
    }

    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    return image;
}

+ (LUT *)LUTFromImage:(NSImage *)image {

    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

    if (imageRep.pixelsWide != imageRep.pixelsHigh) {
        @throw [NSException exceptionWithName:@"HaldCLUTReadError"
                                       reason:@"Image width must be the same as the image height." userInfo:nil];
    }

    int lutSize = round(pow(pow(imageRep.pixelsWide, 2.0), 1.0/3.0));
    if (sqrt(lutSize) != (double)((int)sqrt(lutSize))) {
        @throw [NSException exceptionWithName:@"HaldCLUTReadError"
                                       reason:@"LUT Size isn't square-rootable." userInfo:nil];
    }

    LUT3D *lut3D = [LUT3D LUTOfSize:lutSize inputLowerBound:0.0 inputUpperBound:1.0];



    int cubeIndex = 0;
    for (int y = 0; y < imageRep.pixelsHigh; y++) {
        for (int x = 0; x < imageRep.pixelsHigh; x++) {
            int redIndex = cubeIndex % lut3D.size;
            int greenIndex = (cubeIndex % (lut3D.size * lut3D.size)) / (lut3D.size);
            int blueIndex = cubeIndex / (lut3D.size * lut3D.size);

            [lut3D setColor:[LUTColor colorWithSystemColor:[imageRep colorAtX:x y:y]] r:redIndex g:greenIndex b:blueIndex];

            cubeIndex++;
        }
    }

    return lut3D;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if (![super isValidReaderForURL:fileURL]) {
        return NO;
    }

    NSImage *image = [[NSImage alloc] initWithContentsOfURL:fileURL];
    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

    int lutSize = round(pow(pow(imageRep.pixelsWide, 2.0), 1.0/3.0));
    if (sqrt(lutSize) != (double)((int)sqrt(lutSize)) || lutSize > 64) {
        return NO;
    }
    else{
        return YES;
    }
}
#endif

+ (NSArray *)allOptions{
    NSMutableArray *sizeArray = [NSMutableArray array];

    for (int i = 3; i <= 8; i++) {
        [sizeArray addObject:@{[NSString stringWithFormat:@"%i", i*i] : @(i*i)}];
    }

    NSArray *superOptions = [super allOptions];
    NSMutableArray *newOptions = [NSMutableArray array];
    for (NSDictionary *option in superOptions) {
        NSDictionary *newOption = [option mutableCopy];
        [newOption setValue:M13OrderedDictionaryFromOrderedArrayWithDictionaries(sizeArray) forKey:@"lutSize"];
        [newOptions addObject:newOption];
    }
    
    return newOptions;
}

+ (NSDictionary *)defaultOptions{
    NSMutableDictionary *defaultsExposed = [[super defaultOptions][[self formatterID]] mutableCopy];
    defaultsExposed[@"lutSize"] = @(36);

    return @{[self formatterID] : defaultsExposed};
}

+ (NSString *)formatterName{
    return @"Hald CLUT";
}

+ (NSString *)formatterID{
    return @"haldCLUT";
}


@end
