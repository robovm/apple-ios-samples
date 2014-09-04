#! /usr/bin/python

#   File:       ImageReceiveServer.py
#
#   Contains:   A basic HTTP server to accept HTTP PUTs and POSTs.
#
#   Written by: DTS
#
#   Copyright:  Copyright (c) 2009 Apple Inc. All Rights Reserved.
#
#   Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
#               ("Apple") in consideration of your agreement to the following
#               terms, and your use, installation, modification or
#               redistribution of this Apple software constitutes acceptance of
#               these terms.  If you do not agree with these terms, please do
#               not use, install, modify or redistribute this Apple software.
#
#               In consideration of your agreement to abide by the following
#               terms, and subject to these terms, Apple grants you a personal,
#               non-exclusive license, under Apple's copyrights in this
#               original Apple software (the "Apple Software"), to use,
#               reproduce, modify and redistribute the Apple Software, with or
#               without modifications, in source and/or binary forms; provided
#               that if you redistribute the Apple Software in its entirety and
#               without modifications, you must retain this notice and the
#               following text and disclaimers in all such redistributions of
#               the Apple Software. Neither the name, trademarks, service marks
#               or logos of Apple Inc. may be used to endorse or promote
#               products derived from the Apple Software without specific prior
#               written permission from Apple.  Except as expressly stated in
#               this notice, no other rights or licenses, express or implied,
#               are granted by Apple herein, including but not limited to any
#               patent rights that may be infringed by your derivative works or
#               by other works in which the Apple Software may be incorporated.
#
#               The Apple Software is provided by Apple on an "AS IS" basis. 
#               APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
#               WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
#               MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
#               THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
#               COMBINATION WITH YOUR PRODUCTS.
#
#               IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
#               INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#               TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#               DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
#               OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
#               OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
#               OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
#               OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
#               SUCH DAMAGE.

import os
import sys
import BaseHTTPServer
import string
import email.feedparser

global gImageDirPath

class HTTPError (Exception):
    def __init__(self, statusCode, statusMessage=None):
        self.statusCode    = statusCode
        self.statusMessage = statusMessage

class MyHandler(BaseHTTPServer.BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_error(404)

    def do_PUT(self):
        global gImageDirPath
        
        try:
            assert self.path[0] == "/"

            fileName = self.path[1:]
            if fileName.translate(string.maketrans("", ""), string.ascii_letters + string.digits + "_") != ".":
                # Non-alphanumeric characters must be limited to exactly 
                # one dot, that is, the extension delimiter.
                raise HTTPError(403)

            # These Content-Type comparisons are too naive (they should be 
            # case insensitive, and they should ignore training parameters), 
            # but this is only a test server, not a real server.
            
            contentType = self.headers.get('Content-Type')
            if contentType == None or (contentType not in ["image/png", "image/jpeg", "image/gif"]):
                raise HTTPError(406)

            if contentType == "image/png" and not fileName.endswith(".png"):
                raise HTTPError(406)

            if contentType == "image/jpeg" and not fileName.endswith(".jpg"):
                raise HTTPError(406)
            
            contentLength = self.headers.get('Content-Length')
            if contentLength == None:
                raise HTTPError(411)

            try:
                fileLength = int(contentLength)
                assert fileLength > 0
            except:
                raise HTTPError(411)

            filePath = os.path.join(gImageDirPath, fileName)
            fileExists = os.path.exists(filePath)

            imageFile = open(filePath, "w")
            
            # Transfer the data in MB chunks to prevent us being run out of 
            # memory with large files.
            
            bytesReadSoFar = 0
            while bytesReadSoFar != fileLength:
                bytesToRead = (fileLength - bytesReadSoFar)
                if bytesToRead > (1024 * 1024):
                    bytesToRead = (1024 * 1024)
                
                data = self.rfile.read(bytesToRead)
                bytesReadSoFar += len(data)

                imageFile.write(data)

                data = None

            imageFile.close()
            
            if fileExists:
                self.send_response(200)
            else:
                self.send_response(201)                
            self.end_headers()
        except HTTPError, e:
            self.send_error(e.statusCode, e.statusMessage)
        except:
            self.send_error(500, "Internal Server Error")


    def do_POST(self):
        global gImageDirPath
        
        try:
            if self.path != "/cgi-bin/PostIt.py":
                raise HTTPError(403)

            # These Content-Type comparisons are too naive (they should be 
            # case insensitive, and they should ignore training parameters), 
            # but this is only a test server, not a real server.
            
            contentType = self.headers.get('Content-Type')
            if contentType == None or not contentType.startswith("multipart/form-data"):
                raise HTTPError(406)
            
            contentLength = self.headers.get('Content-Length')
            if contentLength == None:
                raise HTTPError(411)

            try:
                fileLength = int(contentLength)
                assert fileLength > 0
            except:
                raise HTTPError(411)

            # Set up a MIME parser and feed it the Content-Type header.
            
            p = email.feedparser.FeedParser()
            p.feed("Content-Type: %s\r\n" % self.headers.get('Content-Type'))
            
            # Transfer the data in MB chunks to prevent us being run out of 
            # memory with large files.  Of course, a large file is probably 
            # going to hoark and die because the MIME parser keeps everything 
            # in memory.  Good thing this is only a trivial test server.

            bytesReadSoFar = 0
            while bytesReadSoFar != fileLength:
                bytesToRead = (fileLength - bytesReadSoFar)
                if bytesToRead > (1024 * 1024):
                    bytesToRead = (1024 * 1024)
                
                data = self.rfile.read(bytesToRead)
                bytesReadSoFar += len(data)

                p.feed(data)

                data = None
            rootMessage = p.close()
            
            # Check some basic facts about the message.
            
            if not rootMessage.is_multipart() or len(rootMessage.defects) != 0:
                raise HTTPError(400)
            
            # Look for the "fileContents" part.
            
            fileContentsMessage = None
            for message in rootMessage.get_payload():
                if message.get_param("name", header="Content-Disposition") == "fileContents":
                    fileContentsMessage = message
                    break
            if fileContentsMessage == None or fileContentsMessage.is_multipart():
                raise HTTPError(400)
                
            # Extract the file name and check that it's reasonable.
            
            fileName = fileContentsMessage.get_param("filename", header="Content-Disposition")
            if fileName == None:
                raise HTTPError(400)
            if fileName.translate(string.maketrans("", ""), string.ascii_letters + string.digits + "_") != ".":
                # Non-alphanumeric characters must be limited to exactly 
                # one dot, that is, the extension delimiter.
                raise HTTPError(403)

            # Verify the content type.
            
            contentType = fileContentsMessage.get('Content-Type')
            if contentType == None or (contentType not in ["image/png", "image/jpeg", "image/gif"]):
                raise HTTPError(406)

            if contentType == "image/png" and not fileName.endswith(".png"):
                raise HTTPError(406)

            if contentType == "image/jpeg" and not fileName.endswith(".jpg"):
                raise HTTPError(406)

            # Create the file with the supplied name and write the content to it.
            
            filePath = os.path.join(gImageDirPath, fileName)
            fileExists = os.path.exists(filePath)

            imageFile = open(filePath, "w")
            imageFile.write(fileContentsMessage.get_payload())
            imageFile.close()
            
            if fileExists:
                self.send_response(200)
            else:
                self.send_response(201)                
            self.end_headers()
        except HTTPError, e:
            self.send_error(e.statusCode, e.statusMessage)
        except:
            self.send_error(500, "Internal Server Error")

def main():
    global gImageDirPath
    
    gImageDirPath = os.path.join(os.curdir, "images")
    if not os.path.exists(gImageDirPath):
        os.mkdir(gImageDirPath)
    
    server = BaseHTTPServer.HTTPServer(('', 9000), MyHandler)
    print "Hello Cruel World!"
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print ""

if __name__ == "__main__":
    main()
