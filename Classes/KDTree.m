//
//  KDTree.m
//  KDTree
//
//  Created by Bronson Brown-deVost on 11/1/13.
//  Copyright (c) 2013 Bronson Brown-deVost. All rights reserved.
//

#import "KDTree.h"

@implementation KDTree
@synthesize root;

# pragma mark -
# pragma mark Initialize

-(id)initWithArray:(NSArray*)array {
    root = [[KDNode alloc] initWithArray:array];
    return self;
}

# pragma mark -
# pragma mark Search

-(KDLeaf*)findApproximateNearestNeighbor:(NSArray*)coordinates inNode:(KDNode*)node {
    KDLeaf *closestLeaf;
    
    while (!node.leftLeaf) {
        if ([[coordinates objectAtIndex:node.dimension] doubleValue] < node.splitPoint) {
            node = node.left;
        } else {
            node = node.right;
        }
    }
    
    if ([[coordinates objectAtIndex:node.dimension] doubleValue] < node.splitPoint) {
        closestLeaf = node.leftLeaf;
    } else {
        if (node.rightLeaf) {
            closestLeaf = node.rightLeaf;
        } else {
            closestLeaf = node.leftLeaf;
        }
    }
    return closestLeaf;
}

-(KDLeaf*)findApproximateNearestNeighbor:(NSArray*)coordinates {
    return [self findApproximateNearestNeighbor:coordinates inNode:root];
}

-(KDLeaf*)findNearestNeighbor:(NSArray*)coordinates inNode:(KDNode*)node withDistance:(CGFloat) distance toClosestLeaf:(KDLeaf*) closestLeaf {
    if (node.leftLeaf) {
        CGFloat leftLeafDistance = [self euclidianDistance:[[node leftLeaf] points] to:coordinates];
        if (leftLeafDistance < distance) {
            closestLeaf = node.leftLeaf;
            distance = leftLeafDistance;
        }
    } else {
        if (node.left) {
            CGFloat leftExtremity = [[coordinates objectAtIndex:node.dimension] doubleValue] - distance;
            
            if (leftExtremity < node.splitPoint) {
                closestLeaf = [self findNearestNeighbor:coordinates inNode:[node left] withDistance:distance toClosestLeaf:closestLeaf];
            }
        }
    }
    
    if (node.rightLeaf) {
        CGFloat rightLeafDistance = [self euclidianDistance:[[node rightLeaf] points] to:coordinates];
        if (rightLeafDistance < distance) {
            closestLeaf = node.rightLeaf;
            distance = rightLeafDistance;
        }
    } else {
        if (node.right) {
            CGFloat rightExtremity = [[coordinates objectAtIndex:node.dimension] doubleValue] + distance;
            
            if (rightExtremity > node.splitPoint) {
                closestLeaf = [self findNearestNeighbor:coordinates inNode:[node right] withDistance:distance toClosestLeaf:closestLeaf];
            }
        }
    }
    
    //this sends back the closest leaf now.
    return closestLeaf;
}

-(KDLeaf*)findNearestNeighbor:(NSArray*)coordinates inNode:(KDNode*)node {
    KDLeaf *closestLeaf = [self findApproximateNearestNeighbor:coordinates inNode:node];
    CGFloat distance = [self euclidianDistance:[closestLeaf points] to:coordinates];
    return [self findNearestNeighbor:coordinates inNode:node withDistance:distance toClosestLeaf:closestLeaf];
}

-(KDLeaf*)findNearestNeighbor:(NSArray*)coordinates {
    return [self findNearestNeighbor:coordinates inNode:root];
}

-(CGFloat)euclidianDistance:(NSArray*)firstCoordinates to:(NSArray*)secondCoordinates {
    CGFloat distance = 0.0;
    for (int i = 0; i < [firstCoordinates count]; i++) {
        distance += pow([[firstCoordinates objectAtIndex:i] doubleValue] - [[secondCoordinates objectAtIndex:i] doubleValue], 2);
    }
    distance = sqrt(distance);
    return distance;
}

@end
