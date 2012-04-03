#import "MenubarController.h"
#import "PanelController.h"
#import "EjectListener.h"

@interface Emergency_EjectAppDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate> {
@private
    MenubarController *_menubarController;
    PanelController *_panelController;
	EjectListener* ejectListener;
}

@property (nonatomic, retain) MenubarController *menubarController;
@property (nonatomic, readonly) PanelController *panelController;

- (IBAction)togglePanel:(id)sender;

@end
