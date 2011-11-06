/* Copyright (C) 2011 Mikkel Krautz <mikkel@krautz.dk>

   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   - Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
   - Neither the name of the Mumble Developers nor the names of its
     contributors may be used to endorse or promote products derived from this
     software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "MUConnectSheetController.h"

@interface MUConnectSheetController () {
    IBOutlet NSWindow                     *_connectSheet;
    IBOutlet NSTextField                  *_hostnameField;
    IBOutlet NSTextField                  *_portField;
    IBOutlet NSTextField                  *_usernameField;
    IBOutlet NSTextField                  *_passwordField;
    IBOutlet NSButton                     *_connectButton;
    IBOutlet NSButton                     *_cancelButton;
    id<MUConnectSheetControllerDelegate>  _delegate;
}
@end

@implementation MUConnectSheetController

- (id) init {
    return [self initWithHostname:nil port:-1 username:nil];
}

- (id) initWithHostname:(NSString *)hostname port:(NSInteger)port username:(NSString *)username {
    if ((self = [super init])) {
        [NSBundle loadNibNamed:@"MUConnectSheet" owner:self];
        
        [_connectSheet setDefaultButtonCell:[_connectButton cell]];
        
        [_connectButton setTarget:self];
        [_connectButton setAction:@selector(connectButtonClicked:)];
        
        [_cancelButton setTarget:self];
        [_cancelButton setAction:@selector(cancelButtonClicked:)];

        if (hostname)
            [_hostnameField setStringValue:hostname];
        if (port > 0)
            [_portField setIntegerValue:port];
        if (username)
            [_usernameField setStringValue:username];
    }
    return self;
}

- (void) setDelegate:(id<MUConnectSheetControllerDelegate>)delegate {
    _delegate = delegate;
}

- (id<MUConnectSheetControllerDelegate>) delegate {
    return _delegate;
}

- (void) connectButtonClicked:(id)sender {
    [NSApp stopModal];
    [NSApp endSheet:_connectSheet];
    [_connectSheet orderOut:self];
    [_delegate connectSheetShouldConnect:self];
}

- (void) cancelButtonClicked:(id)sender {
    [NSApp stopModal];
    [NSApp endSheet:_connectSheet];
    [_connectSheet orderOut:self];
}

- (void) showModalConnectSheetForWindow:(NSWindow *)win {
    [NSApp beginSheet:_connectSheet modalForWindow:win modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    [NSApp runModalForWindow:_connectSheet];
}

- (NSString *) hostname {
    return [_hostnameField stringValue];
}

- (NSInteger) port {
    return [_portField integerValue];
}

- (NSString *) username {
    return [_usernameField stringValue];
}

- (NSString *) password {
    return [_passwordField stringValue];
}

@end
