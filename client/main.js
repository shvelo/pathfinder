var googlemaps = require('./googlemaps');
var api = require('./api');
var search = require('./search');

var logger = function(message) {
  var el = document.getElementById('messages');
  if( message ) { el.innerHTML = '<span>' + message + '</span>'; }
  else { el.innerHTML = ''; }
};

logger('იტვირთება...');

googlemaps.start().then(googlemaps.create).then(function(map) {
  // setting loggers
  map.logger = api.logger = search.logger = logger;

  // loading data & initialize search
  api.loadTowers().then(map.showTowers)
    .then(api.loadSubstations).then(map.showSubstations)
    .then(api.loadTps).then(map.showTps)
    .then(api.loadPoles).then(map.showPoles)
    .then(map.loadLines)
    .then(function() {
      search.initialize(map)
    })
    ;
});
