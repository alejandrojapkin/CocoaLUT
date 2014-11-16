//
//  LUTFormatter.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LUT.h"
#import "LUT1D.h"
#import "LUT3D.h"
#import "LUTMetadataFormatter.h"
#import "LUTAction.h"



@class LUT;
@class LUT1D;
@class LUT3D;

typedef NS_ENUM(NSInteger, LUTFormatterOutputType) {
    LUTFormatterOutputType3D,
    LUTFormatterOutputType1D,
    LUTFormatterOutputTypeEither,
    LUTFormatterOutputTypeNone
};

typedef NS_ENUM(NSInteger, LUTFormatterRole) {
    LUTFormatterRoleReadOnly,
    LUTFormatterRoleWriteOnly,
    LUTFormatterRoleReadAndWrite,
    LUTFormatterRoleNone
};

/**
 *  An abstract superclass for an object that is responsible for converting between a `LUT` object in-memory and a file-based format.
 */
@interface LUTFormatter : NSObject

+ (NSArray *)LUTFormattersForFileExtension:(NSString *)fileExtension;

+ (LUTFormatter *)LUTFormatterWithID:(NSString *)identifier;

+ (LUTFormatter *)LUTFormatterValidForReadingURL:(NSURL *)fileURL;

+ (NSArray *)LUTFormattersValidForWritingLUTType:(LUT *)lut;

+ (NSArray *)allFormattersFileExtensions;

+ (NSArray *)lut1DFormatterFileExtensions;

+ (NSArray *)lut3DFormatterFileExtensions;

/**
 *  Returns a new LUT from a file in the formatter's file type..
 *
 *  The default implementation reads the contents of the file as a string and returns the result of LUTFromString:.
 *
 *  @param fileURL A file URL.
 *
 *  @return A new `LUT`.
 */
+ (LUT *)LUTFromURL:(NSURL *)fileURL;

/**
 *  Returns a new LUT from a data blob in the formatter's file type..
 *
 *  The default implementation interprets the data as an ASCII string and returns the result of LUTFromString:.
 *
 *  @param data A data blob containing the contents of a LUT file.
 *
 *  @return A new `LUT`.
 */
+ (LUT *)LUTFromData:(NSData *)data;

/**
 *  Returns a new LUT from a string in the formatter's file type..
 *
 *  The default implementation divides the string by newlines and passes the array of strings to LUTFromLines:.
 *
 *  @param string A string containing the contents of a LUT file.
 *
 *  @return A new `LUT`.
 */
+ (LUT *)LUTFromString:(NSString *)string;

/**
 *  Returns a new LUT from an array of string lines in the formatter's file type..
 *
 *  The default implementation raises an exception and is intended to be implemented by a subclass.
 *
 *  @param lines An array of `NSString` objects that represents the lines in a LUT file.
 *
 *  @return A new `LUT`.
 */
+ (LUT *)LUTFromLines:(NSArray *)lines;

/**
 *  Converts the provided `LUT` to a data blob in the formatter's file type.
 *
 *  The default implementation encodes the returned value from stringFromLUT: as UTF-8 text.
 *
 *  @param lut The LUT that is to be formatted.
 *  @param lut The options for the formatter (ex: outputIntegerDepth or fileTypeVariant)
 *  @return A data blob containing the contents of the LUT.
 */
+ (NSData *)dataFromLUT:(LUT *)lut withOptions:(NSDictionary *)options;

/**
 *  Converts the provided `LUT` to a string in the formatter's file type.
 *
 *  The default implementation raises an exception and is intended to be implemented by a subclass.
 *
 *  @param lut The LUT that is to be formatted.
 *  @param lut The options for the formatter (ex: outputIntegerDepth or fileTypeVariant)
 *
 *  @return A string containing the contents of the LUT.
 */
+ (NSString *)stringFromLUT:(LUT *)lut withOptions:(NSDictionary *)options;

+ (BOOL)isValidReaderForURL:(NSURL *)fileURL;

+ (BOOL)isValidWriterForLUTType:(LUT *)lut;

+ (BOOL)isDestructiveWithOptions:(NSDictionary *)options;

+ (LUTFormatterOutputType)outputType;

+ (NSArray *)allOptions;

+ (NSDictionary *)defaultOptions;

+ (BOOL)optionsAreValid:(NSDictionary *)options;

+ (NSString *)utiString;

+ (NSArray *)fileExtensions;

+ (NSString *)formatterName;

+ (NSString *)formatterID;

+ (NSString *)nameWithExtensions;

+ (LUTFormatterRole)formatterRole;

+ (BOOL)canRead;

+ (BOOL)canWrite;

+ (NSDictionary *)constantConstraints;

+ (NSArray *)conformanceLUTActionsForLUT:(LUT *)lut options:(NSDictionary *)options;


@end
