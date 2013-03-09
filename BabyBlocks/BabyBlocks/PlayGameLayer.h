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
    TouchableSprite *newBlock;
    CCSprite *shadow;

    int currentSize;
    int currentLevel;
    int currentMaxLevel;

    int cellSize;
    int offsetX;
    int offsetY;
    int offsetX2;
    CGRect padRect;


    NSDictionary *currentLayout;
    NSMutableDictionary* currentMap;
    NSMutableDictionary *currentSettings;

    
}

+(id) sceneWithSettings:(NSMutableDictionary *)settings;
-(id) initWithSettings:(NSMutableDictionary *)settings;

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
