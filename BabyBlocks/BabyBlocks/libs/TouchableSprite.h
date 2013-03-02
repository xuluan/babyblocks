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
