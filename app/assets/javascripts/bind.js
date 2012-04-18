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
		alert("[ERROR] reload failed");
	});

	$('.bind9-export-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.export-output').html(data)
		$('.export-output').show();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.export-output').html(xhr.responseText)
			$('.export-output').show();
		} else
			alert("[ERROR] export failed");
	});
});
