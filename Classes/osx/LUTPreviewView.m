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
}
@property (strong) CALayer *normalImageLayer;
@property (strong) CALayer *lutImageLayer;
@property (strong) AVPlayerLayer *lutVideoLayer;
@property (strong) AVPlayerLayer *normalVideoLayer;
@property (strong) CALayer *maskLayer;
@property (strong) NSView  *borderView;
@property (strong) NSTextField *captionField;
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
    self.normalImageLayer.frame = self.bounds;
    self.lutImageLayer.frame = self.bounds;
    self.normalVideoLayer.frame = self.bounds;
    self.lutVideoLayer.frame = self.bounds;

    _borderView.frame = CGRectMake(self.bounds.size.width * self.maskAmount, 0, 1, self.bounds.size.height);
    
    self.captionField.frame = CGRectMake(self.bounds.size.width * self.maskAmount - 61, 10, 100, 20);

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
    dispatch_async(dispatch_get_current_queue(), ^{
        [self updateImageViews];
    });
}

- (void)updateFilters {
    if (self.lut) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CIFilter *filter = self.lut.coreImageFilterWithCurrentColorSpace;
            if (filter) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.lutVideoLayer.filters = @[filter];
                });
            }
            
            
        });
        
    }
}

- (void)updateImageViews {
    NSImage *lutImage = self.previewImage;
    if (self.lut) {
        lutImage = [self.lut processNSImage:self.previewImage renderPath:LUTImageRenderPathCoreImage];
    }
    self.lutImageLayer.contents = lutImage;
    self.normalImageLayer.contents = self.previewImage;
}

- (void)setPreviewImage:(NSImage *)previewImage {
    _previewImage = previewImage;
    _avPlayer = nil;
    dispatch_async(dispatch_get_current_queue(), ^{
        [self updateImageViews];
        [self setupPlaybackLayers];
    });
}

- (void)setAvPlayer:(AVPlayer *)avPlayer {
    _avPlayer = avPlayer;
    if (_avPlayer) {
        _previewImage = nil;
    }
    [self setupPlaybackLayers];
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)isOpaque {
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
    
    self.captionField = [[NSTextField alloc] initWithFrame:CGRectZero];
    self.captionField.textColor = [NSColor whiteColor];
    self.captionField.alignment = NSCenterTextAlignment;
    self.captionField.stringValue = @"Original   LUT";
    [self.captionField setBezeled:NO];
    [self.captionField setDrawsBackground:NO];
    [self.captionField setEditable:NO];
    [self.captionField setSelectable:NO];
    [self.captionField setWantsLayer:YES];
    self.captionField.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
    self.captionField.layer.shadowColor = [NSColor blackColor].CGColor;
    self.captionField.layer.shadowOpacity = 1;
    self.captionField.layer.shadowOffset = CGSizeMake(0, 1);
    self.captionField.layer.shadowRadius = 0;
    self.captionField.layer.masksToBounds = YES;
    self.captionField.layer.opacity = 0.7;
    self.captionField.layer.zPosition = 1;
    [self addSubview:self.captionField];
    
    self.normalImageLayer = [[CALayer alloc] init];
    self.normalImageLayer.contentsGravity = kCAGravityResizeAspect;
    self.lutImageLayer = [[CALayer alloc] init];
    self.lutImageLayer.contentsGravity = kCAGravityResizeAspect;
    self.layerUsesCoreImageFilters = YES;
    
    _maskLayer = [CALayer layer];
    _maskLayer.backgroundColor = NSColor.whiteColor.CGColor;
    _maskLayer.frame = CGRectMake(0, 0, self.bounds.size.width * self.maskAmount, self.bounds.size.height);
    
    _borderView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
    _borderView.wantsLayer = YES;
    _borderView.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:0.5].CGColor;
    _borderView.frame = CGRectMake(self.bounds.size.width * self.maskAmount, 0, 1, self.bounds.size.height);
    _borderView.layer.zPosition = 1;
    [self addSubview:_borderView];

    [self setupPlaybackLayers];
}

- (void)setupPlaybackLayers {
    if (self.avPlayer) {
        // remove plyers before reassigning
        [self.lutVideoLayer removeFromSuperlayer];
        [self.normalVideoLayer removeFromSuperlayer];
        [self.lutImageLayer removeFromSuperlayer];
        [self.normalImageLayer removeFromSuperlayer];
        
        self.lutVideoLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        self.normalVideoLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        
        [self.layer addSublayer:self.lutVideoLayer];
        [self.layer addSublayer:self.normalVideoLayer];
        
        self.normalVideoLayer.mask = self.maskLayer;
    }
    else {
        [self.lutVideoLayer removeFromSuperlayer];
        [self.normalVideoLayer removeFromSuperlayer];

        [self.layer addSublayer:self.lutImageLayer];
        [self.layer addSublayer:self.normalImageLayer];
        
        self.normalImageLayer.mask = self.maskLayer;
    }
    [self updateFilters];
}

@end
