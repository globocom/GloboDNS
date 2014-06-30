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

describe AuditsController do

  before(:each) do
    sign_in(Factory(:admin))
  end

  it "should have a search form" do
    get :index

    response.should render_template('audits/index')
  end

  it "should have a domain details page" do
    get :domain, :id => Factory(:domain).id

    assigns(:domain).should_not be_nil

    response.should render_template('audits/domain')
  end
end
