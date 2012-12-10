//
//  HelloWorldLayer.m
//  TestZwykly
//
//  Created by Michał Śmiałko on 26.11.2012.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "MainLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

// Music
#import "SimpleAudioEngine.h"

#pragma mark - HelloWorldLayer

@interface MainLayer ()
@property (nonatomic, strong) CCSprite *sledzSprite;

@property (nonatomic, strong) CCFiniteTimeAction *swirlAction;
@property (nonatomic, strong) NSMutableArray *enemies; // Array of enemies sprites
@property (nonatomic) NSInteger dirtnessCount;
@end

// HelloWorldLayer implementation
@implementation MainLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MainLayer *layer = [MainLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	if( (self=[super init]) ) {
        
        self.enemies = [[NSMutableArray alloc] init];
        self.dirtnessCount = 0;
        
        // Get window size
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        // Sprite sheets
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sledzAnimSheet"];
        
        CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode
                                          batchNodeWithFile:@"sledzAnimSheet.png"];

        
        NSMutableArray *swirlAnimFrames = [NSMutableArray array];
        for(int i = 1; i <= 16; ++i) {
            [swirlAnimFrames addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"sledz_anim_%d.png", i]]];
        }
        
        CCAnimation *swirlAnim = [CCAnimation animationWithSpriteFrames:swirlAnimFrames delay:0.04f];
        swirlAnim.restoreOriginalFrame = YES;
        self.swirlAction = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:swirlAnim]
                                                times:1];
        
        // Create sprite from "tlo.png" file
        CCSprite *bgSprite = [CCSprite spriteWithFile:@"tlo.png"];
        [bgSprite setPosition:CGPointMake(winSize.width/2, winSize.height/2)];
        
        // Add sprite to the layer
        [self addChild:bgSprite];
        
        
        //self.sledzSprite = [CCSprite spriteWithFile:@"sledz.png"];
        self.sledzSprite = [CCSprite spriteWithSpriteFrameName:@"sledz_anim_1.png"];
        [self.sledzSprite setPosition:CGPointMake(winSize.width/2, winSize.height/2)];
        //[self addChild:self.sledzSprite];

        [spriteSheet addChild:self.sledzSprite];
        
        [self addChild:spriteSheet];
        
        [self runSwingAnimationOnSprite:self.sledzSprite];
        
        // Add menu buttons
        CCMenuItemSprite *attackButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithFile:@"attack.png"]
                                                                 selectedSprite:[CCSprite spriteWithFile:@"attack_selected.png"] block:^(id sender) {
                                                                                 [self startSwirlAttack];
                                                                 }];
        attackButton.position = CGPointMake(winSize.width/2 - 100, winSize.height/2 - 100);

        CCMenu *menu = [CCMenu menuWithItems:attackButton, nil];
        [self addChild:menu];
        
       
        // Schedule timer
        [self schedule:@selector(createEnemy:) interval:5.0];
        
        
        // Enable touch events
        self.isTouchEnabled = YES;
        
        
        // execute a Liquid action on the whole layer
        id waves = [CCLiquid actionWithWaves:3 amplitude:8 grid:ccg(15,10) duration:15];
        [self runAction: [CCRepeatForever actionWithAction: waves]];
        
        [self initSounds];
    }
	return self;
}

- (void)initSounds
{
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background.mp3"]; // play background music
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"splash.wav"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"attack.wav"];
}

- (void)runSwingAnimationOnSprite:(CCSprite *)sprite
{
    CGPoint amplitude = CGPointMake(0, 20);
    CCSequence *swingSeq = [CCSequence actions:
                            [CCMoveBy actionWithDuration:0.4 position:CGPointMake(-amplitude.x, -amplitude.y)],
                            [CCMoveBy actionWithDuration:0.4 position:CGPointMake(amplitude.x * 2, amplitude.y * 2)],
                            [CCMoveBy actionWithDuration:0.4 position:CGPointMake(-amplitude.x, -amplitude.y)],
                            nil];
    CCRepeatForever *swingForever = [CCRepeatForever actionWithAction:swingSeq];
    [sprite runAction:swingForever];
}


- (void)startSwirlAttack
{
    // Run Swirl animation
    [self.sledzSprite stopAllActions];
    CCCallBlock *callBlock = [CCCallBlock actionWithBlock:^{
        [self runSwingAnimationOnSprite:self.sledzSprite];
    }];
    CCSequence *seq = [CCSequence actions:self.swirlAction, callBlock, nil];
    [self.sledzSprite runAction:seq];
    
    
    // Check if enemy was hit
    CGFloat distance;
    CGPoint sledzCenter = self.sledzSprite.position;
    CGPoint enemyCenter;
    for (int i=0; i<[self.enemies count]; i++) {
        enemyCenter = [(CCSprite *)[self.enemies objectAtIndex:i] position];
        distance = sqrtf(powf(sledzCenter.x - enemyCenter.x, 2) + powf(sledzCenter.y - enemyCenter.y, 2));
        if (distance <= self.sledzSprite.boundingBox.size.width/2 + 20) {
            [self killEnemy:[self.enemies objectAtIndex:i]];
        }
    }

    [[SimpleAudioEngine sharedEngine] playEffect:@"attack.wav"];
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    [self.sledzSprite stopAllActions];
    
    CGPoint destination = location;
    NSInteger factor = location.x > self.sledzSprite.position.x ? -1 : 1;
    
    destination.x += factor * self.sledzSprite.boundingBox.size.width/2.f;

    
    // Move sprite
    CGFloat distance = sqrtf(powf((destination.x - self.sledzSprite.position.x),2) +
                             powf((destination.y - self.sledzSprite.position.y),2));
    CGFloat animTime = 1*distance/150.f; // 100 px in 1 second
    
    CCMoveTo *moveAnim = [CCMoveTo actionWithDuration:animTime position:destination];
    CCCallFuncN *callFunc = [CCCallFuncN actionWithTarget:self selector:@selector(runSwingAnimationOnSprite:)];
    CCSequence *firstSeq = [CCSequence actions:moveAnim, callFunc, nil];
    
    
    CCRotateBy *rotateACW = [CCRotateBy actionWithDuration:animTime*0.9/3.f/4.f angle:10];
    CCRotateBy *rotateCCW = [CCRotateBy actionWithDuration:animTime*0.9/3.f/2.f angle:-20];
    CCSequence *seq = [CCSequence actions:rotateACW, rotateCCW, rotateACW, nil];
    CCRepeat *repeat = [CCRepeat actionWithAction:seq times:3];
    CCSpawn *spawn = [CCSpawn actionOne:firstSeq two:repeat];

    [self.sledzSprite runAction:spawn];
    
    // Flip if needed
    self.sledzSprite.flipX = location.x > self.sledzSprite.position.x;

}

- (void)createEnemy:(ccTime)dt
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    CCSprite *enemy = [CCSprite spriteWithFile:@"enemy.png"];
    
    // Random position
    NSInteger x = rand() % ((NSInteger)winSize.width - 100 + 1 ) + 100;
    NSInteger y = rand() % ((NSInteger)winSize.height - 600 + 1 ) + 600;
    
    [enemy setPosition:CGPointMake(x, y)];
    
    
    // Animate alpha
    enemy.opacity = 0.f;
    CCFadeIn *faceIn = [CCFadeIn actionWithDuration:0.5];
    
    // Move down
    CCMoveTo *moveTo = [CCMoveTo actionWithDuration:8.0 position:CGPointMake(enemy.position.x, 40)];
    CCCallFuncN *callFunc = [CCCallFuncN actionWithTarget:self selector:@selector(enemyHitGround:)];
    CCSequence *moveSeq = [CCSequence actions:moveTo, callFunc, nil];
    
    // Swing
    CCSequence *swingSeq = [CCSequence actions:
                            [CCRotateBy actionWithDuration:0.5 angle:-10],
                            [CCRotateBy actionWithDuration:1. angle:20],
                            [CCRotateBy actionWithDuration:0.5 angle:-10],
                            nil];
    CCRepeat *swing = [CCRepeat actionWithAction:swingSeq times:10];
    
    CCSpawn *parallerAnim = [CCSpawn actions:faceIn, moveSeq, swing, nil];
    [enemy runAction:parallerAnim];
    
    [self addChild:enemy];
    [self.enemies addObject:enemy];
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"splash.wav"];
}

- (void)killEnemy:(CCSprite *)enemy
{
    // Scale
    CCScaleTo *scale = [CCScaleTo actionWithDuration:0.5 scale:0];
    
    // Fade out
    CCFadeOut *fadeOut = [CCFadeOut actionWithDuration:0.5];
    
    // Parallel actions
    CCSpawn *scaleAndFadeOut = [CCSpawn actions:scale, fadeOut, nil];
    
    // Finish block
    CCCallBlockN *finishBlock = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        [node removeFromParentAndCleanup:YES];
    }];
    
    // Sequence = parallel actions + finish block
    CCSequence *seq = [CCSequence actions:scaleAndFadeOut, finishBlock, nil];
    
    // Run actions!
    [enemy runAction:seq];
}

- (void)enemyHitGround:(id)sender
{
    [(CCSprite *)sender setColor:ccc3(135,250,170)];
    self.dirtnessCount ++;
    [self killEnemy:sender];
}

- (void) dealloc
{
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
