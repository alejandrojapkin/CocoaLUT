//
//  KDNode.m
//  KDTree
//
//  Created by Bronson Brown-deVost on 9/16/13.
//  Copyright (c) 2013 Bronson Brown-deVost. All rights reserved.
//

#import "KDNode.h"

@implementation KDNode

@synthesize splitPoint, dimension, right, left, rightLeaf, leftLeaf;

# pragma mark -
# pragma mark Initialize

-(id)initWithArray:(NSArray*)array withDimensions:(NSUInteger)dimensions andWithCurrentDimension:(NSUInteger)currentDimension {
    //Check to make sure we stay within the coordinate dimensions
    if (currentDimension >= dimensions) {
        currentDimension = 0;
    }
    dimension = currentDimension;
    
    //Sort the array along the current dimension and find the center point
    array = [self sortArray:array inDimension:currentDimension];
    int centerPoint = [self findCenter:array inDimension:currentDimension];
    
    
    //Set the mean value for this node
    splitPoint = [self findMean:array inLayer:currentDimension];
    
    //create children till we reach the end of the array (i.e. the array only holds one or two objects).
    if ([array count] > 2) {
        //Move to the next dimension
        currentDimension++;
        
        //Split off a left array and star building nodes on it.
        NSRange leftRange = NSMakeRange(0, centerPoint);
        NSArray *leftArray = [array subarrayWithRange: leftRange];
        left = [[KDNode alloc] initWithArray:leftArray withDimensions:dimensions andWithCurrentDimension:currentDimension];
        
        NSUInteger offsetLength = [array count] - centerPoint;
        //Split off the right array and start building nodes on it.
        NSRange rightRange = NSMakeRange(centerPoint, offsetLength);
        NSArray *rightArray = [array subarrayWithRange: rightRange];
        right = [[KDNode alloc] initWithArray:rightArray withDimensions:dimensions andWithCurrentDimension:currentDimension];
    } else {
        leftLeaf = [[KDLeaf alloc] initWithArray:[array objectAtIndex:0]];
        if ([array count] > 1) {
            rightLeaf = [[KDLeaf alloc] initWithArray:[array objectAtIndex:1]];
        }
    }
    return self;
}

-(id)initWithArray:(NSArray*)array withDimensions:(NSUInteger)dimensions {
    return [self initWithArray:array withDimensions:dimensions andWithCurrentDimension:0];
}

-(id)initWithArray:(NSArray*)array {
    return [self initWithArray:array withDimensions:[[array objectAtIndex:0] count]-1];
}

# pragma mark -
# pragma mark Sorting and Processing

//This sorts an array along a specified dimension
-(NSArray*)sortArray:(NSArray*)array inDimension:(NSUInteger)layer {
    array = [array sortedArrayUsingComparator:^(id a, id b) {
        NSNumber *coordinateA = [a objectAtIndex:layer];
        NSNumber *coordinateB = [b objectAtIndex:layer];
        return [coordinateA compare:coordinateB];
    }];
    return array;
}

//This finds the mean in a given array
-(CGFloat)findMean:(NSArray*)array inLayer:(NSUInteger)layer{
    CGFloat mean = 0;
    for (NSArray *currentValue in array){
        mean += [[currentValue objectAtIndex:layer] doubleValue];
    }
    mean /= [array count];
    return mean;
}

//This passes back the index of the center of the array (always rounded down)
-(int)findCenter:(NSArray*)array inDimension:(NSUInteger)dimension {
    int center;
    center = (int)[array count]/2;
    return center;
}

@end
