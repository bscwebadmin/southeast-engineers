/**
* Tom Select v2.1.0
* Licensed under the Apache License, Version 2.0 (the "License");
*/

/**
 * Converts a scalar to its best string representation
 * for hash keys and HTML attribute values.
 *
 * Transformations:
 *   'str'     -> 'str'
 *   null      -> ''
 *   undefined -> ''
 *   true      -> '1'
 *   false     -> '0'
 *   0         -> '0'
 *   1         -> '1'
 *
 */
const hash_key = value => {
  if (typeof value === 'undefined' || value === null) return null;
  return get_hash(value);
};
const get_hash = value => {
  if (typeof value === 'boolean') return value ? '1' : '0';
  return value + '';
};
/**
 * Prevent default
 *
 */

const preventDefault = (evt, stop = false) => {
  if (evt) {
    evt.preventDefault();

    if (stop) {
      evt.stopPropagation();
    }
  }
};

// @ts-ignore TS2691 "An import path cannot end with a '.ts' extension"
const latin_convert = {
  'æ': 'ae',
  'ⱥ': 'a',
  'ø': 'o'
};
new RegExp(Object.keys(latin_convert).join('|'), 'gu');

/**
 * Return a dom element from either a dom query string, jQuery object, a dom element or html string
 * https://stackoverflow.com/questions/494143/creating-a-new-dom-element-from-an-html-string-using-built-in-dom-methods-or-pro/35385518#35385518
 *
 * param query should be {}
 */

const getDom = query => {
  if (query.jquery) {
    return query[0];
  }

  if (query instanceof HTMLElement) {
    return query;
  }

  if (isHtmlString(query)) {
    let div = document.createElement('div');
    div.innerHTML = query.trim(); // Never return a text node of whitespace as the result

    return div.firstChild;
  }

  return document.querySelector(query);
};
const isHtmlString = arg => {
  if (typeof arg === 'string' && arg.indexOf('<') > -1) {
    return true;
  }

  return false;
};

/**
 * Plugin: "restore_on_backspace" (Tom Select)
 * Copyright (c) contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at:
 * http://www.apache.org/licenses/LICENsection-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language
 * governing permissions and limitations under the License.
 *
 */
function plugin () {
  var self = this;
  var orig_onOptionSelect = self.onOptionSelect;
  self.settings.hideSelected = false; // update the checkbox for an option

  var UpdateCheckbox = function UpdateCheckbox(option) {
    setTimeout(() => {
      var checkbox = option.querySelector('input');

      if (checkbox instanceof HTMLInputElement) {
        if (option.classList.contains('selected')) {
          checkbox.checked = true;
        } else {
          checkbox.checked = false;
        }
      }
    }, 1);
  }; // add checkbox to option template


  self.hook('after', 'setupTemplates', () => {
    var orig_render_option = self.settings.render.option;

    self.settings.render.option = (data, escape_html) => {
      var rendered = getDom(orig_render_option.call(self, data, escape_html));
      var checkbox = document.createElement('input');
      checkbox.addEventListener('click', function (evt) {
        preventDefault(evt);
      });
      checkbox.type = 'checkbox';
      const hashed = hash_key(data[self.settings.valueField]);

      if (hashed && self.items.indexOf(hashed) > -1) {
        checkbox.checked = true;
      }

      rendered.prepend(checkbox);
      return rendered;
    };
  }); // uncheck when item removed

  self.on('item_remove', value => {
    var option = self.getOption(value);

    if (option) {
      // if dropdown hasn't been opened yet, the option won't exist
      option.classList.remove('selected'); // selected class won't be removed yet

      UpdateCheckbox(option);
    }
  }); // check when item added

  self.on('item_add', value => {
    var option = self.getOption(value);

    if (option) {
      // if dropdown hasn't been opened yet, the option won't exist
      UpdateCheckbox(option);
    }
  }); // remove items when selected option is clicked

  self.hook('instead', 'onOptionSelect', (evt, option) => {
    if (option.classList.contains('selected')) {
      option.classList.remove('selected');
      self.removeItem(option.dataset.value);
      self.refreshOptions();
      preventDefault(evt, true);
      return;
    }

    orig_onOptionSelect.call(self, evt, option);
    UpdateCheckbox(option);
  });
}

export { plugin as default };
//# sourceMappingURL=plugin.js.map
