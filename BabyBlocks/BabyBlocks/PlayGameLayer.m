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


enum {
	Z_BG = -1,
	Z_LAYER = 0,
	Z_ICON = 2,
	Z_BLOCK = 5,
	Z_SHADOW = 8,
	Z_BLOCK_MOVING = 10
};

enum {
    TAG_SHADOW = 1000,
    TAG_EFFECT_NODE = 2000
};

static ccColor3B colors[] = {
	{255,0,0},   // red
    {255,255,0}, // yellow
    {0,255,0},  // green
    {0,0,255},   //blue
    {255,127,0},  //orange
    {127,127,127}  //shadow
   
};
/*
static NSString* colors_name[] = {
	@"red",   // red
    @"yellow", // yellow
    @"green",  // green
    @"blue",   //blue
    @"orange",  //orange
    @"shadow"  //shadow
    
};
*/
static NSString* colors_name[] = {
	@"red",   // red
    @"red", // yellow
    @"red",  // green
    @"red",   //blue
    @"red",  //orange
    @"shadow"  //shadow
};

static float scale_per_size[] = { 0.0, 0.0, 0.0, 1.0, 0.0, 0.75, 0.0, 0.625, 0.0, 0.0, 0.5 };
static float scale2_per_size[] = { 0.0, 0.0, 0.0, 1.2, 0.0, 0.9, 0.0, 0.7, 0.0, 0.0, 0.6 };

bool pointIsInRect(CGPoint p, CGRect r){
	bool isInRect = false;
	if( p.x < r.origin.x + r.size.width &&
	   p.x > r.origin.x &&
	   p.y < r.origin.y + r.size.height &&
	   p.y > r.origin.y )
	{
		isInRect = true;
	}
	return isInRect;
}

float qDistance(CGPoint p1, CGPoint p2){
	return abs(p1.x-p2.x) + abs(p1.y-p2.y);
}

@implementation PlayGameLayer

+(id) sceneWithSettings:(NSMutableDictionary *)settings
{
	//Create our scene
	CCScene *s = [CCScene node];

	PlayGameLayer *node = [[PlayGameLayer alloc] initWithSettings:settings];
	[s addChild:node z:Z_LAYER tag:0];
	return s;
}


-(id) initWithSettings:(NSMutableDictionary *)settings
{
    screenSize = [[CCDirector sharedDirector] winSize];
    currentSettings = settings;
    NSLog(@"settings %@\n", settings);
    NSLog(@"current %@\n", currentSettings);
    currentSize = [[currentSettings objectForKey:@"current_size"] intValue];
    NSString *size_key = [NSString stringWithFormat:@"%d", currentSize];
    currentLevel = [[[currentSettings objectForKey:size_key] objectForKey:@"current_level"] intValue];
    currentMaxLevel = [[[currentSettings objectForKey:size_key] objectForKey:@"max_level"] intValue];
    
    NSLog(@"currentLevel %d, currentSize %d \n",currentLevel, currentSize);

	if( (self=[super init] )) {
        self.isTouchEnabled = YES;
        movingBlock = nil;

        //init map data 
        [self initMap];

        //load layout settings according to currentSize
        [self loadLayout];
        
        //init and draw readyBlocks
        [self initReadyBox];

        //draw pad
        [self drawPad:(screenSize.width/2)];
        [self drawPad:(0)];
        
		//Load level, draw map and update map data
		[self loadLevel];

		//Quit button, prev, next, hint, ...
        [self drawIcon];

        //draw background
        [self drawBG];

	}
	return self;
}

-(void)initMap
{

    currentMap = [[NSMutableDictionary alloc] init];

    for(int x=0; x<currentSize; x++){
        for(int y=0; y<currentSize; y++){
            NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];
            NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
            [d setValue:nil forKey:@"exp"];
            [d setValue:nil forKey:@"now"];
            [currentMap setValue:d forKey:pos];

        }
    }
}

-(void) loadLayout {
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:getActualPath(@"layout.json") encoding:NSUTF8StringEncoding error:nil];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary *dict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    NSString *usingSize = [NSString stringWithFormat:@"%d",currentSize];
    currentLayout = [dict objectForKey:usingSize];
    cellSize = [[currentLayout objectForKey:@"interval"] intValue];

    offsetX = [[currentLayout objectForKey:@"offset_x"] intValue];
    offsetY = [[currentLayout objectForKey:@"offset_y"] intValue];
    lineWidth = [[currentLayout objectForKey:@"line_width"] intValue];    
    borderWidth = [[currentLayout objectForKey:@"border_width"] intValue];    
    interval = lineWidth + cellSize;
    positionX = offsetX + borderWidth + (currentSize*interval+lineWidth)/2;
    positionY = offsetY + borderWidth + (currentSize*interval+lineWidth)/2;
    offsetX1 = offsetX + borderWidth + (interval+lineWidth)/2;
    offsetY1 = offsetY + borderWidth + (interval+lineWidth)/2;
    offsetX2 = offsetX1 + screenSize.width/2;
    offsetX2 = offsetY1;
}

-(void) genNewBlock:(int) color withPosition: (CGPoint) point
{
    NSString* file = [NSString stringWithFormat:@"%@.png", colors_name[color]];
    newBlock = [TouchableSprite spriteWithFile:file];
    //[newBlock setScale:scale_per_size[currentSize]];
    newBlock.position = point;
    newBlock.colorIndex = color;
}

-(void) initReadyBox {
    readyBlocks = [[NSMutableArray alloc] init];
    usedBlocks = [[NSMutableArray alloc] init];
    
    for(int x=0; x<5; x++){
        [self genNewBlock:x withPosition:ccp(x*100+300, screenSize.height-100)];
        [self addChild:newBlock z:Z_BLOCK];
        [readyBlocks addObject:newBlock];
        
    }
}

-(void) drawPad:(int) offset {    
/*    
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
*/
    NSString *pad = [NSString stringWithFormat:@"pad-%d.png",currentSize];
    CCSprite *sprite = [CCSprite spriteWithFile:pad];
    sprite.position = ccp(positionX + offset, positionY);
    [self addChild:sprite z:Z_BG];    
}

-(void)drawMap:(id)node
{
    int x = [[node objectForKey:@"x"] intValue];
    int y = [[node objectForKey:@"y"] intValue];
    int c = [[node objectForKey:@"c"] intValue];
    NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];
    
    [self genNewBlock:c withPosition:ccp(offsetX1+x*interval, offsetY+y*interval)];

    [self addChild:newBlock z:Z_BLOCK];
    [[currentMap objectForKey:pos] setValue:[NSNumber numberWithInt:c] forKey:@"exp"];
    
}

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
    
    /*
    NSString *str2 = [NSString stringWithFormat:@"%d_%d.json", currentSize+1,currentLevel+1];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:str2];
    
    [str2 writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *str3 = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"str3 =%@ \n%@\n  %@\n", filePath , str3 , getActualPath(str));
    */

}

-(void) quit:(id)sender {
    [[CCDirector sharedDirector] popScene];
    [[CCTextureCache sharedTextureCache] removeAllTextures];
}

-(void) drawIcon
{
    //quit
    CCMenuItemFont *quitItem = [CCMenuItemFont itemFromString:@"Quit" target:self selector:@selector(quit:)];
    CCMenu *menu = [CCMenu menuWithItems: quitItem, nil];
    menu.position = ccp(100, screenSize.height - 75);
    [self addChild:menu z:Z_ICON];    

    //next
    //prev
    //hind
}

-(void) drawBG
{
    CCSprite *sprite = [CCSprite spriteWithFile:@"bg.png"];
    sprite.position = ccp(screenSize.width/2, screenSize.height/2);
    [sprite setTextureRect:CGRectMake(0,0,screenSize.width,screenSize.height)];
     [self addChild:sprite z:Z_BG];
    /*
    CGRect repeatRect = CGRectMake(-5000, -5000, 5000, 5000);
    CCSprite* sprite = [CCSprite spriteWithFile:@"bg.png" rect:repeatRect];
    ccTexParams params ={
        GL_LINEAR,
        GL_LINEAR,
        GL_REPEAT,
        GL_REPEAT
    };
    [sprite.texture setTexParameters:&params];
    [self addChild:sprite z:Z_BG];
  */
}

- (void) nextLevel
{
    currentLevel = (currentLevel == currentMaxLevel) ? 1:currentLevel+1;

    NSString *size_key = [NSString stringWithFormat:@"%d", currentSize];
    [[currentSettings objectForKey:size_key] setValue:[NSNumber numberWithInt:currentLevel] forKey:@"current_level"];
    saveSettings(currentSettings);

}

- (void) dealloc
{
    [readyBlocks release];
    [usedBlocks release];
    [currentLayout release];
    [movingBlock release];
	
    [self removeAllChildrenWithCleanup:YES];

	[super dealloc];
}

- (bool) isWin
{
    for (NSString* key in currentMap) {
        NSMutableDictionary* node = [currentMap objectForKey:key];
        if([node objectForKey:@"exp"] != [node objectForKey:@"now"]) {
            //NSLog(@"X %@ %@ %@ \n", key, [node objectForKey:@"exp"], [node objectForKey:@"now"]);
            return NO;
        }

    }
    
    NSLog(@"GOOD\n");
    return YES;
}

- (void) cleanMovingBlock
{
    [self removeChild:movingBlock cleanup:true];
    movingBlock = nil;
}

- (void) cleanMovingBlock2
{
    movingBlock = nil;
}

- (void) backWithBlock
{
    CGPoint point;
    CGPoint point2 = [movingBlock position];
  
    for(id sprite in readyBlocks){
        TouchableSprite *readyblock = sprite;
        if(readyblock.colorIndex == movingBlock.colorIndex){
            NSLog(@" ready block %@\n",  NSStringFromCGPoint([readyblock position]));
            point = [readyblock position];
            break;
        }
    }
     
     [movingBlock runAction: [CCSequence actions:[CCMoveBy actionWithDuration:0.5f position:ccp(point.x - point2.x, point.y- point2.y)],
     [CCScaleTo actionWithDuration:0.1f scale:scale2_per_size[currentSize]],
     [CCScaleTo actionWithDuration:0.2f scale:scale_per_size[currentSize]],
     [CCCallFunc actionWithTarget:self selector:@selector(cleanMovingBlock)], nil] ];

     
}

- (void) dropWithBlock:(TouchableSprite *)block
{
    [block runAction: [CCSequence actions:
                       [CCScaleTo actionWithDuration:0.1f scale:scale2_per_size[currentSize]],
                       [CCScaleTo actionWithDuration:0.2f scale:scale_per_size[currentSize]],
                       [CCCallFunc actionWithTarget:self selector:@selector(cleanMovingBlock2)], nil] ];
}



-(void) createMovingBlock: (TouchableSprite *)block {
    if(movingBlock){ 
    	NSLog(@"assert(false)!!!");
    	return; 
    }
    [self genNewBlock:block.colorIndex withPosition:[block position]];
    
     movingBlock = newBlock;
    
    [self addChild:movingBlock z:Z_BLOCK_MOVING];
}

-(void) createUsedBlock:(createUsedBlock)pos
{

    [self genNewBlock:movingBlock.colorIndex withPosition:pos];
    TouchableSprite *block = newBlock;
    newBlock = nil;
    
    [self addChild:block z:Z_BLOCK_MOVING];
    [usedBlocks addObject:block];
    [self removeChild:movingBlock cleanup:true];

    [self dropWithBlock:block];

}

- (CGPoint) destPosition: (CGPoint) point {
	int x = ((int)point.x + cellSize/2 - offsetX)/cellSize;
	int y = ((int)point.y - offsetY)/cellSize;

    return ccp(offsetX2+x*cellSize,offsetY2+y*cellSize);
}

-(void) addShadow:(CGPoint)point
{
    shadow = [CCSprite spriteWithFile:@"blank.png"];
    [shadow setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    shadow.color = colors[5];
    shadow.position = point;
    [self addChild:shadow z:Z_SHADOW tag:TAG_SHADOW];
}

-(void) removeMapNode:(CGPoint) position
{
    int x = (position.x - offsetX) / cellSize;
    int y = (position.y - offsetY) / cellSize;
    NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];
    [[currentMap objectForKey:pos] setValue:nil forKey:@"now"];
    NSLog(@"rm %d %d\n",x, y);

}

-(void) addMapNode:(CGPoint) pos withColor:(int)c
{
    int x = (pos.x - offsetX2) / interval;
    int y = (pos.y - offsetY2) / interval;
    NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];


    [[currentMap objectForKey:pos] setValue:[NSNumber numberWithInt:c] forKey:@"now"];
    //NSLog(@"ad %@ %d\n", pos, c);
}

-(CCParticleExplosion*) getEffect {
	return [CCParticleExplosion node];
}
-(void) playWin {
	NSString *method = [NSString stringWithFormat:@"getEffect"];
	CCParticleSystem *node = [self performSelector:NSSelectorFromString(method)];
    node.life = 0.2;
    node.autoRemoveOnFinish = YES;
	[self addChild:node z:1 tag:TAG_EFFECT_NODE];
	[node setPosition:ccp(screenSize.width/2, screenSize.height/2)];
}


/* Process touch events */
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if(movingBlock){ return; }

	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	//Process input for all sprites

	for(id sprite in readyBlocks){
		if(pointIsInRect(point, [sprite rect])){
            [self createMovingBlock:sprite];
			return;
		}
	}

	for(id sprite in usedBlocks){
		if(pointIsInRect(point, [sprite rect])){
            [self createMovingBlock:sprite];
            [self removeMapNode:[sprite position]];
            [self removeChild:sprite cleanup:true];
            [usedBlocks removeObject:sprite];
			return;
		}
	}
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!movingBlock) return;
    
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];

	//Process input for all sprites
    if([movingBlock isTouchedState]) {
        if([self getChildByTag:TAG_SHADOW]){
          [self removeChildByTag:TAG_SHADOW cleanup:YES];
        }
        [movingBlock ccTouchesMoved:touches withEvent:event];
        // show shadow
      if(pointIsInRect(point, padRect)){
        CGPoint pos = [self destPosition:point];
          [self addShadow:pos];
      }
    }
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	
    if(movingBlock) {
        [movingBlock ccTouchesEnded:touches withEvent:event];
        if(pointIsInRect(point, padRect)){
            bool overlap = NO;
            CGPoint pos = [self destPosition:point];
            
            if([self getChildByTag:TAG_SHADOW]){
                [self removeChildByTag:TAG_SHADOW cleanup:YES];
            }
            
            for(id sprite in usedBlocks){
                if(CGPointEqualToPoint([ sprite position], pos) ){
                    overlap = YES;
                    break;
                }
            }
            if(!overlap) {
                [self addMapNode:pos withColor:movingBlock.colorIndex];
                [self createUsedBlock:pos];
            } else {
                [self backWithBlock];
            }
            
        } else {
            [self backWithBlock];
        }
        if([self isWin]) {
            [self playWin];
        }
    }
}

@end
