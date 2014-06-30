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

describe "macro_steps/update.js.rjs" do
  before(:each) do
    assigns[:macro] = @macro = Factory(:macro)
    assigns[:macro_step] = @macro_step = Factory(:macro_step_create, :macro => @macro)
  end

  describe "for valid updates" do

    before(:each) do
      render "macro_steps/update.js.rjs"
    end
    
    xit "should display a notice" do
      response.should include_text(%{showflash("info"})
    end
    
    xit "should update the steps table" do
      response.should have_rjs(:remove, "show_macro_step_#{@macro_step.id}")
      response.should have_rjs(:remove, "edit_macro_step_#{@macro_step.id}")
      response.should have_rjs(:replace, "marker_macro_step_#{@macro_step.id}")
    end
      
  end

  describe "for invalid updates" do

    before(:each) do
      assigns[:macro_step].content = ''
      assigns[:macro_step].valid?

      render "macro_steps/update.js.rjs"
    end
      
   
    xit "should display an error" do
      response.should have_rjs(:replace_html, "error_macro_step_#{@macro_step.id}")
    end
    
  end
end

