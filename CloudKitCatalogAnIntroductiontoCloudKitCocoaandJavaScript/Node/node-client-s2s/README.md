# A script for using Server-to-Server keys to make public database requests with CloudKit JS

## Install dependencies

Our script uses the npm module *node-fetch* and the *CloudKit JS* library. Install them by running the following
commands from the same directory as this README.
```
npm install
npm run-script install-cloudkit-js
```

## Configure the script to use a test container

Note that this must be a container for which you have admin access, as the server-to-server key will inherit your
privileges to modify the public database. Insert your container ID in the appropriate place within the file `config.js`.

## Generate a private key

If you are using a Mac, you already have OpenSSL installed and you can generate a private key with this command (make
sure you are in the same directory as this README).
```
openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem
```
This will create the file `Node/node-client-s2s/eckey.pem`.

## Create a Server-to-Server key in CloudKit Dashboard

In [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard) select your test container and navigate to
`API Access -> Server-to-Server Keys`. Copy the public key in the output of this command:
```
openssl ec -in eckey.pem -pubout
```
and paste it into the *Public Key* text field of the new key. Hit *Save* and the *Key ID* attribute will get populated.
Copy this ID and fill in the **keyID** property in `config.js`.

## Create a Test record type in CloudKit Dashboard

In [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard) go to *Record Types* and create a **Test** record type.

## Run the script

```
node index.js
```

Copyright (C) 2015 Apple Inc. All rights reserved.

