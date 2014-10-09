//
//  LUTFormatterNukeCMSTestPattern.m
//
//
//  Created by Greg Cotten on 3/30/14.
//
//

#import "LUTFormatterCMSTestPattern.h"
#import "CocoaLUT.h"


@implementation LUTFormatterCMSTestPattern

+ (void)load{
    [super load];
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#elif TARGET_OS_MAC

+ (NSImage *)imageFromLUT:(LUT *)lut
                 bitdepth:(NSUInteger)bitdepth {

    LUT3D *lut3D = (LUT3D *)lut;

    int cubeSize = (int)[lut3D size];
    int height = round(sqrt(cubeSize)*(double)cubeSize);
    int width  = ceil(((double)pow(cubeSize,3))/(double)height);

    //NSLog(@"w:%i h:%i", width*7, height*7);

//    CGColorSpaceRef cgColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
//    NSColorSpace *linearRGBColorSpace = [[NSColorSpace alloc] initWithCGColorSpace:cgColorSpace];
//    CGColorSpaceRelease(cgColorSpace);


    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                         pixelsWide:(CGFloat)width*7
                                                                         pixelsHigh:(CGFloat)height*7
                                                                      bitsPerSample:bitdepth
                                                                    samplesPerPixel:3
                                                                           hasAlpha:NO
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSDeviceRGBColorSpace
                                                                        bytesPerRow:(width*7 * (bitdepth * 3)) / 8
                                                                       bitsPerPixel:bitdepth * 3];

    for(int y = 0; y < height; y++){
        for(int x = 0; x < width; x++){
            NSUInteger currentCubeIndex = y*width + x;

//                        NSLog(@"ax%i ay%i", x, (int)(height - (y+1)));
//                        NSLog(@"px%i py%i", x*7, (height - (y+1))*7);
            NSUInteger redIndex = currentCubeIndex % cubeSize;
            NSUInteger greenIndex = ( (currentCubeIndex % (cubeSize * cubeSize)) / (cubeSize) );
            NSUInteger blueIndex = currentCubeIndex / (cubeSize * cubeSize);


            if(currentCubeIndex < cubeSize*cubeSize*cubeSize){
                NSColor *color = [[lut3D colorAtR:redIndex g:greenIndex b:blueIndex].systemColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
                for(int px = (int)x*7; px < x*7+7; px++){
                    for(int py = (int)(height - (y+1))*7; py < (height - (y+1))*7+7; py++){
                        [imageRep setColor:color atX:px y:py];
                    }
                }
            }
        }
    }



    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    return image;
}

+ (LUT *)LUTFromImage:(NSImage *)image {

    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

    int cubeSize = (int)(round(pow((imageRep.pixelsHigh/7)*(imageRep.pixelsHigh/7), 1.0/3.0)));

    int height = round(sqrt(cubeSize)*(double)cubeSize);
    int width  = ceil(((double)pow(cubeSize,3))/(double)height);

    if (imageRep.pixelsWide != width*7 || imageRep.pixelsHigh != height*7) {
        NSException *exception = [NSException exceptionWithName:@"CMSTestPatternReadError"
                                                         reason:@"Image dimensions don't conform to spec." userInfo:nil];
        @throw exception;
    }

    LUT3D *lut = [LUT3D LUTOfSize:cubeSize inputLowerBound:0.0 inputUpperBound:1.0];



    LUTConcurrentRectLoop(width, height, ^(NSUInteger x, NSUInteger y) {
        NSUInteger currentCubeIndex = y*width + x;

        NSUInteger redIndex = currentCubeIndex % cubeSize;
        NSUInteger greenIndex = ( (currentCubeIndex % (cubeSize * cubeSize)) / (cubeSize) );
        NSUInteger blueIndex = currentCubeIndex / (cubeSize * cubeSize);

        if(currentCubeIndex < cubeSize*cubeSize*cubeSize){
            [lut setColor:[LUTColor colorWithSystemColor:[imageRep colorAtX:x*7 y:(height - (y+1))*7]] r:redIndex g:greenIndex b:blueIndex];
        }
    });

    return lut;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if (![super isValidReaderForURL:fileURL]) {
        return NO;
    }

    NSImage *image = [[NSImage alloc] initWithContentsOfURL:fileURL];
    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

    int cubeSize = (int)(round(pow((imageRep.pixelsHigh/7)*(imageRep.pixelsHigh/7), 1.0/3.0)));

    int height = round(sqrt(cubeSize)*(double)cubeSize);
    int width  = ceil(((double)pow(cubeSize,3))/(double)height);

    if (imageRep.pixelsWide != width*7 || imageRep.pixelsHigh != height*7) {
        return NO;
    }
    else{
//        NSColor *masterColor = [imageRep colorAtX:0 y:0];
//        for(int y = 0; y < 7; y++){
//            for (int x = 0; x < 7; x++) {
//                NSColor *color = [imageRep colorAtX:x y:y];
//                if (color.redComponent != masterColor.redComponent || color.greenComponent != masterColor.greenComponent || color.blueComponent != masterColor.blueComponent) {
//                    return NO;
//                }
//            }
//        }
        return YES;
    }
}

#endif

+ (NSString *)formatterName{
    return @"CMS Test Pattern Image 3D LUT";
}

+ (NSString *)formatterID{
    return @"cms";
}




@end
