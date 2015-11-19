/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A helper class for building forms.
 */

/**
 * The Form class which contains the properties 'el' (HTML element) and 'fields' (a map of name -> HTML input field).
 * @param id The id of the form element.
 * @constructor
 */
CKCatalog.Form = function Form(id) {
  this.el = document.createElement('form');
  this.el.setAttribute('action','#');
  this.el.setAttribute('method','post');
  this.el.id = id;
  this.table = this.el.appendChild(document.createElement('table'));

  var submitButton = document.createElement('input');
  submitButton.setAttribute('type','submit');
  submitButton.setAttribute('name','submit');
  submitButton.style.display = 'none';

  this.el.appendChild(submitButton);
  this.fields = [];
  this._multipleFields = 0;
  this._multipleFieldsContainer = null;
};

/**
 * Sets the fields to follow to be wrapped inside a single row
 * @param {object} opts An object containing keys 'number' and 'hidden' (optional).
 */
CKCatalog.Form.prototype.addMultipleFields = function(opts) {
  this._multipleFieldsContainer = this._createFieldContainer(opts);
  this._multipleFields = opts.number;
  return this;
};

CKCatalog.Form.prototype._createRelativeId = function(name) {
  return this.el.id + '-' + name;
};

CKCatalog.Form.prototype._createFieldContainer = function(opts) {
  if(this._multipleFields) {
    this._multipleFields--;
    return this._multipleFieldsContainer;
  }

  var tr = document.createElement('tr');
  tr.className = 'field';
  if(opts.hidden) {
    tr.classList.add('hide');
  }
  if(opts.number) {
    tr.classList.add('multiple');
    tr.classList.add('has-' + opts.number + '-fields');
  }

  var labelContainer = document.createElement('th');

  if(opts.label) {
    var label = document.createElement('label');
    label.textContent = opts.label;
    if (opts.name) {
      label.setAttribute('for', this._createRelativeId(opts.name));
    }
    labelContainer.appendChild(label);
  }

  tr.appendChild(labelContainer);
  var td = document.createElement('td');
  return tr.appendChild(td);
};

/**
 * Adds an email input field to the form object.
 * @param {object} opts An object containing keys 'name','placeholder','value','label','type','hidden' (optional).
 * @returns {CKCatalog.Form}
 */
CKCatalog.Form.prototype.addInputField = function(opts) {
  var fieldContainer = this._createFieldContainer(opts);
  var inputContainer = document.createElement('div');
  inputContainer.className = 'border';

  var input = document.createElement('input');
  input.setAttribute('type',opts.type);
  input.setAttribute('name',opts.name);
  input.setAttribute('placeholder',opts.placeholder);
  input.id = this._createRelativeId(opts.name);
  input.value = opts.value;

  this.fields[opts.name] = input;
  inputContainer.appendChild(input);
  fieldContainer.appendChild(inputContainer);
  this.table.appendChild(fieldContainer.parentNode);

  return this;
};

/**
 * Adds a file input field that is stylable.
 * @param {object} opts An object with keys 'name', 'label', 'hidden' (optional).
 * @returns {CKCatalog.Form}
 */
CKCatalog.Form.prototype.addFileInputField = function(opts) {
  var fieldContainer = this._createFieldContainer(opts);
  var inputContainer = document.createElement('div');
  inputContainer.className = 'border';

  var input = document.createElement('input');
  input.setAttribute('type','file');
  input.setAttribute('name',opts.name);
  input.id = this._createRelativeId(opts.name);

  var fakeInput = document.createElement('div');
  fakeInput.className = 'fake-file-input';

  var selectFileButton = document.createElement('button');
  selectFileButton.className = 'link';
  selectFileButton.textContent = 'Choose File…';

  var span = document.createElement('span');
  span.className = 'file-name';

  input.addEventListener('change', function() {
    var file = input.files[0];
    span.textContent = file ? file.name : '';
  });

  fakeInput.appendChild(selectFileButton);
  fakeInput.appendChild(span);
  inputContainer.appendChild(fakeInput);
  inputContainer.appendChild(input);
  fieldContainer.appendChild(inputContainer);

  this.fields[opts.name] = input;
  this.table.appendChild(fieldContainer.parentNode);

  return this;
};

/**
 * Adds a select dropdown field to the form object.
 * @param {object} opts An object containing keys 'name','options','label','hidden' (optional)
 *                      where options is an array of objects containing keys
 *                      'title', 'value', and 'selected' (optional).
 * @returns {CKCatalog.Form}
 */
CKCatalog.Form.prototype.addSelectField = function(opts) {
  var fieldContainer = this._createFieldContainer(opts);
  var selectContainer = document.createElement('div');
  selectContainer.className = 'border select';

  var select = document.createElement('select');
  select.setAttribute('name',opts.name);
  select.id = this._createRelativeId(opts.name);
  opts.options.forEach(function(opt) {
    var option = document.createElement('option');
    option.textContent = opt.title || opt.value;
    option.setAttribute('value',opt.value);
    if(opt.selected) {
      option.setAttribute('selected','');
    }
    select.appendChild(option);
  });
  this.fields[opts.name] = select;

  selectContainer.appendChild(select);
  fieldContainer.appendChild(selectContainer);
  this.table.appendChild(fieldContainer.parentNode);

  return this;
};

/**
 * Adds a row of checkboxes.
 * @param {object} opts An object containing keys 'checkboxes', 'hidden' (optional)
 *                      where checkboxes is an array of objects containing keys
 *                      'label','name','value','checked' (optional).
 * @returns {CKCatalog.Form}
 */
CKCatalog.Form.prototype.addCheckboxes = function(opts) {
  var fieldContainer = this._createFieldContainer(opts);
  var checkboxesContainer = document.createElement('div');
  checkboxesContainer.className = 'checkboxes';
  var fields = this.fields;
  var that = this;

  opts.checkboxes.forEach(function(checkbox) {
    var checkboxContainer = document.createElement('div');
    checkboxContainer.className = 'checkbox';

    var label = document.createElement('label');
    label.setAttribute('for',that._createRelativeId(checkbox.name));
    label.textContent = checkbox.label;

    var input = document.createElement('input');
    input.setAttribute('type','checkbox');
    input.setAttribute('name',checkbox.name);
    input.setAttribute('value',checkbox.value);
    input.id = that._createRelativeId(checkbox.name);

    if(checkbox.checked) {
      input.setAttribute('checked','');
    }
    fields[checkbox.name] = input;

    checkboxContainer.appendChild(label);
    checkboxContainer.appendChild(input);
    checkboxesContainer.appendChild(checkboxContainer);
  });

  fieldContainer.appendChild(checkboxesContainer);
  this.table.appendChild(fieldContainer.parentNode);

  return this;
};

/**
 * Attaches a submit handler to the form.
 * @param {function} handler
 */
CKCatalog.Form.prototype.onSubmit = function(handler) {
  this.el.onsubmit = function(e) {
    e.preventDefault();
    handler();
  };
};


/**
 * Gets the row container element for an input field by name.
 * @param {string} fieldName
 * @returns {Node | null}
 */
CKCatalog.Form.prototype.getFieldRowForFieldName = function(fieldName) {
  var field = this.fields[fieldName];
  if(field) {
    var el = field;
    while(el.parentNode) {
      el = el.parentNode;
      if(el.classList.contains('field')) {
        return el;
      }
    }
  }
  return null;
};
