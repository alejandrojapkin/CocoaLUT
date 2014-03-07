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

    NSImage *baseImage = [image copy];
    NSImage *processedImage = [self.lut processNSImage:[baseImage copy] withColorSpace:nil];

    NSImage *finalImage = [NSImage imageWithSize:image.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        CGContextRef context = NSGraphicsContext.currentContext.graphicsPort;


        NSRect rect = NSMakeRect(0, 0, processedImage.size.width, processedImage.size.height);
        CGImageRef unprocessedImageRef = [baseImage CGImageForProposedRect:&rect context:NSGraphicsContext.currentContext hints:nil];
        CGImageRef processedImageRef = [processedImage CGImageForProposedRect:&rect context:NSGraphicsContext.currentContext hints:nil];

        CGContextDrawImage(context, rect, unprocessedImageRef);
        
        NSImage *maskImage = [NSImage imageWithSize:baseImage.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {

            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint:NSMakePoint(0, 0)];
            [path lineToPoint:NSMakePoint(0, baseImage.size.height)];
            [path lineToPoint:NSMakePoint(baseImage.size.width, baseImage.size.height)];

            [[NSColor whiteColor] setFill];
            [path fill];
            
            return YES;

        }];
        
        CGImageRef maskImageRef = [maskImage CGImageForProposedRect:&rect context:NSGraphicsContext.currentContext hints:nil];
        
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
        
        CGContextDrawImage(context, rect, maskedImage);
        
        CGImageRelease(imageMask);
        CGImageRelease(maskedImage);

        CGContextSetLineWidth(context, 2.0f);
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, baseImage.size.width, baseImage.size.height);
        CGContextSetStrokeColorWithColor(context, [NSColor colorWithWhite:1 alpha:0.5].CGColor);
        CGContextStrokePath(context);

        
        return YES;
        
    }];
    
    return finalImage;
}

@end
