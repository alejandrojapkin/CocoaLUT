//
//  GPUImageCocoaLUTFilter.h
//  Pods
//
//  Created by Wil Gieseler on 8/10/14.
//
//

#import "GPUImageFilter.h"
#import <GPUImage/GPUImage.h>

@class LUT;

#if defined(COCOAPODS_POD_AVAILABLE_GPUImage)
@interface GPUImageCocoaLUTFilter : GPUImageFilterGroup

- (id)initWithLUT:(LUT *)lut;

@end
#endif