//
//  DLDocument.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LUTDocument : NSDocument {
    IBOutlet NSImageView *lutPreviewView;
}

@property (strong) LUT *lut;


@end
