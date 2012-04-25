$(document).ready(function() {

	// ----------------- ajax pagination ---------------
	// will_paginate does not support link attributes yet.
	// See: https://github.com/mislav/will_paginate/pull/100
	$('.pagination a').live('click', function () {
		$.rails.handleRemote($(this));
		return false;
	});

	// ----------------- domains#index -----------------
	
	$('.new-domain-button').click(function () {
		$(this).hide();
		$('.new-domain-form-container').show();
		return false;
	});

	$('#domains-table-pagination a').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.domains-table-container').replaceWith(data);
	}).live('ajax:error', function () {
		alert("[ERROR] unable to retrieve domains");
	});

	$('.cancel-new-domain-button').live('click', function () {
		$('.new-domain-form-container').hide();
		$('.new-domain-button').show();
		return false;
	});

	$('.new-domain-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.create-domain-button').click();
			return false;
		}
	});

	$('.new-domain-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.new-domain-form-container ul.errors').remove();
		$('table#domains-table').append(data);
		fixDomainsTableZebraStriping();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.new-domain-form-container ul.errors').remove();
			$('.new-domain-form-container').prepend(xhr.responseText);
		} else
			alert("[ERROR] unable to create Domain");
	});

	var fixDomainsTableZebraStriping = function () {
		$('table#domains-table tr:nth-child(even)').addClass("even").removeClass("odd");
		$('table#domains-table tr:nth-child(odd)').addClass("odd").removeClass("even");
	}

	$('select#domain_domain_template_id').live('change', function (evt) {
		if ($(this).val() == '') {
			$(this).closest('tbody').find('tr.template').addClass('hidden-by-domain-template');
			$(this).closest('tbody').find('tr.notemplate').removeClass('hidden-by-domain-template');
		} else {
			$(this).closest('tbody').find('tr.notemplate').addClass('hidden-by-domain-template');
			$(this).closest('tbody').find('tr.template').removeClass('hidden-by-domain-template');
		}
		$(this).blur();
	});
	$('select#domain_domain_template_id').change();

	$('select#domain_authority_type').live('change', function (evt) {
		if ($(this).val() == 'M') {
			$(this).closest('tbody').find('tr.slave').addClass('hidden-by-authority-type');
			$(this).closest('tbody').find('tr.master').removeClass('hidden-by-authority-type');
		} else if ($(this).val() == 'S') {
			$(this).closest('tbody').find('tr.master').addClass('hidden-by-authority-type');
			$(this).closest('tbody').find('tr.slave').removeClass('hidden-by-authority-type');
		}
		$(this).blur();
	});
	$('select#domain_authority_type').change();



	// ----------------- domains#show -----------------
	// ------------------- Domain -------------------
	$('.edit-domain-button').click(function () {
		$('.show-domain-container').hide();
		$('.edit-domain-container').show();
		$(this).hide();
		return false;
	});

	// $('select#domain_authority_type').live('change', function (evt) {
	// 	if ($(this).val() == 'MASTER')
	// 		$('table#edit-domain input#domain_master').closest('tr').hide();
	// 	else if ($(this).val() == 'SLAVE')
	// 		$('table#edit-domain input#domain_master').closest('tr').show();
	// });
	// $('table#edit-domain select#domain_authority_type').change();

	$('.cancel-update-domain-button').live('click', function () {
		$('.edit-domain-container').hide();
		$('.show-domain-container').show();
		$('.edit-domain-button').show();
		return false;
	});

	$('.update-domain-button').live('click', function () {
		$('.update-domain-form').submit();
		return false;
	});

	$('.update-domain-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.update-domain-button').click();
			return false;
		}
	});

	$('.update-domain-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.edit-domain-container').remove();
		$('.show-domain-container').replaceWith(data);
		$('.edit-domain-button').show();
		$('table#edit-domain select#domain_authority_type').change();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.edit-domain-container ul.errors').remove();
			$('.edit-domain-container').prepend(xhr.responseText);
		} else
			alert("[ERROR] unable to create Domain");
	});



	// ------------------- SOA Record -------------------
	$('.edit-soa-record-button').click(function () {
		$('.show-soa-container').hide();
		$('.edit-soa-container').show();
		$(this).hide();
		return false;
	});

	$('.cancel-update-soa-record-button').live('click', function () {
		$('.edit-soa-container').hide();
		$('.show-soa-container').show();
		$('.edit-soa-record-button').show();
		return false;
	});

	$('.update-soa-record-button').live('click', function () {
		$('.update-soa-record-form').submit();
		return false;
	});

	$('.update-soa-record-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.update-soa-record-button').click();
			return false;
		}
	});

	$('.update-soa-record-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.edit-soa-container').remove();
		$('.show-soa-container').replaceWith(data);
		$('.edit-soa-record-button').show();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.edit-soa-container ul.errors').remove();
			$('.edit-soa-container').prepend(xhr.responseText);
		} else
			alert("[ERROR] unable to create Domain");
	});

	// ------------------- Records table -------------------

	$('#records-search-form, #record-table-pagination a').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.record-table-container').replaceWith(data);
	}).live('ajax:error', function () {
		alert("[ERROR] unable to retrieve domains");
	});

	$('.edit-record-button').live('click', function () {
		var height = $(this).closest('tr').height();
		$(this).closest('tr').hide();
		$(this).closest('tr').next().height(height);
		$(this).closest('tr').next().show();
		return false;
	});

	$('.update-record-button').live('click', function () {
		// copy inputs from phony form to real form
		var form = $(this).closest('tr').prev().prev().find('form.update-record-form');
		$(this).closest('tr').find('input').each(function (idx, input) {
			form.append($(input).clone());
		});
		form.submit();
		return false;
	});

	$('tr.edit-record input').live('keypress', function (evt) {
		if (evt.which === 13)
			$(this).closest('tr').find('.update-record-button').click();
	});

	$('.cancel-edit-record-button').live('click', function () {
		$(this).closest('tr').hide();
		$(this).closest('tr').prev().show();
		return false;
	});

	$('.update-record-form').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.record-table-container ul').remove();
		var markerRow = $(this).closest('tr');
		markerRow.before(data);
		markerRow.next().next().remove();
		markerRow.next().remove();
		markerRow.remove();
		fixRecordTableZebraStriping();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status === 422) { // :unprocessable_entity
            $('.record-table-container ul').remove();
            $('.record-table-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to update Record");
	});

	$('.delete-record-button').live('ajax:success', function () {
		var row  = $(this).closest('tr');
		var prev = row.prev();
		var next = row.next();
		next.remove(); row.remove(); prev.remove();
		fixRecordTableZebraStriping();
	}).live('ajax:error', function () {
		alert("[ERROR] unable to delete Record");
	});

	var fixRecordTableZebraStriping = function () {
		$('table#record-table tr.show-record:nth-child(even), table#record-table tr.edit-record:nth-child(odd)').addClass("even").removeClass("odd");
		$('table#record-table tr.show-record:nth-child(odd), table#record-table tr.edit-record:nth-child(even)').addClass("odd").removeClass("even");
	}

	// ---------------- New Record form -------------------
	$('#new-record-form').live('ajax:success', function (evt, data, statusSTr, xhr) {
		$('.new-record-form-container ul.errors').remove();
		$('table#record-table tbody').append(data);
		fixRecordTableZebraStriping();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.new-record-form-container ul.errors').remove();
			$('.new-record-form-container').prepend(xhr.responseText);
		} else
			alert("[ERROR] unable to create Domain");
	});

	$('.new-record-button').live('click', function () {
		$('.new-record-button').hide();
		$('.new-record-form-container').show();
		return false;
	});

	$('#new-record-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.create-record-button').click();
			return false;
		}
	});

	$('.cancel-new-record-button').live('click', function () {
		$('.new-record-button').show();
		$('.new-record-form-container').hide();
		return false;
	});

	$('#new-record-form select#record_type').live('change', function () {
		var val = $(this).val();
		$('#new-record-form input#record_prio').closest('tr').toggle((val == 'MX' || val == 'SRV'));
		$(this).blur();
	});
	$('#new-record-form select#record_type').change();

	// ---------------- Reverse checkbox -------------------
	$('#show-reverse-domains-checkbox').live('change', function () {
		if (console) console.log("checkbox changed: " + $(this).attr("checked"));
		$(this).data('params', {reverse: $(this).attr('checked') ? true : false });
		$.rails.handleRemote($(this));
		return false;
	}).live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.domains-table-container').replaceWith(data);
	}).live('ajax:error', function () {
		alert("[ERROR] unable to retrieve domains");
	});
});
