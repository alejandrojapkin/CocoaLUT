//
//  LUTPreviewView.h
//
//
//  Created by Wil Gieseler on 12/15/13.
//
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "LUT.h"

@interface LUTPreviewView : NSView

/**
 *  The LUT to preview.
 */
@property (strong, nonatomic) LUT *lut;

/**
 *  Percentage of the original image displayed. 0 to 1. 1 
 *  being the original image is completely displayed, 0 being the processed image is completely displayed.
 */
@property (assign, nonatomic) float maskAmount;

/**
 *  The current preview image. Setting this replaces the current image or video preview.
 */
@property (strong, nonatomic) NSImage *previewImage;

/**
 *  The current preview video URL. Setting this replaces the current image or video preview.
 */
@property (strong, nonatomic) NSURL *videoURL;

/**
 *  The current AVPlayer responsible for playing the video. Available even if there is no video playing.
 */
@property (readonly) AVPlayer *videoPlayer;

/**
 *  Is the view currently previewing a video.
 */
@property (readonly) BOOL isVideo;

@end
