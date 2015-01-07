//
//  TestHelper.h
//  CocoaLUTTests
//
//  Created by Greg Cotten on 1/7/15.
//
//

#import <Foundation/Foundation.h>
#import <CocoaLUT/CocoaLUT.h>

@interface TestHelper : NSObject

+ (LUT *)loadLUT:(NSString *)name extension:(NSString *)ext;

@end
