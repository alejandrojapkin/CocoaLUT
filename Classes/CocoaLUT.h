#if TARGET_OS_IPHONE
#import <CoreImage/CoreImage.h>
#elif TARGET_OS_MAC
#import <QuartzCore/CoreImage.h>
#endif

#ifndef _COCOALUT_

    #define _COCOALUT_

    #if TARGET_OS_IPHONE
    // TBD
    #elif TARGET_OS_MAC
    #import "NSImage+DeepImages.h"
    #endif

    #import "LUTHelper.h"
    #import "LUT.h"
    #import "LUTLattice.h"
    #import "LUTColor.h"
    #import "LUT1D.h"

#endif

