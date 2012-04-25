$(document).ready(function() {
    $('.new-view-button').click(function () {
        $(this).hide();
        $('.new-view-form-container').show();
        return false;
    });

    $('#views-table-pagination a').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.views-table-container').replaceWith(data);
    }).live('ajax:error', function () {
        alert("[ERROR] unable to retrieve views");
    });

    $('.cancel-new-view-button').live('click', function () {
        $('.new-view-form-container').hide();
        $('.new-view-button').show();
        return false;
    });

    $('.new-view-form input').live('keypress', function (evt) {
        if (evt.which === 13) {
            $('.create-view-button').click();
            return false;
        }
    });

    $('.new-view-form').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('table#views-table tbody').append(data);
        $('.new-view-form-container ul.errors').remove();
        fixViewsTableZebraStriping();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.new-view-form-container ul.errors').remove();
			$('.new-view-form-container').prepend(xhr.responseText);
		} else
			alert("[ERROR] unable to create Domain");
    });

    $('.edit-view-button').live('click', function () {
        var height = $(this).closest('tr').height();
        $(this).closest('tr').hide();
        $(this).closest('tr').next().height(height);
        $(this).closest('tr').next().show();
        return false;
    });

    $('.update-view-button').live('click', function () {
        // copy inputs from phony form to real form
        var form = $(this).closest('tr').prev().prev().find('form.update-view-form');
        $(this).closest('tr').find('input').each(function (idx, input) {
            form.append($(input).clone());
        });
        $(this).closest('tr').find('select').each(function (idx, input) {
            var clonedSelect = $(input).clone();
            clonedSelect.val($(input).val());
            form.append(clonedSelect);
        });

        form.submit();
        return false;
    });

    $('tr.edit-view input').live('keypress', function (evt) {
        if (evt.which === 13)
            $(this).closest('tr').find('.update-view-button').click();
    });

    $('.cancel-edit-view-button').live('click', function () {
        $(this).closest('tr').hide();
        $(this).closest('tr').prev().show();
        return false;
    });

    $('.update-view-form').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.views-table-container ul').remove();
        var markerRow = $(this).closest('tr');
        markerRow.before(data);
        markerRow.next().next().remove();
        markerRow.next().remove();
        markerRow.remove();
        fixViewsTableZebraStriping();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status == 422) { // :unprocessable_entity
            $('.views-table-container ul').remove();
            $('.views-table-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to update view");
    });

    $('.delete-view-button').live('ajax:success', function () {
        var row  = $(this).closest('tr');
        var prev = row.prev();
        var next = row.next();
        next.remove(); row.remove(); prev.remove();
        fixViewsTableZebraStriping();
    }).live('ajax:error', function () {
        alert("[ERROR] unable to delete view");
    });


    var fixViewsTableZebraStriping = function () {
        $('table#views-table tr.show-view:nth-child(even), table#views-table tr.edit-view:nth-child(odd)').addClass("even").removeClass("odd");
        $('table#views-table tr.show-view:nth-child(odd), table#views-table tr.edit-view:nth-child(even)').addClass("odd").removeClass("even");
    }
});
