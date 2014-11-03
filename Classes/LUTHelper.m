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
    if(value < inputLow || value > inputHigh){
        @throw [NSException exceptionWithName:@"RemapValueOutOfBounds"
                                       reason:[NSString stringWithFormat:@"Tried to remap out-of-bounds value (%f) with input constraints low:%f high:%f", value, inputLow, inputHigh]
                                     userInfo:nil];
    }
    if(inputLow > inputHigh){
        @throw [NSException exceptionWithName:@"RemapInputsError"
                                       reason:[NSString stringWithFormat:@"Inputs low:%f high:%f. low must be less than or equal to high", inputLow, inputHigh]
                                     userInfo:nil];
    }
    if(outputLow > outputHigh){
        @throw [NSException exceptionWithName:@"RemapOutputsError"
                                       reason:[NSString stringWithFormat:@"Outputs low:%f high:%f. low must be less than or equal to high", outputLow, outputHigh]
                                     userInfo:nil];
    }
    return remapNoError(value, inputLow, inputHigh, outputLow, outputHigh);
}

double remapNoError(double value, double inputLow, double inputHigh, double outputLow, double outputHigh){
    return outputLow + ((value - inputLow)*(outputHigh - outputLow))/(inputHigh - inputLow);
}

BOOL outOfBounds(double value, double min, double max, BOOL inclusive){
    if(inclusive){
        return value < min || value > max;
    }
    else{
        return value <= min || value >= max;
    }
}


double lerp1d(double beginning, double end, double value01) {
    if (value01 < 0 || value01 > 1){
        @throw [NSException exceptionWithName:@"Invalid Lerp" reason:@"Value out of bounds" userInfo:nil];
    }
    float range = end - beginning;
    return beginning + range * value01;
}

double smootherstep(double beginning, double end, double percentage)
{
    if(percentage < 0 || percentage > 1){
        @throw [NSException exceptionWithName:@"Invalid Smoothstep" reason:@"Percentage out of bounds [0-1]" userInfo:nil];
    }
    percentage = remap(percentage, 0, 1, beginning, end);
    return percentage*percentage*percentage*(percentage*(percentage*6.0 - 15.0) + 10.0);
}

double smoothstep(double beginning, double end, double percentage){
    if(percentage < 0 || percentage > 1){
        @throw [NSException exceptionWithName:@"Invalid Smoothstep" reason:@"Percentage out of bounds [0-1]" userInfo:nil];
    }
    percentage = remap(percentage, 0, 1, beginning, end);
    // Evaluate polynomial
    return percentage*percentage*(3 - 2*percentage);
}

float distancecalc(float x1, float y1, float z1, float x2, float y2, float z2) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float dz = z2 - z1;
    return sqrt((float)(dx * dx + dy * dy + dz * dz));
}

NSArray* indicesDoubleArray(double startValue, double endValue, int numIndices){
    NSMutableArray *indices = [NSMutableArray array];
    double ratio = remap(1, 0, numIndices - 1, startValue, endValue);
    for (int i = 0; i < numIndices; i++) {
        [indices addObject:@(clampUpperBound((double)i * ratio, endValue))];
    }
    return indices;
}

NSArray* indicesIntegerArray(int startValue, int endValue, int numIndices){
    NSMutableArray *indices = [NSMutableArray array];
    double ratio = remap(1, 0, numIndices - 1, startValue, endValue);
    for (int i = 0; i < numIndices; i++) {
        [indices addObject:@((long)round((double)i * ratio))];
    }
    return indices;
}

NSArray* indicesIntegerArrayLegacy(int startValue, int endValue, int numIndices){
    NSMutableArray *indicesArray = [NSMutableArray arrayWithArray:indicesIntegerArray(startValue, endValue+1, numIndices)];

    [indicesArray replaceObjectAtIndex:indicesArray.count-1 withObject:@(endValue)];

    return indicesArray;
}

void timer(NSString* name, void (^block)()) {
    NSLog(@"Starting %@", name);
    NSDate *startTime = [NSDate date];
    block();
    NSLog(@"%@ finished in %fs", name, -[startTime timeIntervalSinceNow]);
}

BOOL isLUT3D(LUT* lut){
    return [lut isKindOfClass:[LUT3D class]];
}

BOOL isLUT1D(LUT* lut){
    return [lut isKindOfClass:[LUT1D class]];
}

LUT3D* LUTAsLUT3D(LUT* lut, NSUInteger size){
    if (isLUT1D(lut)){
        return [(LUT1D *)lut LUT3DOfSize:size];
    }
    else{
        return [(LUT3D *)lut LUTByResizingToSize:size];
    }

}

LUT1D* LUTAsLUT1D(LUT* lut, NSUInteger size){
    if (isLUT3D(lut)){
        return [[(LUT3D *)lut LUT1D] LUTByResizingToSize:size];
    }
    else{
        return [(LUT1D *)lut LUTByResizingToSize:size];
    }
}

double roundValueToNearest(double value, double nearestValue) {
    NSInteger multiplier = floor(value / nearestValue);
    return (double)multiplier * nearestValue;
}

void LUTConcurrentRectLoop(NSUInteger width, NSUInteger height, void (^block)(NSUInteger x, NSUInteger y)) {
    dispatch_apply(width, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t x){
        for (int y = 0; y < height; y++) {
            block(x, y);
        }
    });
}

CGSize CGSizeProportionallyScaled(CGSize currentSize, CGSize targetSize) {
    if ( CGSizeEqualToSize(currentSize, targetSize) == NO ) {
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

NSDictionary *NSDictionaryFromM13OrderedDictionary(M13OrderedDictionary *stupidDict) {
    return [NSDictionary dictionaryWithObjects:stupidDict.allObjects forKeys:stupidDict.allKeys];
}

M13OrderedDictionary* M13OrderedDictionaryFromOrderedArrayWithDictionaries(NSArray *array){
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];

    for (NSDictionary *item in array){
        if([[item allKeys] count] == 1 && [[item allValues] count] == 1){
            [keys addObject:[item allKeys][0]];
            [values addObject:[item allValues][0]];
        }
        else{
            @throw [NSException exceptionWithName:@"M13OrderedDictionary generator failed." reason:@"A dictionary in the array was not of count 1" userInfo:nil];
        }
    }

    return [[M13OrderedDictionary alloc] initWithObjects:values pairedWithKeys:keys];
}

NSNumberFormatter* sharedNumberFormatter(){
    static NSNumberFormatter *numberFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        numberFormatter = [NSNumberFormatter new];
    });
    return numberFormatter;
}

NSCharacterSet* sharedInvertedNumericCharacterSet(){
    static NSCharacterSet *invertedNumericCharacterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        invertedNumericCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"e-.0123456789 "] invertedSet];
    });
    return invertedNumericCharacterSet;
}

BOOL stringIsValidNumber(NSString *string){
    return [string rangeOfCharacterFromSet:sharedInvertedNumericCharacterSet()].location == NSNotFound;
}

NSInteger findFirstLUTLineInLines(NSArray *lines, NSString *seperator, int numValues, int startLine){

    for (int i = startLine; i < lines.count; i++){
        NSArray *splitLine = [lines[i] componentsSeparatedByString:seperator];
        splitLine = arrayWithEmptyElementsRemoved(splitLine);
        if(splitLine.count == numValues){
            BOOL isLine = YES;
            for (int j = 0; j < numValues; j++){
                if(!stringIsValidNumber(splitLine[j])){
                    isLine = NO;
                }
            }
            if(isLine){
                return i;
            }
        }
    }
    return NSNotFound;
}

NSUInteger maxIntegerFromBitdepth(NSUInteger bitdepth){
    return pow(2, bitdepth) - 1;
}

NSInteger findFirstLUTLineInLinesWithWhitespaceSeparators(NSArray *lines, int numValues, int startLine){

    for (int i = startLine; i < lines.count; i++){
        NSArray *splitLine = [lines[i] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        splitLine = arrayWithEmptyElementsRemoved(splitLine);
        if(splitLine.count == numValues){
            BOOL isLine = YES;
            for (int j = 0; j < numValues; j++){
                if(!stringIsValidNumber(splitLine[j])){
                    isLine = NO;
                }
            }
            if(isLine){
                return i;
            }
        }
    }
    return NSNotFound;
}

NSArray* arrayWithEmptyElementsRemoved(NSArray *array){
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
}

NSArray* arrayWithComponentsSeperatedByWhitespaceWithEmptyElementsRemoved(NSString *string){
    return arrayWithEmptyElementsRemoved([string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);
}

NSArray* arrayWithComponentsSeperatedByNewlineAndWhitespaceWithEmptyElementsRemoved(NSString *string){
    return arrayWithEmptyElementsRemoved([string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
}

NSArray* arrayWithComponentsSeperatedByNewlineWithEmptyElementsRemoved(NSString *string){
    return arrayWithEmptyElementsRemoved([string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
}

NSString* substringBetweenTwoStrings(NSString *originString, NSString *firstString, NSString *secondString){
    NSRange r1 = [originString rangeOfString:firstString];
    NSRange r2 = [originString rangeOfString:secondString];
    NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
    return [originString substringWithRange:rSub];
}

SystemColor* systemColorWithHexString(NSString* hexString){
    SystemColor* result = nil;
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;

    if (hexString != nil)
    {
        hexString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSScanner* scanner = [NSScanner scannerWithString:hexString];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // masks off high bits

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    result = [SystemColor
              colorWithRed:(CGFloat)redByte / 0xff
              green:(CGFloat)greenByte / 0xff
              blue:(CGFloat)blueByte / 0xff
              alpha:1.0];
#elif TARGET_OS_MAC
    result = [SystemColor
              colorWithDeviceRed:(CGFloat)redByte / 0xff
              green:(CGFloat)greenByte / 0xff
              blue:(CGFloat)blueByte / 0xff
              alpha:1.0];
#endif
    return result;
}


#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
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


    CGImageRef cgImage = [ciContext createCGImage:ciImage fromRect:ciImage.extent];
    NSImage *nsImage = [[NSImage alloc] initWithCGImage:cgImage size:ciImage.extent.size];
    CGImageRelease(cgImage);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);

    [NSGraphicsContext restoreGraphicsState];

	return nsImage;
}

#endif


@implementation LUTHelper

@end
