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
#import "SimpleAudioEngine.h"


enum {
	Z_BG = 0,
	Z_LAYER = 10,
	Z_ICON = 20,
	Z_BLOCK = 30,
	Z_SHADOW = 40,
	Z_BLOCK_MOVING = 50,
    Z_HINT = 60    
};

enum {
    TAG_SHADOW = 1000,
    TAG_EFFECT_NODE = 2000
};

enum {
    S_BUSY = 1000,
    S_FREE = 2000
};
static ccColor3B colors[] = {
	{255,0,0},   // red
    {255,255,0}, // yellow
    {0,255,0},  // green
    {0,0,255},   //blue
    {255,127,0},  //orange
    {100,100,100},  //shadow
    {200,200,200}  //pad
   
};

static NSString* colors_name[] = {
	@"red",   // red
    @"yellow", // yellow
    @"green",  // green
    @"blue",   //blue
    @"orange",  //orange
    @"shadow"  //shadow
    
};


static float scale_per_size[] = { 0.0, 0.0, 0.0, 1.0, 0.0, 0.75, 0.0, 0.625, 0.0, 0.5, 0.5 };
static float scale2_per_size[] = { 0.0, 0.0, 0.0, 1.2, 0.0, 0.9, 0.0, 0.7, 0.0, 0.6, 0.6 };

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

- (void) createLevel
{
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

-(id) initWithSettings:(NSMutableDictionary *)settings
{
    screenSize = [[CCDirector sharedDirector] winSize];
    currentSettings = settings;

    currentSize = [[currentSettings objectForKey:@"current_size"] intValue];
    NSString *size_key = [NSString stringWithFormat:@"%d", currentSize];
    currentLevel = [[[currentSettings objectForKey:size_key] objectForKey:@"current_level"] intValue];
    currentMaxLevel = [[[currentSettings objectForKey:size_key] objectForKey:@"max_level"] intValue];
    
	if( (self=[super init] )) {
        self.isTouchEnabled = YES;
        currentStatus = S_FREE;
        //[self initSounds];
        [self createLevel];

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
    cellSize = [[currentLayout objectForKey:@"cell_size"] intValue];

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
    offsetY2 = offsetY1;

    padRect = CGRectMake(offsetX2-interval/2, offsetY2-interval/4,
        interval*currentSize, interval*currentSize);

}

-(void) genNewBlock:(int) color withPosition: (CGPoint) point
{
    NSString* file = [NSString stringWithFormat:@"%@.png", colors_name[color]];
    newBlock = [TouchableSprite spriteWithFile:file];
    [newBlock setScale:scale_per_size[currentSize]];
    newBlock.position = point;
    newBlock.colorIndex = color;
}

-(void) initReadyBox {
    readyBlocks = [[NSMutableArray alloc] init];
    usedBlocks = [[NSMutableArray alloc] init];
    hintBlocks = [[NSMutableArray alloc] init];
    
    for(int x=0; x<5; x++){
        [self genNewBlock:x withPosition:ccp(x*100+300, screenSize.height-100)];
        [self addChild:newBlock z:Z_BLOCK];
        [readyBlocks addObject:newBlock];
        
    }
}

-(void) drawPad:(int) offset
{
    CCSprite *sprite = [CCSprite spriteWithFile:[currentLayout objectForKey:@"pad"]];
    sprite.position = ccp(positionX + offset, positionY);
    sprite.color = ccc3(150,150,50);
    sprite.opacity = 100;
    [self addChild:sprite z:Z_LAYER];
    if(offset)
    {
        /*
        float scaleMod = 1.0f;
        float w = [self contentSize].width * [self scale] * scaleMod;
        float h = [self contentSize].height * [self scale] * scaleMod;
        CGPoint point = CGPointMake([self position].x - (w/2), [self position].y - (h/2));
        
        return CGRectMake(point.x, point.y, w, h);
        */
    }
}

-(void)drawMap:(id)node
{
    int x = [[node objectForKey:@"x"] intValue];
    int y = [[node objectForKey:@"y"] intValue];
    int c = [[node objectForKey:@"c"] intValue];
    NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];
    NSLog(@"draw map node: %@, %d\n", pos, currentLevel);
    
    [self genNewBlock:c withPosition:ccp(offsetX1+x*interval, offsetY1+y*interval)];

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
    NSLog(@"loaclevel map node: %@, %d\n", str, currentLevel);

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

-(void) next:(id)sender {
    [self nextLevel];
}

-(void) prev:(id)sender {
    [self prevLevel];
}

-(void) drawIcon
{
    //prev
    CCMenuItemSprite *prevItem = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"prev.png"]
                                                         selectedSprite:[CCSprite spriteWithFile:@"prev.png"]
                                                         disabledSprite:[CCSprite spriteWithFile:@"prev.png"]
                                                                 target:self selector:@selector(prev:)];
    
    
    CCMenu *prev = [CCMenu menuWithItems: prevItem, nil];
    prev.position = ccp(70, screenSize.height - 100);
    [self addChild:prev z:Z_ICON];
    
    //home
    CCMenuItemSprite *homeItem = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"home.png"]
                            selectedSprite:[CCSprite spriteWithFile:@"home.png"]
                            disabledSprite:[CCSprite spriteWithFile:@"home.png"]
                            target:self selector:@selector(quit:)];
    
    
    CCMenu *home = [CCMenu menuWithItems: homeItem, nil];
    home.position = ccp(160, screenSize.height - 100);
    [self addChild:home z:Z_ICON];
    
    //next
    CCMenuItemSprite *nextItem = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"next.png"]
                                                         selectedSprite:[CCSprite spriteWithFile:@"next.png"]
                                                         disabledSprite:[CCSprite spriteWithFile:@"next.png"]
                                                                 target:self selector:@selector(next:)];
    
    
    CCMenu *next = [CCMenu menuWithItems: nextItem, nil];
    next.position = ccp(950, screenSize.height - 100);
    [self addChild:next z:Z_ICON];
    
    
    //help
    CCMenuItemSprite *helpItem = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"help.png"]
                                                         selectedSprite:[CCSprite spriteWithFile:@"help.png"]
                                                         disabledSprite:[CCSprite spriteWithFile:@"help.png"]
                                                                 target:self selector:@selector(help:)];
    
    
    CCMenu *help = [CCMenu menuWithItems: helpItem, nil];
    help.position = ccp(850, screenSize.height - 100);
    [self addChild:help z:Z_ICON];
    
}

-(void) drawBG
{
    CCSprite *sprite = [CCSprite spriteWithFile:@"bg.png"];
    sprite.position = ccp(screenSize.width/2, screenSize.height/2);
    [sprite setTextureRect:CGRectMake(0,0,screenSize.width,screenSize.height)];
/*/
  CGRect repeatRect = CGRectMake(-5000, -5000, 5000, 5000);
    CCSprite* sprite = [CCSprite spriteWithFile:@"bg1.png" rect:repeatRect];
    ccTexParams params ={
        GL_LINEAR,
        GL_LINEAR,
        GL_REPEAT,
        GL_REPEAT
    };
    [sprite.texture setTexParameters:&params];
 */
    [self addChild:sprite z:Z_BG];
}


-(CDSoundSource*) loadSoundEffect:(NSString*)fn {
    //Pre-load sound
    [sae preloadEffect:fn];

    //Init sound
    CDSoundSource *sound = [[sae soundSourceForFile:fn] retain];
    
    //Add sound to container
    [soundSources setObject:sound forKey:fn];
    
    return sound;
}


-(void) initSounds
{
    [[CDAudioManager sharedManager] setResignBehavior:kAMRBStopPlay autoHandle:YES];
    soundSources = [[NSMutableDictionary alloc] init];
    [self loadSoundEffect:@"crazy_chimp.caf"];


}  

-(void) cleanSounds
{
    for(id s in soundSources){
        //Release source
        CDSoundSource *source = [soundSources objectForKey:s];
        [source release];
    }
    [soundSources release];
}

-(void) cleanLevel
{
    [readyBlocks release];
    [usedBlocks release];
    //[currentLayout release];
    [movingBlock release];
	
    [self removeAllChildrenWithCleanup:YES];
}

- (void) dealloc
{
    [self cleanLevel];
    //[self cleanSounds];

	[super dealloc];
}

-(void) genHintBlock:(CGPoint) point
{
    CCSprite * hint = [CCSprite spriteWithFile:@"wrong.png"];
    hint.position = point;
    [hintBlocks addObject:hint];
    [self addChild:hint z:Z_HINT];
}

- (void) cleanHintBlocks
{
	for(id sprite in hintBlocks){
        [self removeChild:sprite cleanup:true];
	}
    [hintBlocks release];
    hintBlocks = [[NSMutableArray alloc] init];

    currentStatus = S_FREE;
}

- (void) help:(id)sender
{
    currentStatus = S_BUSY;
    for(int x=0; x<currentSize; x++){
        for(int y=0; y<currentSize; y++){
            NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];
            NSMutableDictionary* node = [currentMap objectForKey:pos];
            if([node objectForKey:@"exp"] != [node objectForKey:@"now"]) {
                //show wrong symbol in [x,y] for 5 seconds
                [self genHintBlock:ccp(x*interval+offsetX2, y*interval + offsetY2)];
            }

        }
    }
    
    [self runAction: [CCSequence actions:[CCDelayTime actionWithDuration:5],
                             [CCCallFunc actionWithTarget:self selector:@selector(cleanHintBlocks)], nil] ];
    
    
}
- prevLevel
{
    currentStatus = S_BUSY;
    currentLevel = (currentLevel == 1) ?  currentMaxLevel:currentLevel-1;
    
    NSString *size_key = [NSString stringWithFormat:@"%d", currentSize];
    NSLog(@"%@\n", [currentSettings objectForKey:size_key]);
    NSDictionary *dict = [currentSettings objectForKey:size_key];
    [currentSettings removeObjectForKey:size_key];
    NSMutableDictionary *level = [[NSMutableDictionary alloc ] initWithDictionary:dict];
    
    [level setValue:[NSNumber numberWithInt:currentLevel] forKey:@"current_level"];
    [currentSettings setObject:level forKey:size_key];
    NSLog(@"%@\n", currentSettings);
    
    
    saveSettings(currentSettings);
    [self cleanLevel];
    NSLog(@"nextlevel\n");
    [self createLevel];
    
    currentStatus = S_FREE;
}

- (void) nextLevel
{
    currentStatus = S_BUSY;

    currentLevel = (currentLevel == currentMaxLevel) ? 1:currentLevel+1;

    NSString *size_key = [NSString stringWithFormat:@"%d", currentSize];
    NSLog(@"%@\n", [currentSettings objectForKey:size_key]);
    NSDictionary *dict = [currentSettings objectForKey:size_key];
    NSMutableDictionary *level = [[NSMutableDictionary alloc ] initWithDictionary:dict];
    [currentSettings removeObjectForKey:size_key];
    [level setValue:[NSNumber numberWithInt:currentLevel] forKey:@"current_level"];
    [currentSettings setObject:level forKey:size_key];
    NSLog(@"%@\n", currentSettings);


    saveSettings(currentSettings);
    [self cleanLevel];
    NSLog(@"nextlevel\n");
    [self createLevel];
     
    currentStatus = S_FREE;

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

-(void) playWin {
    currentStatus = S_BUSY;
	NSString *method = [NSString stringWithFormat:@"getEffect"];
	CCParticleSystem *node = [self performSelector:NSSelectorFromString(method)];
    node.life = 3;
    node.autoRemoveOnFinish = YES;
	[self addChild:node z:1 tag:TAG_EFFECT_NODE];
	[node setPosition:ccp(screenSize.width/2, screenSize.height/2)];
    
    [self runAction: [CCSequence actions:[CCDelayTime actionWithDuration:5],
                          [CCCallFunc actionWithTarget:self selector:@selector(nextLevel)], nil] ];
    
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
    [self removeMapNode:[block position]];
}

-(void) createUsedBlock:(CGPoint)pos
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
    
	int x = ((int)point.x + interval/2 - offsetX2)/interval;
	int y = ((int)point.y - offsetY2+ interval/4)/interval;

    return ccp(offsetX2+x*interval,offsetY2+y*interval);
}

-(void) addShadow:(CGPoint)point
{
    shadow = [CCSprite spriteWithFile:@"blank.png"];
    [shadow setTextureRect:CGRectMake(0,0,cellSize,cellSize)];
    shadow.color = colors[5];
    shadow.opacity = 100;
    shadow.position = point;
    [self addChild:shadow z:Z_SHADOW tag:TAG_SHADOW];
}

-(void) removeMapNode:(CGPoint) position
{
    int x = (position.x - offsetX2) / interval;
    int y = (position.y - offsetY2) / interval;
    if( x>=0 && x<currentSize && y>=0 && y<currentSize)
    {
        NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];
        [[currentMap objectForKey:pos] setValue:nil forKey:@"now"];
        NSLog(@"rm %d %d\n",x, y);
    }


}

-(void) addMapNode:(CGPoint) position withColor:(int)c
{
    int x = (position.x - offsetX2) / interval;
    int y = (position.y - offsetY2) / interval;
    NSString *pos = [NSString stringWithFormat:@"%d_%d", x,y];


    [[currentMap objectForKey:pos] setValue:[NSNumber numberWithInt:c] forKey:@"now"];
    //NSLog(@"ad %@ %d\n", pos, c);
}

-(CCParticleExplosion*) getEffect {
	return [CCParticleExplosion node];
}



/* Process touch events */
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"current status %d\n", currentStatus);
	if(movingBlock){ return; }
    if(currentStatus != S_FREE) {return;}
    
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
            [usedBlocks removeObject:sprite];
            [self removeChild:sprite cleanup:true];
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
