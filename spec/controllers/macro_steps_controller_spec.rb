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

describe MacroStepsController do

  before(:each) do
    sign_in(Factory(:admin))

    @macro = Factory(:macro)
    @step = Factory(:macro_step_create,
                    :macro => @macro,
                    :name => 'localhost',
                    :content => '127.0.0.1')
  end

  it "should create a valid step" do
    expect {
      post :create, :macro_id => @macro.id,
        :macro_step => {
          :action => 'create',
          :record_type => 'A',
          :name => 'www',
          :content => '127.0.0.1'
        }, :format => 'js'
    }.to change(@macro.macro_steps(true), :count)

    response.should render_template('macro_steps/create')
  end

  it "should position a valid step correctly" do
    post :create, :macro_id => @macro.id,
    :macro_step => {
      :action => 'create',
      :record_type => 'A',
      :name => 'www',
      :content => '127.0.0.1',
      :position => '1'
    }, :format => 'js'

    assigns(:macro_step).position.should == 1
  end

  it "should not create an invalid step" do
    expect {
      post :create, :macro_id => @macro.id,
        :macro_step => {
          :position => '1',
          :record_type => 'A'
        }, :format => 'js'
    }.to_not change(@macro.macro_steps(true), :count)

    response.should render_template('macro_steps/create')
  end

  it "should accept valid updates to steps" do
    put :update, :macro_id => @macro.id, :id => @step.id,
      :macro_step => {
        :name => 'local'
      }, :format => 'js'

    response.should render_template('macro_steps/update')

    @step.reload.name.should == 'local'
  end

  it "should not accept valid updates" do
    put :update, :macro_id => @macro.id, :id => @step.id,
      :macro_step => {
        :name => ''
      }, :format => 'js'

    response.should render_template('macro_steps/update')
  end

  it "should re-position existing steps" do
    Factory(:macro_step_create, :macro => @macro)

    put :update, :macro_id => @macro.id, :id => @step.id,
    :macro_step => { :position => '2' }

    @step.reload.position.should == 2
  end

  it "should remove selected steps when asked" do
    delete :destroy, :macro_id => @macro, :id => @step.id, :format => 'js'

    flash[:info].should_not be_blank
    response.should be_redirect
    response.should redirect_to(macro_path(@macro))

    expect { @step.reload }.to raise_error( ActiveRecord::RecordNotFound )
  end

end
