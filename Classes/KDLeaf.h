//
//  KDLeaf.h
//  KDTree-Framework
//
//  Created by Bronson Brown-deVost on 10/8/13.
//  Copyright (c) 2013 Bronson Brown-deVost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KDLeaf : NSObject
@property (strong, nonatomic) NSArray *points;
@property (strong, nonatomic) id metadata;

-(id)initWithArray:(NSArray*)array;

@end
