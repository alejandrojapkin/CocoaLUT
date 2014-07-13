//
//  LUTPreviewImageGenerator.m
//  Pods
//
//  Created by Wil Gieseler on 12/15/13.
//
//

#import "LUTPreviewImageGenerator.h"

@implementation LUTPreviewImageGenerator

- (NSImage *)renderPreviewImageFromImage:(NSImage *)image resizedToSize:(NSSize)size {

    NSImage *finalImage = [NSImage imageWithSize:image.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [self drawPreviewImageFromImage:image resizedToSize:size inContext:NSGraphicsContext.currentContext];
        return YES;
    }];

    return finalImage;
}

- (void)drawPreviewImageFromImage:(NSImage *)image resizedToSize:(NSSize)size inContext:(NSGraphicsContext *)graphicsContext {

    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:graphicsContext];

    CGContextRef context = graphicsContext.graphicsPort;

    NSImage *baseImage = [image copy];
    NSImage *processedImage = [self.lut processNSImage:[baseImage copy]
                                            renderPath:LUTImageRenderPathCoreImage];

    CGSize targetSize = CGSizeProportionallyScaled(image.size, size);

    NSRect sourceRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    NSRect destinationRect = NSMakeRect(0, 0, targetSize.width, targetSize.height);

    CGImageRef unprocessedImageRef = [baseImage CGImageForProposedRect:&sourceRect context:NSGraphicsContext.currentContext hints:nil];
    CGImageRef processedImageRef = [processedImage CGImageForProposedRect:&sourceRect context:NSGraphicsContext.currentContext hints:nil];

    CGContextDrawImage(context, destinationRect, unprocessedImageRef);

    NSImage *maskImage = [NSImage imageWithSize:targetSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(0, 0)];
        [path lineToPoint:NSMakePoint(0, targetSize.height)];
        [path lineToPoint:NSMakePoint(targetSize.width, targetSize.height)];

        [[NSColor whiteColor] setFill];
        [path fill];

        return YES;

    }];

    CGImageRef maskImageRef = [maskImage CGImageForProposedRect:&sourceRect context:NSGraphicsContext.currentContext hints:nil];

    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskImageRef),
                                             CGImageGetHeight(maskImageRef),
                                             CGImageGetBitsPerComponent(maskImageRef),
                                             CGImageGetBitsPerPixel(maskImageRef),
                                             CGImageGetBytesPerRow(maskImageRef),
                                             CGImageGetDataProvider(maskImageRef),
                                             NULL, // Decode is null
                                             YES // Should interpolate
                                             );

    CGImageRef maskedImage = CGImageCreateWithMask(processedImageRef, imageMask);

    CGContextDrawImage(context, destinationRect, maskedImage);

    CGImageRelease(imageMask);
    CGImageRelease(maskedImage);

    CGContextSetLineWidth(context, 2.0f);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, targetSize.width, targetSize.height);
    CGContextSetStrokeColorWithColor(context, [NSColor colorWithWhite:1 alpha:0.5].CGColor);
    CGContextStrokePath(context);

    [NSGraphicsContext restoreGraphicsState];

}

@end
