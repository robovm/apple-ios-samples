/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The authentication sample code with some helper functions to render the username/user record name and to construct
    the auth button containers.
*/
CKCatalog.tabs['authentication'] = (function() {

  var displayUserName = function(name) {
    var userNameEl = document.getElementById('username');
    userNameEl.textContent = name;
    var displayedUserName = document.getElementById('displayed-username');
    if(displayedUserName) {
      displayedUserName.textContent = name;
    }
  };

  var createButtonContainersHTML = function() {
    return '<div>'+
      '<h2 id="displayed-username"></h2>'+
      '<div id="apple-sign-in-button"></div>'+
      '<div id="apple-sign-out-button"></div>'+
    '</div>';
  };

  var showDialogForPersistError = function() {
    var html = '<h2>Unable to set a cookie</h2><p>';

    if(window.location.protocol === 'file:') {
      html += 'The authentication option <code>persist = true</code> is not compatible with the <i>file://</i> protocol. ';
    }

    html += 'Please edit <i>js/init.js</i> and set <code>persist = false</code> in <i>CloudKit.configure()</i>.</p>';

    CKCatalog.dialog.show(html, { title: 'Close' });
  };

  var authSample = {
    run: function() {
      var content = this.content;
      content.innerHTML = createButtonContainersHTML();
      return this.sampleCode().then(function() {
        return content.firstChild;
      });
    },
    sampleCode: function demoSetUpAuth() {

      // Get the container.
      var container = CloudKit.getDefaultContainer();

      function gotoAuthenticatedState(userInfo) {
        if(userInfo.isDiscoverable) {
          displayUserName(userInfo.firstName + ' ' + userInfo.lastName);
        } else {
          displayUserName('User record name: ' + userInfo.userRecordName);
        }
        container
          .whenUserSignsOut()
          .then(gotoUnauthenticatedState);
      }
      function gotoUnauthenticatedState(error) {

        if(error && error.ckErrorCode === 'AUTH_PERSIST_ERROR') {
          showDialogForPersistError();
        }

        displayUserName('Unauthenticated User');
        container
          .whenUserSignsIn()
          .then(gotoAuthenticatedState)
          .catch(gotoUnauthenticatedState);
      }

      // Check a user is signed in and render the appropriate button.
      return container.setUpAuth()
        .then(function(userInfo) {

          // Either a sign-in or a sign-out button was added to the DOM.

          // userInfo is the signed-in user or null.
          if(userInfo) {
            gotoAuthenticatedState(userInfo);
          } else {
            gotoUnauthenticatedState();
          }
        });
    }
  };

  return [ authSample ];

})();