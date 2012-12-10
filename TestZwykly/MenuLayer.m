//
//  MenuLayer.m
//  TestZwykly
//
//  Created by Michał Śmiałko on 28.11.2012.
//
//

#import "MenuLayer.h"
#import "MainLayer.h"

@implementation MenuLayer

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	
	MenuLayer *layer = [MenuLayer node];
	
	[scene addChild: layer];
	
	return scene;
}

- (id)init
{
    
    if (self = [super init]) {
        // Get window size
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        // Background
        CCSprite *bg = [CCSprite spriteWithFile:@"menubg.png"];
        bg.position = CGPointMake(winSize.width/2, winSize.height/2);
        [self addChild:bg];
        
        CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:@"Szalony śledź ratuje świat!" fontName:@"Helvetica" fontSize:65];
        titleLabel.position = CGPointMake(winSize.width/2, winSize.height - titleLabel.contentSize.height);
        titleLabel.color = ccc3(135, 250, 170);
        [self addChild:titleLabel];
        
        // Create menu items
        CCLabelTTF *buttonLabel = [CCLabelTTF labelWithString:@"Ratuj Świat!" fontName:@"Helvetica-Bold" fontSize:50];
        buttonLabel.color = ccc3(255, 0, 0);
        CCMenuItemLabel *startGameButton = [CCMenuItemLabel itemWithLabel:buttonLabel block:^(id sender) {
                [[CCDirector sharedDirector] replaceScene:[CCTransitionPageTurn transitionWithDuration:1.0 scene:[MainLayer scene]]];
        }];
        startGameButton.position = CGPointMake(0, 100);

        CCMenu *menu = [CCMenu menuWithItems:startGameButton, nil];
        [self addChild:menu];

        
        
    }
    
    return self;
}

@end
