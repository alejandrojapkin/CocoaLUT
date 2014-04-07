//
//  NSImage+DeepImages.m
//  Pods
//
//  Created by Wil Gieseler on 3/6/14.
//
//

#import "NSImage+DeepImages.h"
#import "CocoaLUT.h"

NSImage* deep_ImageWithCIImage(CIImage *ciImage, BOOL useSoftwareRenderer) {
    
    [NSGraphicsContext saveGraphicsState];

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
                                                                colorSpaceName:NSDeviceRGBColorSpace
                                                                  bitmapFormat:0
                                                                   bytesPerRow:rowBytes
                                                                  bitsPerPixel:0];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate([rep bitmapData],
                                                 width,
                                                 rows,
                                                 16,
                                                 rowBytes,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    NSDictionary *contextOptions = @{
                                     kCIContextWorkingColorSpace: (__bridge id)colorSpace,
                                     kCIContextOutputColorSpace: (__bridge id)colorSpace,
                                     kCIContextUseSoftwareRenderer: @(useSoftwareRenderer)
                                     };
    
    CIContext* ciContext = [CIContext contextWithCGContext:context options:contextOptions];
    
    [ciContext drawImage:ciImage
                  inRect:CGRectMake(0, 0, ciImage.extent.size.width, ciImage.extent.size.height)
                fromRect:ciImage.extent];
    
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
    [nsImage addRepresentation:rep];
	return nsImage;

}

@implementation NSImage (DeepImages)

+ (NSImage *)deep_imageWithCImage:(CIImage *)ciImage {
    return deep_ImageWithCIImage(ciImage, NO);
}


- (CIImage *)deep_CIImage {
    return [[CIImage alloc] initWithBitmapImageRep:[self.representations firstObject]];

}

@end
