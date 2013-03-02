#import "cocos2d.h"





@interface TouchableSprite : CCSprite
{
    bool isTouched;				//Are we touching this currently?
    
}

@property (readwrite, assign) int touchedState;

-(id) init;
-(CGRect) rect;
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(bool) isTouchedState;
@end

//Implementation
@implementation TouchableSprite

@synthesize touchedState;

-(id) init {
    isTouched = YES;
		
	return [super init];
}

- (void) dealloc
{    
	[super dealloc];
}

-(bool) isTouchedState
{
    return isTouched;
}

- (CGRect) rect {
	float scaleMod = 1.0f;
	float w = [self contentSize].width * [self scale] * scaleMod;
	float h = [self contentSize].height * [self scale] * scaleMod;
	CGPoint point = CGPointMake([self position].x - (w/2), [self position].y - (h/2));
	
	return CGRectMake(point.x, point.y, w, h); 
}

/* Process touches */
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
    isTouched = YES;
	
}
-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {	
	if(!isTouched){ return; }
	
	UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];		

    self.position = point;
}
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {	
	if(!isTouched){ return; }
	
	UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
    self.position = point;
    isTouched = NO;


}

@end