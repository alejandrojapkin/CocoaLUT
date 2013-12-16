//
//  KDTree.h
//  KDTree
//
//  Created by Bronson Brown-deVost on 11/1/13.
//  Copyright (c) 2013 Bronson Brown-deVost. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDNode.h"

@interface KDTree : NSObject
@property (strong, nonatomic) KDNode *root;

-(id)initWithArray:(NSArray*)array;
-(KDLeaf*)findApproximateNearestNeighbor:(NSArray*)coordinates;
-(KDLeaf*)findNearestNeighbor:(NSArray*)coordinates;
@end