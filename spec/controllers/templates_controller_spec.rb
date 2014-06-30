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

describe TemplatesController, "and admins" do
  before(:each) do
    sign_in(Factory(:admin))
  end

  it "should have a template list" do
    Factory(:zone_template)

    get :index

    assigns(:zone_templates).should_not be_empty
    assigns(:zone_templates).size.should be( ZoneTemplate.count )
  end

  it "should have a detailed view of a template" do
    get :show, :id => Factory(:zone_template).id

    assigns(:zone_template).should_not be_nil

    response.should render_template('templates/show')
  end

  it "should redirect to the template on create" do
    expect {
      post :create, :zone_template => { :name => 'Foo' }
    }.to change( ZoneTemplate, :count ).by(1)

    response.should redirect_to( zone_template_path( assigns(:zone_template) ) )
  end

end

describe TemplatesController, "and users" do
  before(:each) do
    @quentin = Factory(:quentin)
    sign_in(@quentin)
  end

  it "should have a limited list" do
    Factory(:zone_template, :user => @quentin)
    Factory(:zone_template, :name => '!Quentin')

    get :index

    assigns(:zone_templates).should_not be_empty
    assigns(:zone_templates).size.should be(1)
  end

  it "should not have a list of users when showing the new form" do
    get :new

    assigns(:users).should be_nil
  end
end

describe TemplatesController, "should handle a REST client" do
  before(:each) do
    sign_in(Factory(:api_client))
  end

  it "asking for a list of templates" do
    Factory(:zone_template)

    get :index, :format => "xml"

    response.should have_tag('zone-templates > zone-template')
  end
end
