//
//  PlayGameLayer.m
//  BabyBlocks
//
//  Created by xuluan on 13-2-26.
//
//

#import "PlayGameLayer.h"
#import "CJSONDeserializer.h"
#import "ActualPath.h"
#import "ColorTouchSprite.h"


static ccColor3B colors[] = {
	{255,0,0},   // red
    {255,255,0}, // yellow
    {0, 255,0},  // green
    {0,0,255},   //blue
    {255,127,0}  //orange
    
};


@implementation PlayGameLayer

+(id) sceneWithLevel:(int)level withMode:(int)mode withSize:(int)size
{
	//Create our scene
	CCScene *s = [CCScene node];

	PlayGameLayer *node = [[PlayGameLayer alloc] initWithLevel:level withMode:mode withSize:size];
	[s addChild:node z:0 tag:0];
	return s;
}


-(id) initWithLevel:(int)level withMode:(int)mode withSize:(int)size {
    CGSize sz = [[CCDirector sharedDirector] winSize];
    currentSize = size;
    currentMode = mode;
    currentLevel = level;

	if( (self=[super init] )) {
        self.isTouchEnabled = YES;
        [self loadLayout];

        
		//Random colored background
		CCSprite *bg = [CCSprite spriteWithFile:@"bg.png"];
		bg.position = ccp(0,0);
		[self addChild:bg z:-1];
        
        //draw color box
        [self initColorBox];

		//Load our level
		//[self loadLevel:str];
        

		
		//Quit button
		CCMenuItemFont *quitItem = [CCMenuItemFont itemFromString:@"Quit" target:self selector:@selector(quit:)];
		CCMenu *menu = [CCMenu menuWithItems: quitItem, nil];
		menu.position = ccp(100, sz.height - 75);
		[self addChild:menu z:10];

    [self drawGridWithOffset:(sz.width/2)];
    [self drawGridWithOffset:(0)];

    
	}
	return self;
}

/* Add sprites which correspond to grid nodes */
-(void) drawGridWithOffset:(int) offset {    
    
    int offset_x = [[currentLayout objectForKey:@"offset_x"] intValue];
    int offset_y = [[currentLayout objectForKey:@"offset_y"] intValue];
    int interval = [[currentLayout objectForKey:@"interval"] intValue];
    
    NSLog(@"from json %d %d\n",offset_x, offset_y);
    
	for(int x=0; x<currentSize; x++){
		for(int y=0; y<currentSize; y++){
            
			CCSprite *sprite = [CCSprite spriteWithFile:[currentLayout objectForKey:@"cell_pic"]];
			sprite.position = ccp(x*interval+offset+offset_x,y*interval+offset_y);

            sprite.color = ccc3(200,200,200);

			[self addChild:sprite];
		}
	}
}

-(void) initColorBox {
	sprites = [[NSMutableArray alloc] init];
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    
	//We add 10 randomly colored sprites
	for(int x=0; x<5; x++){
		ColorTouchSprite *sprite = [ColorTouchSprite spriteWithFile:@"blank.png"];
        
		sprite.position = ccp(x*100+300, size.height-75);
		[sprite setTextureRect:CGRectMake(0,0,75,75)];
		sprite.color = colors[x];
		[self addChild:sprite z:11];
		[sprites addObject:sprite];
	}
}

-(void) quit:(id)sender {
    [[CCDirector sharedDirector] popScene];
    [[CCTextureCache sharedTextureCache] removeAllTextures];
}

-(void) loadLayout {
	NSString *jsonString = [[NSString alloc] initWithContentsOfFile:getActualPath(@"layout.json") encoding:NSUTF8StringEncoding error:nil];
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
	NSDictionary *dict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    NSString *usingSize = [NSString stringWithFormat:@"%d",currentSize];
	currentLayout = [dict objectForKey:usingSize];

}

/*

//Load level file and process sprites
-(void) loadLevel:(NSString*)str {
	NSString *jsonString = [[NSString alloc] initWithContentsOfFile:getActualPath(str) encoding:NSUTF8StringEncoding error:nil];
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
	NSDictionary *dict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    
	NSArray *nodes = [dict objectForKey:@"nodes"];
	for (id node in nodes) {
		if([[node objectForKey:@"type"] isEqualToString:@"spriteFile"]){
			[self processSpriteFile:node];
		}
	}
}

-(void) processSpriteFile:(NSDictionary*)node {
	//Init the sprite
	NSString *file = [node objectForKey:@"file"];
	CCSprite *sprite = [CCSprite spriteWithFile:file];
	
	//Set sprite position
	sprite.position = ccp(arc4random()%480, arc4random()%200);
	
	//Each numeric value is an NSString or NSNumber that must be cast into a float
	sprite.scale = [[node objectForKey:@"scale"] floatValue];
	
	//Set the anchor point so objects are positioned from the bottom-up
	sprite.anchorPoint = ccp(0.5,0);
    
	//Finally, add the sprite
	[self addChild:sprite z:2];
}
 */


/* Process touch events */
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
    NSLog(@"got ccTouchesBegan %d\n", [sprites count]);
	
	//Process input for all sprites
	for(id sprite in sprites){
        NSLog(@"got POINT %@\n", NSStringFromCGPoint(point));
        NSLog(@"got RECT %@\n", NSStringFromCGRect([sprite rect]));
		if(pointIsInRect(point, [sprite rect])){
			//Swallow the input
			[sprite ccTouchesBegan:touches withEvent:event];
            NSLog(@"got spirte\n");

			return;
		}
	}
}
-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	
	//Process input for all sprites
	for(id sprite in sprites){
		if(pointIsInRect(point, [sprite rect])){
			[sprite ccTouchesMoved:touches withEvent:event];
		}
	}
}
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	
	//Process input for all sprites
	for(id sprite in sprites){
		//End all input when you lift up your finger
		[sprite ccTouchesEnded:touches withEvent:event];
	}
}

@end
