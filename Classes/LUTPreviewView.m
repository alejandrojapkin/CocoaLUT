//
//  LUTPreviewView.m
//  
//
//  Created by Wil Gieseler on 12/15/13.
//
//

#import "LUTPreviewView.h"
#import <QuartzCore/QuartzCore.h>

@interface LUTPreviewView () {
    CALayer *_maskLayer;
    NSView *_borderView;
    NSImageView *_normalImageView;
    NSImageView *_lutImageView;
}

@end

@implementation LUTPreviewView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)layout {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];

    _maskLayer.frame = CGRectMake(0, 0, self.bounds.size.width * self.maskAmount, self.bounds.size.height);
    _normalImageView.frame = self.bounds;
    _lutImageView.frame = self.bounds;
    
    _borderView.frame = CGRectMake(self.bounds.size.width * self.maskAmount, 0, 1, self.bounds.size.height);
    
    [CATransaction commit];

    [super layout];
}

- (void)setMaskAmount:(float)maskAmount {
    if (maskAmount > 1) {
        maskAmount = 1;
    }
    else if (maskAmount < 0) {
        maskAmount = 0;
    }
    _maskAmount = maskAmount;
    [self setNeedsLayout:YES];
}

- (void)setLut:(LUT *)lut {
    _lut = lut;
    
    if (_lut) {
        CIFilter *filter = _lut.coreImageFilter;
        if (filter) {
            [_lutImageView setContentFilters:@[filter]];
            return;
        }
    }
    
    [_lutImageView setContentFilters:@[]];

}

- (void)setPreviewImage:(NSImage *)previewImage {
    _previewImage = previewImage;
    [_normalImageView setImage:self.previewImage];
    [_lutImageView setImage:self.previewImage];
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

-(void)mouseDown:(NSEvent *)event {
    [self maskToEvent:event];
}

-(void)mouseDragged:(NSEvent *)event {
//    [[NSCursor closedHandCursor] push];
    [self maskToEvent:event];
}

- (void)maskToEvent:(NSEvent *)event {
    NSPoint newDragLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    self.maskAmount = newDragLocation.x / self.bounds.size.width;
}

- (void)initialize {
    
    self.maskAmount = 0.5;
    
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.blackColor.CGColor;
    
    _normalImageView = [[NSImageView alloc] initWithFrame:self.bounds];
    [_normalImageView setImage:self.previewImage];
    _normalImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self addSubview:_normalImageView];
    
    _lutImageView = [[NSImageView alloc] initWithFrame:self.bounds];
    _lutImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self addSubview:_lutImageView];

    _maskLayer = [CALayer layer];
    _maskLayer.backgroundColor = NSColor.whiteColor.CGColor;
    _maskLayer.frame = CGRectMake(0, 0, self.bounds.size.width * self.maskAmount, self.bounds.size.height);
    
    _borderView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
    _borderView.wantsLayer = YES;
    _borderView.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:0.5].CGColor;
    _borderView.frame = CGRectMake(self.bounds.size.width * self.maskAmount, 0, 1, self.bounds.size.height);
    [self addSubview:_borderView];

    _lutImageView.layer.mask = _maskLayer;
    
}

@end
