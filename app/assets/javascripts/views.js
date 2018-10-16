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
        eval(data);
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.new-view-form-container ul.errors').remove();
			$('.new-view-form-container').prepend(xhr.responseText);
		} else
			alert("[ERROR] unable to create View");
    });

    // ----------------- views#show -----------------
    // ------------------- Domain -------------------
    $('.edit-view-button').click(function () {
        $('.show-view-container').hide();
        $('.edit-view-container').show();
        $(this).hide();
        return false;
    });

    $('.cancel-update-view-button').live('click', function () {
        $('.edit-view-container').hide();
        $('.show-view-container').show();
        $('.edit-view-button').show();
        return false;
    });

    $('.update-view-button').live('click', function () {
        $('.update-view-form').submit();
        return false;
    });

    $('.update-view-form input').live('keypress', function (evt) {
        if (evt.which === 13) {
            $('.update-view-button').click();
            return false;
        }
    });

    $('.update-view-form').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.edit-view-container').remove();
        $('.show-view-container').replaceWith(data);
        $('.edit-view-button').show();
        $('table#edit-view').change();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status == 422) { // :unprocessable_entity
            $('.edit-view-container ul.errors').remove();
            $('.edit-view-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to create View");
    });


    var fixViewsTableZebraStriping = function () {
        $('table#views-table tr.show-view:nth-child(even), table#views-table tr.edit-view:nth-child(odd)').addClass("even").removeClass("odd");
        $('table#views-table tr.show-view:nth-child(odd), table#views-table tr.edit-view:nth-child(even)').addClass("odd").removeClass("even");
    }
});
