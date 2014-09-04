### CryptoExercise ###

================================================================================
DESCRIPTION:

This sample demonstrates the use of the two main Cryptographic API sets on the iPhone OS SDK. Asymmetric Key Encryption and random nonce generation is handled through the Security framework API set, whereas, Symmetric Key Encryption is handled by the CommonCrypto API set. The CryptoExercise sample brings both of these APIs together through a network service, discoverable via Bonjour, that performs a "dummy" cryptographic protocol between devices found on the same subnet.

Protocol:

<<<important>>>
The 'dummy' cryptographic protocol derived is not meant to be an example of a proper secure networking communication implementation. It is meant solely to be a tool for displaying the various cryptographic APIs found on the iPhone OS SDK.
<<<important>>>

There are two agents in this 'dummy' protocol, a client and a server. 

1.) The client first browses for Bonjour service instances of "_crypttest._tcp". Upon initiating a connection to the server the client sends the server its recently generated public key. The client then blocks and waits for a response back from the server.

2.) The server upon receiving a connection request reads and stores the public key of the current initiating client. The server then generates a binary property list containing the following pieces of data:
	
	a.) The recently generated public key of the server.
	b.) AES128 encrypted text found in CommonCrypto.h using the recently generated symmetric key.
	c.) A boolean value letting the client know whether the encrypted text has PKCS#7 padding.
	d.) The signed SHA-1 signature of the plaintext using the server's private key.
	e.) The symmetric key used for encryption of the plaintext found in CommonCrypto.h wrapped with the client's public key.

The server then sends this data blob to the client and removes the client's public key from the keychain.

3.) The client upon reception of the data blob does the following:

	a.) Unwraps the symmetric key.
	b.) Acquires the padding flag.
	c.) Decrypts the message.
	d.) Adds the public key of the server to the keychain to get a SecKey handle.
	e.) Verifies the signature using the public key of the server and the decrypted plaintext.

4.) The client updates the UI to show if the verification succeeded or failed and then removes the server's public key from the keychain.

5.) The connection is then closed on both ends.

Networking:

The networking APIs used are CFSocket for the socket initialization and then the NSStream set of APIs to do blocking read and writes to the open sockets as well to be notified of events. The server sets the callback for accept notifications, whereas, the CryptoServerRequest and client objects set the delegate to be notified of bytes available and space available events. Just as in most custom networking protocols this sample employs the use of prepending message lengths to the network messages so that either the client or server knows how much data is to be received from the other end.

Testing:

To test the sample you will need two devices with the application installed on both of them. Before you run the sample you will need to make sure that they are both connected to the same wireless subnet. If you would like to test the sample with just one device then you can uncomment the "#define ALLOW_TO_CONNECT_TO_SELF 1" found in CryptoCommon.h.

Caveat(s):
Although this sample was designed, in theory, towards supporting a many-to-one relationship between a server and clients (and, obviously, a one-to-one relationship between a client and a server) it's not really an example of best practices for doing so. Please refer to the documentation for more details.
================================================================================
BUILD REQUIREMENTS:

Mac OS X 10.5.6, Xcode 3.1.3, iPhone OS 3.0

================================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.5.6, iPhone OS 3.0 (Device *Only*)

================================================================================
PACKAGING LIST:

AppDelegate
Main controller that houses the operation queue and initializes the LocalBonjour Controller.

CryptoClient
Contains the client networking and cryptographic operations. It gets invoked by the ServiceController class when the connect button is pressed.

CryptoCommon
Common defines that are used between the Crypto-Client/Server.

CryptoServer
Contains the bootstrapping server networking operations. It gets invoked by the LocalBonjourController class during startup.

CryptoServerRequest
Handles a server networking request, composed of cryptographic operations, made by a connected client.

KeyGeneration
Provides the key generation UI as well as the hooks into the SecKeyWrapper to generate the keys.

LocalBonjourController
Handles all of the Bonjour initialization code and back-end to the UIScrollView for browsing network service instances of this sample.

SecKeyWrapper
Core cryptographic wrapper class to exercise most of the Security APIs on the iPhone OS. Start here if all you are interested in are the cryptographic APIs on the iPhone OS.

ServiceController
Responsible for connection UI and providing an interface to executing a connect request.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
    Adopted iPhone OS 3.0 UITableView and UITableViewCell APIs. Added check for availability of WiFi network.
    Made minor bug fix in hash computation.

Version 1.1
    N/A

Copyright (c) 2008-2009 Apple Inc. All rights reserved.