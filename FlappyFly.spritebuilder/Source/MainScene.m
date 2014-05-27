//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Obstacle.h"

static const CGFloat distanceBetweenObstacles = 160.f;
static const CGFloat firstObstaclePosition    = 280.f;

typedef NS_ENUM(NSInteger, DrawingOrder) {
    DrawingOrderPipes,
    DrawingOrderGround,
    DrawingOrderHero
};

@implementation MainScene {

    CCSprite       * _hero;
    CCNode         * _ground1;
    CCNode         * _ground2;
    NSArray        * _grounds;
    NSMutableArray * _obstacles;
    CCPhysicsNode  * _physicsNode;
    CCButton       * _restartButton;
    CCLabelTTF     * _scoreLabel;

    BOOL           _gameOver;
    NSInteger      _points;
    CGFloat        _scrollSpeed;
    NSTimeInterval _sinceTouch;
}

- (void)didLoadFromCCB {

    self.userInteractionEnabled = YES;
    
    _points = 0;
    _scrollSpeed = 80.f;
    
    _grounds = @[_ground1, _ground2];
    
    // set default zorder
    for (CCNode *ground in _grounds) {
        ground.physicsBody.collisionType = @"level";
        ground.zOrder = DrawingOrderGround;
    }
    
    // set the collision delegate
    _physicsNode.collisionDelegate = self;
    
    // set hero properties
    _hero.physicsBody.collisionType = @"hero";
    _hero.zOrder = DrawingOrderHero;
    
    // add obstacles
    _obstacles = [NSMutableArray array];
    [self spawnNewObstacle];
    [self spawnNewObstacle];
    [self spawnNewObstacle];
}

- (void)update:(CCTime)delta {

    _hero.position = CGPointMake(_hero.position.x + delta * _scrollSpeed,
                                 _hero.position.y);
    _physicsNode.position = CGPointMake(_physicsNode.position.x - delta * _scrollSpeed,
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
    _hero.rotation = clampf(_hero.rotation, -30.f, 90.f);
    if (_hero.physicsBody.allowsRotation) {
        float angularVelocity = clampf(_hero.physicsBody.angularVelocity, -2.f, 1.f);
        _hero.physicsBody.angularVelocity = angularVelocity;
    }
    if (_sinceTouch > 0.5f) {
        [_hero.physicsBody applyAngularImpulse:-4000.f * delta];
    }
    
    [self removeOffScreenObstacle];
}

#pragma mark - Helper Method

- (void)gameOver {

    if (!_gameOver) {
        
        _scrollSpeed = 0.0f;
        _gameOver = YES;
        _restartButton.visible = YES;
        _hero.rotation = 90.f;
        _hero.physicsBody.allowsRotation = NO;
        [_hero stopAllActions];
        CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-2, 2)];
        CCActionInterval *reverseMovement = [moveBy reverse];
        CCActionSequence *shakeSequense = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
        CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSequense];
        [self runAction:bounce];
    }
}

- (void)spawnNewObstacle {

    CCNode *previousObstacle = [_obstacles lastObject];
    CGFloat previousObstacleXPosition = previousObstacle.position.x;
    if (!previousObstacle) {
        
        // this is the first obstacle
        previousObstacleXPosition = firstObstaclePosition;
    }
    
    Obstacle *obstacle = (Obstacle *)[CCBReader load:@"Obstacle"];
    obstacle.position = ccp(previousObstacleXPosition + distanceBetweenObstacles, 0);
    obstacle.zOrder = DrawingOrderPipes;
    [obstacle setupRandomPosition];
    [_physicsNode addChild:obstacle];
    [_obstacles addObject:obstacle];
}

- (void)removeOffScreenObstacle {

    NSMutableArray *offScreenObstacles = nil;
    for (CCNode *obstacle in _obstacles) {
        
        CGPoint obstacleWorldPoint = [_physicsNode convertToWorldSpace:obstacle.position];
        CGPoint obstacleScreenPoint = [self convertToNodeSpace:obstacleWorldPoint];
        if (obstacleScreenPoint.x < -obstacle.contentSize.width) {
            if (!offScreenObstacles) {
                offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
        }
    }
    
    for (CCNode *obstacleToRemove in offScreenObstacles) {
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
        
        // for each removed obstacle, add a new one
        [self spawnNewObstacle];
    }
}

- (void)restart {

    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
}

#pragma mark - Touch Delegate

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {

    if (!_gameOver) {
        
        [_hero.physicsBody applyImpulse:ccp(0, 400.f)];
        [_hero.physicsBody applyAngularImpulse:1000.f];
        _sinceTouch = 0.f;
    }
}

#pragma mark - Collision Delegate

// hero collision with level
- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero level:(CCNode *)level {
    
    [self gameOver];
    
    return YES;
}

// hero collision with goal
- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero goal:(CCNode *)goal {

    [goal removeFromParent];
    _points ++;
    _scoreLabel.string = [NSString stringWithFormat:@"%d",_points];
    
    return YES;
}

@end
