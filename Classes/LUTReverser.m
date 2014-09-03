//
//  LUTReverser.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/16/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTReverser.h"
#import "LUTHelper.h"

#if false

@interface LUTReverser ()
@property (strong) KDTree *kdTree;
@property (strong) NSArray *inputArray;
@property (assign) BOOL useTree;
@property (assign) NSUInteger outputSize;
@property (strong) NSOperationQueue *queue;
@end

@implementation LUTReverser

- (void)process {
    [super process];

    if([self.lut equalsIdentityLUT]){
        [self completedWithLUT:[self.lut copy]];
        return;
    }

    if(isLUT1D(self.lut)){
        LUT1D *reversedLUT1D = [(LUT1D *)self.lut LUT1DByReversingWithStrictness:NO autoAdjustInputBounds:YES];
        if(reversedLUT1D != nil){
            [self completedWithLUT:reversedLUT1D];
        }
        else{
            //not reversible
            [self didCancel];
        }
        return;
    }


    self.queue = [[NSOperationQueue alloc] init];

    self.useTree = YES;

    self.outputSize = [self.lut size];

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
        timer(@"Searching Tree", ^{
            self.progressDescription = @"Searching and building new LUT...";
            [self search];
        });
    }];
    [findOperation addDependency:buildOperation];

    // BUILD KD TREE IF NECCESSARY
    if (self.useTree) {
        NSBlockOperation *buildTreeOperation = [NSBlockOperation blockOperationWithBlock:^{
            timer(@"Building Search Tree", ^{
                self.progressDescription = @"Building search tree...";
                self.kdTree = [[KDTree alloc] initWithArray:self.inputArray];
                [self setProgress:0 section:3 of:4];
            });
        }];
        [buildTreeOperation addDependency:buildOperation];
        [findOperation addDependency:buildTreeOperation];
        [self.queue addOperation:buildTreeOperation];
    }

    [self.queue addOperation:resizeOperation];
    [self.queue addOperation:findOperation];
    [self.queue addOperation:buildOperation];

}

- (void) didCancel {
    [super didCancel];
    [self.queue cancelAllOperations];
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
                if ([self checkCancellation]) return;
                LUTColor *latticePointReference = [LUTColor colorWithRed:nsremapint01(r, maxValue)
                                                                   green:nsremapint01(g, maxValue)
                                                                    blue:nsremapint01(b, maxValue)];
                LUTColor *outputColor = [self.lut colorAtR:r g:g b:b];
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

    LUT3D *newLUT = [LUT3D LUTOfSize:self.outputSize inputLowerBound:[self.lut inputLowerBound] inputUpperBound:[self.lut inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self.lut];
    int maxValue = (int)self.outputSize - 1;

    int __block completedOps = 0;
    NSUInteger totalOps = self.outputSize * self.outputSize * self.outputSize;

    NSLock *progressLock = [[NSLock alloc] init];

    [self.lut LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        if ([self checkCancellation]) return;
        if (self.useTree) {
            KDLeaf *leaf = [self.kdTree findNearestNeighbor:@[@(nsremapint01(r, maxValue)),
                                                              @(nsremapint01(g, maxValue)),
                                                              @(nsremapint01(b, maxValue))]];
            [newLUT setColor:leaf.metadata r:r g:g b:b];
        }
        else {
            LUTColor *color = [self colorNearestToR:nsremapint01(r, maxValue)
                                                  g:nsremapint01(g, maxValue)
                                                  b:nsremapint01(b, maxValue)];
            [newLUT setColor:color r:r g:g b:b];
        }
        completedOps++;
        [progressLock lock];
        [self setProgress:(float)completedOps / (float)totalOps section:4 of:4];
        [progressLock unlock];
    }];

    [self completedWithLUT:newLUT];

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

#endif
