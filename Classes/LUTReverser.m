//
//  LUTReverser.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/16/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTReverser.h"
#import "LUTHelper.h"

@interface LUTReverser ()
@property (strong) KDTree *kdTree;
@property (strong) NSArray *inputArray;
@property (assign) BOOL useTree;
@property (assign) NSUInteger outputSize;
@end

@implementation LUTReverser

- (void)process {
    [super process];
    
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];

    self.useTree = YES;
    
    self.outputSize = self.lut.lattice.size;
    
    // RESIZE LUT
    NSBlockOperation *resizeOperation = [NSBlockOperation blockOperationWithBlock:^{
        timer(@"Enlarging", ^{
            self.progressDescription = @"Enlarging LUT...";
            self.lut = [self.lut LUTByResizingToSize:self.outputSize * 3];
        });
    }];

    // BUILD INPUT LUT
    NSBlockOperation *buildOperation = [NSBlockOperation blockOperationWithBlock:^{
        timer(@"Building Array", ^{
            self.progressDescription = @"Building input array...";
            [self buildInputArray:self.outputSize * 3];
        });
    }];
    [buildOperation addDependency:resizeOperation];
    
    // FIND OUTPUTS
    NSBlockOperation *findOperation = [NSBlockOperation blockOperationWithBlock:^{
        timer(@"Searching", ^{
            self.progressDescription = @"Searching and building new LUT...";
            [self search];
        });
    }];
    [findOperation addDependency:buildOperation];

    // BUILD KD TREE IF NECCESSARY
    if (self.useTree) {
        NSBlockOperation *buildTreeOperation = [NSBlockOperation blockOperationWithBlock:^{
            timer(@"Build Tree", ^{
                self.progressDescription = @"Building search tree...";
                self.kdTree = [[KDTree alloc] initWithArray:self.inputArray];
                [self setProgress:0 section:3 of:4];
            });
        }];
        [buildTreeOperation addDependency:buildOperation];
        [findOperation addDependency:buildTreeOperation];
        [operationQueue addOperation:buildTreeOperation];
    }
    
    [operationQueue addOperation:resizeOperation];
    [operationQueue addOperation:findOperation];
    [operationQueue addOperation:buildOperation];
    
}

- (void)buildInputArray:(NSUInteger)newSize {
    
    NSUInteger maxValue = newSize - 1;

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:newSize * newSize * newSize];
    
    NSLock *arrayLock = [[NSLock alloc] init];
    
    int __block completedRs = 0;
    
    dispatch_apply(newSize, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t r){
        NSMutableArray *thisArray = [NSMutableArray array];
        for (int g = 0; g < newSize; g++) {
            for (int b = 0; b < newSize; b++) {
                LUTColor *latticePointReference = [LUTColor colorWithRed:nsremapint01(r, maxValue)
                                                                   green:nsremapint01(g, maxValue)
                                                                    blue:nsremapint01(b, maxValue)];
                LUTColor *outputColor = [self.lut.lattice colorAtR:r g:g b:b];
                [thisArray addObject:@[@(outputColor.red), @(outputColor.green), @(outputColor.blue), latticePointReference]];
            }
        }
        [arrayLock lock];
        [array addObjectsFromArray: thisArray];
        [arrayLock unlock];
        completedRs++;
        [self setProgress:(float)completedRs / (float)newSize section:2 of:4];
    });
    
    self.inputArray = array;
    
}

- (void)search {
    
    LUTLattice *newLattice = [[LUTLattice alloc] initWithSize:self.outputSize];
    
    int maxValue = (int)self.outputSize - 1;
    
    int __block completedOperations = 0;
//    NSUInteger totalOps = self.outputSize * self.outputSize * self.outputSize;
    
    LUTConcurrentCubeLoop(self.outputSize, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        if (self.useTree) {
            KDLeaf *leaf = [self.kdTree findNearestNeighbor:@[@(nsremapint01(r, maxValue)),
                                                              @(nsremapint01(g, maxValue)),
                                                              @(nsremapint01(b, maxValue))]];
            [newLattice setColor:leaf.metadata r:r g:g b:b];
        }
        else {
            LUTColor *color = [self colorNearestToR:nsremapint01(r, maxValue)
                                                  g:nsremapint01(g, maxValue)
                                                  b:nsremapint01(b, maxValue)];
            [newLattice setColor:color r:r g:g b:b];
        }
        completedOperations += self.outputSize;
//        [self setProgress:(float)completedOperations / (float)totalOps section:4 of:4];
    });
    
    [self completedWithLUT:[LUT LUTWithLattice:newLattice]];

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


@end
