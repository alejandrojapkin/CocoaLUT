//
//  LUT1DGraphView.m
//  Pods
//
//  Created by Greg Cotten on 5/1/14.
//
//

#import "LUT1DGraphView.h"

@interface LUT1DGraphView ()

@property (strong, nonatomic) NSArray *cubicSplinesRGBArray;
@property (strong, nonatomic) NSArray *colorCurve;

@property (assign, nonatomic) double minimumOutputValue;
@property (assign, nonatomic) double maximumOutputValue;

@property (assign, nonatomic) double zoomLevel;
@property (assign, nonatomic) double centerX;
@property (assign, nonatomic) double centerY;

@property (assign) NSPoint currentMouseLocation;

@end

@implementation LUT1DGraphView

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

-(void)initialize{
    self.zoomLevel = 1.0;
    self.centerX = .5;
    self.centerY = .5;
    self.lut = [LUT1D LUTIdentityOfSize:33 inputLowerBound:0 inputUpperBound:1];
    self.interpolation = LUT1DGraphViewInterpolationLinear;
    [self lutDidChange];
}

-(void)setLut:(LUT *)lut{
    _lut = lut;
    [self lutDidChange];
}

-(void)setInterpolation:(LUT1DGraphViewInterpolation)interpolation{
    if(interpolation != _interpolation){
        _interpolation = interpolation;
        [self setNeedsDisplay:YES];
    }
    //no need to redraw if the interpolation didn't actually change!
}

-(void)lutDidChange{
    if(self.lut){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            LUT1D *lut1D = LUTAsLUT1D(self.lut, [self.lut size]);
            self.cubicSplinesRGBArray = [lut1D SAMCubicSplineRGBArrayWithNormalized01XAxis];
            self.colorCurve = [lut1D colorCurve];
            
            self.minimumOutputValue = [lut1D minimumOutputValue];
            self.maximumOutputValue = [lut1D maximumOutputValue];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNeedsDisplay:YES];
            });
        });
    }
}

- (void)mouseMoved:(NSEvent *)theEvent{
    NSLog(@"moved");
    self.currentMouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    [[NSColor whiteColor] setFill];
    NSRectFill(self.bounds);
    
    NSRect drawingRect = self.bounds;
    
    if(!self.colorCurve){
        return;
    }
    
    CGContextRef context = [[NSGraphicsContext
                               currentContext] graphicsPort];

    //RED
    TICK;
    [self drawGridInContext:context inRect:drawingRect numXDivs:5 transparency:.2];

    [self drawCurveWithCurrentInterpolationInContext:context inRect:drawingRect];
    TOCK;
}

- (void)drawGridInContext:(CGContextRef)context
                   inRect:(NSRect)rect
                 numXDivs:(int)numDivs
             transparency:(double)transparency{
    CGFloat xOrigin = rect.origin.x;
    CGFloat yOrigin = rect.origin.y;
    CGFloat pixelWidth = rect.size.width;
    CGFloat pixelHeight = rect.size.height;
    
    NSArray *xIndices = indicesIntegerArray(xOrigin, xOrigin + pixelWidth, numDivs);
    
    CGContextSetRGBStrokeColor(context, 1.0-transparency, 1.0-transparency, 1.0-transparency, 1);
    CGContextSetLineWidth(context, 2.0);
    
    for (NSNumber *index in xIndices){
        NSUInteger indexAsInt = [index integerValue];
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, indexAsInt, yOrigin);
        CGContextAddLineToPoint(context, indexAsInt, yOrigin + pixelHeight);
        CGContextStrokePath(context);
    }
    
    NSArray *yIndices = indicesIntegerArray(yOrigin, yOrigin + pixelHeight, numDivs);
    
    for (NSNumber *index in yIndices){
        NSUInteger indexAsInt = [index integerValue];
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, xOrigin, indexAsInt);
        CGContextAddLineToPoint(context, xOrigin + pixelWidth, indexAsInt);
        CGContextStrokePath(context);
    }
    
}

- (void)drawCurveWithCurrentInterpolationInContext:(CGContextRef)context inRect:(NSRect)rect{
    CGContextSetLineWidth(context, 2.0);
    
    CGFloat xOrigin = rect.origin.x;
    CGFloat yOrigin = rect.origin.y;
    CGFloat pixelWidth = rect.size.width;
    CGFloat pixelHeight = rect.size.height;
    
    NSMutableArray *colorArrayOfPixelWidth = [NSMutableArray array];
    
    for (CGFloat x = 0.0f; x < pixelWidth; x++) {
        // Get the Y value of our point
        double xNormalized = remap(x, 0, pixelWidth-1, 0, 1);
        [colorArrayOfPixelWidth addObject:[self colorNormalizedFromXNormalizedUsingCurrentInterpolation:xNormalized]];
        
    }
    
    //RED
    CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
    CGContextBeginPath(context);
    
    for (int x = 0; x < colorArrayOfPixelWidth.count; x++) {
        // Get the Y value of our point
        CGFloat xMapped = remap(x, 0, colorArrayOfPixelWidth.count - 1, xOrigin, xOrigin + colorArrayOfPixelWidth.count - 1);
        CGFloat yMapped = remap(((LUTColor *)colorArrayOfPixelWidth[x]).red, 0, 1, yOrigin, yOrigin + pixelHeight - 1);
        
        if (x == 0.0f) {
            CGContextMoveToPoint(context, xMapped, yMapped);
        } else {
            CGContextAddLineToPoint(context, xMapped, yMapped);
        }
    }
    
    CGContextStrokePath(context);
    
    //GREEN
    CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
    CGContextBeginPath(context);
    
    for (int x = 0; x < colorArrayOfPixelWidth.count; x++) {
        // Get the Y value of our point
        CGFloat xMapped = remap(x, 0, colorArrayOfPixelWidth.count - 1, xOrigin, xOrigin + colorArrayOfPixelWidth.count - 1);
        CGFloat yMapped = remap(((LUTColor *)colorArrayOfPixelWidth[x]).green, 0, 1, yOrigin, yOrigin + pixelHeight - 1);
        
        if (x == 0.0f) {
            CGContextMoveToPoint(context, xMapped, yMapped);
        } else {
            CGContextAddLineToPoint(context, xMapped, yMapped);
        }
    }
    
    CGContextStrokePath(context);
    
    //BLUE
    CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
    CGContextBeginPath(context);
    
    for (int x = 0; x < colorArrayOfPixelWidth.count; x++) {
        // Get the Y value of our point
        CGFloat xMapped = remap(x, 0, colorArrayOfPixelWidth.count - 1, xOrigin, xOrigin + colorArrayOfPixelWidth.count - 1);
        CGFloat yMapped = remap(((LUTColor *)colorArrayOfPixelWidth[x]).blue, 0, 1, yOrigin, yOrigin + pixelHeight - 1);
        
        if (x == 0.0f) {
            CGContextMoveToPoint(context, xMapped, yMapped);
        } else {
            CGContextAddLineToPoint(context, xMapped, yMapped);
        }
    }
    
    CGContextStrokePath(context);
    
}

- (LUTColor *)colorNormalizedFromXNormalizedUsingCurrentInterpolation:(double)xNormalized{
    if (xNormalized < 0 || xNormalized > 1){
        @throw [NSException exceptionWithName:@"LUT1DGraphViewError" reason:@"xNormalized is not between 0 and 1" userInfo:nil];
    }
    if(self.interpolation == LUT1DGraphViewInterpolationLinear){
        double remappedIndex = remap(xNormalized, 0, 1, 0, self.colorCurve.count - 1);
        return [self.lut colorAtInterpolatedR:remappedIndex g:remappedIndex b:remappedIndex];
    }
    else if(self.interpolation == LUT1DGraphViewInterpolationCubic){
        return [LUTColor colorWithRed:[self.cubicSplinesRGBArray[0] interpolate:xNormalized] green:[self.cubicSplinesRGBArray[1] interpolate:xNormalized] blue:[self.cubicSplinesRGBArray[2] interpolate:xNormalized]];
    }
    return nil;
}


+ (M13OrderedDictionary *)interpolationMethods{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Linear": @(LUT1DGraphViewInterpolationLinear)},
                                                                  @{@"Cubic": @(LUT1DGraphViewInterpolationCubic)}]);
}


@end
