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

describe "macros/show.html.haml" do
  before(:each) do
    @macro = Factory(:macro)
    Factory(:macro_step_create, :macro => @macro)

    assign(:macro, @macro)
    assign(:macro_step, @macro.macro_steps.new)

    render
  end

  it "should have the name of the macro" do
    rendered.should have_tag('h1', :content => @macro.name)
  end

  it "should have an overview table" do
    rendered.should have_tag('table.grid td', :content => "Name")
    rendered.should have_tag('table.grid td', :content => "Description")
    rendered.should have_tag('table.grid td', :content => "Active")
  end

  it "should have a list of steps" do
    rendered.should have_tag('h1', :content => 'Macro Steps')
    rendered.should have_tag('table#steps-table td', :content => "1")
  end

end
