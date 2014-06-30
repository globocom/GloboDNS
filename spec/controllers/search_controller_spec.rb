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

describe SearchController, "for admins" do

  before(:each) do
    #session[:user_id] = Factory(:admin).id
    sign_in Factory(:admin)

    Factory(:domain, :name => 'example.com')
    Factory(:domain, :name => 'example.net')
  end

  it "should return results when searched legally" do
    get :results, :q => 'exa'

    assigns(:results).should_not be_nil
    response.should render_template('search/results')
  end

  it "should handle whitespace in the query" do
    get :results, :q => ' exa '

    assigns(:results).should_not be_nil
    response.should render_template('results')
  end

  it "should redirect to the index page when nothing has been searched for" do
    get :results, :q => ''

    response.should be_redirect
    response.should redirect_to( root_path )
  end

  it "should redirect to the domain page if only one result is found" do
    domain = Factory(:domain, :name => 'slave-example.com')

    get :results, :q => 'slave-example.com'

    response.should be_redirect
    response.should redirect_to( domain_path( domain ) )
  end

end

describe SearchController, "for api clients" do
  before(:each) do
    sign_in(Factory(:api_client))

    Factory(:domain, :name => 'example.com')
    Factory(:domain, :name => 'example.net')
  end

  it "should return an empty JSON response for no results" do
    get :results, :q => 'amazon', :format => 'json'

    assigns(:results).should be_empty

    response.body.should == "[]"
  end

  it "should return a JSON set of results" do
    get :results, :q => 'example', :format => 'json'

    assigns(:results).should_not be_empty

    json = ActiveSupport::JSON.decode( response.body )
    json.size.should be(2)
    json.first["domain"].keys.should include('id', 'name')
    json.first["domain"]["name"].should match(/example/)
    json.first["domain"]["id"].to_s.should match(/\d+/)
  end
end
