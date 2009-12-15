//
//  PBGitHistoryView.h
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitCommit.h"
#import "PBGitTree.h"
#import "PBViewController.h"
#import "PBCollapsibleSplitView.h"
#import <Quartz/Quartz.h> /* for the QLPreviewPanelDataSource et al. stuff */

@class PBQLOutlineView;
@class PBRefController;

@interface PBGitHistoryController : PBViewController <QLPreviewPanelDataSource, QLPreviewPanelDelegate> {
    IBOutlet NSSearchField *searchField;
    IBOutlet NSArrayController* commitController;
    IBOutlet NSTreeController* treeController;
    IBOutlet __weak PBRefController *refController;
    IBOutlet NSTableView* commitList;
    IBOutlet PBQLOutlineView* fileBrowser;
    IBOutlet PBCollapsibleSplitView *historySplitView;
    IBOutlet id webView;
    
    int selectedTab;
    
    PBGitTree* gitTree;
    PBGitCommit* webCommit;
    PBGitCommit* rawCommit;
    PBGitCommit* realCommit;
    
    QLPreviewPanel * previewPanel;
}

@property (assign) int selectedTab;
@property (retain) PBGitCommit *webCommit, *rawCommit;
@property (retain) PBGitTree* gitTree;
@property (readonly) NSArrayController *commitController;

- (IBAction) setDetailedView: sender;
- (IBAction) setRawView: sender;
- (IBAction) setTreeView: sender;

- (void) selectCommit: (NSString*) commit;
- (IBAction) refresh: sender;
- (IBAction) toggleQuickView: sender;
- (IBAction) openSelectedFile: sender;
- (void) updateQuicklookForce: (BOOL) force;

// Context menu methods
- (NSMenu *)contextMenuForTreeView;
- (NSArray *)menuItemsForPaths:(NSArray *)paths;
- (void)showCommitsFromTree:(id)sender;
- (void)showInFinderAction:(id)sender;
- (void)openFilesAction:(id)sender;

// Repository menu methods
- (IBAction) fetchDefaultRemote:(id)sender;
- (IBAction) pullDefaultRemote:(id)sender;
- (IBAction) rebaseDefaultRemote:(id)sender;
- (IBAction) pushDefaultRemote:(id)sender;
- (IBAction) createBranch:(id)sender;
- (IBAction) createTag:(id)sender;
- (IBAction) addRemote:(id)sender;

- (void) copyCommitInfo;

- (BOOL) hasNonlinearPath;

- (NSMenu *)tableColumnMenu;

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview;
- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex;
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset;
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset;

@end
