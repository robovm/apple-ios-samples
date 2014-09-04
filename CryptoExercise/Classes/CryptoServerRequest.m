/*
 
 File: CryptoServerRequest.m
 Abstract: Handles a server networking request, composed of cryptographic 
 operations, made by a connected client.
 
 Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */

#import "CryptoServer.h"
#import "SecKeyWrapper.h"
#import "CryptoCommon.h"
#import "CryptoServerRequest.h"
#include <CFNetwork/CFSocketStream.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>

static const uint8_t kMessageBodyBytes[] = kMessageBody;

@implementation CryptoServerRequest

@synthesize istr, ostr, peerName, peerPublicKey, delegate;

- (id)initWithInputStream:(NSInputStream *)readStream 
			 outputStream:(NSOutputStream *)writeStream 
					 peer:(NSString *)peerAddress 
				 delegate:(NSObject <CryptoServerRequestDelegate, NSObject> *)anObject {
	
	if (self = [super init]) {
		self.istr = readStream;
		self.ostr = writeStream;
		self.peerName = peerAddress;
		self.peerPublicKey = nil;
		self.delegate = anObject;
	}
	return self;
}

- (void)runProtocol {
	
	LOGGING_FACILITY(self.istr != nil && self.ostr != nil, @"Streams not set up properly." );
	
	if (self.istr && self.ostr) {
		self.istr.delegate = self;
		[self.istr scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self.istr open];
		self.ostr.delegate = self;
		[self.ostr scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self.ostr open];
	}
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventHasSpaceAvailable:
		{
			if (stream == self.ostr) {
				if ([(NSOutputStream *) stream hasSpaceAvailable] && self.peerPublicKey) { 
					[self createBlobAndSend];
				}
			}
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == self.istr) {
				
				NSData * publicKey = [self receiveData];
				[self.istr close];
				
				if (publicKey) {
					self.peerPublicKey = publicKey;
					if ([self.ostr hasSpaceAvailable]) {
						[self createBlobAndSend];
					}
				} else {
					LOGGING_FACILITY( 0, @"Connected Client sent too large of a key." );
					[delegate cryptoServerRequestDidReceiveError:self];
				}
			}
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			// No debugging facility because we don't want to exit even in DEBUG.
			// It's annoying.
			NSLog(@"stream: %@", stream);
			[delegate cryptoServerRequestDidReceiveError:self];
			break;
		}
		default:
			break;
	}
}

- (void)createBlobAndSend {
	size_t sentBytes = 0;
	NSData * cryptoBlob = [self createBlob:self.peerName peerPublicKey:self.peerPublicKey];
	
	if (cryptoBlob) {
		sentBytes = [self sendData:cryptoBlob];
	} else {
		LOGGING_FACILITY(0, @"Something wrong with the building of the crypto blob.\n");
	}
	
	LOGGING_FACILITY1( sentBytes == [cryptoBlob length], @"Only sent %d bytes of crypto blob.", sentBytes );
	
	[self.ostr close];
	
	// Remove ourselves from the mutable container and thereby releasing ourselves.
	[delegate cryptoServerRequestDidFinish:self];
}

- (NSData *)receiveData {
	int len = 0;
	size_t lengthByte = 0;
	NSMutableData * retBlob = nil;
	
	len = [self.istr read:(uint8_t *)&lengthByte maxLength:sizeof(size_t)];
	
	LOGGING_FACILITY1( len == sizeof(size_t), @"Read failure errno: [%d]", errno );
	
	if (lengthByte <= kMaxMessageLength && len == sizeof(size_t)) {
		retBlob = [NSMutableData dataWithLength:lengthByte];
		
		len = [self.istr read:(uint8_t *)[retBlob mutableBytes] maxLength:lengthByte];
		
		LOGGING_FACILITY1( len == lengthByte, @"Read failure, after buffer errno: [%d]", errno );
		
		if (len != lengthByte) {
			retBlob = nil;
		}
	}
	
	return retBlob;
}

- (NSUInteger)sendData:(NSData *)outData {
	size_t len = 0;
	
	if (outData) {
		len = [outData length];
		if (len > 0) {
			size_t longSize = sizeof(size_t);
			
			NSMutableData * message = [[NSMutableData alloc] initWithCapacity:(len + longSize)];
			[message appendBytes:(const void *)&len length:longSize];
			[message appendData:outData];
			
			[self.ostr write:[message bytes] maxLength:[message length]];
			[message release];
		}
	}
	
	return len;
}

- (NSData *)createBlob:(NSString *)peer peerPublicKey:(NSData *)peerKey {
	NSData * message = nil;
	NSString * error = nil;
	CCOptions pad = 0;
	SecKeyRef peerPublicKeyRef = NULL;
	
	NSMutableDictionary * messageHolder = [[NSMutableDictionary alloc] init];
	NSData * symmetricKey = [[SecKeyWrapper sharedWrapper] getSymmetricKeyBytes];
	
	// Build the plain text.
	NSData * plainText = [NSData dataWithBytes:(const void *)kMessageBodyBytes length:(sizeof(kMessageBodyBytes)/sizeof(kMessageBodyBytes[0]))];
	
	// Acquire handle to public key.
	peerPublicKeyRef = [[SecKeyWrapper sharedWrapper] addPeerPublicKey:peer keyBits:peerKey];
	
	LOGGING_FACILITY( peerPublicKeyRef, @"Could not establish client handle to public key." );
	
	if (peerPublicKey) {
	
		// Add the public key.
		[messageHolder	setObject:[[SecKeyWrapper sharedWrapper] getPublicKeyBits]
						  forKey:[NSString stringWithUTF8String:(const char *)kPubTag]];
		
		// Add the signature to the message holder.		
		[messageHolder	setObject:[[SecKeyWrapper sharedWrapper] getSignatureBytes:plainText]
						  forKey:[NSString stringWithUTF8String:(const char *)kSigTag]];
		
		// Add the encrypted message.
		[messageHolder	setObject:[[SecKeyWrapper sharedWrapper] doCipher:plainText key:symmetricKey context:kCCEncrypt padding:&pad] 
						  forKey:[NSString stringWithUTF8String:(const char *)kMesTag]];
		
		// Add the padding PKCS#7 flag.
		[messageHolder	setObject:[NSNumber numberWithUnsignedInt:pad] 
						  forKey:[NSString stringWithUTF8String:(const char *)kPadTag]];
		
		// Add the wrapped symmetric key.
		[messageHolder	setObject:[[SecKeyWrapper sharedWrapper] wrapSymmetricKey:symmetricKey keyRef:peerPublicKeyRef]
						  forKey:[NSString stringWithUTF8String:(const char *)kSymTag]];
		
		message = [NSPropertyListSerialization dataFromPropertyList:messageHolder format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
		
		// All done. Time to remove the public key from the keychain.
		[[SecKeyWrapper sharedWrapper] removePeerPublicKey:peer];
	} else {
		LOGGING_FACILITY(0, @"Could not establish client handle to public key.");
	}
	
	[messageHolder release];
	
	LOGGING_FACILITY( error == nil, error );
	[error release];

	return message;
}

- (void)dealloc {
	[istr removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[istr release];
	
	[ostr removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[ostr release];
	
	[peerName release];
	[peerPublicKey release];
	
	[super dealloc];
}

@end
