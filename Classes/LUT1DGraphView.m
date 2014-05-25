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
@property (strong, nonatomic) NSArray *lerpRGBArray;

@property (assign, nonatomic) double minimumOutputValue;
@property (assign, nonatomic) double maximumOutputValue;

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
            self.lerpRGBArray = [lut1D rgbCurveArray];
            
            self.minimumOutputValue = [lut1D minimumOutputValue];
            self.maximumOutputValue = [lut1D maximumOutputValue];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNeedsDisplay:YES];
            });
        });
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    
    [[NSColor whiteColor] setFill];
    NSRectFill(self.bounds);
    
    NSRect drawingRect = self.bounds;
    
    if(!self.lerpRGBArray){
        return;
    }
    
    CGContextRef context = [[NSGraphicsContext
                               currentContext] graphicsPort];

    [self drawGridInContext:context inRect:drawingRect numXDivs:5 transparency:.3];
    
    if(self.interpolation == LUT1DGraphViewInterpolationLinear){
        CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
        [self drawArray:_lerpRGBArray[0] inContext:context inRect:drawingRect thickness:2.0];
        CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
        [self drawArray:_lerpRGBArray[1] inContext:context inRect:drawingRect thickness:2.0];
        CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
        [self drawArray:_lerpRGBArray[2] inContext:context inRect:drawingRect thickness:2.0];
    }
    else if(self.interpolation == LUT1DGraphViewInterpolationCubic){
        CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
        [self drawSpline:self.cubicSplinesRGBArray[0] inContext:context inRect:drawingRect];
        CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
        [self drawSpline:self.cubicSplinesRGBArray[1] inContext:context inRect:drawingRect];
        CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
        [self drawSpline:self.cubicSplinesRGBArray[2] inContext:context inRect:drawingRect];
    }
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

- (void)drawArray:(NSArray *)array inContext:(CGContextRef)context inRect:(NSRect)rect thickness:(double)thickness {
    CGFloat xOrigin = rect.origin.x;
    CGFloat yOrigin = rect.origin.y;
    CGFloat pixelWidth = rect.size.width;
    CGFloat pixelHeight = rect.size.height;
    
    //NSLog(@"Drawing in %f %f", pixelWidth, pixelHeight);
    
    CGContextSetLineWidth(context, thickness);
    CGContextBeginPath(context);
    
    for (CGFloat x = 0.0f; x < pixelWidth; x++) {
        // Get the Y value of our point
        double xAsInterpolatedIndex = remap(x, 0, pixelWidth-1, 0, array.count-1);
        CGFloat yUnscaled;
        if(x == pixelWidth-1){
            yUnscaled = [array[array.count-1] doubleValue];
        }
        else{
            yUnscaled = lerp1d([array[(int)floor(xAsInterpolatedIndex)] doubleValue], [array[(int)ceil(xAsInterpolatedIndex)] doubleValue], xAsInterpolatedIndex - floor(xAsInterpolatedIndex));
        }
        CGFloat xMapped = remap(x, 0, pixelWidth-1, xOrigin, xOrigin + pixelWidth-1);
        CGFloat yMapped = remapNoError(yUnscaled, clampUpperBound(self.minimumOutputValue, 0), clampLowerBound(self.maximumOutputValue, 1), yOrigin, yOrigin + pixelHeight - 1);
        //NSLog(@"%f %f -> %f %f", x/pixelWidth, interpolatedY, x, y);
        // Add the point to the context's path
        
        if (x == xOrigin) {
            CGContextMoveToPoint(context, xMapped, yMapped);
        } else {
            CGContextAddLineToPoint(context, xMapped, yMapped);
        }
        
    }


    CGContextStrokePath(context);
    
    if([self.lut size] < pixelWidth/2.0){
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        for (int x = 0; x < [self.lut size]; x++){
            CGFloat xMapped = remap(x, 0, [self.lut size]-1, xOrigin, xOrigin + pixelWidth-1);
            CGFloat yMapped = remapNoError([array[x] doubleValue], clampUpperBound(self.minimumOutputValue, 0), clampLowerBound(self.maximumOutputValue, 1), yOrigin, yOrigin + pixelHeight - 1);
            CGContextFillEllipseInRect(context, CGRectMake(xMapped-(3.0/2.0)*thickness, yMapped-(3.0/2.0)*thickness, 3.0*thickness, 3.0*thickness));
        }
    }
    
}


- (void)drawSpline:(SAMCubicSpline *)spline inContext:(CGContextRef)context inRect:(NSRect)rect{
    CGFloat xOrigin = rect.origin.x;
    CGFloat yOrigin = rect.origin.y;
    CGFloat pixelWidth = rect.size.width;
    CGFloat pixelHeight = rect.size.height;
    
    //NSLog(@"Drawing in %f %f", pixelWidth, pixelHeight);
    
    CGContextSetLineWidth(context, 2.0);
    CGContextBeginPath(context);
    for (CGFloat x = 0.0f; x < pixelWidth; x++) {
        // Get the Y value of our point
        CGFloat interpolatedY = [spline interpolate:x / (pixelWidth)];
        
        CGFloat xMapped = remap(x, 0, pixelWidth-1, xOrigin, xOrigin + pixelWidth-1);
        CGFloat yMapped = remapNoError(interpolatedY, clampUpperBound(self.minimumOutputValue, 0), clampLowerBound(self.maximumOutputValue, 1), yOrigin, yOrigin + pixelHeight-1);
        
        //NSLog(@"%f %f -> %f %f", x/pixelWidth, interpolatedY, x, y);
        // Add the point to the context's path
        
        if (x == xOrigin) {
            CGContextMoveToPoint(context, xMapped, yMapped);
        } else {
            CGContextAddLineToPoint(context, xMapped, yMapped);
        }
        
    }
    CGContextStrokePath(context);
    
    if([self.lut size] < pixelWidth/2.0){
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
        for (int x = 0; x < [self.lut size]; x++){
            CGFloat xMapped = remap(x, 0, [self.lut size]-1, xOrigin, xOrigin + pixelWidth-1);
            CGFloat yMapped = remapNoError([spline interpolate:(double)x/((double)[self.lut size]-1.0)], clampUpperBound(self.minimumOutputValue, 0), clampLowerBound(self.maximumOutputValue, 1), yOrigin, yOrigin + pixelHeight - 1);
            CGContextFillEllipseInRect(context, CGRectMake(xMapped-3, yMapped-3, 6, 6));
        }
    }
    
}

+ (M13OrderedDictionary *)interpolationMethods{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Linear": @(LUT1DGraphViewInterpolationLinear)},
                                                                  @{@"Cubic": @(LUT1DGraphViewInterpolationCubic)}]);
}


@end
