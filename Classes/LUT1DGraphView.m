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
    [self lutDidChange];
}

-(void)setLut:(LUT *)lut{
    _lut = lut;
    [self lutDidChange];
}

-(void)lutDidChange{
    if(self.lut){
        LUT1D *lut1D = LUTAsLUT1D(self.lut, [self.lut size]);
        //self.cubicSplinesRGBArray = [lut1D SAMCubicSplineRGBArrayWithNormalized01XAxis];
        self.lerpRGBArray = [lut1D rgbCurveArray];
        
        self.minimumOutputValue = [lut1D minimumOutputValue];
        self.maximumOutputValue = [lut1D maximumOutputValue];
        [self display];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor whiteColor] setFill];
    
    NSRectFill(dirtyRect);
    
    if(!self.lerpRGBArray){
        return;
    }
    
    CGContextRef context = [[NSGraphicsContext
                               currentContext] graphicsPort];
    
    

    //RED
    CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
    [self drawArray:_lerpRGBArray[0] inContext:context inRect:dirtyRect];
    //[self drawSpline:self.cubicSplinesRGBArray[0] inContext:context inRect:dirtyRect];
    //GREEN
    CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
    [self drawArray:_lerpRGBArray[1] inContext:context inRect:dirtyRect];
    //[self drawSpline:self.cubicSplinesRGBArray[1] inContext:context inRect:dirtyRect];
    //BLUE
    CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
    [self drawArray:_lerpRGBArray[2] inContext:context inRect:dirtyRect];
    //[self drawSpline:self.cubicSplinesRGBArray[2] inContext:context inRect:dirtyRect];
    
}

- (void)drawArray:(NSArray *)array inContext:(CGContextRef)context inRect:(NSRect)dirtyRect{
    CGFloat pixelWidth = dirtyRect.size.width;
    CGFloat pixelHeight = dirtyRect.size.height;
    
    //NSLog(@"Drawing in %f %f", pixelWidth, pixelHeight);
    
    CGContextSetLineWidth(context, 1.0);
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
        
        CGFloat y = yUnscaled * pixelHeight;
        
        //NSLog(@"%f %f -> %f %f", x/pixelWidth, interpolatedY, x, y);
        // Add the point to the context's path
        
        if (x == 0.0f) {
            CGContextMoveToPoint(context, x, y);
        } else {
            CGContextAddLineToPoint(context, x, y);
        }
        
    }
    
//    for (int xIndex = 0; xIndex < array.count; xIndex++){
//        CGFloat yUnscaled = [array[xIndex] doubleValue];
//        
//        CGFloat x = remap(xIndex, 0, array.count-1, 0, pixelWidth-1);
//        CGFloat y = yUnscaled*pixelHeight;
//        
//        
//        //NSLog(@"%d %f -> %f %f", xIndex, yUnscaled, x, y);
//        if (x == 0.0f) {
//            CGContextMoveToPoint(context, x, y);
//        } else {
//            CGContextAddLineToPoint(context, x, y);
//        }
//    }

    CGContextStrokePath(context);
}

- (void)drawSpline:(SAMCubicSpline *)spline inContext:(CGContextRef)context inRect:(NSRect)dirtyRect{
    CGFloat pixelWidth = dirtyRect.size.width;
    CGFloat pixelHeight = dirtyRect.size.height;
    
    //NSLog(@"Drawing in %f %f", pixelWidth, pixelHeight);
    
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);
    for (CGFloat x = 0.0f; x < pixelWidth; x++) {
        // Get the Y value of our point
        CGFloat interpolatedY = [spline interpolate:x / (pixelWidth)];
        CGFloat y = interpolatedY * pixelHeight;
        
        //NSLog(@"%f %f -> %f %f", x/pixelWidth, interpolatedY, x, y);
        // Add the point to the context's path
        
        if (x == 0.0f) {
            CGContextMoveToPoint(context, x, y);
        } else {
            CGContextAddLineToPoint(context, x, y);
        }
        
    }
    CGContextStrokePath(context);
    
}


@end
