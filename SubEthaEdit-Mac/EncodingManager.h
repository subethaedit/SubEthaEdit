#import <Foundation/Foundation.h>

enum {
    ModeStringEncoding = 0xFFFFFFFE,
    NoStringEncoding = 0xFFFFFFFF
};


@interface EncodingPopUpButton : NSPopUpButton {
    NSStringEncoding defaultEncoding;
    NSStringEncoding selectedEncoding;
    BOOL hasDefaultEntry;
    BOOL hasModeEntry;
}

- (NSStringEncoding)selectedEncoding;
- (void)setSelectedEncoding:(NSStringEncoding)newEncoding;
- (void)setEncoding:(NSStringEncoding)encoding defaultEntry:(BOOL)flag modeEntry:(BOOL)modeFlag lossyEncodings:(NSArray *)encodings;
@end


@interface EncodingMenu : NSMenu {
    SEL action;
}
- (void)configureWithAction:(SEL)aSelector;
@end
    
@interface EncodingManager : NSWindowController {
    @private
    NSArray *encodings;
    NSCountedSet *registeredEncodings;
}

@property (nonatomic, strong) IBOutlet NSMatrix *encodingMatrix;

/* There is just one instance...
*/
+ (instancetype)sharedInstance;

/* List of encodings that should be shown in encoding lists
*/
- (NSArray *)enabledEncodings;

/* Empties then initializes the supplied popup with the supported encodings.
*/
- (void)setupPopUp:(NSPopUpButton *)button selectedEncoding:(unsigned)selectedEncoding withDefaultEntry:(BOOL)flag withModeEntry:(BOOL)modeFlag lossyEncodings:(NSArray *)listOfEncodings;

- (void)setupMenu:(NSMenu *)aMenu action:(SEL)aSelector;

- (IBAction)selectedEncoding:(id)sender;

/* Action methods for bringing up and dealing with changes in the encodings list panel
*/
- (IBAction)encodingListChanged:(id)sender;
- (IBAction)clearAll:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)revertToDefault:(id)sender;
- (void)activateEncoding:(NSStringEncoding)anEncoding;    
/* Internal method to save and communicate changes to the encoding list
*/
- (void)noteEncodingListChange:(BOOL)writeDefault updateList:(BOOL)updateList postNotification:(BOOL)post;

/* Methods to register and unregister currently used enocdings
*/
- (void)registerEncoding:(NSStringEncoding)encoding;
- (void)unregisterEncoding:(NSStringEncoding)encoding;
@end
