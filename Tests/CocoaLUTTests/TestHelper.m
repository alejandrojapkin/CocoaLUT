//
//  TestHelper.m
//  CocoaLUTTests
//
//  Created by Greg Cotten on 1/7/15.
//
//

#import "TestHelper.h"

@implementation TestHelper

+ (LUT *)loadLUT:(NSString *)name extension:(NSString *)ext {
    return [LUT LUTFromURL:[[NSBundle bundleForClass: [self class]] URLForResource:name withExtension:ext]];
}

@end
