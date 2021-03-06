//
//  EjectListener.m
//  Emergency Eject
//
//  Created by Wil Hall on 4/1/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "EjectListener.h"
#import "CoreFoundation/CoreFoundation.h"
#import "DiskArbitration/DADisk.h"
#import "DiskArbitration/DADissenter.h"
#import "DiskArbitration/DASession.h"
#import <DiskArbitration/DiskArbitration.h>

static CGEventRef receiveEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
static void diskAppeared(DADiskRef disk, void *context);

@implementation EjectListener

@synthesize ejectedDisks;

- (id)init
{
    self = [super init];
    if (self) {
        eventPort = nil;
		eventSource = nil;
		listenThread = nil;
		self.ejectedDisks = [NSMutableArray array];
		daSession = DASessionCreate(kCFAllocatorDefault);
		DASessionScheduleWithRunLoop(daSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    
    return self;
}

-(void)ejectListenThread
{
	listenThread = CFRunLoopGetCurrent();
	CFRunLoopAddSource(listenThread, eventSource, kCFRunLoopCommonModes);
	CFRunLoopRun();
}

static void diskAppeared(DADiskRef disk, void *context) {
	EjectListener* self = context;
	
	//Get the description dictionary
	NSDictionary* desc = (NSDictionary*)DADiskCopyDescription(disk);
	
	bool mountable = [desc objectForKey: (NSString*)kDADiskDescriptionVolumeMountableKey];
	bool ejectable = [desc objectForKey: (NSString*)kDADiskDescriptionMediaEjectableKey];
	NSString* protocol = [desc objectForKey: (NSString*)kDADiskDescriptionDeviceProtocolKey];
	
	//Only proceed if this is an external media partition that is mountable/unmountable
	if(mountable && ejectable && ![protocol isEqualToString:@"SATA"] && ![protocol isEqualToString:@"IDE"]) {
		[self performSelectorOnMainThread:@selector(doDiskEject:) withObject:(void*)disk waitUntilDone:NO];
	}
}

static CGEventRef receiveEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	
	EjectListener* self = refcon;
	
	NSEvent* ejectEvent;
	@try {
		ejectEvent = [NSEvent eventWithCGEvent:event];
	} @catch (NSException * e) {
		return event;
	}
	
	int key = (([ejectEvent data1] & 0xFFFF0000) >> 16);
	if(key != NX_KEYTYPE_EJECT)
		return event;
	
	[ejectEvent retain];
	[self performSelectorOnMainThread:@selector(handleEjectKeyPressed:) withObject:ejectEvent waitUntilDone:NO];
	return NULL;
}

-(void)doDiskEject:(DADiskRef)disk {
	NSDictionary* desc = (NSDictionary*)DADiskCopyDescription(disk);
	if([self.ejectedDisks containsObject:[desc objectForKey: (NSString*)kDADiskDescriptionVolumeNameKey]]) {
		//We need to stop.
		self.ejectedDisks = [[NSMutableArray alloc] init];
		self.ejectedDisks = [NSMutableArray array];
		DAUnregisterCallback(daSession, diskAppeared, self);
	} else {
		@try {
			[self.ejectedDisks addObject:[desc objectForKey: (NSString*)kDADiskDescriptionVolumeNameKey]];
			DADiskUnmount(disk, kDADiskUnmountOptionDefault, NULL, NULL);
		}
		@catch (NSException *exception) {
			
		}
		
	}
}

-(void)handleEjectKeyPressed:(NSEvent*)ejectEvent {
	[ejectEvent autorelease];
	NSLog ( @"Eject Key Pressed" );
	DARegisterDiskAppearedCallback(daSession, NULL, diskAppeared, self);
	
}

-(void)listenForKeys {
	eventPort = CGEventTapCreate(kCGSessionEventTap,
								 kCGHeadInsertEventTap,
								 kCGEventTapOptionDefault,
								 CGEventMaskBit(NX_SYSDEFINED),
								 receiveEvent,
								 self);
	assert(eventPort != NULL);
	
    eventSource = CFMachPortCreateRunLoopSource(kCFAllocatorSystemDefault, eventPort, 0);
	assert(eventSource != NULL);
	
	[NSThread detachNewThreadSelector:@selector(ejectListenThread) toTarget:self withObject:nil];
	
}

@end
