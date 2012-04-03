#import "Emergency_EjectAppDelegate.h"

void *kContextActivePanel = &kContextActivePanel;

@implementation Emergency_EjectAppDelegate

@synthesize menubarController = _menubarController;

#pragma mark -

- (void)dealloc
{
    [_menubarController release];
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
    [_panelController release];
    
    [super dealloc];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextActivePanel)
    {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	ejectListener = [[EjectListener alloc] init];
	[ejectListener listenForKeys];
    [self.menubarController = [[MenubarController alloc] init] release];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    self.menubarController = nil;
    
    return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender
{
    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

#pragma mark - Public accessors

- (PanelController *)panelController
{
    if (_panelController == nil)
    {
        _panelController = [[PanelController alloc] initWithDelegate:self];
        [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    }
    return _panelController;
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

@end
