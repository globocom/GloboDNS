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

describe "templates/new.html.haml" do

  context "and new templates" do
    before(:each) do
      assign(:zone_template, ZoneTemplate.new)
    end

    it "should have a list of users if provided" do
      Factory(:quentin)

      render

      rendered.should have_tag('select#zone_template_user_id')
    end

    it "should render without a list of users" do
      render

      rendered.should_not have_tag('select#zone_template_user_id')
    end

    it "should render with a missing list of users (nil)" do
      render

      rendered.should_not have_tag('select#zone_template_user_id')
    end

    it "should show the correct title" do
      render

      rendered.should have_tag('h1.underline', :content => 'New Zone Template')
    end
  end

end
