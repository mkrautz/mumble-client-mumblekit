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

#import "MULogView.h"

@interface MULogView () {
    WebView *_webView;
}
@end

@implementation MULogView

- (id) initWithWebView:(WebView *)webView {
    if ((self = [super init])) {
        _webView = webView;
        NSString *logViewHtml = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LogView" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
        [_webView setFrameLoadDelegate:self];
        [[_webView mainFrame] loadHTMLString:logViewHtml baseURL:nil];
    }
    return self;
}

- (void) addLogEntry:(NSString *)msg {
    WebScriptObject *scriptObject = [_webView windowScriptObject];
    NSString *timeStamp = [[NSDate  date] descriptionWithCalendarFormat:@"[%H:%M:%S]" timeZone:nil
                                                                  locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
    [scriptObject callWebScriptMethod:@"addLogEntry" withArguments:[NSArray arrayWithObjects:timeStamp, msg, nil]];
}

- (void) webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {
    if (frame == [webView mainFrame]) {
        [self addLogEntry:@"Welcome to Mumble."];
    }
}

@end
