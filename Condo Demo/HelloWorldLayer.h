//
//  HelloWorldLayer.h
//  Condo Demo
//
//  Created by Cullen O'Neill on 10/5/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "MyContactListener.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
	b2World *_world;
	GLESDebugDraw *_m_debugDraw;
    b2MouseJoint *_mouseJoint;
    b2Body *_groundBody;
    b2Fixture *_bottomFixture;
    float holdTouchHeight;
    MyContactListener *_contactListener;
    int _condoindex;
    CCLabelTTF *_gameLabel;
    int _comboCount;
    
    BOOL _condoGeneratorIsOn;
    BOOL _gameIsRunning;
    float _timeGenerator;
    int _currentCondoCount;
    
}

@property (retain) CCArray *condos;
@property (retain) NSMutableDictionary *touchCondoData;

// returns a CCScene that contains the HelloWorldLayer as the only child
+ (CCScene *)scene;
// adds a new sprite at a given coordinate
- (void)addNewSpriteWithCoords:(CGPoint)p;
- (void)resetCondosArray;

@end
