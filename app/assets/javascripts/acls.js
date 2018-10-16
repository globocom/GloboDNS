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
    $('select#acl_acl_type').live('change', function (evt) {
        $(".content-info").hide();
        $("." + $(this).val().replace(" ", "-").toLowerCase() + "-info").show();
    });

    $('.new-acls-button').click(function () {
        $(this).hide();
        $('.new-acls-form-container').show();
        return false;
    });

    $('#acls-table-pagination a').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.acls-table-container').replaceWith(data);
    }).live('ajax:error', function () {
        alert("[ERROR] unable to retrieve acls");
    });

    $('.cancel-new-acls-button').live('click', function () {
        $('.new-acls-form-container').hide();
        $('.new-acls-button').show();
        return false;
    });

    $('.new-acls-form input').live('keypress', function (evt) {
        if (evt.which === 13) {
            $('.create-acls-button').click();
            return false;
        }
    });

    $('.new-acls-form').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.new-acl-form-container ul.errors').remove();
        $('table#acls-table').append(data);
        fixAclsTableZebraStriping();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status == 422) {
            $('.new-acls-form-container ul.errors').remove();
            $('.new-acls-form-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to create View");
    });

    var fixAclsTableZebraStriping = function () {
        $('table#acls-table tr:nth-child(even)').addClass("even").removeClass("odd");
        $('table#acls-table tr:nth-child(odd)').addClass("odd").removeClass("even");
    }

    function setRegions(){
        $.ajax({
            type: "GET",
            url: "/geoip/regions",
            dataType: "json",
            data: {
                country: $('#acl_country').val()
            },
            success: function(data){
                $("#acl_region").find('option').remove().end();
                $("#acl_region").append($('<option>', {value: '', text: ''}));
                for (var k in data){
                    $("#acl_region").append($('<option>', {value: data[k], text: k}));
                }
            }
        });
    }

    function setCities(){
        $.ajax({
            type: "GET",
            url: "/geoip/cities",
            dataType: "json",
            data: {
                country: $('#acl_country').val(),
                region: $('#acl_region').val()
            },
            success: function(data){
                $("#acl_city").find('option').remove().end();
                $("#acl_city").append($('<option>', {value: '', text: ''}));
                for (var k in data){
                    $("#acl_city").append($('<option>', {value: data[k], text: data[k]}));
                }
            }
        });
    }

    // ----------------- acls#show -----------------
    // ------------------- Domain -------------------
    $('.edit-acls-button').click(function () {
        $('.show-acls-container').hide();
        $('.edit-acls-container').show();
        $(this).hide();
        return false;
    });

    $('#acl_country').live('change', function (evt) {
        setRegions();
    });

    $('#acl_region').live('change', function (evt) {
        setCities();
    });

    $('.cancel-update-acls-button').live('click', function () {
        $('.edit-acls-container').hide();
        $('.show-acls-container').show();
        $('.edit-acls-button').show();
        return false;
    });

    $('.update-acls-button').live('click', function () {
        $('.update-acls-form').submit();
        return false;
    });

    $('.update-acls-form input').live('keypress', function (evt) {
        if (evt.which === 13) {
            $('.update-acls-button').click();
            return false;
        }
    });

    $('.update-acls-form').live('ajax:success', function (evt, data, statusStr, xhr) {
        $('.edit-acls-container').remove();
        $('.show-acls-container').replaceWith(data);
        $('.edit-acls-button').show();
        $('table#edit-acl').change();
    }).live('ajax:error', function (evt, xhr, statusStr, error) {
        if (xhr.status == 422) { // :unprocessable_entity
            $('.edit-acls-container ul.errors').remove();
            $('.edit-acls-container').prepend(xhr.responseText);
        } else
            alert("[ERROR] unable to create View");
    });


    var fixViewsTableZebraStriping = function () {
        $('table#acls-table tr.show-acl:nth-child(even), table#acls-table tr.edit-acl:nth-child(odd)').addClass("even").removeClass("odd");
        $('table#acls-table tr.show-acl:nth-child(odd), table#acls-table tr.edit-acl:nth-child(even)').addClass("odd").removeClass("even");
    }
});
