//
//  LUTFormatterArriLook.m
//  Pods
//
//  Created by Greg Cotten on 5/16/14.
//
//

#import "LUTFormatterArriLook.h"
#import <XMLDictionary/XMLDictionary.h>

@implementation LUTFormatterArriLook

+ (LUT *)LUTFromData:(NSData *)data{
    NSDictionary *xml = [NSDictionary dictionaryWithXMLData:data];
    
    return nil;
}

+ (NSString *)utiString{
    return @"public.xml";
}

@end
