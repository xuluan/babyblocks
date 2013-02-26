//
//  MainMenuLayer.m
//  BabyBlocks
//
//  Created by xuluan on 13-2-26.
//
//

#import "MainMenuLayer.h"

@implementation MainMenuLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MainMenuLayer *layer = [MainMenuLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
        
        CCMenuItemFont* startGameMIF = [CCMenuItemFont itemFromString:@"START GAME" target:self selector:@selector(startGame)];
        CCMenuItemFont* sizeMIF = [CCMenuItemFont itemFromString:@"SIZE" target:self selector:@selector(showSetSize)];
        CCMenuItemFont* modeMIF = [CCMenuItemFont itemFromString:@"MODE" target:self selector:@selector(startGame)];
        CCMenuItemFont* exitMIF = [CCMenuItemFont itemFromString:@"EXIT" target:self selector:@selector(startGame)];
        
        mainMenu = [CCMenu menuWithItems:startGameMIF, sizeMIF, modeMIF, exitMIF, nil];
        [mainMenu alignItemsVertically];

		CGSize size = [[CCDirector sharedDirector] winSize];
        CGPoint center = ccp( size.width /2 , size.height/2);
		mainMenu.position = center;
        [self addChild:mainMenu z:1];
        
        CCMenuItemFont* size3 = [CCMenuItemFont itemFromString:@"3 X 3" target:self selector:@selector(setSize3)];
        CCMenuItemFont* size7 = [CCMenuItemFont itemFromString:@"7 X 7" target:self selector:@selector(setSize7)];
        CCMenuItemFont* size10 = [CCMenuItemFont itemFromString:@"10 X 10" target:self selector:@selector(setSize10)];
        sizeToChoose = [CCMenu menuWithItems:size3, size7, size10, nil];
        [sizeToChoose alignItemsVertically];
        sizeToChoose.position = center;
        sizeToChoose.visible = NO;
        [self addChild:sizeToChoose z:1];
	}
	return self;
}

- startGame
{
    NSLog(@" HERE \n ");
}

-(void) showSetSize {
	mainMenu.visible = NO;
	sizeToChoose.visible = YES;
}

-(void) setSize:(int)n {
	currentSize = n;
    NSLog(@"currentSize = %d \n", currentSize);

	mainMenu.visible = YES;
	sizeToChoose.visible = NO;
}

-(void) setSize3 { [self setSize:3]; }
-(void) setSize7 { [self setSize:7]; }
-(void) setSize10 { [self setSize:10]; }

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end

