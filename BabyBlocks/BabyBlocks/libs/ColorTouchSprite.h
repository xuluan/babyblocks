#import "cocos2d.h"


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

@interface StaticSprite : CCSprite
{
    
}

-(CGRect) rect;
@end

@implementation StaticSprite

- (CGRect) rect {
	float scaleMod = 1.0f;
	float w = [self contentSize].width * [self scale] * scaleMod;
	float h = [self contentSize].height * [self scale] * scaleMod;
	CGPoint point = CGPointMake([self position].x - (w/2), [self position].y - (h/2));
	
	return CGRectMake(point.x, point.y, w, h);
}
@end

@interface ColorTouchSprite : CCSprite
{
    bool isTouched;				//Are we touching this currently?
    CCSprite *shadow;
    
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
@implementation ColorTouchSprite

@synthesize touchedState;

-(id) init {
    isTouched = YES;
		
	return [super init];
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