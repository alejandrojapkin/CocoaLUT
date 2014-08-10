//
//  GPUImageCocoaLUTFilter.m
//  Pods
//
//  Created by Wil Gieseler on 8/10/14.
//
//

#import "GPUImageCocoaLUTFilter.h"
#import "CocoaLUT.h"
#import "LUTFormatterUnwrappedTexture.h"

#if defined(COCOAPODS_POD_AVAILABLE_GPUImage)
@implementation GPUImageCocoaLUTFilter {
    GPUImagePicture *lookupImageSource;
}

- (id)initWithLUT:(LUT *)lut {
    if (!(self = [super init])) {
        return nil;
    }

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [LUTFormatterUnwrappedTexture imageFromLUT:lut bitdepth:8];
#else
    NSImage *image = [LUTFormatterUnwrappedTexture imageFromLUT:lut bitdepth:8];
#endif

    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];

    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];

    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

@end
#endif