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
    NSMutableArray *_keys;
    NSMutableArray *_objects;
}

#pragma mark - Required override methods

- (id)initWithObjects:(const id[])objects forKeys:(const id < NSCopying >[])keys count:(NSUInteger)count
{
    self = [super init];
    if (self != nil) {
        _keys = [[NSMutableArray alloc] initWithObjects:keys count:count];
        _objects = [[NSMutableArray alloc] initWithObjects:objects count:count];
    }
    
    return self;
}

- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self) {
        _keys = [[NSMutableArray alloc] initWithCapacity:numItems];
        _objects = [[NSMutableArray alloc] initWithCapacity:numItems];
    }
    return self;
}

- (NSUInteger)count
{
    return _keys.count;
}

- (id)objectForKey:(id)aKey
{
    NSInteger index = [_keys indexOfObject:aKey];
    
    if (index != NSNotFound) {
        return [_objects objectAtIndex:index];
    }
    
    return nil;
}

- (NSEnumerator *)keyEnumerator
{
    return [_keys objectEnumerator];
}

- (void)setObject:(id)anObject forKey:(id < NSCopying >)aKey
{
    [_keys addObject:aKey];
    [_objects addObject:anObject];
}

- (void)removeObjectForKey:(id)aKey
{
    NSInteger index = [_keys indexOfObject:aKey];
    
    if (index != NSNotFound) {
        [_keys removeObjectAtIndex:index];
        [_objects removeObjectAtIndex:index];
    }
}


#pragma mark - Optional override methods

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
    [_keys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        id obj = _objects[idx];
        
        block(key, obj, stop);
    }];
}

@end
