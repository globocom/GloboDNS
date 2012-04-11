$(document).ready(function() {
	// ------------------- BIND -------------------
	$('.reload-bind-config-button').live('click', function () {
		$.rails.handleRemote($(this));
		return false;
	});

	$('.reload-bind-config-button').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('textarea#named_conf').val(data);
		return false;
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		alert("[ERROR] export failed");
	});

	$('.bind9-export-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.export-output pre').remove()
		$('.export-output').append(data)
		$('.export-output').show();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		alert("[ERROR] export failed");
	});
});
