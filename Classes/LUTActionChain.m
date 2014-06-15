//
//  LUTActionChain.m
//  Pods
//
//  Created by Greg Cotten on 6/14/14.
//
//

#import "LUTActionChain.h"

@interface LUTAction ()

@property (strong) LUT* cachedInLUT;
@property (strong) LUT* cachedOutLUT;

@end

@implementation LUTAction

+(instancetype)actionWithBlock:(LUT *(^)(LUT *lut))actionBlock
                    actionName:(NSString *)actionName{
    return [[[self class] alloc] initWithBlock:actionBlock actionName:actionName];
}

-(instancetype)initWithBlock:(LUT *(^)(LUT *lut))actionBlock
                  actionName:(NSString *)actionName{
    if(self = [super init]){
        self.actionBlock = actionBlock;
        self.actionName = actionName;
    }
    return self;
}

-(LUT *)LUTByUsingActionBlockOnLUT:(LUT *)lut{
    if(self.cachedInLUT != nil && self.cachedInLUT == lut){
        //NSLog(@"cached");
        return self.cachedOutLUT;
    }
    else{
        //NSLog(@"not cached");
        self.cachedInLUT = lut;
        self.cachedOutLUT = self.actionBlock(lut);
        return self.cachedOutLUT;
    }
}

-(NSString *)description{
    return self.actionName;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    LUTAction *copiedAction = [LUTAction actionWithBlock:self.actionBlock actionName:[self.actionName copyWithZone:zone]];
    copiedAction.cachedInLUT = self.cachedInLUT;
    copiedAction.cachedOutLUT = self.cachedOutLUT;
    return copiedAction;
}

@end

@implementation LUTActionChain

+(instancetype)actionChain{
    return [[[self class] alloc] init];
}

-(instancetype)init{
    if(self = [super init]){
        self.actionChainArray = [NSMutableArray array];
    }
    return self;
}

-(void)removeActionAtIndex:(NSUInteger)index{
    [self.actionChainArray removeObjectAtIndex:index];
}

-(void)insertAction:(LUTAction *)actionBlock atIndex:(NSUInteger)index{
    [self.actionChainArray insertObject:actionBlock atIndex:index];
}

-(void)addAction:(LUTAction *)actionBlock{
    [self.actionChainArray addObject:actionBlock];
}

-(LUTAction *)actionAtIndex:(NSUInteger)index{
    return [self.actionChainArray objectAtIndex:index];
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
    LUT *lut = sourceLUT;
    for(LUTAction *action in self.actionChainArray){
        lut = [action LUTByUsingActionBlockOnLUT:lut];
    }
    return lut;
}

-(NSArray *)actionNames{
    NSMutableArray *actionNames = [NSMutableArray array];
    for(LUTAction *action in self.actionChainArray){
        [actionNames addObject:action.actionName];
    }
    return actionNames;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    LUTActionChain *copiedActionChain = [LUTActionChain actionChain];
    copiedActionChain.actionChainArray = [self.actionChainArray mutableCopyWithZone:zone];
    return copiedActionChain;
}

@end
