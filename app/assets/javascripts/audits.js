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
	// ----------------- ajax pagination ---------------
	// will_paginate does not support link attributes yet.
	// See: https://github.com/mislav/will_paginate/pull/100

	$('#audits-table-pagination a').live('ajax:success', function (evt, data, statusStr, xhr) {
		$('.audits-table-container').replaceWith(data);
		fixAuditChangesColumnWidth();
	}).live('ajax:error', function () {
		alert("[ERROR] unable to retrieve audits");
	});

	// -------------- fix td.changes width -------------
	var fixAuditChangesColumnWidth = function () {
		var td = $('#audits-table td.changes').first();
		var table = td.closest('table');
		var width = table.parent().width() - td.position().left + table.position().left - 5;
		$('#audits-table td.changes span').width(width);
	};

	if ($('#audits-table').size() > 0)
		fixAuditChangesColumnWidth();
});
