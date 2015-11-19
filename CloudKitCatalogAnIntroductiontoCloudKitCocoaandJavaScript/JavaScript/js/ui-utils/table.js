/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A Table builder class.
*/

/**
 * The Table builder class.
 * @param {Array|undefined} heading An array of column titles or don't supply this if you want a
 *                                  table of rows containing a key heading cell and a value normal table cell.
 * @constructor
 */
CKCatalog.Table = function(heading) {
  this.el = document.createElement('div');
  this.el.className = 'table-wrapper';
  this._numberOfColumns = 2;

  var table = document.createElement('table');
  if(heading && Array.isArray(heading)) {
    this._numberOfColumns = heading.length;
    var head = table.appendChild(document.createElement('thead'));
    var tr = head.appendChild(document.createElement('tr'));
    heading.forEach(function(name) {
      var th = document.createElement('th');
      th.textContent = name;
      tr.appendChild(th);
    });
    this.body = table.appendChild(document.createElement('tbody'));
  } else {
    this.body = table;
  }

  this.el.appendChild(table);
};

/**
 * Display an object of key-value pairs in a table
 * @param {object} object Key-value pairs to display in a table
 * @returns {CKCatalog.Table}
 */
CKCatalog.Table.prototype.renderObject = function(object) {
  for(var k in object) {
    if(object.hasOwnProperty(k)) {
      this.appendRow(k,object[k]);
    }
  }
  return this;
};

/**
 * Sets the text for a cell with an undefined value.
 * @param {string} text
 * @returns {CKCatalog.Table}
 */
CKCatalog.Table.prototype.setTextForUndefinedValue = function(text) {
  this._textForUndefinedValue = text;
  return this;
};

/**
 * Sets the text for an empty row.
 * @param {string} text
 * @returns {CKCatalog.Table}
 */
CKCatalog.Table.prototype.setTextForEmptyRow = function(text) {
  this._textForEmptyRow = text;
  return this;
};

CKCatalog.Table.prototype._textForUndefinedValue = '-';
CKCatalog.Table.prototype._textForEmptyRow = 'No Content';


CKCatalog.Table.prototype._createRowWithKey = function(key) {
  var tr = document.createElement('tr');

  var th = document.createElement('th');
  th.textContent = key;

  tr.appendChild(th);
  return tr;
};

CKCatalog.Table.prototype._createRowWithValues = function(values,boolArray) {
  var tr = document.createElement('tr');
  var that = this;
  values.forEach(function(value,index) {
    var td;
    if(value === null || value === undefined) {
      td = that._createEmptyValueCell();
    } else {
      td = document.createElement('td');
      if(boolArray && !boolArray[index]) {
        if(typeof value === 'object' && !(value instanceof Date)) {
          td.appendChild(that._createPrettyObject(value));
        } else {
          td.textContent = that._prettyPrintValue(value);
        }
      } else {
        td.innerHTML = value;
      }
    }
    tr.appendChild(td);
  });
  return tr;
};

CKCatalog.Table.prototype._createEmptyRow = function() {
  var tr = document.createElement('tr');
  tr.innerHTML = '<td class="light align-center" colspan="'+
    this._numberOfColumns + '">' + this._textForEmptyRow + '</td>';
  tr.className = 'empty';
  return tr;
};

CKCatalog.Table.prototype._createEmptyValueCell = function() {
  var td = document.createElement('td');

  var span = document.createElement('span');
  span.className = 'light';
  span.textContent = this._textForUndefinedValue;

  td.appendChild(span);
  return td;
};

CKCatalog.Table.prototype._createRowWithHtmlValues = function(keyOrValues,html) {
  var tr;
  if(Array.isArray(keyOrValues)) {
    tr = this._createRowWithValues(keyOrValues,html);
  } else {
    tr = this._createRowWithKey(keyOrValues);
    var td = document.createElement('td');
    td.innerHTML = html;
    tr.appendChild(td);
  }
  return tr;
};

CKCatalog.Table.prototype._prettyPrintValue = function(value) {
  if(value instanceof Date) {
    return value.toLocaleString();
  } else if(typeof value === 'object') {
    return JSON.stringify(value,null,'  ');
  } else {
    return value;
  }
};

CKCatalog.Table.prototype._createPrettyObject = function(object) {
  var el = document.createElement('div');
  el.className = 'object';
  if(Array.isArray(object)) {
    el.textContent = object.join(', ');
  } else {
    for (var k in object) {
      if (object.hasOwnProperty(k)) {
        var key = document.createElement('span');
        key.className = 'object-key';
        key.textContent = k + ':';

        var val;
        if(typeof object[k] === 'object' && !(object[k] instanceof Date)) {
          val = document.createElement('pre');
        } else {
          val = document.createElement('span');
        }
        val.className = 'object-value';
        val.textContent = this._prettyPrintValue(object[k]);

        var wrapper = document.createElement('div');
        wrapper.appendChild(key);
        wrapper.appendChild(val);
        el.appendChild(wrapper);
      }
    }
  }
  return el;
};

CKCatalog.Table.prototype._createRow = function(keyOrValues,value) {
  var tr;
  if(Array.isArray(keyOrValues)) {
    if(keyOrValues.length === 0) {
      tr = this._createEmptyRow();
    } else {
      tr = this._createRowWithValues(keyOrValues, []);
    }
  } else {
    tr = this._createRowWithKey(keyOrValues);
    var td;
    if(value === null || value === undefined) {
      td = this._createEmptyValueCell();
    } else {
      td = document.createElement('td');
      if(typeof value === 'object' && !(value instanceof Date)) {
        td.appendChild(this._createPrettyObject(value));
      } else {
        td.textContent = this._prettyPrintValue(value);
      }
    }
    tr.appendChild(td);
  }
  return tr;
};

CKCatalog.Table.prototype.appendRow = function(keyOrValues,value) {
  var tr = this._createRow(keyOrValues,value);
  this.body.appendChild(tr);
  return this;
};

CKCatalog.Table.prototype.prependRow = function(keyOrValues,value) {
  var tr = this._createRow(keyOrValues,value);
  this.body.insertBefore(tr,this.body.firstChild);
  return this;
};

/**
 * Adds a row to the Table with HTML value(s).
 * @param keyOrValues if this is an Array then 'html' will be interpreted as an array of booleans indicating which values
 *                    are to be treated as HTML or if undefined then all values will be treated as html
 * @param html
 * @returns {CKCatalog.Table}
 */
CKCatalog.Table.prototype.appendRowWithHtmlValues = function(keyOrValues,html) {
  var tr = this._createRowWithHtmlValues(keyOrValues,html);
  this.body.appendChild(tr);
  return this;
};

/**
 * Prepends a row with HTML value(s) to the Table.
 * @param keyOrValues
 * @param html
 * @returns {CKCatalog.Table}
 */
CKCatalog.Table.prototype.prependRowWithHtmlValues = function(keyOrValues,html) {
  var tr = this._createRowWithHtmlValues(keyOrValues,html);
  this.body.insertBefore(tr,this.body.firstChild);
  return this;
};

/**
 * Appends a row with a download link to a url.
 * @param {string} name
 * @param {string} url
 * @returns {CKCatalog.Table}
 */
CKCatalog.Table.prototype.appendRowWithDownloadLink = function(name,url) {
  if(!url) {
    return this.appendRow(name);
  }
  return this.appendRowWithHtmlValues(name,'<a class="link" href="' + url + '" download>Download</a>');
};

/**
 * Prepends a row with a download link to a url.
 * @param {string} name
 * @param {string} url
 * @returns {CKCatalog.Table}
 */
CKCatalog.Table.prototype.prependRowWithDownloadLink = function(name,url) {
  if(!url) {
    return this.prependRow(name);
  }
  return this.prependRowWithHtmlValues(name,'<a class="link" href="' + url + '" download>Download</a>');
};