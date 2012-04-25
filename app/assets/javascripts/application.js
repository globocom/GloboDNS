//= require jquery.js
//# require jquery.min.js
//= require jquery.tipTip.js
//= require humane.js
//= require jquery_ujs.js
//# require jquery-ui.js
//# require prototip.js
//= require domains
//= require domain_templates
//= require users
//= require views
//= require bind
//= require_self

$(document).ready(function() {
    // ajax activity indicator
    $('body').append('<div id="ajaxBusy"><img src="/assets/loading.gif"></div>');

    // setup tooltips where required
    $('.help-icon').each(function(i, icon){
        $(icon).tipTip({
            content: $( "#" + $(icon).data("help") ).text()
        });
    });

	$.fn.flashMessage = function(xhr) {
		var message     = xhr.getResponseHeader('x-flash');
		var messageType = xhr.getResponseHeader('x-flash-type');

		if (!message || !messageType)
			return;

		var container = $('.flash-ajax.flash-' + messageType);
		if (container.empty()) {
			var container = $('<div class="flash-ajax flash-' + messageType + '"></div>');
			$('body').append(container);
		}
		container.html(message).show().delay(2000).fadeOut('slow');
	};
});

// ajax activity indicator bound to ajax start/stop document events
$(document).ajaxStart(function() {
    $('#ajaxBusy').show();
}).ajaxStop(function(){
    $('#ajaxBusy').hide();
});


$(document).ajaxComplete(function(evt, xhr, options) {
	if (console) { console.log("[global ajax complete]"); console.log("evt: ", evt); console.log("xhr: ", xhr); console.log("opt: ", options); }
	if (console) { console.log("[all response headers]", xhr.getAllResponseHeaders()); }
	$.fn.flashMessage(xhr);
});

//* rest of file omitted */
