/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This node script uses a server-to-server key to make public database calls with CloudKit JS
 */


process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

(function() {
  var fetch = require('node-fetch');

  var CloudKit = require('./cloudkit');
  var containerConfig = require('./config');

  // A utility function for printing results to the console.
  var println = function(key,value) {
    console.log("--> " + key + ":");
    console.log(value);
    console.log();
  };

  //CloudKit configuration
  CloudKit.configure({
    services: {
      fetch: fetch,
      logger: console
    },
    containers: [ containerConfig ]
  });


  var container = CloudKit.getDefaultContainer();
  var database = container.publicCloudDatabase; // We'll only make calls to the public database.

  // Sign in using the keyID and public key file.
  container.setUpAuth()
    .then(function(userInfo){
      println("userInfo",userInfo);

      return database.performQuery({ recordType: 'Test' });
    })
    .then(function(response) {
      println("Queried Records",response.records);

      return database.saveRecords({recordType: 'Test', recordName: 'hello-u'});
    })
    .then(function(response) {
      var record = response.records[0];
      println("Saved Record",record);

      return database.fetchRecords(record);
    })
    .then(function(response) {
      var record = response.records[0];
      println("Fetched Record", record);

      return database.deleteRecords(record);
    })
    .then(function(response) {
      var record = response.records[0];
      println("Deleted Record", record);

      console.log("Done");
      process.exit();
    })
    .catch(function(error) {
      console.warn(error);
      process.exit(1);
    });

})();

