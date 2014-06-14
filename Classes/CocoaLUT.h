#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <CoreImage/CoreImage.h>
#elif TARGET_OS_MAC
#import <QuartzCore/CoreImage.h>
#import <Cocoa/Cocoa.h>
#endif

#define TICK   NSDate *startTime = [NSDate date]
#define TOCK   NSLog(@"%s Time: %f", __func__, -[startTime timeIntervalSinceNow])

#ifndef _COCOALUT_

    #define _COCOALUT_

    #define COCOALUT_MAX_CICOLORCUBE_SIZE 64

    #import "LUTHelper.h"
    #import "LUT.h"
    #import "LUT1D.h"
    #import "LUT3D.h"
    #import "LUTColor.h"
    #import "LUTColorSpace.h"
    #import "LUTColorTransferFunction.h"

#endif

