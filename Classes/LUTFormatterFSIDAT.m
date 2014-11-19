//
//  LUTFormatterFSIDAT.m
//  Pods
//
//  Created by Greg Cotten on 8/11/14.
//
//

#import "LUTFormatterFSIDAT.h"

struct LUTFormatterFSIDAT_FileHeader{
    unsigned int magic; // 4Bytes, must be 0x42340299
    unsigned int ver; // 4Bytes, 0x01000002 or 0x02000000
    char model[16]; // 16Bytes, monitor model. No match required for DIT LUT.
    char version[16]; // 16Bytes, data version, eg. “1.0.11”
    unsigned int data_checksum; // 4Bytes, data sum
    unsigned int length; // 4Bytes, data length = 1048576 (v1) or 19652 (v2)
    char description[16]; //16Bytes, 3dlut description info, e.g. “LightSpace(c)”
    unsigned int reserved2; // 4Bytes, reserved
    char name[16]; // 16Bytes, information or name of lut
    char reserved[43]; // 43 Bytes, reserved
    unsigned char header_checksum; // file header sum
};

@implementation LUTFormatterFSIDAT


+ (void)load{
    [super load];
}

+ (LUT *)LUTFromData:(NSData *)data{
    struct LUTFormatterFSIDAT_FileHeader fileHeader;
    [data getBytes:&fileHeader length:128];

    LUT3D *lut;

    if (fileHeader.ver < 0x02000000) {
        unsigned int lutBytes[64*64*64];

        [data getBytes:lutBytes range:NSMakeRange(128, sizeof(lutBytes))];

        lut = [LUT3D LUTOfSize:64 inputLowerBound:0 inputUpperBound:1];

        for (int currentCubeIndex = 0; currentCubeIndex < 64*64*64; currentCubeIndex++) {
            // Valid cube line
            unsigned int rgbPacked = lutBytes[currentCubeIndex];

            LUTColorValue redValue = (double)(rgbPacked & 1023) / 1008.0;
            LUTColorValue greenValue = (double)((rgbPacked >> 10) & 1023) / 1008.0;
            LUTColorValue blueValue = (double)((rgbPacked >> 20) & 1023) / 1008.0;

            LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];

            NSUInteger redIndex = currentCubeIndex % 64;
            NSUInteger greenIndex = ( (currentCubeIndex % (64 * 64)) / (64) );
            NSUInteger blueIndex = currentCubeIndex / (64 * 64);

            [lut setColor:color r:redIndex g:greenIndex b:blueIndex];
        }

        lut.passthroughFileOptions = @{[self formatterID]: @{@"fileTypeVariant": @"v1",
                                                             @"lutSize": @(64)}};
    }
    else if (fileHeader.ver == 0x02000000) {
        unsigned int lutBytes[17*17*17];

        [data getBytes:lutBytes range:NSMakeRange(128, sizeof(lutBytes))];

        lut = [LUT3D LUTOfSize:17 inputLowerBound:0 inputUpperBound:1];

        for (int currentCubeIndex = 0; currentCubeIndex < 17*17*17; currentCubeIndex++) {
            // Valid cube line
            unsigned int rgbPacked = CFSwapInt32(lutBytes[currentCubeIndex]);

            LUTColorValue redValue = (double)(rgbPacked & 1023) / 1023.0;
            LUTColorValue greenValue = (double)((rgbPacked >> 10) & 1023) / 1023.0;
            LUTColorValue blueValue = (double)((rgbPacked >> 20) & 1023) / 1023.0;

            LUTColor *color = [LUTColor colorWithRed:redValue green:greenValue blue:blueValue];

            NSUInteger redIndex = currentCubeIndex % 17;
            NSUInteger greenIndex = ( (currentCubeIndex % (17 * 17)) / (17) );
            NSUInteger blueIndex = currentCubeIndex / (17 * 17);

            [lut setColor:color r:redIndex g:greenIndex b:blueIndex];
        }

        lut.passthroughFileOptions = @{[self formatterID]: @{@"fileTypeVariant": @"v2",
                                                             @"lutSize": @(17)}};

    }
    else{
        @throw [NSException exceptionWithName:@"FSIDATLUTReadError" reason:@"Incompatible Version" userInfo:nil];
    }
    
    NSString *nameString = [NSString stringWithCString:fileHeader.name encoding:NSUTF8StringEncoding] ?: @"";
    
    lut.title = nameString;

    NSString *modelString = [NSString stringWithCString:fileHeader.model encoding:NSUTF8StringEncoding] ?: @"";

    NSString *headerDescription = [NSString stringWithCString:fileHeader.description encoding:NSUTF8StringEncoding];
    lut.descriptionText = headerDescription ? headerDescription : @"";

    NSString *versionString = [NSString stringWithCString:fileHeader.version encoding:NSUTF8StringEncoding];
    if (versionString) {
        lut.metadata = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"version", versionString, @"model", modelString, nil];
    }

    return lut;
}



+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    if(![self optionsAreValid:options]){
        @throw [NSException exceptionWithName:@"FSIDATLUTWriteError" reason:[NSString stringWithFormat:@"Options don't pass the spec: %@", options] userInfo:nil];
    }
    else{
        options = options[[self formatterID]];
    }

    if ([options[@"fileTypeVariant"] isEqualToString:@"v1"]) {
        return [self dataFromLUTv1:lut withOptions:options];
    }
    else if ([options[@"fileTypeVariant"] isEqualToString:@"v2"]) {
        return [self dataFromLUTv2:lut withOptions:options];
    }
    return nil;
}

+ (NSData *)dataFromLUTv2:(LUT *)lut withOptions:(NSDictionary *)options{
    //pack LUT in bytes
    if (lut.size != 17) {
        @throw [NSException exceptionWithName:@"FSIDATLUTWriteError" reason:@"LUT is not size 17" userInfo:nil];
    }
    unsigned int *lutBytes = malloc(17*17*17*4);

    for (int currentCubeIndex = 0; currentCubeIndex < 17*17*17; currentCubeIndex++) {
        NSUInteger redIndex = currentCubeIndex % 17;
        NSUInteger greenIndex = ( (currentCubeIndex % (17 * 17)) / (17) );
        NSUInteger blueIndex = currentCubeIndex / (17 * 17);

        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];


        unsigned int rgbPacked = (unsigned int)round(color.red * 1023.0) | ((unsigned int)round(color.green * 1023.0) << 10) | ((unsigned int)round(color.blue * 1023.0) << 20);

        lutBytes[currentCubeIndex] = CFSwapInt32(rgbPacked);
    }

    //--end LUT

    //---create header
    struct LUTFormatterFSIDAT_FileHeader fileHeader;

    //set constants in header
    fileHeader.magic = 0x42340299;
    fileHeader.ver = 0x02000000;
    fileHeader.length = 17*17*17*4;
    strncpy(fileHeader.reserved, "", sizeof(fileHeader.reserved));

    //set variables in header
    if (lut.metadata[@"version"]) {
        strncpy(fileHeader.version, [lut.metadata[@"version"] UTF8String], sizeof(fileHeader.version));
    }
    else{
        strncpy(fileHeader.version, "", sizeof(fileHeader.version));
    }
    
    if (lut.metadata[@"model"]) {
        strncpy(fileHeader.model, [lut.metadata[@"model"] UTF8String], sizeof(fileHeader.model));
    }
    else{
        strncpy(fileHeader.model, "", sizeof(fileHeader.model));
    }

    strncpy(fileHeader.name, lut.title ? [lut.title UTF8String] : "", sizeof(fileHeader.name));
    strncpy(fileHeader.description, lut.descriptionText ? [lut.descriptionText UTF8String] : "", sizeof(fileHeader.description));


    //LUT checksum
    unsigned int data_sum = 0;
    for (int i = 0; i < 17*17*17*4; i++){
        data_sum += ((unsigned char *)lutBytes)[i];
    }
    fileHeader.data_checksum = data_sum;

    //HEADER checksum
    unsigned char header_sum = 0;
    for (int i = 0; i < 128; i++){
        header_sum += ((unsigned char *)&fileHeader)[i];
    }
    fileHeader.header_checksum = header_sum;

    //---end header


    NSMutableData *data = [NSMutableData dataWithBytes:&fileHeader length:sizeof(fileHeader)];
    [data appendBytes:lutBytes length:17*17*17*4];
    free(lutBytes);
    return data;
}

+ (NSData *)dataFromLUTv1:(LUT *)lut withOptions:(NSDictionary *)options{
    if (lut.size != 64) {
        @throw [NSException exceptionWithName:@"FSIDATLUTWriteError" reason:@"LUT is not size 64" userInfo:nil];
    }
    //pack LUT in bytes
    unsigned int *lutBytes = malloc(64*64*64*4);

    for (int currentCubeIndex = 0; currentCubeIndex < 64*64*64; currentCubeIndex++) {
        NSUInteger redIndex = currentCubeIndex % 64;
        NSUInteger greenIndex = ( (currentCubeIndex % (64 * 64)) / (64) );
        NSUInteger blueIndex = currentCubeIndex / (64 * 64);

        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];


        unsigned int rgbPacked = (unsigned int)(color.red * 1008.0) | ((unsigned int)(color.green * 1008.0) << 10) | ((unsigned int)(color.blue * 1008.0) << 20);

        lutBytes[currentCubeIndex] = rgbPacked;
    }

    //--end LUT

    //---create header
    struct LUTFormatterFSIDAT_FileHeader fileHeader;

    //set constants in header
    fileHeader.magic = 0x42340299;
    fileHeader.ver = 0x01000002;
    fileHeader.length = 64*64*64*4;
    strncpy(fileHeader.reserved, "", sizeof(fileHeader.reserved));

    //set variables in header
    if (lut.metadata[@"version"]) {
        strncpy(fileHeader.version, [lut.metadata[@"version"] UTF8String], sizeof(fileHeader.version));
    }
    else{
        strncpy(fileHeader.version, "", sizeof(fileHeader.version));
    }

    if (lut.metadata[@"model"]) {
        strncpy(fileHeader.model, [lut.metadata[@"model"] UTF8String], sizeof(fileHeader.model));
    }
    else{
        strncpy(fileHeader.model, "", sizeof(fileHeader.model));
    }
    
    strncpy(fileHeader.name, lut.title ? [lut.title UTF8String] : "", sizeof(fileHeader.name));
    strncpy(fileHeader.description, lut.descriptionText ? [lut.descriptionText UTF8String] : "", sizeof(fileHeader.description));


    //LUT checksum
    unsigned int data_sum = 0;
    for (int i = 0; i < 64*64*64*4; i++){
        data_sum += ((unsigned char *)lutBytes)[i];
    }
    fileHeader.data_checksum = data_sum;

    //HEADER checksum
    unsigned char header_sum = 0;
    for (int i = 0; i < 127; i++){
        header_sum += ((unsigned char *)&fileHeader)[i];
    }
    fileHeader.header_checksum = header_sum;

    //---end header


    NSMutableData *data = [NSMutableData dataWithBytes:&fileHeader length:sizeof(fileHeader)];
    [data appendBytes:lutBytes length:64*64*64*4];
    free(lutBytes);
    return data;
}

+ (NSDictionary *)constantConstraints{
    return @{@"inputBounds":@[@0, @1],
             @"outputBounds":@[@0, @1]};
}


+ (LUTFormatterOutputType)outputType{
    return LUTFormatterOutputType3D;
}

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL{
    if ([super isValidReaderForURL:fileURL] == NO) {
        return NO;
    }
    NSData *data = [NSData dataWithContentsOfURL:fileURL];

    struct LUTFormatterFSIDAT_FileHeader fileHeader;
    [data getBytes:&fileHeader length:sizeof(fileHeader)];

    if (data.length != 128 + 64*64*64*4 && data.length != 128 + 17*17*17*4) {
        return NO;
    }
    if (fileHeader.magic == 0x42340299) {
        return YES;
    }
    return NO;
}

+ (NSString *)formatterName{
    return @"FSI DAT 3D LUT";
}

+ (NSString *)formatterID{
    return @"fsiDAT";
}

+ (BOOL)canRead{
    return YES;
}

+ (BOOL)canWrite{
    return YES;
}

+ (NSString *)utiString{
    return @"public.dat-lut";
}

+ (NSArray *)fileExtensions{
    return @[@"dat"];
}

+ (NSArray *)allOptions{

    NSDictionary *v1Options = @{@"fileTypeVariant":@"v1",
                              @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"64": @(64)}])};

    NSDictionary *v2Options = @{@"fileTypeVariant":@"v2",
                              @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"17": @(17)}])};
    
    return @[v1Options, v2Options];
    
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant":@"v1",
                                 @"lutSize": @(64)};
    
    return @{[self formatterID]: dictionary};
}

@end

