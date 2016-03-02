/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The sample code for CRUD operations on subscriptions. Includes form builders and rendering helpers.
*/

CKCatalog.tabs['private-subscriptions'] = (function() {

  var subscriptionTypeForm = new CKCatalog.Form('subscription-create-form')
    .addSelectField({
      name: 'type',
      label: 'subscriptionType:',
      options: [
        { value: 'zone', selected: true },
        { value: 'query' }
      ]
    })
    .addInputField({
      type: 'text',
      placeholder: 'Zone name',
      name: 'zone',
      label: 'zoneName:',
      value: 'myCustomZone'
    })
    .addCheckboxes({
      label: 'firesOn:',
      hidden: true,
      checkboxes: [
        { name: 'fires-on-create', label: 'create', value: 'create', checked: true },
        { name: 'fires-on-update', label: 'update', value: 'update', checked: true },
        { name: 'fires-on-delete', label: 'delete', value: 'delete', checked: true }
      ]
    })
    .addCheckboxes({
      label: 'filterBy:',
      hidden: true,
      checkboxes: [
        { name: 'filter-by', label: 'name', value: 'name' }
      ]
    })
    .addMultipleFields({
      hidden: true,
      number: 2
    })
    .addSelectField({
      name: 'comparator',
      options: [
        { value: 'EQUALS' },
        { value: 'NOT_EQUALS' },
        { value: 'BEGINS_WITH', selected: true },
        { value: 'NOT_BEGINS_WITH' }
      ]
    })
    .addInputField({
      type: 'text',
      name: 'filter',
      placeholder: 'Text',
      value: 'New'
    });

  var createSubscriptionIDForm = function(id) {
    return new CKCatalog.Form(id)
      .addInputField({
        type: 'text',
        name: 'subscription-id',
        label: 'subscriptionID:',
        placeholder: 'Subscription ID',
        value: ''
      });
  };

  var fetchSubscriptionSubscriptionIDForm = createSubscriptionIDForm('create-subscription-form');
  var deleteSubscriptionSubscriptionIDForm = createSubscriptionIDForm('delete-subscription-form');

  var subscriptionTypeField = subscriptionTypeForm.fields['type'];
  var zoneNameField = subscriptionTypeForm.fields['zone'];
  var filterByField = subscriptionTypeForm.fields['filter-by'];
  var firesOnFields = {
    create: subscriptionTypeForm.fields['fires-on-create'],
    update: subscriptionTypeForm.fields['fires-on-update'],
    delete: subscriptionTypeForm.fields['fires-on-delete']
  };

  var filterContainer = subscriptionTypeForm.getFieldRowForFieldName('comparator');

  subscriptionTypeField.addEventListener('change',function() {
    var zoneNameFieldContainer = subscriptionTypeForm.getFieldRowForFieldName('zone');
    var firesOnFieldContainer = subscriptionTypeForm.getFieldRowForFieldName('fires-on-create');
    var filterByFieldContainer = subscriptionTypeForm.getFieldRowForFieldName('filter-by');

    var focusZoneName = function() {
      zoneNameFieldContainer.classList.remove('hide');
      zoneNameField.focus();
      zoneNameField.select();
    };
    switch(subscriptionTypeField.value) {
      case 'zone':
        firesOnFieldContainer.classList.add('hide');
        filterByFieldContainer.classList.add('hide');
        filterContainer.classList.add('hide');
        focusZoneName();
        break;
      case 'query':
        firesOnFieldContainer.classList.remove('hide');
        filterByFieldContainer.classList.remove('hide');
        if(filterByField.checked) {
          filterContainer.classList.remove('hide');
        }
        focusZoneName();
        break;
    }
  });

  filterByField.addEventListener('change',function() {
    if(filterByField.checked) {
      filterContainer.classList.remove('hide');
    } else {
      filterContainer.classList.add('hide');
    }
  });

  var runSampleCode = function() {
    var subscriptionID = this.form.fields['subscription-id'].value;
    return this.sampleCode(subscriptionID);
  };

  var renderSubscriptions = function(title,subscriptions) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = title;
    var table = new CKCatalog.Table([
      'subscriptionID', 'subscriptionType', 'zoneID', 'firesOn', 'query', 'zoneWide'
    ]).setTextForEmptyRow('No subscriptions');
    if(subscriptions.length) {
      subscriptions.forEach(function (subscription,i) {
        if(i === 0) {

          // Populate subscription ID form fields with this ID for convenience.
          fetchSubscriptionSubscriptionIDForm.fields['subscription-id'].value = subscription.subscriptionID;
          deleteSubscriptionSubscriptionIDForm.fields['subscription-id'].value = subscription.subscriptionID;

        }
        table.appendRow([
          subscription.subscriptionID,
          subscription.subscriptionType,
          subscription.zoneID,
          subscription.firesOn,
          subscription.query,
          subscription.zoneWide
        ]);
      });
    } else {
      table.appendRow([]);
    }
    content.appendChild(heading);
    content.appendChild(table.el);
    return content;
  };

  var renderSubscription = function(title,object) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = title;
    var table = new CKCatalog.Table().renderObject(object);
    content.appendChild(heading);
    content.appendChild(table.el);
    return content;
  };

  var saveSubscriptionSample = {
    title: 'saveSubscription',
    form: subscriptionTypeForm,
    run: function() {
      var subscriptionType = subscriptionTypeField.value;
      var zoneName = zoneNameField.value;
      var firesOn;
      var filterBy;
      if(subscriptionType === 'query') {
        firesOn = [];
        for(var k in firesOnFields) {
          if(firesOnFields[k].checked) {
            firesOn.push(firesOnFields[k].value);
          }
        }
        if(filterByField.checked) {
          filterBy = {
            comparator: subscriptionTypeForm.fields['comparator'].value,
            value: subscriptionTypeForm.fields['filter'].value
          };
        }
      }
      return this.sampleCode(subscriptionType,zoneName,firesOn,filterBy);
    },
    sampleCode: function demoSaveSubscription(subscriptionType,zoneName,firesOn,filterBy) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      var subscription = {
        subscriptionType: subscriptionType
      };

      // If no zoneName is supplied for a query subscription,
      // it will be zone-wide.
      if(zoneName) {
        subscription.zoneID = { zoneName: zoneName };
      }

      if(subscriptionType === 'query' && firesOn) {

        subscription.firesOn = firesOn; // An array
                                        // like [ 'create', 'update', 'delete' ]

        subscription.query = { // A query object.
          recordType: 'Items'
        };

        if(filterBy) {
          subscription.query.filterBy = [{
            fieldName: 'name',
            comparator: filterBy.comparator, // e.g. 'EQUALS'.
            fieldValue: {
              value: filterBy.value // The text to match against.
            }
          }];
        }

      }

      return privateDB.saveSubscription(subscription).then(function(response) {
        if(response.hasErrors) {

          // Handle them in your app.
          throw response.errors[0];

        } else {
          var title = 'Created subscription:';
          return renderSubscription(title,response.subscriptions[0]);
        }
      });
    }
  };

  var deleteSubscriptionSample = {
    title: 'deleteSubscription',
    form: deleteSubscriptionSubscriptionIDForm,
    run: runSampleCode,
    sampleCode: function demoDeleteSubscription(subscriptionID) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      var subscription = {
        subscriptionID: subscriptionID
      };

      return privateDB.deleteSubscription(subscription).then(function(response) {
        if(response.hasErrors) {

          // Handle the error.
          throw response.errors[0];

        } else {
          var title = 'Deleted subscription:';
          return renderSubscription(title,response.subscriptions[0]);
        }
      });
    }
  };

  var fetchSubscriptionSample = {
    title: 'fetchSubscription',
    form: fetchSubscriptionSubscriptionIDForm,
    run: runSampleCode,
    sampleCode: function demoFetchSubscription(subscriptionID) {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      var subscription = {
        subscriptionID: subscriptionID
      };

      return privateDB.fetchSubscription(subscription).then(function(response) {
        if(response.hasErrors) {

          // Handle the error.
          throw response.errors[0];

        } else {
          var title = 'Fetched subscription:';
          return renderSubscription(title,response.subscriptions[0]);
        }
      });
    }
  };

  var fetchAllSubscriptionsSample = {
    title: 'fetchAllSubscriptions',
    sampleCode: function demoFetchAllSubscriptions() {
      var container = CloudKit.getDefaultContainer();
      var privateDB = container.privateCloudDatabase;

      return privateDB.fetchAllSubscriptions().then(function(response) {
        if(response.hasErrors) {

          // Handle the error.
          throw response.errors[0];

        } else {
          var title = 'Subscriptions:';
          return renderSubscriptions(title,response.subscriptions);
        }
      });
    }
  };

  return [ saveSubscriptionSample, deleteSubscriptionSample, fetchSubscriptionSample, fetchAllSubscriptionsSample ];

})();