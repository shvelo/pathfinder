var draw=require('./draw')
  , ui=require('./ui');

var mapElement;
var sidebarElement;
var toolbarElement;
var apikey;
var defaultCenterLat;
var defaultCenterLng;
var defaultZoom;
var map;

/**
 * This function is used to start the application.
 */
exports.start=function(opts){
  sidebarElement=document.getElementById((opts&&opts.sidebarid)||'sidebar');
  toolbarElement=document.getElementById((opts&&opts.toolbarid)||'toolbar');
  mapElement=document.getElementById((opts&&opts.mapid)||'map');
  defaultCenterLat=(opts&&opts.centerLat)||41.693328079546774;
  defaultCenterLng=(opts&&opts.centerLat)||44.801473617553710;
  defaultZoom=(opts&&opts.startZoom)||10;
  window.onload=loadingGoogleMapsAsyncronously;
};

var loadingGoogleMapsAsyncronously=function(){
  var host='https://maps.googleapis.com/maps/api/js';
  var script = document.createElement('script');
  script.type = 'text/javascript';
  if (apikey){ script.src = host+'?v=3.ex&key='+apikey+'&sensor=false&callback=onGoogleMapLoaded'; }
  else{ script.src = host+'?v=3.ex&sensor=false&callback=onGoogleMapLoaded'; }
  document.body.appendChild(script);
  window.onGoogleMapLoaded=onGoogleMapLoaded;
};

var onGoogleMapLoaded=function(){
  initMap();
};

var initMap=function(){
  var mapOptions = {
    zoom: defaultZoom,
    center: new google.maps.LatLng(defaultCenterLat,defaultCenterLng),
    mapTypeId: google.maps.MapTypeId.TERRAIN
  };
  map=new google.maps.Map(mapElement, mapOptions);

  // map.data.loadGeoJson('/test.json?v=1');
  // map.data.setStyle({
  //   strokeColor:'red',
  //   strokeOpacity:0.5,
  // });
  // map.data.addListener('mouseover', function(evt) {
  //   map.data.overrideStyle(evt.feature,{strokeWeight:10});
  // });
  // map.data.addListener('mouseout', function(evt) {
  //   map.data.revertStyle();
  // });

  var b1=ui.button.actionButton('გზის შენახვა', function(){
    var path=drawHandle.getPath();
    var points=[];
    path.forEach(function(element,index){
      points.push([element.lat(),element.lng()]);
    });
    $.post('/api/geo/new_path',{points:points},function(data) {
      console.log(data);
    });
  });
  toolbarElement.appendChild(b1);

  // draw path
  var drawHandle=draw.drawPath(map);
};