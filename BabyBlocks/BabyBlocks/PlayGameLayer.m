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
	Z_SHADOW = 8,
	Z_BLOCK_MOVING = 10
};

static ccColor3B colors[] = {
	{255,0,0},   // red
    {255,255,0}, // yellow
    {0,255,0},  // green
    {0,0,255},   //blue
    {255,127,0},  //orange
    {127,127,127}  //shadow
   
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
        movingBlock = nil;
        [self loadLayout];

        
		//background
        [self drawColoredSpriteAt:ccp(0,0) withRect:CGRectMake(0,0,sz.width*2,sz.height*2) withColor:ccc3(150,150,200) withZ:Z_BG];

        
        //draw color box
        [self initColorBox];

        [self drawGridWithOffset:(sz.width/2)];
        [self drawGridWithOffset:(0)];
        
		//Load our level
		[self loadLevel];

		//Quit button
		CCMenuItemFont *quitItem = [CCMenuItemFont itemFromString:@"Quit" target:self selector:@selector(quit:)];
		CCMenu *menu = [CCMenu menuWithItems: quitItem, nil];
		menu.position = ccp(100, sz.height - 75);
		[self addChild:menu z:Z_ICON];
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

    if(offset > 0) {
	    offsetX = offset + offset_x;
        offsetX2 = offset_x;
	    cellSize = interval;
	    offsetY = offset_y;
	    padRect = CGRectMake(offsetX - cellSize/2, offsetY, cellSize * currentSize, cellSize * currentSize);
    }

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
	newBlocks = [[NSMutableArray alloc] init];
    oldBlocks = [[NSMutableArray alloc] init];
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    for(int x=0; x<5; x++){
		StaticSprite *sprite = [StaticSprite spriteWithFile:@"blank.png"];
        
		sprite.position = ccp(x*100+300, size.height-75);
		[sprite setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
		sprite.color = colors[x];
		[self addChild:sprite z:Z_BLOCK];
		[newBlocks addObject:sprite];
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
    cellSize = [[currentLayout objectForKey:@"interval"] intValue];

}

-(void)drawMap:(id)node
{
    int x = [[node objectForKey:@"x"] intValue];
    int y = [[node objectForKey:@"y"] intValue];
    int c = [[node objectForKey:@"c"] intValue];
    
    CCSprite *sprite = [CCSprite spriteWithFile:@"blank.png"];
    sprite.position = ccp(offsetX2+x*cellSize, offsetY+y*cellSize);
    [sprite setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    sprite.color = colors[c];
    [self addChild:sprite z:Z_BLOCK];


}

//Load level file and process sprites
-(void) loadLevel
{
    NSString *str = [NSString stringWithFormat:@"%d_%d.json", currentSize,currentLevel];
	NSString *jsonString = [[NSString alloc] initWithContentsOfFile:getActualPath(str) encoding:NSUTF8StringEncoding error:nil];
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
	NSDictionary *dict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    
	NSArray *map = [dict objectForKey:@"map"];

	for (id node in map) {
        [self drawMap:node];
	}
}



// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    [newBlocks release];
    [oldBlocks release];
    [currentLayout release];
    [movingBlock release];
	
    [self removeAllChildrenWithCleanup:YES];
    
	// don't forget to call "super dealloc"
    
	[super dealloc];
}
-(void) createMovingBlock: (StaticSprite *)block {
    if(movingBlock){ 
    	NSLog("assert(false)!!!");
    	return; 
    }

    movingBlock = [ColorTouchSprite spriteWithFile:@"blank.png"];
    
    movingBlock.position = [block position];
    [movingBlock setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    movingBlock.color = [block color];
    [self addChild:movingBlock z:Z_BLOCK_MOVING];
}

-(void) createOldBlock:(CGRect)rect
{

    StaticSprite *sprite = [ColorTouchSprite spriteWithFile:@"blank.png"];
    
    sprite.position = rect.origin;
    [sprite setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    sprite.color = [movingBlock color];
    [self addChild:sprite z:Z_BLOCK_MOVING];
    [oldBlocks addObject:sprite];
    [self removeChild:movingBlock cleanup:true];
    movingBlock = nil;
}

- (CGRect) destRect: (CGPoint) point {
	int x = ((int)point.x + cellSize/2 - offsetX)/cellSize;
	int y = ((int)point.y - offsetY)/cellSize;

	return CGRectMake(offsetX+x*cellSize,offsetY+y*cellSize, offsetX+(x+1)*cellSize-1, offsetY+(y+1)*cellSize-1);
}

/* Process touch events */
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if(movingBlock){ return; }

	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	//Process input for all sprites
	for(id sprite in newBlocks){
		if(pointIsInRect(point, [sprite rect])){
            [self createMovingBlock:sprite];
			return;
		}
	}

	for(id sprite in oldBlocks){
		if(pointIsInRect(point, [sprite rect])){
            [self createMovingBlock:sprite];
            [self removeChild:sprite cleanup:true];
            [oldBlocks removeObject:sprite];
			return;
		}
	}
}

-(void) addShadow:(CGPoint)point
{
    shadow = [CCSprite spriteWithFile:@"blank.png"];
    shadow.position = ccp(0, 0);
    [shadow setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    shadow.color = colors[5];
    shadow.position = point;
    [self addChild:shadow z:Z_SHADOW tag:1000];
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];

	//Process input for all sprites
    if([movingBlock isTouchedState]) {
        if([self getChildByTag:1000]){
          [self removeChildByTag:1000 cleanup:YES];
        }
        [movingBlock ccTouchesMoved:touches withEvent:event];
        // show shadow
      if(pointIsInRect(point, padRect)){
        CGRect rect = [self destRect:point];
          [self addShadow:rect.origin];
      }else{
          
      }
    }
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	
	//Process input for all sprites
    if([movingBlock isTouchedState]) {
	   [movingBlock ccTouchesEnded:touches withEvent:event];
      if(pointIsInRect(point, padRect)){
      	CGRect rect = [self destRect:point];
          [self createOldBlock:rect];
      	  // show drop animate
          // update data
          // win?
      } else {
      	  //   dispear animatemovingBlock
          [self removeChild:movingBlock cleanup:true];
          movingBlock = nil;
      }
    }
}

@end
