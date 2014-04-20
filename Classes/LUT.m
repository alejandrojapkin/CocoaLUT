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
@property (strong) LUTLattice *lattice;
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

- (instancetype)init {
    if (self = [super init]) {
        self.metadata = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)LUTWithLattice:(LUTLattice *)lattice {
    LUT *lut = [[LUT alloc] init];
    lut.lattice = lattice;
    return lut;
}

+ (instancetype)identityLutOfSize:(NSUInteger)size {
    NSMutableArray *indices = [NSMutableArray array];
    float ratio = 1.0 / (float)(size - 1);
    for (int i = 0; i < size; i++) {
        [indices addObject:@((float)i * ratio)];
    }
    
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:size];

    LUTConcurrentCubeLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColorValue rv = [indices[r] doubleValue];
        LUTColorValue gv = [indices[g] doubleValue];
        LUTColorValue bv = [indices[b] doubleValue];
        [lattice setColor:[LUTColor colorWithRed:rv green:gv blue:bv] r:r g:g b:b];
    });

    return [LUT LUTWithLattice:lattice];
}

- (instancetype)LUTByCombiningWithLUT:(LUT *)otherLUT {
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:self.lattice.size];
    
    LUTConcurrentCubeLoop(lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *startColor = [self.lattice colorAtR:r g:g b:b];
        LUTColor *newColor = [otherLUT.lattice colorAtColor:startColor];
        [lattice setColor:newColor r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:lattice];
}

- (instancetype)LUTByCombiningWithLUT1D:(LUT1D *)otherLUT {
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:self.lattice.size];
    
    LUTConcurrentCubeLoop(self.lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *color = [self.lattice colorAtR:r
                                               g:g
                                               b:b];
        LUTColor *transformedColor = [otherLUT colorAtColor:color];
        [lattice setColor:transformedColor r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:lattice];
}

- (instancetype)LUTByClamping01{
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:self.lattice.size];
    
    LUTConcurrentCubeLoop(lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        [lattice setColor:[[self.lattice colorAtR:r g:g b:b] clamped01] r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:lattice];
}

- (instancetype)LUTByExtracting1DWithExtractionMethod:(LUT1DExtractionMethod)extractionMethod{
    LUT1D *extracted1D = [self LUT1DWithExtractionMethod:extractionMethod];
    return [extracted1D lutOfSize:self.lattice.size];
}

+ (M13OrderedDictionary *)LUT1DExtractionMethods{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Averaged RGB":@(LUT1DExtractionMethodAverageRGB)},
                                                                  @{@"Unique RGB":@(LUT1DExtractionMethodUniqueRGB)},
                                                                  @{@"Copy Red Channel":@(LUT1DExtractionMethodRedCopiedToRGB)},
                                                                  @{@"Copy Green Channel":@(LUT1DExtractionMethodGreenCopiedToRGB)},
                                                                  @{@"Copy Blue Channel":@(LUT1DExtractionMethodBlueCopiedToRGB)}]);
}

- (LUT1D *)LUT1DWithExtractionMethod:(LUT1DExtractionMethod)extractionMethod{
    NSMutableArray *redCurve = [NSMutableArray array];
    NSMutableArray *greenCurve = [NSMutableArray array];
    NSMutableArray *blueCurve = [NSMutableArray array];
    
    LUTColor *color;
    for(int i = 0; i < self.lattice.size; i++){
        if(extractionMethod == LUT1DExtractionMethodAverageRGB){
            color = [self.lattice colorAtR:i g:i b:i];
            double averageValue = (color.red+color.green+color.blue)/3.0;
            [redCurve addObject:@(averageValue)];
            [greenCurve addObject:@(averageValue)];
            [blueCurve addObject:@(averageValue)];
        }
        else if(extractionMethod == LUT1DExtractionMethodUniqueRGB){
            color = [self.lattice colorAtR:i g:i b:i];
            [redCurve addObject:@(color.red)];
            [greenCurve addObject:@(color.green)];
            [blueCurve addObject:@(color.blue)];
        }
        else if(extractionMethod == LUT1DExtractionMethodRedCopiedToRGB){
            color = [self.lattice colorAtR:i g:i b:i];
            [redCurve addObject:@(color.red)];
            [greenCurve addObject:@(color.red)];
            [blueCurve addObject:@(color.red)];
        }
        else if(extractionMethod == LUT1DExtractionMethodGreenCopiedToRGB){
            color = [self.lattice colorAtR:i g:i b:i];
            [redCurve addObject:@(color.green)];
            [greenCurve addObject:@(color.green)];
            [blueCurve addObject:@(color.green)];
        }
        else if(extractionMethod == LUT1DExtractionMethodBlueCopiedToRGB){
            color = [self.lattice colorAtR:i g:i b:i];
            [redCurve addObject:@(color.blue)];
            [greenCurve addObject:@(color.blue)];
            [blueCurve addObject:@(color.blue)];
        }
    }
    
    return [LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve lowerBound:0.0 upperBound:1.0];
}

- (instancetype)LUTByResizingToSize:(NSUInteger)newSize {
    if (newSize == self.lattice.size) {
        return [self copy];
    }
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:newSize];

    double ratio = ((double)self.lattice.size - 1.0) / ((float)newSize - 1.0);
    
    LUTConcurrentCubeLoop(newSize, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *color = [self.lattice colorAtInterpolatedR:r * ratio g:g * ratio b:b * ratio];
        [lattice setColor:color r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:lattice];
}

- (instancetype)LUTByExtractingColorOnly{
    LUT1D *reversed1D = [[self LUT1DWithExtractionMethod:LUT1DExtractionMethodUniqueRGB] LUT1DByReversing];
    
    if(reversed1D == nil){
        return nil;
    }
    
    
    
    LUT *extractedLUT = [self LUTByCombiningWithLUT1D:reversed1D];
    
    [extractedLUT.metadata setObject:@(reversed1D.inputLowerBound) forKey:@"Input Lower"];
    [extractedLUT.metadata setObject:@(reversed1D.inputUpperBound) forKey:@"Input Upper"];
    return extractedLUT;
}

- (bool) equalsIdentityLUT{
    return [self equalsLUT:[LUT identityLutOfSize:self.lattice.size]];
}

- (bool)equalsLUT:(LUT *)comparisonLUT{
    if(comparisonLUT.lattice.size != self.lattice.size){
        return false;
    }
    bool __block isEqual = true;
    LUTConcurrentCubeLoop(self.lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        if(! ([[comparisonLUT.lattice colorAtR:r g:g b:b] equalsLUTColor:[self.lattice colorAtR:r g:g b:b]]) ){
            isEqual = false;
        }
    });
    return isEqual;
}

- (id)copyWithZone:(NSZone *)zone {
    LUT *lut = [LUT LUTWithLattice:[self.lattice copyWithZone:zone]];
    lut.metadata = [self.metadata mutableCopyWithZone:zone];
    lut.description = [self.description copyWithZone:zone];
    lut.title = [self.title copyWithZone:zone];
    return lut;
}

- (CIFilter *)coreImageFilterWithCurrentColorSpace {
    #if TARGET_OS_IPHONE
    return [self coreImageFilterWithColorSpace:CGColorSpaceCreateDeviceRGB()];
    #elif TARGET_OS_MAC
    return [self coreImageFilterWithColorSpace:[[[NSScreen mainScreen] colorSpace] CGColorSpace]];
    #endif
}

- (CIFilter *)coreImageFilterWithColorSpace:(CGColorSpaceRef)colorSpace {
    
    LUT *usedLut = self.lattice.size > COCOALUT_MAX_CICOLORCUBE_SIZE ? [self LUTByResizingToSize:COCOALUT_MAX_CICOLORCUBE_SIZE] : self;
    
    NSUInteger size = usedLut.lattice.size;
    size_t cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *) malloc (cubeDataSize);
    
    size_t offset = 0;
    for (int b = 0; b < size; b++) {
        for (int g = 0; g < size; g++) {
            for (int r = 0; r < size; r++) {
                LUTColor *color = [usedLut.lattice colorAtR:r g:g b:b];
                
                cubeData[offset]   = (float)color.red;
                cubeData[offset+1] = (float)color.green;
                cubeData[offset+2] = (float)color.blue;
                cubeData[offset+3] = 1.0f;
                
                offset += 4;
            }
        }
    }
    
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
            LUTColor *transformedColor =[self.lattice colorAtColor:lutColor];
            [imageRep setColor:transformedColor.NSColor atX:x y:y];

        }
    }
    
    NSImage* outImage = [[NSImage alloc] initWithSize:image.size];
    [outImage addRepresentation:imageRep];
    return outImage;
}
#endif

@end
