/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The tab manager takes care of URL routing, selecting and constructing tabs,
    highlighting the code blocks, binding the run button handler, scrolling to the results, etc.
    Almost all functionality that is common to the tabs is to be found here.
*/

CKCatalog.tabManager = (function() {

  var self = {};

  var page = document.getElementById('page');
  var scrollView = page.parentNode;
  var menuItems = document.querySelectorAll('.menu-item');
  var runButton = document.getElementById('run-button');
  var defaultRoute = 'readme';

  var subTabs;
  var subTabMenuItems;
  var selectedTab;
  var selectedSubTabIndex = 0;
  var subTabMenus = {};

  var codeHighlightingIsInitialized = false;

  // Highlight the sample code if possible.
  var highlightCode = function() {
    if(typeof hljs !== 'undefined') {
      codeHighlightingIsInitialized = true;
      try {
        var codeSamples = document.querySelectorAll('pre code');
        for (var j = 0; j < codeSamples.length; j++) {
          hljs.highlightBlock(codeSamples[j]);
        }
      } catch (e) {
        console.error('Unable to highlight sample code: ' + e.message);
      }
    }
  };

  var runCode = function() {
    if(typeof CloudKit === 'undefined') {
      CKCatalog.dialog.showError(new Error(
        'The variable CloudKit is not defined. The CloudKit JS library may still be loading or may have failed to load.'
      ));
      return;
    }
    if(selectedTab) {
      var subTab = selectedTab[selectedSubTabIndex];
      CKCatalog.dialog.show('Executing…');
      var run = subTab.run ? subTab.run : subTab.sampleCode;
      try {
        run.call(subTab).then(function (content) {
          CKCatalog.dialog.hide();

          if (content && content instanceof Node) {
            // Replace the DOM content with the code results.
            subTab.content.replaceChild(content,subTab.content.firstChild);
            var heading = document.createElement('h1');
            heading.textContent = 'Result';
            content.insertBefore(heading,content.firstChild);
          }

          // Animate scrolling the results up the page.
          var padding = 39;
          var change = subTab.content.offsetTop - padding;
          subTab.content.style.minHeight = (scrollView.offsetHeight - padding) + 'px';
          var start = scrollView.scrollTop;
          var startTime = 0;
          var duration = 500;
          var easingValue = function(t) {
            var tc = (t/=duration)*t*t;
            return start + change*(tc);
          };
          var animateScroll = function(timestamp) {
            if(!startTime) {
              startTime = timestamp;
            }
            var progress = timestamp - startTime;
            scrollView.scrollTop = easingValue(Math.min(progress,duration));
            if(progress < duration) {
              window.requestAnimationFrame(animateScroll);
            } else {
              var results = subTab.content.firstChild;
              results.className = 'results';
            }
          };
          window.requestAnimationFrame(animateScroll);

        }, CKCatalog.dialog.showError);
      } catch(e) {
        CKCatalog.dialog.showError(e);
      }
    }
  };

  runButton.onclick = runCode;
  runButton.onmousedown = function() {
    runButton.parentNode.classList.add('active');
  };
  runButton.onmouseup = function() {
    runButton.parentNode.classList.remove('active');
  };

  var createSampleCodeSegment = function(tabSegment,selected) {
    var el = document.createElement('div');
    el.className = 'page-segment' + (selected ? ' selected' : '');
    el.appendChild(tabSegment.description);

    if(tabSegment.sampleCode) {
      var sampleCode = document.createElement('pre');
      sampleCode.className = 'javascript sample-code';
      // Fix up indentation.
      var sampleCodeString = tabSegment.sampleCode.toString();
      var indentationCorrection = sampleCodeString.lastIndexOf('}') - sampleCodeString.lastIndexOf('\n') - 1;
      var regExp = new RegExp('\n[ ]{' + indentationCorrection + '}', 'g');

      // Insert sample code into HTML.
      sampleCode.innerHTML = '<code>' + sampleCodeString.replace(regExp, '\n') + '</code>';
      if (!tabSegment.content) {
        tabSegment.content = document.createElement('div');
        tabSegment.content.className = 'content';
        tabSegment.content.innerHTML = '<div class="results"></div>';
      }

      if(tabSegment.form) {
        tabSegment.form.onSubmit(runCode);
        var formContainer = document.createElement('div');
        formContainer.className = 'input-fields';
        formContainer.appendChild(tabSegment.form.el);
        el.appendChild(formContainer);
        sampleCode.classList.add('no-top-border');
      }

      el.appendChild(sampleCode);
      el.appendChild(tabSegment.content);

      runButton.disabled = false;
      runButton.parentNode.classList.remove('disabled');
    } else {
      runButton.disabled = true;
      runButton.parentNode.classList.add('disabled');
    }
    return el;
  };

  var createSubTabMenu = function() {
    var menu = document.createElement('div');
    menu.className = 'tab-menu';
    return menu;
  };

  var createSubTabMenuItem = function(name,index) {
    var item = document.createElement('div');
    item.className = 'tab-menu-item' + (index === selectedSubTabIndex ? ' selected': '');
    item.textContent = name;
    item.onclick = function() {
      selectedSubTabIndex = index;
      subTabMenuItems.forEach(function(menuItem,i) {
        if(index === i) {
          menuItem.classList.add('selected');
        } else {
          menuItem.classList.remove('selected');
        }
      });
      subTabs.forEach(function(tagSegment,i) {
        if(index === i) {
          tagSegment.classList.add('selected');
        } else {
          tagSegment.classList.remove('selected');
        }
      });
      // Scroll to top.
      scrollView.scrollTop = 0;
    };
    return item;
  };

  // Now insert the submenus into the DOM in the left-hand pane.
  for(var tabName in CKCatalog.tabs) {
    if(CKCatalog.tabs.hasOwnProperty(tabName)) {
      if(CKCatalog.tabs[tabName].length > 1) {
        var subMenuContainer = document.querySelector('.left-pane .menu-items .menu-item-container.' + tabName);
        var subTabMenu = createSubTabMenu();
        subTabMenus[tabName] = [];
        CKCatalog.tabs[tabName].forEach(function(subTab,index) {
          subTabMenus[tabName].push(subTabMenu.appendChild(createSubTabMenuItem(subTab.title,index)));
        });
        subMenuContainer.appendChild(subTabMenu);
        subMenuContainer.classList.add('caret');
      }
    }
  }

  var getRoute = function() {
    var hash = window.location.hash;
    if(!hash || hash[0] !== '#') return defaultRoute;
    return hash.substr(1) || defaultRoute;
  };

  var selectTab = function() {
    var tabName = getRoute();
    var tab = CKCatalog.tabs[tabName];
    if(!tab) {
      tabName = 'not-found';
      tab = CKCatalog.tabs[tabName];
    }
    for(var i=0; i<menuItems.length; i++) {
      var menuItem = menuItems[i];
      if(menuItem.attributes.href.value === '#' + tabName) {
        menuItem.parentNode.classList.add('selected');
      } else {
        menuItem.parentNode.classList.remove('selected');
      }
    }
    // Scroll to top.
    scrollView.scrollTop = 0;

    var pageSegments = document.createElement('div');
    pageSegments.className = 'page-segments';
    subTabs = [];
    subTabMenuItems = subTabMenus[tabName];
    selectedSubTabIndex = 0;
    selectedTab = tab;
    var descriptions = document.getElementById(tabName);
    tab.forEach(function(tabSegment,index) {
      if(!tabSegment.description) {
        tabSegment.description = descriptions.firstElementChild;
      }
      if(subTabMenuItems) {
        if(index === selectedSubTabIndex) {
          subTabMenuItems[index].classList.add('selected');
        } else {
          subTabMenuItems[index].classList.remove('selected');

        }
      }
      subTabs.push(pageSegments.appendChild(createSampleCodeSegment(tabSegment,index === selectedSubTabIndex)));
    });
    page.replaceChild(pageSegments,page.firstElementChild);
    highlightCode();
  };

  // Set up URL routing.
  window.addEventListener('hashchange',selectTab);
  // select the default tab.
  selectTab();

  // This is the only public method on this singleton.
  self.initializeCodeHighlighting = function() {

    // Insert the stylesheet.
    var link = document.createElement('link');
    link.setAttribute('rel','stylesheet');
    link.setAttribute('href','https://cdn.apple-cloudkit.com/cloudkit-catalog/xcode.css');

    document.getElementsByTagName('head')[0].appendChild(link);

    // Highlight the code if necessary.
    link.onload = function() {
      if (!codeHighlightingIsInitialized) {
        highlightCode();
      }
    }

  };

  return self;

})();