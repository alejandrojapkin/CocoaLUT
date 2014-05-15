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

    //RED
    
    if(self.interpolation == LUT1DGraphViewInterpolationLinear){
        CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
        [self drawArray:_lerpRGBArray[0] inContext:context inRect:drawingRect];
        CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
        [self drawArray:_lerpRGBArray[1] inContext:context inRect:drawingRect];
        CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
        [self drawArray:_lerpRGBArray[2] inContext:context inRect:drawingRect];
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

- (void)drawArray:(NSArray *)array inContext:(CGContextRef)context inRect:(NSRect)rect {
    CGFloat xOrigin = rect.origin.x;
    CGFloat yOrigin = rect.origin.y;
    CGFloat pixelWidth = rect.size.width;
    CGFloat pixelHeight = rect.size.height;
    
    //NSLog(@"Drawing in %f %f", pixelWidth, pixelHeight);
    
    CGContextSetLineWidth(context, 2.0);
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
        CGFloat yMapped = remap(yUnscaled, self.minimumOutputValue, self.maximumOutputValue, yOrigin, yOrigin + pixelHeight - 1);
        //NSLog(@"%f %f -> %f %f", x/pixelWidth, interpolatedY, x, y);
        // Add the point to the context's path
        
        if (x == 0.0f) {
            CGContextMoveToPoint(context, xMapped, yMapped);
        } else {
            CGContextAddLineToPoint(context, xMapped, yMapped);
        }
        
    }

    CGContextStrokePath(context);
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
        CGFloat yMapped = remap(interpolatedY, 0, 1, yOrigin, yOrigin + pixelHeight-1);
        
        //NSLog(@"%f %f -> %f %f", x/pixelWidth, interpolatedY, x, y);
        // Add the point to the context's path
        
        if (x == 0.0f) {
            CGContextMoveToPoint(context, xMapped, yMapped);
        } else {
            CGContextAddLineToPoint(context, xMapped, yMapped);
        }
        
    }
    CGContextStrokePath(context);
    
}

+ (M13OrderedDictionary *)interpolationMethods{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Linear": @(LUT1DGraphViewInterpolationLinear)},
                                                                  @{@"Cubic": @(LUT1DGraphViewInterpolationCubic)}]);
}


@end
