//
//  NSImage+DeepImages.m
//  Pods
//
//  Created by Wil Gieseler on 3/6/14.
//
//

#import "NSImage+DeepImages.h"
#import "CocoaLUT.h"

@implementation NSImage (DeepImages)

+ (NSImage *)deep_imageWithCImage:(CIImage *)ciImage {
    
    int width = [ciImage extent].size.width;
    int rows = [ciImage extent].size.height;
    int rowBytes = (width * 8);
    
    
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                    pixelsWide:width
                                                                    pixelsHigh:rows
                                                                 bitsPerSample:16
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSCalibratedRGBColorSpace
                                                                  bitmapFormat:0
                                                                   bytesPerRow:rowBytes
                                                                  bitsPerPixel:0];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef context = CGBitmapContextCreate([rep bitmapData],
                                                 width,
                                                 rows,
                                                 16,
                                                 rowBytes,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CIContext* ciContext = [CIContext contextWithCGContext:context options:nil];
    [ciContext drawImage:ciImage atPoint:CGPointZero fromRect: [ciImage extent]];
    
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
    
    NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
    [nsImage addRepresentation:rep];
	return nsImage;
}


- (CIImage *)deep_CIImage {
    return [[CIImage alloc] initWithBitmapImageRep:[self.representations firstObject]];

}

@end
