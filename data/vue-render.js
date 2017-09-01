const Vue = require('vue');

module.exports = {
  renderToString: function(app) {
    const renderer = require('vue-server-renderer').createRenderer();

    renderer.renderToString(app, (err, html) => {
      if (err) {
        console.log('<pre>' + err.stack.replace('&', '&amp;').
          replace('<', '&lt;').replace('>', '&gt;') + '</pre>')
      } else {
        console.log(html) 
      } 
    })
  }
}


