#if TARGET_OS_IPHONE
#import <CoreImage/CoreImage.h>
#elif TARGET_OS_MAC
#import <QuartzCore/CoreImage.h>
#import <Cocoa/Cocoa.h>
#endif

#ifndef _COCOALUT_

    #define _COCOALUT_

    #import "LUTHelper.h"
    #import "LUT.h"
    #import "LUTLattice.h"
    #import "LUTColor.h"
    #import "LUT1D.h"
    #import "LUTColorSpace.h"
    #import "LUTColorTransferFunction.h"

#endif

