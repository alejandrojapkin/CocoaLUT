//
//  LUTHelper.m
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import "LUTHelper.h"

double contrastStretch(double value, double currentMin, double currentMax, double finalMin, double finalMax){
    return (value - currentMin)*((finalMax-finalMin)/(currentMax-currentMin)) + finalMin;
}

double clamp(double value, double min, double max){
    return (value > max) ? max : ((value < min) ? min : value);
}

double clamp01(double value) {
    return clamp(value, 0, 1);
}

double clampLowerBound(double value, double lowerBound){
    if(value < lowerBound) return lowerBound;
    else return value;
}

double clampUpperBound(double value, double upperBound){
    if(value > upperBound) return upperBound;
    else return value;
}

double nsremapint01(NSInteger value, NSInteger maxValue) {
    return (double)value / (double)maxValue;
}

double remapint01(int value, int maxValue) {
    return nsremapint01(value, maxValue);
}

double remap(double value, double inputLow, double inputHigh, double outputLow, double outputHigh){
    return outputLow + ((value - inputLow)*(outputHigh - outputLow))/(inputHigh - inputLow);
}

double lerp1d(double beginning, double end, double value01) {
    if (value01 < 0 || value01 > 1){
        @throw [NSException exceptionWithName:@"Invalid Lerp" reason:@"Value out of bounds" userInfo:nil];
    }
    float range = end - beginning;
    return beginning + range * value01;
}

float distancecalc(float x1, float y1, float z1, float x2, float y2, float z2) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float dz = z2 - z1;
    return sqrt((float)(dx * dx + dy * dy + dz * dz));
}

void timer(NSString* name, void (^block)()) {
    NSLog(@"Starting %@", name);
    NSDate *startTime = [NSDate date];
    block();
    NSLog(@"%@ finished in %fs", name, -[startTime timeIntervalSinceNow]);
}

void LUTConcurrentCubeLoop(NSUInteger cubeSize, void (^block)(NSUInteger r, NSUInteger g, NSUInteger b)) {
    dispatch_apply(cubeSize, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t r){
        dispatch_apply(cubeSize, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t g){
            for (int b = 0; b < cubeSize; b++) {
                block(r, g, b);
            }
        });
    });
}

void LUTConcurrentRectLoop(NSUInteger width, NSUInteger height, void (^block)(NSUInteger x, NSUInteger y)) {
    dispatch_apply(width, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t x){
        for (int y = 0; y < height; y++) {
            block(x, y);
        }
    });
}

CGSize CGSizeProportionallyScaled(CGSize currentSize, CGSize targetSize) {
    if ( NSEqualSizes(currentSize, targetSize) == NO ) {
        float widthFactor  = targetSize.width / currentSize.width;
        float heightFactor = targetSize.height / currentSize.height;
        
        float scaleFactor  = 0.0;

        if ( widthFactor < heightFactor )
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        float scaledWidth  = currentSize.width  * scaleFactor;
        float scaledHeight = currentSize.height * scaleFactor;
        
        return CGSizeMake(scaledWidth, scaledHeight);
    }
    return currentSize;
}

#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
void LUTNSImageLog(NSImage *image) {
    for (NSImageRep *rep in image.representations) {
        NSLog(@"Color Space: %@", rep.colorSpaceName);
        NSLog(@"Bits Per Sample: %ld", (long)rep.bitsPerSample);
        if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
            NSLog(@"Bits Per Pixel: %ld", (long)((NSBitmapImageRep *)rep).bitsPerPixel);
        }
    }
}

NSString* FirstRegexMatch(NSString *text, NSString *pattern) {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    return [text substringWithRange:[match rangeAtIndex:1]];
}

NSImage* LUTNSImageFromCIImage(CIImage *ciImage, BOOL useSoftwareRenderer) {
    
    [NSGraphicsContext saveGraphicsState];
    
    int width = [ciImage extent].size.width;
    int rows = [ciImage extent].size.height;
    int rowBytes = (width * 8);
    
    
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                    pixelsWide:width
                                                                    pixelsHigh:rows
                                                                 bitsPerSample:16
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSDeviceRGBColorSpace
                                                                  bitmapFormat:0
                                                                   bytesPerRow:rowBytes
                                                                  bitsPerPixel:0];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate([rep bitmapData],
                                                 width,
                                                 rows,
                                                 16,
                                                 rowBytes,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    NSDictionary *contextOptions = @{
                                     kCIContextWorkingColorSpace: (__bridge id)colorSpace,
                                     kCIContextOutputColorSpace: (__bridge id)colorSpace,
                                     kCIContextUseSoftwareRenderer: @(useSoftwareRenderer)
                                     };
    
    CIContext* ciContext = [CIContext contextWithCGContext:context options:contextOptions];
    
    [ciContext drawImage:ciImage
                  inRect:CGRectMake(0, 0, ciImage.extent.size.width, ciImage.extent.size.height)
                fromRect:ciImage.extent];
    
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
    [nsImage addRepresentation:rep];
	return nsImage;
    
}

#endif


@implementation LUTHelper

@end
