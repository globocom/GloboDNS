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

describe "macro_steps/create.js.rjs" do
  describe "for failed records" do
    before(:each) do
      assigns[:macro] = Factory.build(:macro)
      assigns[:macro_step] = MacroStep.new
      assigns[:macro_step].valid?

      render('macro_steps/create.js.rjs')
    end

    xit "should insert errors into the page" do
      response.should have_rjs(:replace_html, 'record-form-error')
    end

    xit "should have a error flash" do
      response.should include_text(%{showflash("error"})
    end
  end

  describe "for successful records" do
    before(:each) do
      assigns[:macro] = Factory(:macro)
      assigns[:macro_step] = Factory(:macro_step_create, :macro => assigns[:macro])

      render('macro_steps/create.js.rjs')
    end

    xit "should display a notice flash" do
      response.should include_text(%{showflash("info"} )
    end

    xit "should insert the steps into the table" do
      response.should have_rjs(:insert, :bottom, 'steps-table')
    end

  end

end
