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

describe ReportsController, "index" do
  before(:each) do
    sign_in(Factory(:admin))

    Factory(:domain)
    q = Factory(:quentin)
    Factory(:domain, :name => 'example.net', :user => q)
  end

  it "should display all users to the admin" do
    get 'index'

    response.should render_template('reports/index')
    assigns(:users).should_not be_empty
    assigns(:users).size.should be(1)
  end

  it "should display total system domains and total domains to the admin" do
    get 'index'

    response.should render_template('reports/index')
    assigns(:total_domains).should be(Domain.count)
    assigns(:system_domains).should be(1)
  end
end

describe ReportsController, "results" do
  before(:each) do
    sign_in(Factory(:admin))
  end

  it "should display a list of users for a search hit" do
    Factory(:aaron)
    Factory(:api_client)

    get 'results', :q => "a"

    response.should render_template('reports/results')
    assigns(:results).should_not be_empty
    assigns(:results).size.should be(3)
  end

  it "should redirect to reports/index if the search query is empty" do
    get 'results' , :q => ""

    response.should be_redirect
    response.should redirect_to( reports_path )
  end

end

describe ReportsController , "view" do
  before(:each) do
    sign_in(Factory(:admin))
  end

  it "should show a user reports" do
    get "view" , :id => Factory(:aaron).id

    response.should render_template("reports/view")
    assigns(:user).should_not be_nil
    assigns(:user).login.should == 'aaron'
  end

end

