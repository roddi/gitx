//
//  PBRefMenuItem.h
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRef.h"
#import "PBGitCommit.h"

@interface PBRefMenuItem : NSMenuItem {
	PBGitRef *ref;
	PBGitCommit *commit;
}
	
@property (retain) PBGitCommit *commit;
@property (retain) PBGitRef *ref;

+ (PBRefMenuItem *)addRemoteMethod:(BOOL)isRemote title:(NSString *)title action:(SEL)selector;
+ (NSArray *)defaultMenuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit target:(id)target;
+ (NSArray *) defaultMenuItemsForCommit:(PBGitCommit *)commit target:(id)target;
+ (PBRefMenuItem *)separatorItem;

+ (NSMenu *) pullDownMenuForRemotes:(NSMutableArray *)remoteBranches target:(id)target action:(SEL)action;
+ (NSMenu *) pullDownMenuForLocalBranches:(NSMutableArray *)localBranches remotes:(NSMutableArray *)remoteBranches tags:(NSMutableArray *)tags target:(id)target action:(SEL)action;
+ (NSMenu *) pullDownMenuForLocalBranches:(NSMutableArray *)localBranches remotes:(NSMutableArray *)remoteBranches tags:(NSMutableArray *)tags other:(NSMutableArray *)other target:(id)target action:(SEL)action;

@end
