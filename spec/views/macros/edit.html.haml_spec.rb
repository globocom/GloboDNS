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

describe "macros/edit.html.haml" do
  context "for new macros" do
    before(:each) do
      assign(:macro, Macro.new)
      render
    end

    it "should behave accordingly" do
      rendered.should have_tag('h1', :content => 'New Macro')
    end

  end

  context "for existing records" do
    before(:each) do
      @macro = Factory(:macro)
      assign(:macro, @macro)
      render
    end

    it "should behave accordingly" do
      rendered.should have_tag('h1', :content => 'Update Macro')
    end
  end

  describe "for records with errors" do
    before(:each) do
      m = Macro.new
      m.valid?
      assign(:macro, m)
      render
    end

    it "should display the errors" do
      rendered.should have_tag('div.errorExplanation')
    end
  end

end
