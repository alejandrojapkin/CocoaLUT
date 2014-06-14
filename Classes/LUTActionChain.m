//
//  LUTActionChain.m
//  Pods
//
//  Created by Greg Cotten on 6/14/14.
//
//

#import "LUTActionChain.h"

@implementation LUTAction

+(instancetype)actionWithBlock:(LUT *(^)(LUT *))actionBlock
                    actionName:(NSString *)actionName{
    return [[[self class] alloc] initWithBlock:actionBlock actionName:actionName];
}

-(instancetype)initWithBlock:(LUT *(^)(LUT *))actionBlock
                  actionName:(NSString *)actionName{
    if(self = [super init]){
        self.actionBlock = actionBlock;
        self.actionName = actionName;
    }
    return self;
}

-(LUT *)LUTByUsingActionBlockOnLUT:(LUT *)lut{
    return self.actionBlock(lut);
}

@end

@interface LUTActionChain ()

@property (strong) NSMutableArray *actionChain;

@end

@implementation LUTActionChain

+(instancetype)actionChain{
    return [[[self class] alloc] init];
}

-(instancetype)init{
    if(self = [super init]){
        self.actionChain = [NSMutableArray array];
    }
    return self;
}

-(void)removeActionAtIndex:(NSUInteger)index{
    [self.actionChain removeObjectAtIndex:index];
}

-(void)insertAction:(LUTAction *)actionBlock atIndex:(NSUInteger)index{
    [self.actionChain insertObject:actionBlock atIndex:index];
}

-(void)addAction:(LUTAction *)actionBlock{
    [self.actionChain addObject:actionBlock];
}

-(LUTAction *)actionAtIndex:(NSUInteger)index{
    return [self.actionChain objectAtIndex:index];
}

-(LUT *)lutAtIndex:(NSUInteger)index
    usingSourceLUT:(LUT *)sourceLUT{
    LUT *lut = [sourceLUT copy];
    for(int i = 0; i <= index; i++){
        lut = [[self actionAtIndex:index] LUTByUsingActionBlockOnLUT:lut];
    }
    return lut;
}

-(LUT *)outputLUTUsingSourceLUT:(LUT *)sourceLUT{
    return [self lutAtIndex:self.actionChain.count-1 usingSourceLUT:sourceLUT];
}

-(NSArray *)actionNames{
    NSMutableArray *actionNames = [NSMutableArray array];
    for(LUTAction *action in self.actionChain){
        [actionNames addObject:action.actionName];
    }
    return actionNames;
}

@end
