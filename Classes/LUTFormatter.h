//
//  LUTFormatter.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LUTFormatter : NSObject

+ (LUT *)LUTFromFile:(NSURL *)fileURL;
+ (LUT *)LUTFromData:(NSData *)data;
+ (LUT *)LUTFromString:(NSString *)string;
+ (LUT *)LUTFromLines:(NSArray *)lines;

@end
