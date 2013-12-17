//
//  LUTReverser.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/16/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTReverser.h"

@interface LUTReverser ()
@property (strong) KDTree *kdTree;
@property (strong) NSArray *inputArray;
@end

float distancecalc(float x1, float y1, float z1, float x2, float y2, float z2) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float dz = z2 - z1;
    return sqrt((float)(dx * dx + dy * dy + dz * dz));
}

@implementation LUTReverser

- (void)buildInputArray:(NSUInteger)newSize {
    NSLog(@"Building input array...");
    self.progressDescription = @"Building input array...";
    NSDate *startTime = [NSDate date];

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:pow(newSize, 3)];
    
    double ratio = ((double)self.lut.lattice.size - 1.0) / ((float)newSize - 1.0);
    
    int maxValue = (int)newSize - 1;
    
    
    NSLock *arrayLock = [[NSLock alloc] init];
    
    int __block completedRs = 0;
    
    dispatch_apply(newSize, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t r){
        NSMutableArray *thisArray = [NSMutableArray array];
        for (int g = 0; g < newSize; g++) {
            for (int b = 0; b < newSize; b++) {
                LUTColor *reverseColor = [self.lut.lattice colorAtInterpolatedR:remapint01((int)r, maxValue)
                                                                              g:remapint01(g, maxValue)
                                                                              b:remapint01(b, maxValue)];
                [thisArray addObject:@[@(r * ratio), @(g * ratio), @(b * ratio), reverseColor]];
            }
        }
        [arrayLock lock];
        [array addObjectsFromArray: thisArray];
        [arrayLock unlock];
        completedRs++;
        self.progress = (float)completedRs / (float)newSize * 0.33;
    });
    
    self.inputArray = array;
    
    NSLog(@"array built in: %f s", -[startTime timeIntervalSinceNow]);
}

- (LUTColor *)colorNearestToR:(int)r g:(int)g b:(int)b {
    float __block pickedDistance = FLT_MAX;
    NSUInteger __block pickedIndex = 0;
    [self.inputArray enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger idx, BOOL *stop) {
        float distance = distancecalc([array[0] floatValue], [array[1] floatValue], [array[2] floatValue], r, g, b);
        if (distance < pickedDistance) {
            pickedDistance = distance;
            pickedIndex = idx;
        }
    }];
    NSArray *subArray = self.inputArray[pickedIndex];
    return subArray[3];
}

- (void)process {
    
    BOOL useTree = NO;
    
    NSUInteger outputSize = self.lut.lattice.size;
    
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];

    NSBlockOperation *buildOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self buildInputArray:outputSize * 3];
    }];

    NSBlockOperation *findOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSLog(@"Building LUT...");
        self.progressDescription = @"Building LUT...";
        NSDate *startTime2 = [NSDate date];
        
        LUTLattice *newLattice = [[LUTLattice alloc] initWithSize:outputSize];
        
        int maxValue = (int)outputSize - 1;
        
        int __block completedOperations = 0;
        NSUInteger totalOps = outputSize * outputSize * outputSize;
        
        NSLock *latticeLock = [[NSLock alloc] init];
        
        dispatch_apply(outputSize, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t rl){
            int r = (int)rl;
            dispatch_apply(outputSize, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t gl){
                int g = (int)gl;
                for (int b = 0; b < outputSize; b++) {
                    if (useTree) {
                        KDLeaf *leaf = [self.kdTree findNearestNeighbor:@[@(remapint01(r, maxValue)),
                                                                          @(remapint01(g, maxValue)),
                                                                          @(remapint01(b, maxValue))]];
                        [latticeLock lock];
                        [newLattice setColor:leaf.metadata r:r g:g b:b];
                        [latticeLock unlock];
                    }
                    else {
                        LUTColor *color = [self colorNearestToR:remapint01(r, maxValue) g:remapint01(g, maxValue) b:remapint01(b, maxValue)];
                        [latticeLock lock];
                        [newLattice setColor:color r:r g:g b:b];
                        [latticeLock unlock];
                    }
                }
                completedOperations += outputSize;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (useTree) {
                        self.progress = (float)completedOperations / (float)totalOps * 0.33 + 0.66;
                    }
                    else {
                        self.progress = (float)completedOperations / (float)totalOps * 0.66 + 0.33;
                    }
                });
            });
        });
        
        NSLog(@"LUT built in: %f s", -[startTime2 timeIntervalSinceNow]);
        
        [self completedWithLUT:[LUT LUTWithLattice:newLattice]];

    }];
    
    [findOperation addDependency:buildOperation];

    if (useTree) {
        NSBlockOperation *buildTreeOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self buildInputArray:outputSize * 3];
            
            NSLog(@"Building search tree...");
            self.progressDescription = @"Building search tree...";
            NSDate *startTime2 = [NSDate date];
            
            self.kdTree = [[KDTree alloc] initWithArray:self.inputArray];
            NSLog(@"Tree built in: %f s", -[startTime2 timeIntervalSinceNow]);
            self.progress = 0.66;

        }];
        [findOperation addDependency:buildTreeOperation];
        [operationQueue addOperation:buildTreeOperation];
    }

    [operationQueue addOperation:findOperation];
    [operationQueue addOperation:buildOperation];

}

@end
