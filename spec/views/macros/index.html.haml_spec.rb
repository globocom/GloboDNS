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

describe "macros/index.html.haml" do

  it "should render a list of macros" do
    2.times { |i| Factory(:macro, :name => "Macro #{i}") }
    assign(:macros, Macro.all)

    render

    rendered.should have_tag('h1', :content => 'Macros')
    render.should have_tag("table a[href^='/macro']")
  end

  it "should indicate no macros are present" do
    assign(:macros, Macro.all)

    render

    rendered.should have_tag('em', :content => "don't have any macros")
  end

end
