//
//  LUT.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUT.h"
#import "CocoaLUT.h"
#import "LUTFormatter.h"

@interface LUT ()
@end

@implementation LUT

- (instancetype)init {
    if (self = [super init]) {
        self.metadata = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithSize:(NSUInteger)size
             inputLowerBound:(double)inputLowerBound
             inputUpperBound:(double)inputUpperBound{
    if (self = [super init]) {
        if(inputLowerBound >= inputUpperBound){
            @throw [NSException exceptionWithName:@"LUTCreationError" reason:@"Input Lower Bound >= Input Upper Bound" userInfo:nil];
        }
        self.metadata = [NSMutableDictionary dictionary];
        self.passthroughFileOptions = [NSMutableDictionary dictionary];
        self.size = size;
        self.inputLowerBound = inputLowerBound;
        self.inputUpperBound = inputUpperBound;
    }
    return self;
}

+ (instancetype)LUTFromURL:(NSURL *)url {
    LUTFormatter *formatter = [LUTFormatter LUTFormatterForURL:url];
    NSLog(@"%@ %@", formatter, url);
    return [[formatter class] LUTFromURL:url];
}

- (NSData *)dataFromLUTWithUTIString:(NSString *)utiString
                             options:(NSDictionary *)options{
    LUTFormatter *formatter = [LUTFormatter LUTFormatterForUTIString:utiString];
    if(formatter == nil){
        return nil;
    }
    else{
        return [[formatter class] dataFromLUT:self withOptions:options];
    }
    
}

+ (instancetype)LUTOfSize:(NSUInteger)size
          inputLowerBound:(double)inputLowerBound
          inputUpperBound:(double)inputUpperBound{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

+ (instancetype)LUTIdentityOfSize:(NSUInteger)size
                  inputLowerBound:(double)inputLowerBound
                  inputUpperBound:(double)inputUpperBound{
    LUT *identityLUT = [[self class] LUTOfSize:size inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
    
    [identityLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [identityLUT setColor:[identityLUT identityColorAtR:r g:g b:b] r:r g:g b:b];
    }];
    
    return identityLUT;
}

- (void)copyMetaPropertiesFromLUT:(LUT *)lut{
    self.title = [lut.title copy];
    self.descriptionText = [lut.descriptionText copy];
    self.metadata = [lut.metadata mutableCopy];
    self.passthroughFileOptions = [lut.passthroughFileOptions copy];
}

- (void)LUTLoopWithBlock:(void (^)(size_t r, size_t g, size_t b))block{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}


- (instancetype)LUTByResizingToSize:(NSUInteger)newSize {
    if (newSize == [self size]) {
        return [self copy];
    }
    LUT *resizedLUT = [[self class] LUTOfSize:newSize inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    
    [resizedLUT copyMetaPropertiesFromLUT:self];
    
    double ratio = ((double)self.size - 1.0) / ((double)newSize - 1.0);
    
    [resizedLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtInterpolatedR:clampUpperBound(r * ratio, self.size-1.0) g:clampUpperBound(g * ratio, self.size-1.0) b:clampUpperBound(b * ratio, self.size-1.0)];
        [resizedLUT setColor:color r:r g:g b:b];
    }];

    return resizedLUT;
}

- (instancetype)LUTByClampingLowerBound:(double)lowerBound
                             upperBound:(double)upperBound{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] clampedWithLowerBound:lowerBound upperBound:upperBound] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (instancetype)LUTByClampingLowerBoundOnly:(double)lowerBound{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] clampedWithLowerBoundOnly:lowerBound] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (instancetype)LUTByClampingUpperBoundOnly:(double)upperBound{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] clampedWithUpperBoundOnly:upperBound] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (instancetype)LUTByRemappingValuesWithInputLow:(double)inputLow
                                       inputHigh:(double)inputHigh
                                       outputLow:(double)outputLow
                                      outputHigh:(double)outputHigh
                                         bounded:(BOOL)bounded{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self colorAtR:r g:g b:b] remappedFromInputLow:inputLow
                                                               inputHigh:inputHigh
                                                               outputLow:outputLow
                                                              outputHigh:outputHigh
                                                                 bounded:bounded] r:r g:g b:b];
    }];
    
    return newLUT;
    
}

- (instancetype)LUTByChangingStrength:(double)strength{
    if(strength > 1.0){
        @throw [NSException exceptionWithName:@"ChangeStrengthError" reason:[NSString stringWithFormat:@"You can't set the strength of the LUT past 1.0 (%f)", strength] userInfo:nil];
    }
    if(strength == 1.0){
        return [self copy];
    }
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[[self identityColorAtR:r g:g b:b] lerpTo:[self colorAtR:r g:g b:b] amount:strength] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (instancetype)LUTByCombiningWithLUT:(LUT *)otherLUT {
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (instancetype)LUTBySwizzling1DChannelsWithMethod:(LUT1DSwizzleChannelsMethod)method{
     @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (instancetype)LUTByChangingInputLowerBound:(double)inputLowerBound
                             inputUpperBound:(double)inputUpperBound{
    if(inputLowerBound == [self inputLowerBound] && inputUpperBound == [self inputUpperBound]){
        return [self copy];
    }
    
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *identityColor = [newLUT identityColorAtR:r g:g b:b];
        [newLUT setColor:[self colorAtColor:identityColor] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (instancetype)LUTByInvertingColor{
    LUT *newLUT = [[self class] LUTOfSize:[self size] inputLowerBound:self.inputLowerBound inputUpperBound:self.inputUpperBound];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *startColor = [self colorAtR:r g:g b:b];
        [newLUT setColor:[startColor colorByInvertingColorWithMinimumValue:0 maximumValue:1] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (LUTColor *)identityColorAtR:(double)redPoint g:(double)greenPoint b:(double)bluePoint{
    double red = remap(redPoint, 0, [self size] - 1, [self inputLowerBound], [self inputUpperBound]);
    double green = remap(greenPoint, 0, [self size] - 1, [self inputLowerBound], [self inputUpperBound]);
    double blue = remap(bluePoint, 0, [self size] - 1, [self inputLowerBound], [self inputUpperBound]);
    return [LUTColor colorWithRed:red green:green blue:blue];
}

- (LUTColor *)colorAtColor:(LUTColor *)color{
    color = [color clampedWithLowerBound:[self inputLowerBound] upperBound:[self inputUpperBound]];
    double redRemappedInterpolatedIndex = remap(color.red, [self inputLowerBound], [self inputUpperBound], 0, [self size]-1);
    double greenRemappedInterpolatedIndex = remap(color.green, [self inputLowerBound], [self inputUpperBound], 0, [self size]-1);
    double blueRemappedInterpolatedIndex = remap(color.blue, [self inputLowerBound], [self inputUpperBound], 0, [self size]-1);
    
    return [self colorAtInterpolatedR:redRemappedInterpolatedIndex
                                    g:greenRemappedInterpolatedIndex
                                    b:blueRemappedInterpolatedIndex];
}

- (LUTColor *)colorAtR:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (LUTColor *)colorAtInterpolatedR:(double)redPoint g:(double)greenPoint b:(double)bluePoint{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (void)setColor:(LUTColor *)color r:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}

- (double)maximumOutputValue{
    __block double maxValue = [self colorAtR:0 g:0 b:0].red;
    [self LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtR:r g:g b:b];
        if(color.red > maxValue){
            maxValue = color.red;
        }
        if(color.green > maxValue){
            maxValue = color.green;
        }
        if(color.blue > maxValue){
            maxValue = color.blue;
        }
    }];
    return maxValue;
}

- (double)minimumOutputValue{
    __block double minValue = [self colorAtR:0 g:0 b:0].red;
    [self LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *color = [self colorAtR:r g:g b:b];
        if(color.red < minValue){
            minValue = color.red;
        }
        if(color.green < minValue){
            minValue = color.green;
        }
        if(color.blue < minValue){
            minValue = color.blue;
        }
    }];
    return minValue;
}


//000

- (bool) equalsIdentityLUT{
    return [self equalsLUT:[[self class] LUTIdentityOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]]];
}

- (bool)equalsLUT:(LUT *)comparisonLUT{
    @throw [NSException exceptionWithName:@"NotImplemented" reason:[NSString stringWithFormat:@"\"%s\" Not Implemented", __func__] userInfo:nil];
}



- (id)copyWithZone:(NSZone *)zone {
    LUT *copiedLUT = [[self class] LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [copiedLUT setMetadata:[[self metadata] mutableCopyWithZone:zone]];
    copiedLUT.descriptionText = [[self description] mutableCopyWithZone:zone];
    [copiedLUT setTitle:[[self title] mutableCopyWithZone:zone]];
    [copiedLUT setPassthroughFileOptions:[[self passthroughFileOptions] mutableCopyWithZone:zone]];
    return copiedLUT;
}

- (CIFilter *)coreImageFilterWithCurrentColorSpace {
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [self coreImageFilterWithColorSpace:CGColorSpaceCreateDeviceRGB()];
    #elif TARGET_OS_MAC
    //good for render, not good for viewing
    return [self coreImageFilterWithColorSpace:CGColorSpaceCreateDeviceRGB()];
    //good for viewing, not good for render
    //return [self coreImageFilterWithColorSpace:[[[NSScreen mainScreen] colorSpace] CGColorSpace]];
    #endif
}

- (CIFilter *)coreImageFilterWithColorSpace:(CGColorSpaceRef)colorSpace {
    NSUInteger sizeOfColorCubeFilter = clamp([self size], 0, COCOALUT_MAX_CICOLORCUBE_SIZE);
    LUT3D *used3DLUT = [LUTAsLUT3D(self, sizeOfColorCubeFilter) LUTByChangingInputLowerBound:0.0 inputUpperBound:1.0];
    
    size_t size = [used3DLUT size];
    size_t cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *) malloc (cubeDataSize);
    
    [used3DLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *transformedColor = [used3DLUT colorAtR:r g:g b:b];
        
        size_t offset = 4*(b*size*size + g*size + r);
        
        cubeData[offset]   = (float)transformedColor.red;
        cubeData[offset+1] = (float)transformedColor.green;
        cubeData[offset+2] = (float)transformedColor.blue;
        cubeData[offset+3] = 1.0f;
    }];
    
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

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
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
            
            LUTColor *lutColor = [LUTColor colorWithSystemColor:[inImageRep colorAtX:x y:y]];
            LUTColor *transformedColor =[self colorAtColor:lutColor];
            [imageRep setColor:transformedColor.systemColor atX:x y:y];

        }
    }
    
    NSImage* outImage = [[NSImage alloc] initWithSize:image.size];
    [outImage addRepresentation:imageRep];
    return outImage;
}
#endif

@end
