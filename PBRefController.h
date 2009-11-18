//
//  PBLabelController.h
//  GitX
//
//  Created by Pieter de Bie on 21-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitHistoryController.h"
#import "PBCommitList.h"
#import "PBGitRef.h"
#import "PBGitCommit.h"
#import "PBRefContextDelegate.h"

@class KBPopUpToolbarItem;
@class PBRefMenuItem;

@interface PBRefController : NSObject <PBRefContextDelegate> {
	IBOutlet __weak PBGitHistoryController *historyController;
	IBOutlet NSArrayController *commitController;
	IBOutlet PBCommitList *commitList;

	IBOutlet NSWindow *newBranchSheet;
	IBOutlet NSTextField *newBranchName;
	IBOutlet NSTextField *errorMessage;
    
	IBOutlet NSWindow *addRemoteSheet;
	IBOutlet NSTextField *addRemoteName;
	IBOutlet NSTextField *addRemoteURL;
	IBOutlet NSTextField *addRemoteErrorMessage;    

	IBOutlet NSWindow *newTagSheet;
	IBOutlet NSTextField *newTagName;
    IBOutlet NSTextView *newTagMessage;
	IBOutlet NSTextField *newTagErrorMessage;
	IBOutlet NSTextField *newTagCommit;
	IBOutlet NSTextField *newTagSHA;
	IBOutlet NSTextField *newTagSHALabel;
    PBGitCommit *cachedCommit;

	IBOutlet NSPopUpButton *branchPopUp;
    IBOutlet KBPopUpToolbarItem *pullItem;
    IBOutlet KBPopUpToolbarItem *pushItem;
    IBOutlet KBPopUpToolbarItem *rebaseItem;
    IBOutlet KBPopUpToolbarItem *fetchItem;
    IBOutlet KBPopUpToolbarItem *checkoutItem;
    
    IBOutlet NSMenu *tableMenu;
}

- (IBAction) fetchCurrentRemote:(id)sender;
- (void) fetchFromRemote:(NSMenuItem *)sender;

- (void) pullRemoteForRef:(PBRefMenuItem *)sender;
- (IBAction) pullCurrentRemote:(id)sender;
- (void) pullFromRemote:(NSMenuItem *)sender;

- (void) pushRemoteForRef:(PBRefMenuItem *)sender;
- (IBAction) pushCurrentRemote:(id)sender;
- (void) pushToRemote:(NSMenuItem *)sender;

- (void) checkoutRef:(PBRefMenuItem *)sender;
- (void) checkoutCommit:(PBRefMenuItem *)sender;
- (void) checkoutFromRef:(NSMenuItem *)sender;

- (void) cherryPick:(PBRefMenuItem *)sender;

- (void) rebaseOnUpstreamRef:(PBRefMenuItem *)sender;
- (void) rebaseOnUpstreamCommit:(PBRefMenuItem *)sender;
- (IBAction) rebaseCurrentBranch:(id)sender;
- (void) rebaseOnUpstreamBranch:(NSMenuItem *)sender;

- (IBAction) showCreateBranchSheet:(id)sender;
- (IBAction) saveNewBranch:(id) sender;
- (IBAction) closeCreateBranchSheet:(id) sender;
- (void) createBranchHere:(PBRefMenuItem *)sender;

- (void) changeBranch:(NSMenuItem *)sender;
- (void) selectCurrentBranch;

- (void) showDeleteRefSheet:(PBRefMenuItem *)sender;

- (IBAction) showCreateTagSheet:(id)sender;
- (IBAction) saveNewTag:(id)sender;
- (IBAction) closeCreateTagSheet:(id)sender;

- (IBAction) showAddRemoteSheet:(id)sender;
- (IBAction) saveNewRemote:(id)sender;
- (IBAction) closeAddRemoteSheet:(id)sender;

- (void) toggleToolbarItems:(NSToolbar *)tb matchingLabels:(NSArray *)labels enabledState:(BOOL)state;

- (NSArray *) menuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit;
- (NSArray *) menuItemsForCommit:(PBGitCommit *)commit;
- (void) updateBranchMenus;

@end
