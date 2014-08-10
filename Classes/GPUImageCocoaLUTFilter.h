//
//  GPUImageCocoaLUTFilter.h
//  Pods
//
//  Created by Wil Gieseler on 8/10/14.
//
//

#import "GPUImageFilter.h"
#if defined(COCOAPODS_POD_AVAILABLE_GPUImage)
#import <GPUImage/GPUImage.h>

@class LUT;

@interface GPUImageCocoaLUTFilter : GPUImageFilterGroup

- (id)initWithLUT:(LUT *)lut;

@end
#endif