/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Sample code for performing a location query for Items objects in the public database. Includes rendering helpers.
*/

CKCatalog.tabs['public-query'] = (function() {

  var renderItem = function (name, location, assetUrl) {
    var item = document.createElement('div');
    item.className = 'item';

    // Div to clear floats.
    var clear = document.createElement('div');
    clear.className = 'clear';

    // Build the img element.
    var imageEl = document.createElement('img');
    imageEl.src = assetUrl;
    imageEl.setAttribute('width', '300');
    imageEl.className = 'item-asset';

    // Build the name element.
    var nameEl = document.createElement('h1');
    nameEl.className = 'item-name';
    nameEl.textContent = name;

    // Build the location element.
    var locationEl = document.createElement('div');
    locationEl.className = 'item-location';

    var latitude = document.createElement('div');
    var latitudeTitle = document.createElement('span');
    latitudeTitle.className = 'item-location-title';
    latitudeTitle.textContent = 'Latitude: ';
    latitude.appendChild(latitudeTitle);
    latitude.appendChild(document.createTextNode(location.latitude));

    var longitude = document.createElement('div');
    var longitudeTitle = document.createElement('span');
    longitudeTitle.className = 'item-location-title';
    longitudeTitle.textContent = 'Longitude: ';
    longitude.appendChild(longitudeTitle);
    longitude.appendChild(document.createTextNode(location.longitude));

    locationEl.appendChild(latitude);
    locationEl.appendChild(longitude);

    // Append all children.
    item.appendChild(imageEl);
    item.appendChild(nameEl);
    item.appendChild(locationEl);
    item.appendChild(clear);

    return item;
  };

  var render = function(title) {
    var content = document.createElement('div');
    var heading = document.createElement('h2');
    heading.textContent = title;
    content.appendChild(heading);
    return content;
  };

  var getUsersPosition = function() {
    return new CloudKit.Promise(function(resolve) {
      var fallbackToSF = function() {
        var location = {
          latitude: 37.7833,
          longitude: -122.4167
        };

        var html = '<h2>Unable to lookup location of client</h2>' +
          '<p>Using location of San Francisco instead: </p>' +
          '<ul>' +
            '<li><b>Latitude: </b>'+location.latitude+'</li>' +
            '<li><b>Longitude: </b>'+location.longitude+'</li>' +
          '</ul>';

        CKCatalog.dialog.show(html, {
          title: 'Continue',
          action: function() {
            CKCatalog.dialog.show('Executing…');
            resolve(location);
          }
        });
      };
      try {
        navigator.geolocation.getCurrentPosition(function(position) {
          var coordinates = position.coords;
          resolve({
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
          });
        }, fallbackToSF);
      } catch(e) {
        fallbackToSF();
      }
    });
  };

  var publicQuerySample = {
    title: 'performQuery',
    sampleCode: function demoPerformQuery() {
      var container = CloudKit.getDefaultContainer();
      var publicDB = container.publicCloudDatabase;

      // Get the user's current geolocation.
      return getUsersPosition().then(function (position) {

        // position is an object containing keys 'latitude' and 'longitude'.

        // Set up a query that sorts results in ascending distance from the
        // user's location.
        var query = {
          recordType: 'Items',
          sortBy: [{
            fieldName: 'location',
            relativeLocation: position
          }]
        };

        // Execute the query.
        return publicDB.performQuery(query)
          .then(function (response) {
            if(response.hasErrors) {

              // Handle them in your app.
              throw response.errors[0];

            } else {
              var records = response.records;
              var numberOfRecords = records.length;
              if (numberOfRecords === 0) {
                return render('No matching items')
              } else {
                var el = render('Found ' + numberOfRecords + ' matching item'
                  + (numberOfRecords > 1 ? 's' : ''));
                records.forEach(function (record) {
                  var fields = record.fields;
                  el.appendChild(renderItem(
                    fields['name'].value,
                    fields['location'].value,
                    fields['asset'].value.downloadURL
                  ));
                });
                return el;
              }
            }
          })
      });
    }
  };

  return [ publicQuerySample ];

})();