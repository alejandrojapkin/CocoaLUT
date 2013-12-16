//
//  KDNode.h
//  KDTree
//
//  Created by Bronson Brown-deVost on 9/16/13.
//  Copyright (c) 2013 Bronson Brown-deVost. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDLeaf.h"

@interface KDNode : NSObject

@property CGFloat splitPoint;
@property NSUInteger dimension;
@property (strong, nonatomic) KDNode *right, *left;
@property (strong, nonatomic) KDLeaf *rightLeaf, *leftLeaf;

-(id)initWithArray:(NSArray*)array withDimensions:(NSUInteger)dimensions andWithCurrentDimension:(NSUInteger)currentDimension;
-(id)initWithArray:(NSArray*)array withDimensions:(NSUInteger)dimensions;
-(id)initWithArray:(NSArray*)array;

@end
