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

#import <MumbleKit/MKAudio.h>
#import <MumbleKit/MKConnection.h>

#import "MUAppDelegate.h"
#import "MUConnectSheetController.h"
#import "MUGlobalShortcutController.h"

@interface MUAppDelegate () <MUGlobalShortcutControllerDelegate> {
}
@end

@implementation MUAppDelegate

@synthesize window = _window;
@synthesize serverView = _serverView;
@synthesize webView = _webView;

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {    
    MKAudioSettings settings;
    settings.transmitType = MKTransmitTypeVAD;
	settings.codec = MKCodecFormatCELT;
	settings.quality = 24000;
	settings.audioPerPacket = 10;
	settings.noiseSuppression = -42; /* -42 dB */
	settings.amplification = 20.0f;
	settings.jitterBufferSize = 0; /* 10 ms */
	settings.volume = 1.0;
	settings.outputDelay = 0; /* 10 ms */
	settings.enablePreprocessor = YES;
	settings.enableBenchmark = YES;

	MKAudio *audio = [MKAudio sharedAudio];
	[audio updateAudioSettings:&settings];
	[audio restart];

    MUGlobalShortcutController *gs = [MUGlobalShortcutController sharedController];
    [gs setDelegate:self];

    _logView = [[MULogView alloc] initWithWebView:_webView];
}

- (void) globalShortcutController:(MUGlobalShortcutController *)globalShortcut keyCode:(NSUInteger)keyCode down:(BOOL)isDown {
    
    NSUInteger pttKeyCode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MUPushToTalkKey"] unsignedIntegerValue];

    if (pttKeyCode == keyCode) {
        MKAudio *audio = [MKAudio sharedAudio];
        [audio setForceTransmit:isDown];
    }
}

- (IBAction) showConnectDialog:(id)sender {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *username = [ud objectForKey:@"ConnectDialogUsername"];
    NSString *hostname = [ud objectForKey:@"ConnectDialogHostname"];
    NSInteger port = [[ud objectForKey:@"ConnectDialogPort"] integerValue];
    
    MUConnectSheetController *connSheet = [[MUConnectSheetController alloc] initWithHostname:hostname port:port username:username];
    [connSheet setDelegate:self];
    [connSheet showModalConnectSheetForWindow:_window];
}

- (IBAction) disconnectFromServer:(id)sender {
    [_conn disconnect];
    _conn = nil;
    _model = nil;
}

- (void) connectSheetShouldConnect:(MUConnectSheetController *)connSheet {
    _conn = [[MKConnection alloc] init];
    [_conn setDelegate:self];
    
    _model = [[MKServerModel alloc] initWithConnection:_conn];
    [_model addDelegate:self];
    
    [_conn connectToHost:[connSheet hostname] port:[connSheet port]];
    [_logView addLogEntry:[NSString stringWithFormat:@"Connecting to %@.", [connSheet hostname]]];

    _username = [connSheet username];
    _password = [connSheet password];

    [[NSUserDefaults standardUserDefaults] setObject:_username forKey:@"ConnectDialogUsername"];
    [[NSUserDefaults standardUserDefaults] setObject:[connSheet hostname] forKey:@"ConnectDialogHostname"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[connSheet port]] forKey:@"ConnectDialogPort"];
}

// Connection opened
- (void) connectionOpened:(MKConnection *)conn {
    [_logView addLogEntry:@"Connection established."];
    [conn authenticateWithUsername:_username password:_password];
}

// Connection closed
- (void) connectionClosed:(MKConnection *)conn {
    [_serverView setDataSource:nil];
    [_serverView setDelegate:nil];
    [_serverView reloadItem:nil];
    [_logView addLogEntry:@"Disconnected from server."];
}

// Trust failure
- (void) connection:(MKConnection *)conn trustFailureInCertificateChain:(NSArray *)chain {
    // Ignore trust failures, for now...
    [conn setIgnoreSSLVerification:YES];
    [conn reconnect];
}

// Rejected
- (void) connection:(MKConnection *)conn rejectedWithReason:(MKRejectReason)reason explanation:(NSString *)explanation {
    
}

// Joined server as user!
- (void) serverModel:(MKServerModel *)model joinedServerAsUser:(MKUser *)user {
    _serverViewDelegate = [[MUServerViewDelegate alloc] initWithServerModel:model];
    [_serverView setDelegate:_serverViewDelegate];

    _serverViewDataSource = [[MUServerViewDataSource alloc] initWithServerModel:model];
    [_serverView setDataSource:_serverViewDataSource];

    [_serverView expandItem:nil expandChildren:YES];
    
    [_serverView setTarget:self];
    [_serverView setDoubleAction:@selector(serverViewDoubleClick:)];
}

- (void) serverModel:(MKServerModel *)model userMoved:(MKUser *)user toChannel:(MKChannel *)chan fromChannel:(MKChannel *)prevChan byUser:(MKUser *)mover {
    if (prevChan != nil) {
        NSInteger row = [_serverView rowForItem:prevChan];
        [_serverView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [_serverView reloadItem:prevChan reloadChildren:YES];
        [_serverView isItemExpanded:prevChan];
    }
    NSInteger row = [_serverView rowForItem:chan];
    [_serverView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    [_serverView reloadItem:chan reloadChildren:YES];
    [_serverView isItemExpanded:chan];
    [_serverView expandItem:chan];
}

- (void) serverModel:(MKServerModel *)model userTalkStateChanged:(MKUser *)user {
    NSInteger row = [_serverView rowForItem:user];
    [_serverView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void) serverViewDoubleClick:(id)sender {
    NSInteger row = [_serverView clickedRow];
    id item = [_serverView itemAtRow:row];
    if ([item class] == [MKChannel class]) {
        [_model joinChannel:(MKChannel *)item];
    }
}

@end
