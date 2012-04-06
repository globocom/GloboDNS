//= require jquery.js
//# require jquery.min.js
//= require jquery.tipTip.js
//= require humane.js
//= require jquery_ujs.js
//= require jquery-ui.js
//# require prototip.js
//= require_self

$(document).ready(function() {
  // display button-like elements as jquery-ui buttons
  $('.ui-button, button, input[type="submit"]').each(function(i, e) {
      var elem    = $(e);
      var options = {};

      if (console)
          console.log(elem);
      if (elem.attr("class")) {
          var match = elem.attr("class").match(/(ui\-icon\-[\w\d\-]+)/);
          if (match)
              options["icons"] = {"primary": match[1]};
      }
      if (elem.attr("icon"))
          options["icons"] = {"primary": elem.attr("icon")};
      if ((elem.attr("icon-only") === "true") || elem.hasClass("ui-button-icon-only"))
          options["text"] = false;
      if ((elem.attr("text-only") === "true") || elem.hasClass("ui-button-text-only"))
          options["icons"] = false;
      if (console)
          console.log("[INFO] creating button with options:", options)
      elem.button(options);
  });

  // AJAX activity indicator
  $('body').append('<div id="ajaxBusy"><img src="/assets/loading.gif">Processing</div>');

  // Setup tooltips where required
  $('.help-icn').each(function(i, icon){
    $(icon).tipTip({
      content: $( "#" + $(icon).data("help") ).text()
    });
  });

  // Used by the new record form
  $('#record-form #record_type').change(function() {
    toggleRecordFields( $(this).val() );
  });

  // Used by the new domain form
  $('#domain_type').change(function() {
    if ( $(this).val() == 'SLAVE' ) {
      $('#master-address').show();
      $('#zone-templates').hide();
      $('#no-template-input').hide();
    } else {
      $('#master-address').hide();
      $('#zone-templates').show();
      $('#no-template-input').show();
    }
  });

  // Used by the new domain form
  $('#domain_zone_template_id').change(function() {
    if ( $(this).val() == '' ) {
      $('#no-template-input').show();
    } else {
      $('#no-template-input').hide();
    }
  });

  // Used by the new record template form
  $('#record-form #record_template_record_type').change(function() {
    toggleRecordFields( $(this).val() );
  });

  // Used by the new macro step form
  $('#record-form #macro_step_record_type').change(function() {
    toggleRecordFields( $(this).val() );
  });
});

// Ajax activity indicator bound to ajax start/stop document events
$(document).ajaxStart(function(){ 
  $('#ajaxBusy').show(); 
}).ajaxStop(function(){ 
  $('#ajaxBusy').hide();
});

//* rest of file omitted */
