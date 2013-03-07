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

static NSString* colors_name[] = {
	@"red",   // red
    @"yellow", // yellow
    @"green",  // green
    @"blue",   //blue
    @"orange",  //orange
    @"shadow"  //shadow
    
};

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

        //init map data 
        [self initMap];

        //load layout settings according to currentSize
        [self loadLayout];
        
        //init and draw readyBlocks
        [self initReadyBox];

        //draw pad
        [self drawPad:(sz.width/2)];
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

}

-(NSString *) getBlockFileName:(int) color
{
    return  [NSString stringWithFormat:@"%@-%d.png", colors_name, currentSize];
}

-(void) initReadyBox {
    readyBlocks = [[NSMutableArray alloc] init];
    usedBlocks = [[NSMutableArray alloc] init];
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    for(int x=0; x<5; x++){
        TouchableSprite *sprite = [TouchableSprite spriteWithFile:@"red-3.png"];
        
        sprite.position = ccp(x*100+300, size.height-75);
        [sprite setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
        //sprite.color = colors[x];
        [self addChild:sprite z:Z_BLOCK];
        [readyBlocks addObject:sprite];
    }
}

-(void) drawPad:(int) offset {    
    
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

-(void)drawMap:(id)node
{
    int x = [[node objectForKey:@"x"] intValue];
    int y = [[node objectForKey:@"y"] intValue];
    int c = [[node objectForKey:@"c"] intValue];
    NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];

    CCSprite *sprite = [CCSprite spriteWithFile:@"blank.png"];
    sprite.position = ccp(offsetX2+x*cellSize, offsetY+y*cellSize);
    [sprite setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    sprite.color = colors[c];
    [self addChild:sprite z:Z_BLOCK];
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
    CGSize sz = [[CCDirector sharedDirector] winSize];
    CCMenuItemFont *quitItem = [CCMenuItemFont itemFromString:@"Quit" target:self selector:@selector(quit:)];
    CCMenu *menu = [CCMenu menuWithItems: quitItem, nil];
    menu.position = ccp(100, sz.height - 75);
    [self addChild:menu z:Z_ICON];    
}

-(void) drawBG
{
    CGSize sz = [[CCDirector sharedDirector] winSize];

    CCSprite *sprite = [CCSprite spriteWithFile:@"blank.png"];
    
    sprite.position = ccp(sz.width/2, sz.height/2);
    [sprite setTextureRect:CGRectMake(0,0,sz.width,sz.height)];
    sprite.color = ccc3(150,150,200);
    [self addChild:sprite z:Z_BG];
  
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

-(void) createMovingBlock: (TouchableSprite *)block {
    if(movingBlock){ 
    	NSLog(@"assert(false)!!!");
    	return; 
    }

    movingBlock = [TouchableSprite spriteWithFile:@"red-3.png"];
    
    movingBlock.position = [block position];
    [movingBlock setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    //movingBlock.color = [block color];
    [self addChild:movingBlock z:Z_BLOCK_MOVING];
}

-(void) createUsedBlock:(CGRect)rect
{

    TouchableSprite *sprite = [TouchableSprite spriteWithFile:@"red-3.png"];
    
    sprite.position = rect.origin;
    [sprite setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    //sprite.color = [movingBlock color];
    [self addChild:sprite z:Z_BLOCK_MOVING];
    [usedBlocks addObject:sprite];
    [self removeChild:movingBlock cleanup:true];
    movingBlock = nil;
}

- (CGRect) destRect: (CGPoint) point {
	int x = ((int)point.x + cellSize/2 - offsetX)/cellSize;
	int y = ((int)point.y - offsetY)/cellSize;

	return CGRectMake(offsetX+x*cellSize,offsetY+y*cellSize, offsetX+(x+1)*cellSize-1, offsetY+(y+1)*cellSize-1);
}

-(void) addShadow:(CGPoint)point
{
    shadow = [CCSprite spriteWithFile:@"blank.png"];
    shadow.position = ccp(0, 0);
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

-(void) addMapNode:(CGRect) rect withColor:(ccColor3B)cc
{
    int x = (rect.origin.x - offsetX) / cellSize;
    int y = (rect.origin.y - offsetY) / cellSize;
    NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];

    for(int i = 0; i < 5; i++)
    {
        ccColor3B c = colors[i];
        if(c.r == cc.r && c.g == cc.g && c.b == cc.b){
            [[currentMap objectForKey:pos] setValue:[NSNumber numberWithInt:i] forKey:@"now"];
            NSLog(@"ad %@ %d\n", pos, i);
            return;

        }
    }
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
    CGSize sz = [[CCDirector sharedDirector] winSize];

	[node setPosition:ccp(sz.width/2, sz.height/2)];

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
        CGRect rect = [self destRect:point];
          [self addShadow:rect.origin];
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
      bool overlap = NO;
      CGRect rect = [self destRect:point];

        if([self getChildByTag:TAG_SHADOW]){
           [self removeChildByTag:TAG_SHADOW cleanup:YES];
        }

            for(id sprite in usedBlocks){
                if(CGPointEqualToPoint([ sprite position], rect.origin) ){
                    overlap = YES;
                    break;
                }
            }
            if(!overlap) {
              [self addMapNode:rect withColor:movingBlock.color];
              [self createUsedBlock:rect];
            } else {
              //animate
              [self removeChild:movingBlock cleanup:true];
              movingBlock = nil;
            }


        // show drop animate
        // update data
        // win?
    } else {
        //   dispear animatemovingBlock
          [self removeChild:movingBlock cleanup:true];
          movingBlock = nil;
    }

      if([self isWin]) {
        // show animate
        // menu, play again, play another
          [self playWin];

      }
    }
}

@end
