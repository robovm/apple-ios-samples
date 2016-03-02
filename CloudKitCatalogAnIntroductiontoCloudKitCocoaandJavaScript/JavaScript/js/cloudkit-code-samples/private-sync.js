/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The sample code for syncing a custom zone. Includes a cache for syncTokens with methods for setting and clearing the
    values as well as a table for the fetched records.
 */

CKCatalog.tabs['private-sync'] = (function() {

  var zoneNameForm = new CKCatalog.Form('sync-zone-name-form')
    .addInputField({
      type: 'text',
      placeholder: 'Zone name',
      name: 'zone',
      label: 'zoneName:',
      value: 'myCustomZone'
    });

  var zoneSyncTokens = {};

  var saveSyncToken = function(zone,token) {
    zoneSyncTokens[zone] = token;
  };

  var getSavedSyncToken = function(zone) {
    return zoneSyncTokens[zone];
  };

  var recordsTable;


  var addRows = function(records) {
    if(recordsTable) {
      records.forEach(function (record) {
        var fields = record.fields;
        var name = fields ? fields['name'] : undefined;
        var location = fields ? fields['location'] : undefined;
        recordsTable.appendRow([
          record.recordName,
          record.recordType || '',
          record.recordChangeTag || '',
          record.modified ? new Date(record.modified.timestamp) : '',
          name ? name.value : '',
          location ? location.value : '',
          record.deleted !== undefined ? record.deleted : ''
        ]);
      });
    }
  };

  var renderRecords = function(zoneName,records,syncToken,moreComing) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    var p = document.createElement('p');
    p.innerHTML = '<span class="light small">At syncToken:</span> '
      + '<span id="sync-token" class="small">' + syncToken + '</span> ';
    var deleteSyncTokenButton = document.createElement('button');
    deleteSyncTokenButton.className = 'link small';
    deleteSyncTokenButton.textContent = 'delete';
    deleteSyncTokenButton.onclick = function() {
      saveSyncToken(zoneName,null);
      p.classList.add('hide');
    };
    p.appendChild(deleteSyncTokenButton);
    heading.innerHTML = 'Records' + (moreComing ? '<span id="more-coming">' + ' (incomplete)' + '</span>:' : ':');
    recordsTable = new CKCatalog.Table([
      'recordName','recordType','recordChangeTag','modified','name','location','deleted'
    ])
      .setTextForEmptyRow('No new records');
    if(records.length === 0) {
      recordsTable.appendRow([]);
    } else {
      addRows(records);
    }
    content.appendChild(heading);
    content.appendChild(p);
    content.appendChild(recordsTable.el);
    return content;
  };

  var shouldAppendRecords = false;

  var appendRecords = function(records,syncToken,moreComing) {
    if(recordsTable) {
      document.getElementById('sync-token').textContent = syncToken;
      var moreComingClassList = document.getElementById('more-coming').classList;
      if(moreComing) {
        moreComingClassList.remove('hide');
      } else {
        moreComingClassList.add('hide');
      }
      addRows(records);
    }
  };

  var fetchChangedRecordsSample = {
    title: 'fetchChangedRecords',
    form: zoneNameForm,
    run: function() {
      var zone = this.form.fields['zone'].value;
      return this.sampleCode(zone);
    },
    sampleCode: function demoFetchChangedRecords(zoneName) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      var zone = { zoneName: zoneName };

      var opts = {

        // We shall restrict our returned fields to these.
        desiredKeys: ['name','location'],

        // Limit to 3 results.
        resultsLimit: 3
      };

      // Check if we have a saved syncToken for this zone.
      var savedSyncToken = getSavedSyncToken(zoneName);

      if(savedSyncToken) {
        opts.syncToken = savedSyncToken;
      } else {

        // If we don't have a syncToken we don't want to
        // append records to an existing list.
        shouldAppendRecords = false;

      }

      return privateDB.fetchChangedRecords(zone,opts).then(function(response) {
        if(response.hasErrors) {

          // Handle the errors.
          throw response.errors[0];

        } else {
          var syncToken = response.syncToken;
          var records = response.records;
          var moreComing = response.moreComing;

          // Save the new syncToken somewhere.
          saveSyncToken(zoneName,syncToken);

          var renderedRecords;

          if(shouldAppendRecords) {

            // Append records to an existing list.
            renderedRecords = appendRecords(records,syncToken,moreComing);

          } else {

            // Replace the existing list of records with a new one.
            renderedRecords = renderRecords(zoneName,records,syncToken,moreComing);

          }

          // If there are more records to come, we will append the records instead
          // of replacing them on the next run.
          shouldAppendRecords = moreComing;

          return renderedRecords;
        }
      });
    }

  };

  return [ fetchChangedRecordsSample ];
})();