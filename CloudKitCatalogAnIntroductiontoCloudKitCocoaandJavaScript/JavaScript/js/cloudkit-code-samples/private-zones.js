/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Sample code for CRUD operations on custom zones. Includes forms for user input and rendering helpers.
*/

CKCatalog.tabs['private-zones'] = (function() {

  var createZoneNameForm = function(id) {
    return new CKCatalog.Form(id)
      .addInputField({
        name: 'name',
        placeholder: 'Custom zone name',
        type: 'text',
        label: 'zoneName:',
        value: 'myCustomZone'
      });
  };

  var renderZones = function(zones) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = 'Zones:';
    var table = new CKCatalog.Table([
      'zoneID', 'atomic', 'syncToken'
    ]).setTextForEmptyRow('No custom zones');
    if(zones.length === 0) {
      table.appendRow([]);
    } else {
      zones.forEach(function(zone) {
        table.appendRow([
          zone.zoneID,
          zone.atomic,
          zone.syncToken
        ]);
      })
    }
    content.appendChild(heading);
    content.appendChild(table.el);
    return content;
  };

  var renderZone = function(zone) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = 'Zone:';
    var table = new CKCatalog.Table().renderObject(zone);
    content.appendChild(heading);
    content.appendChild(table.el);
    return content;
  };

  var runSampleCode = function() {
    var zoneName = this.form.fields['name'].value;
    return this.sampleCode(zoneName);
  };

  var createZoneSample = {
    title: 'saveRecordZone',
    form: createZoneNameForm('create-zone-form'),
    run: runSampleCode,
    sampleCode: function demoSaveRecordZone(zoneName) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      return privateDB.saveRecordZone({zoneName: zoneName}).then(function(response) {
        if(response.hasErrors) {

          // Handle any errors.
          throw response.errors[0];

        } else {

          // response.zones is an array of zone objects.
          return renderZone(response.zones[0]);

        }
      });
    }
  };

  var deleteRecordZoneSample = {
    title: 'deleteRecordZone',
    form: createZoneNameForm('delete-zone-form'),
    run: runSampleCode,
    sampleCode: function demoDeleteRecordZone(zoneName) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      return privateDB.deleteRecordZone({zoneName: zoneName}).then(function(response) {
        if(response.hasErrors) {

          // Handle any errors.
          throw response.errors[0];

        } else {

          // response.zones is an array of zone objects.
          return renderZone(response.zones[0]);

        }
      });
    }
  };

  var fetchRecordZoneSample = {
    title: 'fetchRecordZone',
    form: createZoneNameForm('fetch-zone-form'),
    run: runSampleCode,
    sampleCode: function demoFetchRecordZone(zoneName) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      return privateDB.fetchRecordZone({zoneName: zoneName}).then(function(response) {
        if(response.hasErrors) {

          // Handle any errors.
          throw response.errors[0];

        } else {

          // response.zones is an array of zone objects.
          return renderZone(response.zones[0]);

        }
      });
    }
  };

  var fetchAllRecordZonesSample = {
    title: 'fetchAllRecordZones',
    sampleCode: function demoFetchAllRecordZones() {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      return privateDB.fetchAllRecordZones().then(function(response) {
        if(response.hasErrors) {

          // Handle any errors.
          throw response.errors[0];

        } else {

          // response.zones is an array of zone objects.
          return renderZones(response.zones);

        }
      });
    }
  };

  return [ createZoneSample, deleteRecordZoneSample, fetchRecordZoneSample, fetchAllRecordZonesSample ];
})();