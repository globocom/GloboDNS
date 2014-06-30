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
	// ------------------- BIND -------------------
	$('.reload-bind-config-button').live('click', function () {
		$.rails.handleRemote($(this));
		return false;
	}).live('ajax:success', function (evt, data, statusStr, xhr) {
		$('textarea#named_conf').val(data);
		return false;
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		alert("[ERROR] reload failed");
	});

	$('.bind-export-button').live('click', function () {
		$(this).data('params', $(this).data('params') + '&' + $('textarea#master-named-conf').serialize() + '&' + $('textarea#slave-named-conf').serialize());
		$.rails.handleRemote($(this));
		return false;
	}).live('ajax:beforeSend', function (xhr, settings) {
		$('.export-output').hide();
		$('.export-output').html();
	}).live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.export-output').html(data)
		$('.export-output').show();
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		if (xhr.status == 422) { // :unprocessable_entity
			$('.export-output').html(xhr.responseText)
			$('.export-output').show();
		} else
			alert("[ERROR] export failed");
	});

	// -- Export menu item; show only to "operator" users
	$('.export-menu-item').live('ajax:success', function(evt, data, statusStr, xhr) {
		$.fn.flashMessage(data.output, 'notice', 5000);
	}).live('ajax:error', function (evt, xhr, statusStr, error) {
		alert("[ERROR] export failed");
	});
});
