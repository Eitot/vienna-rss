//
//  FolderView.m
//  Vienna
//
//  Created by Steve on Tue Apr 06 2004.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FolderView.h"
#import "ImageAndTextCell.h"
#import "TreeNode.h"
#import "AppController.h"
#import "FoldersFilterable.h"

@interface NSObject (FolderViewDelegate)
	-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags;
	-(BOOL)copyTableSelection:(NSArray *)items toPasteboard:(NSPasteboard *)pboard;
	-(BOOL)canDeleteFolderAtRow:(NSInteger)row;
	-(IBAction)deleteFolder:(id)sender;
	-(void)outlineViewWillBecomeFirstResponder;
@end

@implementation FolderView {
    NSPredicate*            _filterPredicate;
    FoldersFilterableDataSourceImpl* _filterDataSource;
    NSDictionary*           _prefilterState;
    id _directDataSource;
}

-(BOOL)becomeFirstResponder
{
    [(id)self.delegate outlineViewWillBecomeFirstResponder];
	return [super becomeFirstResponder];
}

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder
                              forEvent:(NSEvent *)event
{
    // This prevents the unread count from becoming a responder; it will behave
    // like a view instead of a button.
    if ([((NSButton *)responder).identifier isEqualToString:@"CountButton"]) {
        return NO;
    } else {
        return [super validateProposedFirstResponder:responder forEvent:event];
    }
}

/* draggingSession:sourceOperationMaskForDraggingContext
 * Let the control know the expected behaviour for local and external drags.
 */
-(NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch(context) {
        case NSDraggingContextWithinApplication:
            return NSDragOperationMove|NSDragOperationGeneric;
            break;
        default:
            return NSDragOperationCopy;
    }
}

/* setDataSource
 * Called when the data source changes.
 */
-(void)setDataSource:(id)aSource
{
    _directDataSource = aSource;
    _filterDataSource = [[FoldersFilterableDataSourceImpl alloc] initWithDataSource:aSource];
       super.dataSource = aSource;
}

/* reloadData
 * Called when the user reloads the view data.
 */
-(void)reloadData
{
    if (_filterDataSource && _filterPredicate)
        [_filterDataSource reloadData:self];
	[super reloadData];
}

- (NSPredicate*)filterPredicate {
    return _filterPredicate;
}

- (void)setFilterPredicate:(NSPredicate *)filterPredicate {
    if (_filterPredicate == filterPredicate)
        return;

    if (_filterPredicate == nil) {
        _prefilterState = self.state;
    }

    _filterPredicate = filterPredicate;
    if (_filterDataSource && _filterPredicate){
        [_filterDataSource setFilterPredicate:_filterPredicate outlineView:self];
        super.dataSource = _filterDataSource;
    }
    else{
        super.dataSource = _directDataSource;
    }

    [super reloadData];

    if (_filterPredicate) {
        [self expandItem:nil expandChildren:YES];
        self.selectionState = _prefilterState[@"Selection"];
    }
    else if (_prefilterState) {
        self.state = _prefilterState;
        _prefilterState = nil;
    }
}

// MARK: Responders

// This responder is also declared in NSText and assessible from the Edit menu.
- (void)copy:(id)sender
{
    if (self.selectedRow == -1) {
        return;
    }

    NSInteger numberOfRows = self.numberOfSelectedRows;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:numberOfRows];
    NSIndexSet *selectedRowIndexes = self.selectedRowIndexes;
    NSUInteger item = selectedRowIndexes.firstIndex;
    while (item != NSNotFound) {
        id node = [self itemAtRow:item];
        [array addObject:node];
        item = [selectedRowIndexes indexGreaterThanIndex:item];
    }
    [(id)self.delegate copyTableSelection:array
                             toPasteboard:NSPasteboard.generalPasteboard];
}

// This responder is also declared in NSText and assessible from the Edit menu.
- (void)delete:(id)sender
{
    [APPCONTROLLER deleteFolder:self];
}

// MARK: Overrides

// Stop renaming the folder and restore the current name.
- (void)cancelOperation:(nullable id)sender
{
//    if (backupString) {
//        NSText *editor = [self.window fieldEditor:YES forObject:self];
//        editor.string = backupString;
//    }
//#warning Is this needed?
//    [self reloadData];
}

- (nullable NSMenu *)menuForEvent:(NSEvent *)event
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(outlineView:menuWillAppear:)]) {
        [(id)self.delegate outlineView:self menuWillAppear:event];
    }
    return self.menu;
}

- (void)keyDown:(NSEvent *)event
{
    if (event.characters.length != 1) {
        [super keyDown:event];
    }

    unichar keyChar = [event.characters characterAtIndex:0];
    if ([APPCONTROLLER handleKeyDown:keyChar withFlags:event.modifierFlags]) {
        return;
    }
}

// MARK: - Menu-item validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(copy:)) {
        return self.selectedRow >= 0;
    } else if (menuItem.action == @selector(delete:)) {
        return [(id)self.delegate canDeleteFolderAtRow:self.selectedRow];
    } else if (menuItem.action == @selector(selectAll:)) {
        return YES;
    } else {
        return NO;
    }
}

@end
