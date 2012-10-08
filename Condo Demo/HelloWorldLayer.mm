//
//  HelloWorldLayer.mm
//  Condo Demo
//
//  Created by Cullen O'Neill on 10/5/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "CondoClass.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

#define kCondoBatchSize 10
#define kMaxCondoCount 10

#define kWhiteCondo 0
#define kRedCondo 1
#define kBlueCondo 2
#define kGreenCondo 3


// source: http://stackoverflow.com/questions/5282254/how-to-grab-a-b2body-and-move-it-around-the-screen-cocos2d-box2d-iphone
class QueryCallback : public b2QueryCallback
{
public:
    QueryCallback(const b2Vec2& point)
    {
        m_point = point;
        m_object = nil;
    }
    
    bool ReportFixture(b2Fixture* fixture)
    {
        if (fixture->IsSensor()) return true; //ignore sensors
        
        bool inside = fixture->TestPoint(m_point);
        if (inside)
        {
            // We are done, terminate the query.
            m_object = fixture->GetBody();
            return false;
        }
        
        // Continue the query.
        return true;
    }
    
    b2Vec2  m_point;
    b2Body* m_object;
};

// HelloWorldLayer implementation
@implementation HelloWorldLayer

//@synthesize bodiesToDestroy = _bodiesToDestroy;
@synthesize condos = _condos;
@synthesize touchCondoData = _touchCondoData;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (void)restartGame {
    
    [[CCDirector sharedDirector] pushScene:[HelloWorldLayer scene]];
    
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// enable touches
		self.isTouchEnabled = YES;
		
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
        
        //create a restart button
        CCMenuItemLabel *restartLbl = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"restart" fontName:@"Marker Felt" fontSize:16] target:self selector:@selector(restartGame)];
        CCMenu *restart = [CCMenu menuWithItems:restartLbl, nil];
        restart.position = ccp(screenSize.width*0.9, screenSize.height*0.75);
        [self addChild:restart];
        
		
		// Define the gravity vector.
		b2Vec2 gravity;
		gravity.Set(0.0f, -20.0f);
		
		// Do we want to let bodies sleep?
		// This will speed up the physics simulation
		bool doSleep = true;
		
		// Construct a world object, which will hold and simulate the rigid bodies.
		_world = new b2World(gravity, doSleep);
		
		_world->SetContinuousPhysics(true);
		
		// Debug Draw functions
		_m_debugDraw = new GLESDebugDraw( PTM_RATIO );
		_world->SetDebugDraw(_m_debugDraw);
		
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
//		flags += b2DebugDraw::e_jointBit;
//		flags += b2DebugDraw::e_aabbBit;
//		flags += b2DebugDraw::e_pairBit;
//		flags += b2DebugDraw::e_centerOfMassBit;
		_m_debugDraw->SetFlags(flags);
		
		// Define the ground body.
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(0, 0); // bottom-left corner
		
		// Call the body factory which allocates memory for the ground body
		// from a pool and creates the ground box shape (also from a pool).
		// The body is also added to the world.
		_groundBody = _world->CreateBody(&groundBodyDef);
		
		// Define the ground box shape.
		b2PolygonShape groundBox;		
		
		// bottom
		groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(screenSize.width/PTM_RATIO,0));
		_bottomFixture = _groundBody->CreateFixture(&groundBox,0);
		
		// top
		//groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO));
		//_groundBody->CreateFixture(&groundBox,0);
		
		// left
		//groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
		//_groundBody->CreateFixture(&groundBox,0);
		
		// right
		//groundBox.SetAsEdge(b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,0));
		//_groundBody->CreateFixture(&groundBox,0);
        
        // Create contact listener
        _contactListener = new MyContactListener();
        _world->SetContactListener(_contactListener);
		
        //create data stores and populate condo array
		_touchCondoData = [[NSMutableDictionary alloc] init];
        _condos = [[CCArray alloc] initWithCapacity:kCondoBatchSize];
        [self resetCondosArray];
        
        _timeGenerator = 0;
        _currentCondoCount = 0;
        
        _condoGeneratorIsOn = YES;
        _gameIsRunning = YES;
		
		_gameLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Combos: %d",_comboCount] fontName:@"Marker Felt" fontSize:32];
		[self addChild:_gameLabel z:0];
		_gameLabel.position = ccp( screenSize.width/2, screenSize.height*0.9);
		
		[self schedule: @selector(tick:)];
        
        
	}
	return self;
}


//uncomment to show box2d debug data
/*
-(void) draw
{
    
    
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states:  GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	_world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

}
//*/

-(void) addNewSpriteWithCoords:(CGPoint)p
{
    b2Body *body = (b2Body*)[[_condos objectAtIndex:_condoindex] pointerValue];
    body->SetTransform(b2Vec2(p.x/PTM_RATIO, p.y/PTM_RATIO),body->GetAngle());
    body->SetActive(true);
    body->ResetMassData();
    
    _condoindex++;
    
    if (_condoindex >= kCondoBatchSize) {
        //reached the end of the array, create a new one
        NSLog(@"reset");
        [self resetCondosArray];
    }
    
}

static int _whiteIndex = 0;
static int _redIndex = 0;
static int _blueIndex = 0;
static int _greenIndex = 0;

- (void)resetCondosArray {
    
    if ([_condos count] > 0) {
        [_condos removeAllObjects];
    }
    
    _condoindex = 0;
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    for (int i = 0; i < kCondoBatchSize; i++) {
        //place the sprites offscreen initially
        CGPoint offscreen = ccp(-screenSize.width/2, 0);
        
        //generate the sprites and color them, index so we can find them later in the touch dictionary
        CondoClass *sprite = [CondoClass condoClassWithFile:@"rectblock.png"];
        [self addChild:sprite];
        
        int color = arc4random_uniform(1000000);
        ccColor3B condoColor;
        if (color < 250000) {
            // @"white";
            condoColor = ccc3(255, 255, 255);
            sprite.tag = kWhiteCondo;
            sprite.indexName = [NSString stringWithFormat:@"%d_%d",kWhiteCondo,_whiteIndex];
            _whiteIndex++;
        } else if (color >= 250000 and color < 500000) {
            // @"red";
            condoColor = ccc3(255, 0, 0);
            sprite.tag = kRedCondo;
            sprite.indexName = [NSString stringWithFormat:@"%d_%d",kRedCondo,_redIndex];
            _redIndex++;
        } else if (color >= 500000 and color < 750000) {
            // @"blue";
            condoColor = ccc3(0, 0, 255);
            sprite.tag = kBlueCondo;
            sprite.indexName = [NSString stringWithFormat:@"%d_%d",kBlueCondo,_blueIndex];
            _blueIndex++;
        } else {
            // @"green";
            condoColor = ccc3(0, 255, 0);
            sprite.tag = kGreenCondo;
            sprite.indexName = [NSString stringWithFormat:@"%d_%d",kGreenCondo,_greenIndex];
            _greenIndex++;
        }
        
        sprite.mySprite.color = condoColor;
        
        
        // Define the dynamic body.
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.angularDamping = 10.0f;
        
        bodyDef.position.Set(offscreen.x/PTM_RATIO, offscreen.y/PTM_RATIO);
        bodyDef.userData = sprite;
        b2Body *body = _world->CreateBody(&bodyDef);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(sprite.mySprite.contentSize.width/(2*PTM_RATIO),(sprite.mySprite.contentSize.height)/(2*PTM_RATIO));//These are mid points of the sprite
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        fixtureDef.density = 50.0f;
        fixtureDef.restitution = 0.0f;
        fixtureDef.friction = 0.1f;
        body->CreateFixture(&fixtureDef);
        body->SetActive(false);
        
        [_condos addObject:[NSValue valueWithPointer:body]];
        
    }
    
}

- (void)didMakeCombo {
    
    // increase combo and update label
    _comboCount++;
    [_gameLabel setString:[NSString stringWithFormat:@"Combos: %d",_comboCount]];
    
}

- (void)didEndGame {
    
    // end condition met, change label
    [_gameLabel setString:[NSString stringWithFormat:@"Game Over! %d combos",_comboCount]];
    _condoGeneratorIsOn = NO;
    _gameIsRunning = NO;
    
}



-(void) tick: (ccTime) dt
{
    if (_currentCondoCount < kMaxCondoCount && _condoGeneratorIsOn) {
        // automatically add new condos if the 
        _timeGenerator += dt;
        if (_timeGenerator > 0.8) {
            CGSize screenSize = [CCDirector sharedDirector].winSize;
            [self addNewSpriteWithCoords:ccp(screenSize.width/2, screenSize.height*0.8)];
            _currentCondoCount++;
            
            _timeGenerator = 0;
        }
        
    }
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	_world->Step(dt, 10, 10);

	//Iterate over the bodies in the physics world
    
    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for (b2Body* b = _world->GetBodyList(); b; b = b->GetNext())
	{
        // continue if the body isn't in the destroy array and has valid user data
		if (std::find(toDestroy.begin(), toDestroy.end(), b) == toDestroy.end() && b->GetUserData() != NULL) {
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			CCSprite *myActor = (CCSprite*)b->GetUserData();
			myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
            
            if (abs(b->GetLinearVelocity().x) >= 5 && !(b->GetContactList()) && _gameIsRunning) {
                //NSLog(@"fast enough!");
                if (std::find(toDestroy.begin(), toDestroy.end(), b)
                    == toDestroy.end()) {
                    toDestroy.push_back(b);
                }
            } 
            
            CGSize screenSize = [CCDirector sharedDirector].winSize;
            
            if ((b->GetPosition().x >= screenSize.width/PTM_RATIO || b->GetPosition().x <= 0) && b->IsActive()) {
                if (std::find(toDestroy.begin(), toDestroy.end(), b) == toDestroy.end()) {
                        toDestroy.push_back(b);
                }
            }
            
		}
        
	}

    
    if (_gameIsRunning) {
        for(pos = _contactListener->_contacts.begin();
            pos != _contactListener->_contacts.end(); ++pos) {
            MyContact contact = *pos;
            
            b2Body *bodyA = contact.fixtureA->GetBody();
            b2Body *bodyB = contact.fixtureB->GetBody();
            
            // loss condition, if a condo touches the bottom of the screen at at angle greater than 15 degrees
            if (contact.fixtureA == _bottomFixture && abs(CC_RADIANS_TO_DEGREES(bodyB->GetAngle())) > 15) {
                [self didEndGame];
            } else if (contact.fixtureB == _bottomFixture && abs(CC_RADIANS_TO_DEGREES(bodyA->GetAngle())) > 15) {
                [self didEndGame];
            }
            
            if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL && bodyA != _groundBody && bodyB != _groundBody) {
                CondoClass *spriteA = (CondoClass *) bodyA->GetUserData();
                CondoClass *spriteB = (CondoClass *) bodyB->GetUserData();
                
                // if condos of the same color are touching each other
                if (spriteA.tag == spriteB.tag) {
                    
                    if ([_touchCondoData objectForKey:spriteA.indexName] && [_touchCondoData objectForKey:spriteB.indexName]) {
                        //Both bodies already in the touching list, check if touching body is one captured in data
                        NSDictionary *dictA = [_touchCondoData objectForKey:spriteA.indexName];
                        b2Body *adjacentA = (b2Body *)[[dictA valueForKey:@"adjacent"] pointerValue];
                        NSDictionary *dictB = [_touchCondoData objectForKey:spriteB.indexName];
                        b2Body *adjacentB = (b2Body *)[[dictB valueForKey:@"adjacent"] pointerValue];
                        if (bodyB != adjacentA || bodyA != adjacentB) {
                            //combo condition met, destroy all adjacent bodies
                            NSLog(@"combo!");
                            if (std::find(toDestroy.begin(), toDestroy.end(), bodyA)
                                == toDestroy.end()) {
                                toDestroy.push_back(bodyA);
                            }
                            if (std::find(toDestroy.begin(), toDestroy.end(), bodyB)
                                == toDestroy.end()) {
                                toDestroy.push_back(bodyB);
                            }
                            if (std::find(toDestroy.begin(), toDestroy.end(), adjacentA)
                                == toDestroy.end()) {
                                toDestroy.push_back(adjacentA);
                            }
                            if (std::find(toDestroy.begin(), toDestroy.end(), adjacentB)
                                == toDestroy.end()) {
                                toDestroy.push_back(adjacentB);
                            }
                            [self didMakeCombo];
                            
                        }
                        
                        
                    } else if ([_touchCondoData objectForKey:spriteA.indexName] && ![_touchCondoData objectForKey:spriteB.indexName]) {
                        //Only body A is in the touching list, check if combo eligible
                        
                        NSDictionary *dict = [_touchCondoData objectForKey:spriteA.indexName];
                        b2Body *adjacent = (b2Body *)[[dict valueForKey:@"adjacent"] pointerValue];
                        if (bodyB != adjacent) {
                            //combo condition met, destroy all adjacent bodies
                            NSLog(@"combo!");
                            if (std::find(toDestroy.begin(), toDestroy.end(), bodyA)
                                == toDestroy.end()) {
                                toDestroy.push_back(bodyA);
                            }
                            if (std::find(toDestroy.begin(), toDestroy.end(), bodyB)
                                == toDestroy.end()) {
                                toDestroy.push_back(bodyB);
                            }
                            if (std::find(toDestroy.begin(), toDestroy.end(), adjacent)
                                == toDestroy.end()) {
                                toDestroy.push_back(adjacent);
                            }
                            [self didMakeCombo];
                            
                        }
                        
                        
                        
                        
                    } else if (![_touchCondoData objectForKey:spriteA.indexName] && [_touchCondoData objectForKey:spriteB.indexName]) {
                        //Only body B is in the touching list, check if combo eligible
                        
                        NSDictionary *dict = [_touchCondoData objectForKey:spriteB.indexName];
                        b2Body *adjacent = (b2Body *)[[dict valueForKey:@"adjacent"] pointerValue];
                        if (bodyA != adjacent) {
                            //combo condition met, destroy all adjacent bodies
                            NSLog(@"combo!");
                            if (std::find(toDestroy.begin(), toDestroy.end(), bodyA)
                                == toDestroy.end()) {
                                toDestroy.push_back(bodyA);
                            }
                            if (std::find(toDestroy.begin(), toDestroy.end(), bodyB)
                                == toDestroy.end()) {
                                toDestroy.push_back(bodyB);
                            }
                            if (std::find(toDestroy.begin(), toDestroy.end(), adjacent)
                                == toDestroy.end()) {
                                toDestroy.push_back(adjacent);
                            }
                            [self didMakeCombo];
                        }
                        
                    } else if (![_touchCondoData objectForKey:spriteA.indexName] && ![_touchCondoData objectForKey:spriteB.indexName]) {
                        //Neither body in the touching list, add both
                        NSDictionary *dictionaryA = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSValue valueWithPointer:bodyA]
                                                     , @"origin"
                                                     , [NSValue valueWithPointer:bodyB]
                                                     , @"adjacent"
                                                     , nil];
                        NSDictionary *dictionaryB = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSValue valueWithPointer:bodyB]
                                                     , @"origin"
                                                     , [NSValue valueWithPointer:bodyA]
                                                     , @"adjacent"
                                                     , nil];
                        [_touchCondoData setObject:dictionaryA forKey:spriteA.indexName];
                        [_touchCondoData setObject:dictionaryB forKey:spriteB.indexName];
                        
                    }
                    
                    
                    
                    
                }
                
            }
        }

        std::vector<b2Body *>::iterator pos2;
        for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
            b2Body *body = *pos2;
            if (body->GetUserData() != NULL) {
                CondoClass *sprite = (CondoClass *) body->GetUserData();
                id remove = [CCCallBlock actionWithBlock:^{
                    [sprite removeFromParentAndCleanup:YES];
                }];
                
                id sequence = [CCSequence actions:[CCFadeOut actionWithDuration:0.2]
                               , [CCDelayTime actionWithDuration:0.21]
                               , remove
                               , nil];
                [sprite.mySprite runAction:sequence];
                if ([_touchCondoData objectForKey:sprite.indexName]) {
                    b2Body *adjacent = (b2Body *)[[[_touchCondoData objectForKey:sprite.indexName] valueForKey:@"adjacent"] pointerValue];
                    CondoClass *adjacentSprite = (CondoClass *)adjacent->GetUserData();
                    if ([_touchCondoData objectForKey:adjacentSprite.indexName]) {
                        [_touchCondoData removeObjectForKey:adjacentSprite.indexName];
                    }
                    
                    
                    [_touchCondoData removeObjectForKey:sprite.indexName];
                    
                }
            }
            _world->DestroyBody(body);
            _currentCondoCount--;
        }
    }
    
    
    
}


static float _staticCondoHeight;

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_mouseJoint != NULL) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    // Make a small box.
    b2AABB aabb;
    b2Vec2 d;
    d.Set(0.001f, 0.001f);
    aabb.lowerBound = locationWorld - d;
    aabb.upperBound = locationWorld + d;
    
    // Query the world for overlapping shapes.
    QueryCallback callback(locationWorld);
    _world->QueryAABB(&callback, aabb);
    
    b2Body *body = callback.m_object;
    if (body)
    {
        //pick the body
        b2MouseJointDef md;
        md.bodyA = _groundBody; 
        md.bodyB = body;
        md.target = locationWorld;
        md.collideConnected = true;
        md.maxForce = 500.0f * body->GetMass();
        
        _mouseJoint = (b2MouseJoint *)_world->CreateJoint(&md);
        //body->SetAwake(true);
        _staticCondoHeight = body->GetPosition().y;
        
        
    }
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_mouseJoint == NULL) return;
    
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, _staticCondoHeight);
    
    _mouseJoint->SetTarget(locationWorld);
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_mouseJoint) {
        _world->DestroyJoint(_mouseJoint);
        _mouseJoint = NULL;
        _staticCondoHeight = nil;
    }
    
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_mouseJoint) {
        _world->DestroyJoint(_mouseJoint);
        _mouseJoint = NULL;
        _staticCondoHeight = nil;
    } else {
        //Add a new body/atlas sprite at the touched location
        /*for( UITouch *touch in touches ) {
            CGPoint location = [touch locationInView: [touch view]];
            
            location = [[CCDirector sharedDirector] convertToGL: location];
            
            [self addNewSpriteWithCoords: location];
        }//*/
    }
    
    
	
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	delete _world;
	_world = NULL;
	
	delete _m_debugDraw;
    delete _contactListener;
    
    [_touchCondoData release]; _touchCondoData = nil;
    [_condos release]; _condos = nil;

	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
