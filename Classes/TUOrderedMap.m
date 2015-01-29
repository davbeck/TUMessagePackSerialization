//
//  TUOrderedMap.m
//  Pods
//
//  Created by David Beck on 8/24/13.
//
//

#import "TUOrderedMap.h"


@implementation TUOrderedMap
{
    NSMutableOrderedSet *_keys;
    NSMutableDictionary *_objects;
}

#pragma mark - Required override methods

- (id)initWithObjects:(const id[])objects forKeys:(const id < NSCopying >[])keys count:(NSUInteger)count
{
    self = [super init];
    if (self != nil) {
        _keys = [[NSMutableOrderedSet alloc] initWithObjects:keys count:count];
        _objects = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:count];
    }
    
    return self;
}

- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self) {
        _keys = [[NSMutableOrderedSet alloc] initWithCapacity:numItems];
        _objects = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    }
    return self;
}

- (NSUInteger)count
{
    return _keys.count;
}

- (id)objectForKey:(id)aKey
{
    return [_objects objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [_keys objectEnumerator];
}

- (void)setObject:(id)anObject forKey:(id < NSCopying >)aKey
{
    [_keys addObject:aKey];
    [_objects setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
    [_keys removeObject:aKey];
    [_objects removeObjectForKey:aKey];
}


#pragma mark - Optional override methods

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
    [_keys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        id obj = _objects[key];
        
        block(key, obj, stop);
    }];
}

@end
