//
//  MainMenuLayer.h
//  BabyBlocks
//
//  Created by xuluan on 13-2-26.
//
//
#import "cocos2d.h"

#import "CCLayer.h"

@interface MainMenuLayer : CCLayer
{
    CCMenu *mainMenu;
  	CCMenu *sizeToChoose;
    int currentSize;
  
}


+(CCScene *) scene;

@end
