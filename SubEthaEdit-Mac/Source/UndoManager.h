//  UndoManager.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 12 2004.

#import <Foundation/Foundation.h>


extern NSString * const UndoManagerCheckpointNotification;
extern NSString * const UndoManagerDidOpenUndoGroupNotification;
extern NSString * const UndoManagerDidRedoChangeNotification;
extern NSString * const UndoManagerDidUndoChangeNotification;
extern NSString * const UndoManagerWillCloseUndoGroupNotification;
extern NSString * const UndoManagerWillRedoChangeNotification;
extern NSString * const UndoManagerWillUndoChangeNotification;

@class TCMMMOperation, PlainTextDocument, UndoGroup;

@interface UndoGroup : NSObject 

@property (nonatomic, copy) NSString *actionName;
@property (nonatomic, readonly) NSMutableArray *actions;
@property (nonatomic, readonly) UndoGroup *parent;

- (instancetype)initWithParent:(UndoGroup *)parent;

@end

@interface UndoManager : NSObject {
    __weak PlainTextDocument *_document;

    NSMutableArray *_undoStack;
    NSMutableArray *_redoStack;
    
    UndoGroup *_undoGroup;
    UndoGroup *_redoGroup;
    __weak id _preparedInvocationTarget;
    
    struct {
        unsigned int undoing;
        unsigned int redoing;
        unsigned int internal;
        int automaticGroupLevel;
        BOOL isPerformingGroup;
    } _flags;
}

        /* Begin/End Grouping */

- (void)beginUndoGrouping;
- (void)endUndoGrouping;
    // These nest.

- (int)groupingLevel;
    // Zero means no open group.

        /* Enable/Disable registration */

- (void)disableUndoRegistration;
- (void)enableUndoRegistration;
- (BOOL)isUndoRegistrationEnabled;

        /* Groups By Event */

- (BOOL)groupsByEvent;
- (void)setGroupsByEvent:(BOOL)groupsByEvent;
    // If groupsByEvent is enabled, the undoManager automatically groups
    // all undos registered during a single NSRunLoop event together in
    // a single top-level group. This featured is enabled by default.

        /* Undo levels */

- (void)setLevelsOfUndo:(unsigned)levels;
- (unsigned)levelsOfUndo;
    // Sets the number of complete groups (not operations) that should
    // be kept my the manager.  When limit is reached, oldest undos are
    // thrown away.  0 means no limit !

        /* Run Loop Modes */

- (void)setRunLoopModes:(NSArray *)runLoopModes;
- (NSArray *)runLoopModes;

        /* Undo/Redo */

- (void)undo;
    // Undo until a matching begin. It terminates a top level undo if
    // necesary. Useful for undoing when groupByEvents is on (default is
    // on)
- (void)redo;
    // Will redo last top-level undo.

- (void)undoNestedGroup;
    // Undoes a nested grouping without first trying to close a top level
    // undo group.

- (BOOL)canUndo;
- (BOOL)canRedo;
    // returns whether or not the UndoManager has anything to undo or redo

- (BOOL)isPerformingGroup; // mainly to decide when to take changes seriously for state changes like blockedit and stuff
- (BOOL)isUndoing;
- (BOOL)isRedoing;
    // returns whether or not the undo manager is currently in the process
    // of invoking undo or redo operations.

        /* remove */

- (void)removeAllActions;

- (void)removeAllActionsWithTarget:(id)target;
    // Should be called from the dealloc method of any object that may have
    // registered as a target for undo operations

        /* Object based Undo */

- (void)registerUndoWithTarget:(id)target selector:(SEL)selector object:(id)anObject;

        /* Invocation based undo */

- (id)prepareWithInvocationTarget:(id)target;
   // called as:
   // [[undoManager prepareWithInvocationTarget:self] setFont:oldFont color:oldColor]
   // When undo is called, the specified target will be called with
   // [target setFont:oldFont color:oldColor]

- (void)forwardInvocation:(NSInvocation *)anInvocation;

    	/* Undo/Redo action name */

- (NSString *)undoActionName;
- (NSString *)redoActionName;
    // Call undoActionName or redoActionName to get the name of the next action to be undone or redone.
    // Returns @"" if there is nothing to undo/redo or no action names were registered.

- (void)setActionName:(NSString *)actionName;
    // Call setActionName: to set the name of an action.
    // The actionName parameter can not be nil

    	/* Undo/Redo menu item title */

- (NSString *)undoMenuItemTitle;
- (NSString *)redoMenuItemTitle;
    // Call undoMenuItemTitle or redoMenuItemTitle to get the string for the undo or redo menu item.
    // In English they will return "Undo <action name>"/"Redo <action name>" or "Undo"/"Redo" if there is
    // nothing to undo/redo or no action names were set.

    	/* localization hooks */

- (NSString *)undoMenuTitleForUndoActionName:(NSString *)actionName;
- (NSString *)redoMenuTitleForUndoActionName:(NSString *)actionName;
    // The localization of the pattern is usually done by localizing the string patterns in
    // undo.strings. But undo/redoMenuTitleForUndoActionName can also be overridden if
    // localizing the pattern happens to not be sufficient.

#pragma mark -

- (instancetype)initWithDocument:(PlainTextDocument *)document;
- (void)performUndoGroup:(UndoGroup *)group;
- (void)registerUndoChangeTextInRange:(NSRange)aAffectedCharRange
                    replacementString:(NSString *)aReplacementString  shouldGroupWithPriorOperation:(BOOL)shouldGroup;
- (void)transformStacksWithOperation:(TCMMMOperation *)anOperation;

@end
