//
//  CondoClass.m
//  Condo Demo
//
//  Created by Cullen O'Neill on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "CondoClass.h"


@implementation CondoClass

@synthesize indexName = _indexName;
@synthesize mySprite = _mySprite;

+ (id)condoClassWithFile:(NSString *)file {
    return [[[self alloc] initCondoClassWithFile:file] autorelease];
}

- (id)initCondoClassWithFile:(NSString *)file {
    
    if ((self=[super init])) {
        
        
        _mySprite = [CCSprite spriteWithFile:file];
        [self addChild:_mySprite];
        
    }
    
    return self;
    
}

- (void)dealloc {
    
    [super dealloc];
}

@end
