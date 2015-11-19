/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The sample code for record CRUD operations in the private database. Included are helper functions for rendering
    records and for building the forms for user input.
*/

CKCatalog.tabs['private-records'] = (function() {

  var renderRecord = function(recordName,recordType,recordChangeTag,created,modified,name,location,asset) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = 'Record:';
    var table = (new CKCatalog.Table)
      .setTextForUndefinedValue('None')
      .appendRow('recordName',recordName)
      .appendRow('recordType',recordType)
      .appendRow('recordChangeTag',recordChangeTag)
      .appendRow('created',{
        userRecordName: created.userRecordName,
        timestamp: new Date(created.timestamp)
      })
      .appendRow('modified',{
        userRecordName: modified.userRecordName,
        timestamp: new Date(modified.timestamp)
      })
      .appendRow('name',name)
      .appendRow('location',location)
      .appendRowWithDownloadLink('asset', asset);
    content.appendChild(heading);
    content.appendChild(table.el);
    return content;
  };

  var renderDeletedRecord = function(recordName,deleted) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = 'Deleted Record:';
    var table = (new CKCatalog.Table)
      .setTextForUndefinedValue('None')
      .appendRow('recordName',recordName)
      .appendRow('deleted',deleted);
    content.appendChild(heading);
    content.appendChild(table.el);
    return content;
  };

  var createRecordIDForm = function(id) {
    return new CKCatalog.Form(id)
      .addInputField({
        type: 'text',
        placeholder: 'Record name',
        name: 'record-id',
        label: 'recordName:',
        value: 'NewItem'
      })
      .addInputField({
        type: 'text',
        placeholder: 'Zone name',
        name: 'zone',
        label: 'zoneName:',
        value: '_defaultZone'
      });
  };

  var runSampleCode = function() {
    var recordName = this.form.fields['record-id'].value;
    var zoneName = this.form.fields['zone'].value;
    return this.sampleCode(recordName,zoneName);
  };

  var createItemForm = (new CKCatalog.Form('create-item-form'))
    .addInputField({
      type: 'text',
      placeholder: 'Record ID',
      name: 'record-id',
      label: 'recordName:',
      value: 'NewItem'
    })
    .addInputField({
      type: 'text',
      placeholder: 'Zone name',
      name: 'zone',
      label: 'zoneName:',
      value: '_defaultZone'
    })
    .addInputField({
      type: 'text',
      placeholder: 'Item name',
      name: 'name',
      label: 'name:',
      value: 'New Item'
    })
    .addInputField({
      type: 'text',
      placeholder: 'latitude,longitude',
      name: 'location',
      label: 'location:',
      value: '37.3175,-122.0419'
    })
    .addFileInputField({
      name: 'asset',
      label: 'asset:'
    });

  var saveRecordSample = {
    title: 'saveRecord',
    form: createItemForm,
    run: function() {
      var recordName = this.form.fields['record-id'].value;
      var name = this.form.fields['name'].value;
      var zoneName = this.form.fields['zone'].value;
      var latLong = this.form.fields['location'].value.split(',').map(function(string) {
        return !isNaN(string) ? parseInt(string) : undefined;
      });
      var location = {
        latitude: latLong[0],
        longitude: latLong[1]
      };
      var asset = this.form.fields['asset'].files[0];
      return this.sampleCode(recordName,zoneName,name,location,asset);
    },
    sampleCode: function demoSaveRecord(recordName,zoneName,name,location,asset) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      // If no options are provided the record will be saved to the default zone.
      var options = zoneName ? { zoneID: zoneName } : undefined;

      var record = {
        recordName: recordName,

        recordType: 'Items',

        fields: {
          name: {
            value: name
          },
          location: {
            value: location
          },
          asset: {
            value: asset // A File handle.
          }
        }
      };

      return privateDB.saveRecord(record,options)
        .then(function(response) {
          if(response.hasErrors) {

            // Handle the errors in your app.
            throw response.errors[0];

          } else {
            var createdRecord = response.records[0];
            var fields = createdRecord.fields;
            var name = fields['name'];
            var location = fields['location'];
            var asset = fields['asset'];

            // Render the created record.
            return renderRecord(
              createdRecord.recordName,
              createdRecord.recordType,
              createdRecord.recordChangeTag,
              createdRecord.created,
              createdRecord.modified,
              name ? name.value : '',
              location ? location.value : '',
              asset ? asset.value.downloadURL : null
            );
          }
        });
    }

  };

  var deleteRecordSample = {
    title: 'deleteRecord',
    form: createRecordIDForm('delete-record-form'),
    run: runSampleCode,
    sampleCode: function demoDeleteRecord(recordName,zoneName) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      var options = zoneName ? { zoneID: zoneName } : undefined;

      return privateDB.deleteRecord(recordName,options)
        .then(function(response) {
          if(response.hasErrors) {

            // Handle the errors in your app.
            throw response.errors[0];

          } else {
            var deletedRecord = response.records[0];

            // Render the deleted record.
            return renderDeletedRecord(
              deletedRecord.recordName,
              deletedRecord.deleted
            );
          }
        });
    }
  };

  var fetchRecordSample = {
    title: 'fetchRecord',
    form: createRecordIDForm('fetch-record-form'),
    run: runSampleCode,
    sampleCode: function demoFetchRecord(recordName,zoneName) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      var options = zoneName ? { zoneID: zoneName } : undefined;

      return privateDB.fetchRecord(recordName,options)
        .then(function(response) {
          if(response.hasErrors) {

            // Handle the errors in your app.
            throw response.errors[0];

          } else {
            var record = response.records[0];
            var fields = record.fields;
            var name = fields['name'];
            var location = fields['location'];
            var asset = fields['asset'];

            // Render the fetched record.
            return renderRecord(
              record.recordName,
              record.recordType,
              record.recordChangeTag,
              record.created,
              record.modified,
              name ? name.value : '',
              location ? location.value : '',
              asset ? asset.value.downloadURL : null
            );
          }
        });
    }
  };

  return [ saveRecordSample, deleteRecordSample, fetchRecordSample ];

})();