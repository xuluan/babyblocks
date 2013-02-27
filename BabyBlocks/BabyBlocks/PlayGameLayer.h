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
    NSMutableArray *sprites;
    int currentSize;
    int currentMode;
    int currentLevel;
    NSDictionary *currentLayout;
    
}

+(id) sceneWithLevel:(int)level withMode:(int)mode withSize:(int)size;
-(id) initWithLevel:(int)level withMode:(int)mode withSize:(int)size;
//-(void) loadLevel:(NSString*)str;
//-(void) processSpriteFile:(NSDictionary*)node;
-(void) quit:(id)sender;
-(void) initColorBox;
-(void) drawGridWithOffset:(int)offset;

@end
