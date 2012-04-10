//= require jquery.js
//# require jquery.min.js
//= require jquery.tipTip.js
//= require humane.js
//= require jquery_ujs.js
//# require jquery-ui.js
//# require prototip.js
//= require domains
//= require users
//= require_self

$(document).ready(function() {
    // ajax activity indicator
    $('body').append('<div id="ajaxBusy"><img src="/assets/loading.gif">Processing</div>');

    // setup tooltips where required
    $('.help-icon').each(function(i, icon){
        $(icon).tipTip({
            content: $( "#" + $(icon).data("help") ).text()
        });
    });
});

// ajax activity indicator bound to ajax start/stop document events
$(document).ajaxStart(function() {
    $('#ajaxBusy').show();
}).ajaxStop(function(){
    $('#ajaxBusy').hide();
});

//* rest of file omitted */
