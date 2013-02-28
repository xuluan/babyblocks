//
//  PlayGameLayer.h
//  BabyBlocks
//
//  Created by xuluan on 13-2-26.
//
//
#import "cocos2d.h"

#import "CCLayer.h"

@interface PlayGameLayer : CCLayer
{
    NSMutableArray *newBlocks;
    NSMutableArray *oldBlocks;
    CCSprite *movingBlock;
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
    
}

+(id) sceneWithLevel:(int)level withMode:(int)mode withSize:(int)size;
-(id) initWithLevel:(int)level withMode:(int)mode withSize:(int)size;
-(void) loadLevel:(NSString*)str;
//-(void) processSpriteFile:(NSDictionary*)node;
-(void) quit:(id)sender;
-(void) initColorBox;
-(void) drawGridWithOffset:(int)offset;
-(void) loadLayout;
-(void) drawColoredSpriteAt:(CGPoint)position withRect:(CGRect)rect withColor:(ccColor3B)color withZ:(float)z;

@end
