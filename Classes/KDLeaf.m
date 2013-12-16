//
//  KDLeaf.m
//  KDTree-Framework
//
//  Created by Bronson Brown-deVost on 10/8/13.
//  Copyright (c) 2013 Bronson Brown-deVost. All rights reserved.
//

#import "KDLeaf.h"

@implementation KDLeaf
@synthesize points, metadata;

-(id)initWithArray:(NSArray*)array {
    //Get the coordinates for the center point and then grab the metadata.
    points = [[NSMutableArray alloc] init];
    NSUInteger dimensions = [array count] - 1;
    NSMutableArray *tempPoints = [[NSMutableArray alloc] init];
    for (int i = 0; i < dimensions; i++) {
        [tempPoints addObject:[array objectAtIndex:i]];
    }
    points = [tempPoints copy];
    metadata = [array objectAtIndex:dimensions];
    
    return self;
}

@end
