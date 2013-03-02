//
//  PlayGameLayer.h
//  BabyBlocks
//
//  Created by xuluan on 13-2-26.
//
//
#import "cocos2d.h"
#import "CCLayer.h"
#import "TouchableSprite.h"


@interface PlayGameLayer : CCLayer
{
    NSMutableArray *readyBlocks;
    NSMutableArray *usedBlocks;
    TouchableSprite *movingBlock;
    CCSprite *shadow;

    int currentSize;
    int currentMode;
    int currentLevel;

    int cellSize;
    int offsetX;
    int offsetY;
    int offsetX2;
    CGRect padRect;


    NSDictionary *currentLayout;
    NSMutableDictionary* currentMap;
    
}

+(id) sceneWithLevel:(int)level withMode:(int)mode withSize:(int)size;
-(id) initWithLevel:(int)level withMode:(int)mode withSize:(int)size;

-(void)initMap;
-(void) loadLayout;
-(void) initReadyBox;
-(void) drawPad:(int) offset;
-(void)drawMap:(id)node;
-(void) loadLevel;
-(void) quit:(id)sender;
-(void) drawIcon;
-(void) drawBG;
-(bool) isWin;

- (void) dealloc;
-(void) createUsedBlock:(CGRect)rect;
- (CGRect) destRect: (CGPoint) point;
-(void) addShadow:(CGPoint)point;
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
@end
