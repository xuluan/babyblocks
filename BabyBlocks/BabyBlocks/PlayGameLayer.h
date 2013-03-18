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
#import "SimpleAudioEngine.h"


@interface PlayGameLayer : CCLayer
{
    NSMutableArray *readyBlocks;
    NSMutableArray *usedBlocks;
    TouchableSprite *movingBlock;
    TouchableSprite *newBlock;
    TouchableSprite *pad;
    CCSprite *shadow;
    
    SimpleAudioEngine *sae;


    NSMutableDictionary *soundSources;

    NSMutableArray *hintBlocks;

    int currentStatus;


    int currentSize;
    int currentLevel;
    int currentMaxLevel;

    int lineWidth;
    int borderWidth;
    int interval;

    int cellSize;
    int offsetX;
    int offsetY;
    int positionX;
    int positionY;    
    int offsetX1;
    int offsetY1;
    int offsetX2;
    int offsetY2;    
    CGRect padRect;
    CGSize screenSize;

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
-(void) drawMap:(id)node;
-(void) loadLevel;
-(void) help:(id)sender;
-(void) quit:(id)sender;
-(void) next:(id)sender;
-(void) prev:(id)sender;

-(void) nextLevel;
-(void) prevLevel;
-(void) drawIcon;
-(void) drawBG;
-(bool) isWin;
-(void) removeMapNode:(CGPoint) position;
-(void) dealloc;
-(void) createUsedBlock:(CGPoint)pos;
-(void) addShadow:(CGPoint)point;
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
@end
