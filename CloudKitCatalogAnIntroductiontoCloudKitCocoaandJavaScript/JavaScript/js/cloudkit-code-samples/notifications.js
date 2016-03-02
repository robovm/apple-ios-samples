/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The notifications sample code with helper functions to add an alert to the left-hand menu,
    to clear 'new' notifications, and to render the notifications in a table.
*/
CKCatalog.tabs['notifications'] = (function() {

  var alertTextContainer = document.getElementById('number-of-alerts');
  var notificationsAlertContainer = document.querySelector('.menu-item[href="#notifications"] .alert');
  var notificationsSubtitle = document.getElementById('connected-text');
  var unseenNotifications = 0;

  var areNotificationsVisible = function() {
    return window.location.hash === '#notifications';
  };

  var setUnseenNotifications = function(val) {
    unseenNotifications = val;
    alertTextContainer.textContent = val + '';
  };

  var showOrHideAlert = function() {
    if(areNotificationsVisible() || unseenNotifications === 0) {
      notificationsAlertContainer.classList.add('hide');
      notificationsAlertContainer.parentNode.classList.remove('notify');
    } else {
      notificationsAlertContainer.classList.remove('hide');
      notificationsAlertContainer.parentNode.classList.add('notify');
    }
  };

  var updateNotificationsSubtitle = function(text) {
    notificationsSubtitle.innerHTML = '<span class="green">' + text + '</span>';
  };

  window.addEventListener('hashchange',function(hashChangeEvent) {

    // Let's remove the 'new' class from the rows when leaving the notifications page and reset unseen notifications.
    if(/#notifications/.test(hashChangeEvent.oldURL)) {
      setUnseenNotifications(0);
      var rows = notificationsTable.body.childNodes;
      for(var i=0; i<rows.length; i++) {
        rows[i].classList.remove('new');
      }
    }
    showOrHideAlert();
  });

  var notificationsTable = new CKCatalog.Table(
    ['notificationID','notificationType','subscriptionID','zoneID']
  ).setTextForEmptyRow('No notifications').appendRow([]);

  var renderNotificationsTable = function() {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = 'Notifications:';
    content.appendChild(heading);
    content.appendChild(notificationsTable.el);
    return content;
  };

  var appendNotificationToTable = function(notificationID,notificationType,subscriptionID,zoneID) {
    if(!areNotificationsVisible()) {
      setUnseenNotifications(unseenNotifications + 1);
      showOrHideAlert();
    } else {
      setUnseenNotifications(0);
    }
    var tbody = notificationsTable.body;
    var firstRow = tbody.firstChild;
    if(firstRow.classList.contains('empty')) {
      tbody.removeChild(firstRow);
    }
    notificationsTable.prependRow([
      notificationID,notificationType,subscriptionID,zoneID
    ]);
    tbody.firstChild.classList.add('new');
  };

  var addNotificationListenerSample = {
    title: 'registerForNotifications',
    sampleCode: function demoRegisterForNotifications() {
      var container = CloudKit.getDefaultContainer();

      // Check if our container is already registered for notifications. If so, return.
      if(container.isRegisteredForNotifications) {
        return CloudKit.Promise.resolve();
      }

      function renderNotification(notification) {
        appendNotificationToTable(
          notification.notificationID,
          notification.notificationType,
          notification.subscriptionID,
          notification.zoneID
        );
      }

      // Add a notification listener which appends the received notification object
      // to the table below.
      container.addNotificationListener(renderNotification);

      // Now let's park a connection with the notification backend so that
      // we can receive notifications.
      return container.registerForNotifications().then(function(container) {
        if(container.isRegisteredForNotifications) {

          // Update the subtitle in the left-hand menu.
          updateNotificationsSubtitle('Connected');

          return renderNotificationsTable();
        }
      });
    }
  };

  return [ addNotificationListenerSample ];
})();