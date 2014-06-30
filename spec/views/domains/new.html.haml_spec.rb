# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe "domains/new.html.haml" do

  before(:each) do
    assign(:domain, Domain.new)

    view.stubs(:current_user).returns( Factory(:admin) )
  end

  it "should have a link to create a zone template if no zone templates are present" do
    assign(:zone_templates, [])

    render

    rendered.should have_selector("a[href='#{new_zone_template_path}']")
    rendered.should_not have_selector("select[name*=zone_template_id]")
  end

  it "should have a list of zone templates to select from" do
    zt = Factory(:zone_template)
    Factory(:template_soa, :zone_template => zt)

    render

    rendered.should have_selector("select[name*=zone_template_id]")
    rendered.should_not have_selector("a[href='#{new_zone_template_path}']")
  end

end
