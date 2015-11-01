WithSchemaEditor
===================

JSON/YAML Editor with schemas - using [JSON Editor](https://github.com/jdorn/json-editor)

Schema plugins are required, whose package name begins with `with-schema-editor-schema-`.

Schema Plugin
-------------------
WithSchemaEditor requires "schema plugins", node modules whose package name starts with `with-schema-editor-schema-`.

Since node modules' minimal form only requires `index.js`, minimal schema plugin is like below.

- node_modules/with-schema-editor-schema-foo/index.js
```javascript

var fs = require('fs');

module.exports = {
  name: 'foo plugin', // schema plugin name
  read_type: 'file', // file / directory / both
  filters: function() { // file dialog filters (electron)
    return [
      {
        name: 'JSON',
        extensions: ['json']
      }, {
        name: 'All files',
        extensions: ['*']
      }
    ];
  },
  read: function(file, editor) { // read file function
    this.file = file;
    return JSON.parse(fs.readFileSync(file));
  },
  oneditor: function(editor) { // called on editor initialized
    return editor.on('change', (function(_this) {
      return function() {
        return fs.writeFileSync(_this.file, JSON.stringify(editor.getValue()));
      };
    })(this));
  },
  schema: function() { // JSON schema (JSON Editor)
    return {
      title: 'config',
      type: 'object',
      format: 'grid',
      properties: {
        target: {
          title: 'Target',
          type: 'string'
        },
        schema: {
          title: 'Schema Name',
          type: 'string'
        }
      }
    };
  }
};
```

License
-------------------
This is released under [MIT License](http://narazaka.net/license/MIT?2015).
