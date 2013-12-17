//
//  LUTHelper.m
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import "LUTHelper.h"

double clamp(double value, double min, double max){
    return (value > max) ? max : ((value < min) ? min : value);
}

double clamp01(double value) {
    return clamp(value, 0, 1);
}

double nsremapint01(NSInteger value, NSInteger maxValue) {
    return (double)value / (double)maxValue;
}

double remapint01(int value, int maxValue) {
    return nsremapint01(value, maxValue);
}

double lerp1d(double beginning, double end, double value01) {
    if (value01 < 0 || value01 > 1){
        @throw [NSException exceptionWithName:@"Invalid Lerp" reason:@"Valye out of bounds" userInfo:nil];
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

@implementation LUTHelper

@end
