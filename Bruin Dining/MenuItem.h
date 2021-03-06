//
//  MenuItem.h
//  UCLA_Dining
//
//  Created by Mahir Eusufzai on 3/26/14.
//  Copyright (c) 2014 Mahir Eusufzai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
typedef enum VegPreference : NSUInteger {
    VegPrefAll,
    VegPrefVegetarian,
    VegPrefVegan
} VegPreference;

@interface MenuItem : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) BOOL isVegetarian;
@property (nonatomic, assign) BOOL isVegan; //added for correctness
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, retain) NSURL *link;

- (id)initWithName:(NSString*)n andURL:(NSString*)url;
- (void)toggleFavorites;
- (void)saveToDatabase;
- (void)removeFromDatabase;
@end
