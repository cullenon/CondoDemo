//
//  CondoClass.h
//  Condo Demo
//
//  Created by Cullen O'Neill on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CondoClass : CCNode {
    
}

@property (retain) NSString *indexName;
@property (assign) CCSprite *mySprite;

+ (id)condoClassWithFile:(NSString *)file;
- (id)initCondoClassWithFile:(NSString *)file;

@end
