/*
* Licensed to the Apache Software Foundation (ASF) under one or more
* contributor license agreements.  See the NOTICE file distributed with
* this work for additional information regarding copyright ownership.
* The ASF licenses this file to You under the Apache License, Version 2.0
* (the "License"); you may not use this file except in compliance with
* the License.  You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
$(document).ready(function() {

	// ------------------- domain_templates#index -------------------

	$('#domain-templates-table-pagination a').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.domain-templates-table-container').replaceWith(data);
	}).live('ajax:error', function () {
		alert("[ERROR] unable to retrieve domain templates");
	});

	$('.new-domain-template-button').click(function () {
		$(this).hide();
		$('.new-domain-template-form-container').show();
		return false;
	});

	$('.cancel-new-domain-template-button').live('click', function () {
		$('.new-domain-template-form-container').hide();
		$('.new-domain-template-button').show();
		return false;
	});

	$('.new-domain-template-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.create-domain-template-button').click();
			return false;
		}
	});

	$('.new-domain-template-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('table#domain-templates-table').append(data);
		$('.new-domain-template-form-container ul.errors').remove();
		fixDomainTemplatesTableZebraStriping();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
            $('.new-domain-template-form-container ul').remove();
            $('.new-domain-template-form-container').prepend(xhr.responseText);
		} else
			alert("[ERROR] unable to create Domain Template");
	});

	var fixDomainTemplatesTableZebraStriping = function () {
		$('table#domain-templates-table tr:nth-child(even) td').addClass("even").removeClass("odd");
		$('table#domain-templates-table tr:nth-child(odd) td').addClass("odd").removeClass("even");
	}


	// ------------------- Domain Template (#show) -------------------
	$('.edit-domain-template-button').click(function () {
		$('#show-domain-template-container').hide();
		$('#edit-domain-template-container').show();
		$(this).hide();
		return false;
	});

	$('.cancel-edit-domain-template-button').live('click', function () {
		$('#edit-domain-template-container').hide();
		$('#show-domain-template-container').show();
		$('.edit-domain-template-button').show();
		return false;
	});

	$('.update-domain-template-button').live('click', function () {
		$('.update-domain-template-form').submit();
		return false;
	});

	$('.update-domain-template-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.update-domain-template-button').click();
			return false;
		}
	});

	$('.update-domain-template-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('#edit-domain-template-container').remove();
		$('#show-domain-template-container').replaceWith(data);
		$('.edit-domain-template-button').show();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status === 422) { // :unprocessable_entity
            $('#edit-domain-template-container ul').remove();
            $('#edit-domain-template-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to update Domain Template");
	});



	// ------------------- SOA Record -------------------
	$('.edit-soa-record-template-button').click(function () {
		$('#show-soa-record-template-container').hide();
		$('#edit-soa-record-template-container').show();
		$(this).hide();
		return false;
	});

	$('.cancel-edit-soa-record-template-button').live('click', function () {
		$('#edit-soa-record-template-container').hide();
		$('#show-soa-record-template-container').show();
		$('.edit-soa-record-template-button').show();
		return false;
	});

	$('.update-soa-record-template-button').live('click', function () {
		$('.update-soa-record-template-form').submit();
		return false;
	});

	$('.update-soa-record-template-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.update-soa-record-template-button').click();
			return false;
		}
	});

	$('.update-soa-record-template-form').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('#edit-soa-record-template-container').remove();
		$('#show-soa-record-template-container').replaceWith(data);
		$('.edit-soa-record-template-button').show();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status === 422) { // :unprocessable_entity
            $('#edit-soa-record-template-container ul').remove();
            $('#edit-soa-record-template-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to update SOA Record Template");
	});


	// ------------------- View -------------------
	$('.edit-domain-template-view-button').click(function () {
		$('#show-domain-template-view').hide();
		$('#select-domain-template-view').show();
		$(this).hide();
		return false;
	});

	$('.cancel-select-domain-template-view-button').live('click', function () {
		$('#show-domain-template-view').show();
		$('#select-domain-template-view').hide();
		$('.edit-domain-template-view-button').show();
		return false;
	});

	$('.select-domain-template-view-button').live('click', function () {
		$('.select-domain-template-view-form').submit();
		return false;
	});

	$('.select-domain-template-view-form').live('ajax:success', function (evt, data, statusStr, xhr) {
          $('#show-domain-template-view').html($('#domain_template_view_id option:selected').text()).show();
          $('#select-domain-template-view').hide();
          $('.edit-domain-template-view-button').show();
          return false;
        }).live('ajax:error', function (evt, xhr, statusStr, error) {
          alert("[ERROR] unable to update View");
	});

	// ------------------- Record Templates table -------------------

	$('#record-templates-table-pagination a').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.record-templates-table-container').replaceWith(data);
	}).live('ajax:error', function () {
		alert("[ERROR] unable to retrieve domains");
	});



	$('.delete-record-template-button').live('ajax:success', function () {
		var row  = $(this).closest('tr');
		var prev = row.prev();
		var next = row.next();
		next.remove(); row.remove(); prev.remove();
		fixRecordTemplatesTableZebraStriping();
	}).live('ajax:error', function () {
		alert("[ERROR] unable to delete Record");
	});

	$('.edit-record-template-button').live('click', function () {
		var height = $(this).closest('tr').height();
		$(this).closest('tr').hide();
		$(this).closest('tr').next().height(height);
		$(this).closest('tr').next().show();
		return false;
	});

	$('.update-record-template-button').live('click', function () {
		// copy inputs from phony form to real form
		var form = $(this).closest('tr').prev().prev().find('form.update-record-template-form');
		$(this).closest('tr').find('input').each(function (idx, input) {
			form.append($(input).clone());
		});
		form.submit();
		return false;
	});

	$('tr.edit-record-template input').live('keypress', function (evt) {
		if (evt.which === 13)
			$(this).closest('tr').find('.update-record-template-button').click();
	});

	$('.cancel-edit-record-template-button').live('click', function () {
		$(this).closest('tr').hide();
		$(this).closest('tr').prev().show();
		return false;
	});

	$('.update-record-template-form').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.record-templates-table-container ul').remove();
		var markerRow = $(this).closest('tr');
		markerRow.before(data);
		markerRow.next().next().remove();
		markerRow.next().remove();
		markerRow.remove();
		fixRecordTemplatesTableZebraStriping();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status === 422) { // :unprocessable_entity
            $('.record-templates-table-container ul').remove();
            $('.record-templates-table-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to update Record");
	});

	var fixRecordTemplatesTableZebraStriping = function () {
		$('table#record-templates-table tr.show-record-template:nth-child(even), table#record-templates-table tr.edit-record-template:nth-child(odd)').addClass("even").removeClass("odd");
		$('table#record-templates-table tr.show-record-template:nth-child(odd), table#record-templates-table tr.edit-record-template:nth-child(even)').addClass("odd").removeClass("even");
	}


	// ---------------- New Record Template form -------------------

	$('#new-record-template-form').live('ajax:success', function (evt, data, statusSTr, xhr) {
		$('.new-record-template-form-container ul').remove();
		$('table#record-templates-table tbody').append(data);
		fixRecordTemplatesTableZebraStriping();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status === 422) { // :unprocessable_entity
            $('.new-record-template-form-container ul').remove();
            $('.new-record-template-form-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to create Record Template");
	});

	$('.new-record-template-button').live('click', function () {
		$('.new-record-template-button').hide();
		$('.new-record-template-form-container').show();
		return false;
	});

	$('#new-record-template-form input').live('keypress', function (evt) {
		if (evt.which === 13) {
			$('.create-record-template-button').click();
			return false;
		}
	});

	$('.cancel-new-record-template-button').live('click', function () {
		$('.new-record-template-button').show();
		$('.new-record-template-form-container').hide();
		return false;
	});

	$('#new-record-template-form select#record_template_type').live('change', function () {
		$('input#record_template_prio').val(null);
		$('input#record_template_weight').val(null);
		$('input#record_template_port').val(null);
		$('input#record_tag').val(null);

		var val = $(this).val();
		$('#new-record-template-form input#record_template_prio').closest('tr').toggle((val == 'MX' || val == 'SRV' || val == 'CAA'));
		$('#new-record-template-form input#record_template_weight').closest('tr').toggle(val == 'SRV');
		$('#new-record-template-form input#record_template_port').closest('tr').toggle(val == 'SRV');
		if (val == 'CAA') {
			$('#new-record-template-form select#record_tag').closest('tr').toggle();
		}
		else{
			$('#new-record-template-form select#record_tag').closest('tr').hide();
		}
		$(this).blur();
	});
	$('#new-record-template-form select#record_template_type').change();

});
