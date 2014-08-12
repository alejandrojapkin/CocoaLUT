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
    unsigned int ver; // 4Bytes, 0x01000002
    char model[16]; // 16Bytes, monitor model. No match required for DIT LUT.
    char version[16]; // 16Bytes, data version, eg. “1.0.11”
    unsigned int data_checksum; // 4Bytes, data sum
    unsigned int length; // 4Bytes, data length = 1048576
    char description[16]; //16Bytes, 3dlut description info, e.g. “LightSpace(c)”
    char reserved[63]; // reserved
    unsigned char header_checksum; // file header sum
};

@implementation LUTFormatterFSIDAT


+ (void)load{
    [super load];
}

+ (LUT *)LUTFromData:(NSData *)data{
    struct LUTFormatterFSIDAT_FileHeader fileHeader;
    [data getBytes:&fileHeader length:128];

    unsigned int * lutBytes = malloc(1048576);

    [data getBytes:lutBytes range:NSMakeRange(128, 1048576)];

    LUT3D *lut = [LUT3D LUTOfSize:64 inputLowerBound:0 inputUpperBound:1];

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

    free(lutBytes);

    NSString *versionString = [NSString stringWithCString:fileHeader.version encoding:NSUTF8StringEncoding];
    if (versionString) {
        lut.metadata = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"version", versionString, nil];
    }


    lut.passthroughFileOptions = @{[self formatterID]: @{@"fileTypeVariant": @"FSI",
                                                         @"lutSize": @(64)}};

    NSString *headerTitle = [NSString stringWithCString:fileHeader.model encoding:NSUTF8StringEncoding];
    lut.title = headerTitle ? headerTitle : @"";

    NSString *headerDescription = [NSString stringWithCString:fileHeader.description encoding:NSUTF8StringEncoding];
    lut.descriptionText = headerDescription ? headerDescription : @"";


    return lut;
}



+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options{
    if (![self optionsAreValid:options]) {
        return nil;
    }


    //pack LUT in bytes
    unsigned int * lutBytes = malloc(1048576);

    for (int currentCubeIndex = 0; currentCubeIndex < 64*64*64; currentCubeIndex++) {
        NSUInteger redIndex = currentCubeIndex % 64;
        NSUInteger greenIndex = ( (currentCubeIndex % (64 * 64)) / (64) );
        NSUInteger blueIndex = currentCubeIndex / (64 * 64);

        LUTColor *color = [lut colorAtR:redIndex g:greenIndex b:blueIndex];


        unsigned int rgbPacked = (int)(color.red * 1008.0) | ((int)(color.green * 1008.0) << 10) | ((int)(color.blue * 1008.0) << 20);

        lutBytes[currentCubeIndex] = rgbPacked;
    }

    //--end LUT

    //---create header
    struct LUTFormatterFSIDAT_FileHeader fileHeader;

    //set constants in header
    fileHeader.magic = 0x42340299;
    fileHeader.ver = 0x01000002;
    fileHeader.length = 1048576;
    strcpy(fileHeader.reserved, "");

    //set variables in header
    if (lut.metadata[@"version"]) {
       strcpy(fileHeader.version, [lut.metadata[@"version"] UTF8String]);
    }
    else{
        strcpy(fileHeader.version, "");
    }
    
    strcpy(fileHeader.model, lut.title ? [lut.title UTF8String] : "");
    strcpy(fileHeader.description, lut.descriptionText ? [lut.descriptionText UTF8String] : "");


    //LUT checksum
    unsigned int data_sum = 0;
    for (int i = 0; i < 1048576; i++){
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
    [data appendBytes:lutBytes length:1048576];

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
    if (data.length != 128 + 1048576) {
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

    NSDictionary *options = @{@"fileTypeVariant":@"FSI",
                              @"lutSize": M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"64": @(64)}])};
    
    return @[options];
    
}

+ (NSDictionary *)defaultOptions{
    NSDictionary *dictionary = @{@"fileTypeVariant":@"FSI",
                                 @"lutSize": @(64)};
    
    return @{[self formatterID]: dictionary};
}

@end

