//
//  LUTPreviewImageGenerator.m
//  Pods
//
//  Created by Wil Gieseler on 12/15/13.
//
//

#import "LUTPreviewImageGenerator.h"

@implementation LUTPreviewImageGenerator

- (NSImage *)renderPreviewImageOfSize:(NSSize)size {
    
    NSImage *baseImage = [[NSImage imageNamed:@"testimage.jpg"] copy];
    NSImage *processedImage = [self.lut processNSImage:[baseImage copy]];
    
    NSRect rect = NSMakeRect(0, 0, processedImage.size.width, processedImage.size.height);
    CGImageRef processedImageRef = [processedImage CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil];
    
    NSImage *maskImage = [NSImage imageWithSize:baseImage.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(0, 0)];
        [path lineToPoint:NSMakePoint(0, baseImage.size.height)];
        [path lineToPoint:NSMakePoint(baseImage.size.width, baseImage.size.height)];

        [[NSColor whiteColor] setFill];
        [path fill];
        
        return YES;

    }];
    
    CGImageRef maskImageRef = [maskImage CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil];

    [baseImage lockFocus];
    
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    
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

    
    [baseImage unlockFocus];
    
    return baseImage;
}

@end
