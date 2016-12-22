/* global require, google */

var _ = require('lodash'),
  objectTypes = require('./object-types'),
  api = require('./api');

var data = {};

var $output = $("#search-output");

var view = {
  resizeOutput: function () {
    $(".search .scrollable").css("max-height", $(window).innerHeight() - 50)
  },

  initSearch: function () {
    var field = $('#search-query');
    var typeField = $('#search-types');
    var regionField = $("#search-region");
    var form = $("#search-form");

    form.submit(function (event) {
      event.preventDefault();

      var q = field.val();

      if (q.length < 2) return;

      var type = [];

      typeField.find("input[type=checkbox]:checked").each(function () {
        type.push($(this).val());
      });

      var filters = {name: q, type: type};

      if (regionField.val() != "") {
        filters.region = regionField.val();
      }

      var $btn = $("#search-form").find(".btn");
      $btn.prop("disabled", "disabled").addClass("loading");

      $.get(api.getUrl("/api/search/by_name"), filters).done(function (data) {
        $btn.prop("disabled", false).removeClass("loading");
        view.displayMarkers(q, data);
      }).error(function () {
        $btn.removeProp("disabled", false).removeClass("loading");
      });
    });

    field.on('click', function () {
      if ($output.find(".collection .collection-item").length > 0) {
        $output.show();
      }
    });

    $(window).on('resize', view.resizeOutput);
    view.resizeOutput();
  },

  renderMarker: function (marker) {
    var realMarker;
    var markers = data.map.objects;

    realMarker = _.find(markers, _.matchesProperty('id', marker.id));

    if (!realMarker) {
      markers = data.map.showObjects([marker]);
      realMarker = markers[0];
    }

    var m = _.template('<a class="search-marker collection-item">'
      + '<span class="type"><%=type%></span> '
      + '<span class="name"><%=name%></span> '
      + '<span class="moreinfo"><%=moreinfo%> მუნიციპალიტეტი: <%=region%></span>'
      + '</a>');
    var el = $(m({
      name: marker.name,
      region: marker.region.name,
      type: (objectTypes[marker.type].name || marker.type),
      moreinfo: marker.info
    }));
    el.click(function () {
      var zoom = objectTypes[marker.type].zoom;

      if (data.map.zoom < zoom) data.map.setZoom(zoom);
      if (marker.lat && marker.lng) data.map.setCenter({lat: marker.lat, lng: marker.lng});

      if(view.oldSearchMarker)
        view.oldSearchMarker.setMap(null);

      view.oldSearchMarker = new google.maps.Marker({
        position: {lat: marker.lat, lng: marker.lng},
        map: map
      });

      setTimeout(function () {
        realMarker.setVisible(true);
        google.maps.event.trigger(realMarker, 'click');
      }, 500);
    });
    return el;
  },

  displayMarkers: function (q, markers) {
    var renderCollection = function (array, output) {
      _.forEach(array, function (item) {
        var element = view.renderMarker(item);
        output.append(element);
      });
    };

    $output.show();
    var summary = _.template('ნაპოვნია: <strong><%=length%></strong> ობიექტი');
    $output.find(".summary").html(summary({length: markers.length}));
    var output = $output.find('.collection');
    output.html('');
    renderCollection(markers, output);
  }
};

module.exports = {
  initialize: function (map) {
    data.map = map;
    view.initSearch();
    view.resizeOutput();
  }
};
