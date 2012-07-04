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
//= require audits
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

	// ----------------- ajax pagination ---------------
	// will_paginate does not support link attributes yet.
	// See: https://github.com/mislav/will_paginate/pull/100
	$('.pagination a').live('click', function () {
		$.rails.handleRemote($(this));
		return false;
	});
});

// ajax activity indicator bound to ajax start/stop document events
$(document).ajaxStart(function() {
    $('#ajaxBusy').show();
}).ajaxStop(function(){
    $('#ajaxBusy').hide();
});


$(document).ajaxComplete(function(evt, xhr, options) {
	$.fn.flashMessage(xhr);
});

//* rest of file omitted */
