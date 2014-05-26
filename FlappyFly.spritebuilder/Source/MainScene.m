//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"

static const CGFloat scrollSpeed = 80.0f;

@implementation MainScene {

    CCSprite *_hero;
    CCNode *_ground1;
    CCNode *_ground2;
    NSArray *_grounds;
    CCPhysicsNode *_physicsNode;
    NSTimeInterval _sinceTouch;
}

- (void)didLoadFromCCB {

    self.userInteractionEnabled = YES;
    
    _grounds = @[_ground1, _ground2];
}

- (void)update:(CCTime)delta {

    _hero.position = CGPointMake(_hero.position.x + delta * scrollSpeed,
                                 _hero.position.y);
    _physicsNode.position = CGPointMake(_physicsNode.position.x - delta * scrollSpeed,
                                        _physicsNode.position.y);
    
    for (CCNode *ground in _grounds) {
        
#warning 没搞清楚这个坐标的事情
        
//        NSLog(@"ground position is: %f, %f",ground.position.x, ground.position.y);
        
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
        
//        NSLog(@"world position is: %f, %f",groundWorldPosition.x, groundWorldPosition.y);
        
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        
//        NSLog(@"screen position is: %f, %f",groundScreenPosition.x, groundScreenPosition.y);
        
         // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= -1 * ground.contentSize.width) {
            
            ground.position = ccp(ground.position.x + 2 * ground.contentSize.width,
                                  ground.position.y);
        }
    }
    
    float yVelocity = clampf(_hero.physicsBody.velocity.y, -1 * MAXFLOAT, 200.f);
    _hero.physicsBody.velocity = ccp(0, yVelocity);
    
    _sinceTouch += delta;
    _hero.rotation = clampf(_hero.rotation, -30.0f, 90.0f);
    if (_hero.physicsBody.allowsRotation) {
        float angularVelocity = clampf(_hero.physicsBody.angularVelocity, -2.0f, 1.0f);
        _hero.physicsBody.angularVelocity = angularVelocity;
    }
    if (_sinceTouch > 0.5f) {
        [_hero.physicsBody applyAngularImpulse:-4000.0f * delta];
    }
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {

    [_hero.physicsBody applyImpulse:ccp(0, 400.0)];
    [_hero.physicsBody applyAngularImpulse:1000.0f];
    _sinceTouch = 0.0f;
}

@end