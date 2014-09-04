/*
 
 File: SecKeyWrapper.h
 Abstract: Core cryptographic wrapper class to exercise most of the Security 
 APIs on the iPhone OS. Start here if all you are interested in are the 
 cryptographic APIs on the iPhone OS.
 
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

#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

/* Begin global declarations */

// Global constants used for symmetric key algorithm choice and
// chosen digest.

// The chosen symmetric key and digest algorithm chosen for this sample is AES and SHA1.
// The reasoning behind this was due to the fact that the iPhone and iPod touch have
// hardware accelerators for those particular algorithms and therefore are energy efficient.

#define kChosenCipherBlockSize	kCCBlockSizeAES128
#define kChosenCipherKeySize	kCCKeySizeAES128
#define kChosenDigestLength		CC_SHA1_DIGEST_LENGTH

// Global constants for padding schemes.
#define	kPKCS1					11
#define kTypeOfWrapPadding		kSecPaddingPKCS1
#define kTypeOfSigPadding		kSecPaddingPKCS1SHA1

// constants used to find public, private, and symmetric keys.
#define kPublicKeyTag			"com.apple.sample.publickey"
#define kPrivateKeyTag			"com.apple.sample.privatekey"
#define kSymmetricKeyTag		"com.apple.sample.symmetrickey"

@interface SecKeyWrapper : NSObject {
	NSData * publicTag;
	NSData * privateTag;
	NSData * symmetricTag;
	CCOptions typeOfSymmetricOpts;
	SecKeyRef publicKeyRef;
	SecKeyRef privateKeyRef;
	NSData * symmetricKeyRef;
}

@property (nonatomic, retain) NSData * publicTag;
@property (nonatomic, retain) NSData * privateTag;
@property (nonatomic, retain) NSData * symmetricTag;
@property (nonatomic, retain) NSData * symmetricKeyRef;

+ (SecKeyWrapper *)sharedWrapper;
- (void)generateKeyPair:(NSUInteger)keySize;
- (void)deleteAsymmetricKeys;
- (void)deleteSymmetricKey;
- (void)generateSymmetricKey;
- (SecKeyRef)addPeerPublicKey:(NSString *)peerName keyBits:(NSData *)publicKey;
- (void)removePeerPublicKey:(NSString *)peerName;
- (NSData *)getSymmetricKeyBytes;
- (NSData *)wrapSymmetricKey:(NSData *)symmetricKey keyRef:(SecKeyRef)publicKey;
- (NSData *)unwrapSymmetricKey:(NSData *)wrappedSymmetricKey;
- (NSData *)getSignatureBytes:(NSData *)plainText;
- (NSData *)getHashBytes:(NSData *)plainText;
- (BOOL)verifySignature:(NSData *)plainText secKeyRef:(SecKeyRef)publicKey signature:(NSData *)sig;
- (NSData *)doCipher:(NSData *)plainText key:(NSData *)symmetricKey context:(CCOperation)encryptOrDecrypt padding:(CCOptions *)pkcs7;
- (SecKeyRef)getPublicKeyRef;
- (NSData *)getPublicKeyBits;
- (SecKeyRef)getPrivateKeyRef;
- (CFTypeRef)getPersistentKeyRefWithKeyRef:(SecKeyRef)keyRef;
- (SecKeyRef)getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef;

@end
