//
//  LUTPreviewImageGenerator.h
//  Pods
//
//  Created by Wil Gieseler on 12/15/13.
//
//

#import <Foundation/Foundation.h>
#import "LUT.h"

@interface LUTPreviewImageGenerator : NSObject

@property (strong) LUT *lut;

- (NSImage *)renderPreviewImageFromImage:(NSImage *)image resizedToSize:(NSSize)size;
- (void)drawPreviewImageFromImage:(NSImage *)image resizedToSize:(NSSize)size inContext:(NSGraphicsContext *)graphicsContext;

@end
