//     puts.js
//     Sergey Klimov <sergey.v.klimov@gmail.com>
//     https://github.com/darvin/node-puts

(function() {
  var treefy = require('treeify');
  module.exports = function(obj) {
    var result = treefy.asTree(obj, true,true);
    if (!result) {
      console.log(obj);
    } else {
      console.log(result);
    }
  };


})();
