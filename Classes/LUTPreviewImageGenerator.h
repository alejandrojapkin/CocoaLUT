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

- (NSImage *)renderPreviewImageOfSize:(NSSize)size;


@end
