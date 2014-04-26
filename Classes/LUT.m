//
//  LUT.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUT.h"
#import "CocoaLUT.h"
#import "LUTFormatterCube.h"
#import "LUTFormatter3DL.h"
#import "LUTFormatterOLUT.h"
#import "LUTFormatterILUT.h"
#import "LUTFormatterDiscreet1DLUT.h"
#import "LUTFormatterUnwrappedTexture.h"
#import "LUTFormatterCMSTestPattern.h"

@interface LUT ()
@end

@implementation LUT

+ (instancetype)LUTFromURL:(NSURL *)url {
    if ([url.pathExtension.lowercaseString isEqualToString:@"cube"]){
        return [LUTFormatterCube LUTFromFile:url];
    }
    else if ([url.pathExtension.lowercaseString isEqualToString:@"3dl"]) {
        return [LUTFormatter3DL LUTFromFile:url];
    }
    else if ([url.pathExtension.lowercaseString isEqualToString:@"olut"]) {
        return [LUTFormatterOLUT LUTFromFile:url];
    }
    else if ([url.pathExtension.lowercaseString isEqualToString:@"ilut"]) {
        return [LUTFormatterILUT LUTFromFile:url];
    }
    else if ([url.pathExtension.lowercaseString isEqualToString:@"lut"]) {
        return [LUTFormatterDiscreet1DLUT LUTFromFile:url];
    }
    else if ([@[@"tif", @"tiff", @"png", @"dpx"] containsObject:url.pathExtension.lowercaseString]) {
        @try{
            return [LUTFormatterUnwrappedTexture LUTFromFile:url];
        }
        @catch (NSException *e) {
            NSLog(@"%@", e);
        }
        
        @try{
            return [LUTFormatterCMSTestPattern LUTFromFile:url];
        }
        @catch (NSException *e) {
            NSLog(@"%@", e);
        }
        
        NSException *exception = [NSException exceptionWithName:@"LUTParseError"
                                                         reason:@"Image dimensions don't conform to LUTFormatterCMSTestPattern or LUTFormatterUnwrappedTexture" userInfo:nil];
        @throw exception;
    }
    return nil;
}

+ (instancetype)LUTOfSize:(NSUInteger)size
          inputLowerBound:(double)inputLowerBound
          inputUpperBound:(double)inputUpperBound{
    return nil;
}

+ (instancetype)LUTIdentityOfSize:(NSUInteger)size {
    return nil;
}

- (instancetype)init {
    if (self = [super init]) {
        self.metadata = [NSMutableDictionary dictionary];
    }
    return self;
}


- (instancetype)LUTByResizingToSize:(NSUInteger)newSize {
    return nil;
}


- (instancetype)LUTByCombiningWithLUT:(LUT *)otherLUT {
    return nil;
}

- (instancetype)LUTByClamping01{
    return nil;
}

- (LUTColor *)colorAtColor:(LUTColor *)color{
    return nil;
}

- (LUTColor *)colorAtR:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b{
    return nil;
}

- (LUTColor *)colorAtInterpolatedR:(double)redPoint g:(double)greenPoint b:(double)bluePoint{
    return nil;
}


//000

- (bool) equalsIdentityLUT{
    return [self equalsLUT:[LUT LUTIdentityOfSize:[self size]]];
}

- (bool)equalsLUT:(LUT *)comparisonLUT{
    return nil;
}



- (id)copyWithZone:(NSZone *)zone {
    return nil;
}

- (CIFilter *)coreImageFilterWithCurrentColorSpace {
    #if TARGET_OS_IPHONE
    return [self coreImageFilterWithColorSpace:CGColorSpaceCreateDeviceRGB()];
    #elif TARGET_OS_MAC
    //good for render, not good for viewing
    return [self coreImageFilterWithColorSpace:CGColorSpaceCreateDeviceRGB()];
    //good for viewing, not good for render
    //return [self coreImageFilterWithColorSpace:[[[NSScreen mainScreen] colorSpace] CGColorSpace]];
    #endif
}

- (CIFilter *)coreImageFilterWithColorSpace:(CGColorSpaceRef)colorSpace {
    NSUInteger size = COCOALUT_MAX_CICOLORCUBE_SIZE;
    size_t cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *) malloc (cubeDataSize);
    
    
    LUT3DConcurrentLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *sourceColor = [LUTColor colorWithRed:remap(r, 0, size-1, [self inputLowerBound], [self inputUpperBound])
                                                 green:remap(g, 0, size-1, [self inputLowerBound], [self inputUpperBound])
                                                  blue:remap(b, 0, size-1, [self inputLowerBound], [self inputUpperBound])];
        LUTColor *transformedColor = [self colorAtColor:sourceColor];
        
        size_t offset = 4*(b*size*size + g*size + r);
        
        cubeData[offset]   = (float)transformedColor.red;
        cubeData[offset+1] = (float)transformedColor.green;
        cubeData[offset+2] = (float)transformedColor.blue;
        cubeData[offset+3] = 1.0f;
    });
    

    
    NSData *data = [NSData dataWithBytesNoCopy:cubeData length:cubeDataSize freeWhenDone:YES];
    
    CIFilter *colorCube;
    if (colorSpace) {
        colorCube = [CIFilter filterWithName:@"CIColorCubeWithColorSpace"];
        [colorCube setValue:(__bridge id)(colorSpace) forKey:@"inputColorSpace"];
    }
    else {
        colorCube = [CIFilter filterWithName:@"CIColorCube"];
    }
    [colorCube setValue:@(size) forKey:@"inputCubeDimension"];
    [colorCube setValue:data forKey:@"inputCubeData"];
    
    return colorCube;
}

- (CIImage *)processCIImage:(CIImage *)image {
    CIFilter *filter = [self coreImageFilterWithCurrentColorSpace];
    [filter setValue:image forKey:@"inputImage"];
    return [filter valueForKey:@"outputImage"];
}

#if TARGET_OS_IPHONE
- (UIImage *)processUIImage:(UIImage *)image withColorSpace:(CGColorSpaceRef)colorSpace {
    return [[UIImage alloc] initWithCIImage:[self processCIImage:image.CIImage]];
}
#elif TARGET_OS_MAC

- (NSImage *)processNSImage:(NSImage *)image
                 renderPath:(LUTImageRenderPath)renderPath {
        
    if (renderPath == LUTImageRenderPathCoreImage || renderPath == LUTImageRenderPathCoreImageSoftware) {
        CIImage *inputCIImage = [[CIImage alloc] initWithBitmapImageRep:[image.representations firstObject]];;
        CIImage *outputCIImage = [self processCIImage:inputCIImage];
        return LUTNSImageFromCIImage(outputCIImage, renderPath == LUTImageRenderPathCoreImageSoftware);
    }
    else if (renderPath == LUTImageRenderPathDirect) {
        return [self processNSImageDirectly:image];
    }
    
    return nil;
}

- (NSImage *)processNSImageDirectly:(NSImage *)image {
    
    NSBitmapImageRep *inImageRep = [image representations][0];
    

    int nchannels = 3;
    int bps = 16;
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                         pixelsWide:image.size.width
                                                                         pixelsHigh:image.size.height
                                                                      bitsPerSample:bps
                                                                    samplesPerPixel:nchannels
                                                                           hasAlpha:NO
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSDeviceRGBColorSpace
                                                                        bytesPerRow:(image.size.width * (bps * nchannels)) / 8
                                                                       bitsPerPixel:bps * nchannels];
    
    for (int x = 0; x < image.size.width; x++) {
        for (int y = 0; y < image.size.height; y++) {
            
            LUTColor *lutColor = [LUTColor colorWithNSColor:[inImageRep colorAtX:x y:y]];
            LUTColor *transformedColor =[self colorAtColor:lutColor];
            [imageRep setColor:transformedColor.NSColor atX:x y:y];

        }
    }
    
    NSImage* outImage = [[NSImage alloc] initWithSize:image.size];
    [outImage addRepresentation:imageRep];
    return outImage;
}
#endif

@end
