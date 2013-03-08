//
//  MainMenuLayer.m
//  BabyBlocks
//
//  Created by xuluan on 13-2-26.
//
//

#import "MainMenuLayer.h"
#import "PlayGameLayer.h"


enum {
	TAG_RECIPE = 0,
	TAG_RECIPE_NAME = 1,
	TAG_NEXT_BUTTON = 2,
	TAG_PREV_BUTTON = 3,
	TAG_BG = 4
};

enum {
	Z_BG = 0,
	Z_RECIPE = 1,
	Z_HUD = 2
};

extern NSDictionary* loadSettings();
extern void saveSettings(NSDictionary *dictionary);

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
        
        //currentSize = 7; //default size = 10 * 10
        NSDictionary *dict = loadSettings();
        
        currentSettings = [[NSDictionary alloc ] initWithDictionary:dict];        
        currentSize = [[currentSettings objectForKey:@"current_size"] intValue];
        NSString *size_key = [NSString stringWithFormat:@"%d", currentSize];
        currentLevel = [[[currentSettings objectForKey:size_key] objectForKey:@"current_level"] intValue];
        
        CCMenuItemFont* startGameMIF = [CCMenuItemFont itemFromString:@"START GAME" target:self selector:@selector(startGame)];
        CCMenuItemFont* sizeMIF = [CCMenuItemFont itemFromString:@"SIZE" target:self selector:@selector(showSetSize)];
        CCMenuItemFont* modeMIF = [CCMenuItemFont itemFromString:@"MODE" target:self selector:@selector(startGame)];
        CCMenuItemFont* exitMIF = [CCMenuItemFont itemFromString:@"EXIT" target:self selector:@selector(exit)];
        
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
        //[self schedule:@selector(step:)];

	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    [mainMenu release];
    [sizeToChoose release];
    [currentSettings release]
	
    [self removeAllChildrenWithCleanup:YES];

	// don't forget to call "super dealloc"
    
	[super dealloc];
}


-(void) startGame
{
    [[CCDirector sharedDirector] pushScene:[PlayGameLayer sceneWithSettings:currentSettings]];
}

-(void) showSetSize {
	mainMenu.visible = NO;
	sizeToChoose.visible = YES;
}

-(void) setSize:(int)n {
	currentSize = n;
	[currentSettings setValue:[NSNumber numberWithInt:n] forKey:@"current_size"];
	saveSettings(currentSettings);

	mainMenu.visible = YES;
	sizeToChoose.visible = NO;
}

-(void) setSize3 { [self setSize:3]; }
-(void) setSize7 { [self setSize:7]; }
-(void) setSize10 { [self setSize:10]; }

-(void) exit {
    exit(0);
}
/*
-(void)showExit {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Do You Like Exit?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes",nil];
    
	[alert show];
	[alert release];
}

//AlertView callback
-(void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 0) {
        NSLog(@"cancel");
 	}else {
        
		exit(0);
	}
}
*/

@end

