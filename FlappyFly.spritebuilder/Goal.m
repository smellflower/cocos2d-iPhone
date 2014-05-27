//
//  Goal.m
//  FlappyFly
//
//  Created by zhangdl on 27/5/14.
//  Copyright 2014 Apportable. All rights reserved.
//

#import "Goal.h"


@implementation Goal

- (void)didLoadFromCCB {

    self.physicsBody.collisionType = @"goal";
    self.physicsBody.sensor = YES;
}

@end
