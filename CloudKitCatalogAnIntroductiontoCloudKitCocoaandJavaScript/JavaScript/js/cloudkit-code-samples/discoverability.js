/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The discoverability sample code with some helper functions to render the userInfo inside a table and some forms
    to accept user input.
*/
CKCatalog.tabs['discoverability'] = (function() {

  var createUserInfoTable = function(userRecordName,firstName,lastName,emailAddress) {
    var table = (new CKCatalog.Table)
      .setTextForUndefinedValue('PRIVATE')
      .appendRow('userRecordName',userRecordName)
      .appendRow('firstName',firstName)
      .appendRow('lastName',lastName)
      .appendRow('emailAddress',emailAddress);
    return table.el;
  };

  var renderUserInfo = function(title,userRecordName,firstName,lastName,emailAddress) {

    // Add the user id to the recordName input form for convenience.
    recordNameInputForm.fields['record-name'].value = userRecordName;

    // Now render the info.
    var heading = document.createElement('h2');
    heading.textContent = title;
    var table = createUserInfoTable(userRecordName,firstName,lastName,emailAddress);

    var content = document.createElement('div');
    content.appendChild(heading);
    content.appendChild(table);
    return content;
  };

  var createUserInfosTable = function(userInfos) {
    var table = new CKCatalog.Table([
      'userRecordName', 'firstName', 'lastName', 'emailAddress'
    ]).setTextForUndefinedValue('PRIVATE')
      .setTextForEmptyRow('No discovered users');
    if(userInfos.length) {
      userInfos.forEach(function(userInfo) {
        table.appendRow([
          userInfo.userRecordName,
          userInfo.firstName,
          userInfo.lastName,
          userInfo.emailAddress
        ]);
      });
    } else {
      table.appendRow([]);
    }
    return table.el;
  };

  var renderUserInfos = function(title,userInfos) {
    var heading = document.createElement('h2');
    heading.textContent = title;
    var table = createUserInfosTable(userInfos);
    var content = document.createElement('div');
    content.appendChild(heading);
    content.appendChild(table);
    return content;
  };

  var emailInputForm = (new CKCatalog.Form('discover-by-email-address-form'))
    .addInputField({
      type: 'email',
      placeholder: 'Email address',
      name: 'email',
      label: 'emailAddress:',
      value: 'my_discoverable_user@icloud.com'
    });

  var recordNameInputForm = (new CKCatalog.Form('discover-by-user-record-name'))
    .addInputField({
      type: 'text',
      placeholder: 'User record name',
      name: 'record-name',
      label: 'userRecordName:',
      value: ''
    });


  var fetchUserInfoSample = {
    title: 'fetchUserInfo',
    sampleCode: function demoFetchUserInfo() {
      var container = CloudKit.getDefaultContainer();

      // Fetch user's info.
      return container.fetchUserInfo()
        .then(function(userInfo) {
          var title = 'UserInfo for current '+
            (userInfo.isDiscoverable ? 'discoverable' : 'non-discoverable')+
            ' user:';

          // Render the user's info.
          return renderUserInfo(
            title,

            userInfo.userRecordName, // The user's opaque ID.

            userInfo.firstName, // This will be undefined when the user is not
                                // discoverable.

            userInfo.lastName, // As will this.

            userInfo.emailAddress // This is undefined unless discovering userInfo by
                                  // emailAddress (see the related sample).
          );
        });
    }

  };

  var discoverAllContactUserInfosSample = {
    title: 'discoverAllContactUserInfos',
    sampleCode: function demoDiscoverAllContactUserInfos() {
      var container = CloudKit.getDefaultContainer();

      return container.discoverAllContactUserInfos().then(function(response) {
        if(response.hasErrors) {

          // Handle the errors in your app.
          throw response.errors[0];

        } else {
          var title = 'Discovered users from your iCloud contacts:';

          // response.users is an array of userInfo objects.
          return renderUserInfos(title, response.users);

        }
      });
    }
  };

  var discoverUserInfoWithEmailAddressSample = {
    title: 'discoverUserInfoWithEmailAddress',
    form: emailInputForm,
    run: function() {
      var emailAddress = this.form.fields['email'].value;
      return this.sampleCode(emailAddress);
    },
    sampleCode: function demoDiscoverUserInfoWithEmailAddress(emailAddress) {
      var container = CloudKit.getDefaultContainer();

      return container.discoverUserInfoWithEmailAddress(emailAddress)
        .then(function(response) {
          if(response.hasErrors) {

            // Handle the errors in your app.
            throw response.errors[0];

          } else {
            var title = 'Discovered users by email address:';
            return renderUserInfos(title, response.users);
          }
        });
    }
  };

  var discoverUserInfoWithUserRecordNameSample = {
    title: 'discoverUserInfoWithUserRecordName',
    form: recordNameInputForm,
    run: function() {
      var recordName = this.form.fields['record-name'].value;
      return this.sampleCode(recordName);
    },
    sampleCode: function demoDiscoverUserInfoWithUserRecordName(userRecordName) {
      var container = CloudKit.getDefaultContainer();

      return container.discoverUserInfoWithUserRecordName(userRecordName)
        .then(function(response) {
          if(response.hasErrors) {

            // Handle the errors in your app.
            throw response.errors[0];

          } else {
            var title = 'Discovered users by record name:';
            return renderUserInfos(title, response.users);
          }
        });
    }
  };


  return [
    fetchUserInfoSample,
    discoverAllContactUserInfosSample,
    discoverUserInfoWithEmailAddressSample,
    discoverUserInfoWithUserRecordNameSample
  ];

})();