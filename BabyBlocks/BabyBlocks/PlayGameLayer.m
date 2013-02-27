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


enum {
	Z_BG = -1,
	Z_LAYER = 0,
	Z_ICON = 2,
	Z_BLOCK = 5,
	Z_BLOCK_MOVING = 10
};

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
	[s addChild:node z:Z_LAYER tag:0];
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

        
		//background
        [self drawColoredSpriteAt:ccp(0,0) withRect:CGRectMake(0,0,sz.width*2,sz.height*2) withColor:ccc3(150,150,200) withZ:Z_BG];

        
        //draw color box
        [self initColorBox];

		//Load our level
		//[self loadLevel:str];
        

		
		//Quit button
		CCMenuItemFont *quitItem = [CCMenuItemFont itemFromString:@"Quit" target:self selector:@selector(quit:)];
		CCMenu *menu = [CCMenu menuWithItems: quitItem, nil];
		menu.position = ccp(100, sz.height - 75);
		[self addChild:menu z:Z_ICON];

    [self drawGridWithOffset:(sz.width/2)];
    [self drawGridWithOffset:(0)];

    
	}
	return self;
}


-(void) drawColoredSpriteAt:(CGPoint)position withRect:(CGRect)rect withColor:(ccColor3B)color withZ:(float)z {
	CCSprite *sprite = [CCSprite spriteWithFile:@"blank.png"];
	[sprite setPosition:position];
	[sprite setTextureRect:rect];
	[sprite setColor:color];
	[self addChild:sprite];
	
	//Set Z Order
	[self reorderChild:sprite z:z];
}

/* Add sprites which correspond to grid nodes */
-(void) drawGridWithOffset:(int) offset {    
    
    int offset_x = [[currentLayout objectForKey:@"offset_x"] intValue];
    int offset_y = [[currentLayout objectForKey:@"offset_y"] intValue];
    int interval = [[currentLayout objectForKey:@"interval"] intValue];

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
	stBlocks = [[NSMutableArray alloc] init];
    dyBlocks = [[NSMutableArray alloc] init];
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    for(int x=0; x<5; x++){
		StaticSprite *sprite = [StaticSprite spriteWithFile:@"blank.png"];
        
		sprite.position = ccp(x*100+300, size.height-75);
		[sprite setTextureRect:CGRectMake(0,0,75,75)];
		sprite.color = colors[x];
		[self addChild:sprite z:Z_BLOCK];
		[stBlocks addObject:sprite];
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


// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    [stBlocks release];
    [dyBlocks release];
    [currentLayout release];
	
    [self removeAllChildrenWithCleanup:YES];
    
	// don't forget to call "super dealloc"
    
	[super dealloc];
}
-(void) createDyblock: (StaticSprite *)block {
    ColorTouchSprite *sprite = [ColorTouchSprite spriteWithFile:@"blank.png"];
    
    sprite.position = [block position];
    [sprite setTextureRect:CGRectMake(0,0,75,75)];
    sprite.color = [block color];
    [self addChild:sprite z:Z_BLOCK_MOVING];
    [dyBlocks addObject:sprite];
}

/* Process touch events */
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	//Process input for all sprites
	for(id sprite in stBlocks){
		if(pointIsInRect(point, [sprite rect])){
            [self createDyblock:sprite];
			return;
		}
	}
	for(id sprite in dyBlocks){
		if(pointIsInRect(point, [sprite rect])){
            [sprite ccTouchesBegan:touches withEvent:event];
			return;
		}
	}
}
-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];

	//Process input for all sprites
	for(id sprite in dyBlocks){
        if([sprite isTouchedState]) {
          [sprite ccTouchesMoved:touches withEvent:event];
            // show shadow
        }
	}
}
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	
	//Process input for all sprites
	for(id sprite in dyBlocks){
        if([sprite isTouchedState]) {
		   [sprite ccTouchesEnded:touches withEvent:event];
            /*
            //if(in)
              show drop animate
              update data
               win?
             else
               dispear animate
             */
        }
	}
}

@end
