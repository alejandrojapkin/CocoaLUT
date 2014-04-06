//
//  NSImage+DeepImages.h
//  Pods
//
//  Created by Wil Gieseler on 3/6/14.
//
//

#import <Cocoa/Cocoa.h>

@interface NSImage (DeepImages)

NSImage* deep_ImageWithCIImage(CIImage *ciImage);

+ (NSImage *)deep_imageWithCImage:(CIImage *)ciImage;
- (CIImage *)deep_CIImage;

@end
