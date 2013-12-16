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
@end

double remapint01(int value, int maxValue) {
    return (double)value / (double)maxValue;
}

@implementation LUTReverser

- (void)buildSearchTreeWithSize:(NSUInteger)newSize {
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
    
    NSLog(@"array built in: %f s", -[startTime timeIntervalSinceNow]);

    NSLog(@"Building search tree...");
    self.progressDescription = @"Building search tree...";
    NSDate *startTime2 = [NSDate date];

    self.kdTree = [[KDTree alloc] initWithArray:array];
    NSLog(@"Tree built in: %f s", -[startTime2 timeIntervalSinceNow]);
    self.progress = 0.66;
}

- (void)process {
    
    NSUInteger outputSize = self.lut.lattice.size;
    
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];

    NSBlockOperation *buildOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self buildSearchTreeWithSize:outputSize * 3];
    }];
    

    NSBlockOperation *findOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSLog(@"Building LUT from tree...");
        self.progressDescription = @"Building LUT...";
        NSDate *startTime2 = [NSDate date];
        
        LUTLattice *newLattice = [[LUTLattice alloc] initWithSize:outputSize];
        
        int maxValue = (int)outputSize - 1;
        
        for (int r = 0; r < outputSize; r++) {
            for (int g = 0; g < outputSize; g++) {
                for (int b = 0; b < outputSize; b++) {
                    KDLeaf *leaf = [self.kdTree findNearestNeighbor:@[@(remapint01(r, maxValue)),
                                                                      @(remapint01(g, maxValue)),
                                                                      @(remapint01(b, maxValue))]];
                    [newLattice setColor:leaf.metadata r:r g:g b:b];
                }
            }
            self.progress = (float)r / (float)outputSize * 0.33 + 0.66;
        }
        
        NSLog(@"LUT built in: %f s", -[startTime2 timeIntervalSinceNow]);
        
        [self completedWithLUT:[LUT LUTWithLattice:newLattice]];

    }];
    
    [findOperation addDependency:buildOperation];
    
    [operationQueue addOperation:buildOperation];
    [operationQueue addOperation:findOperation];

}

@end
