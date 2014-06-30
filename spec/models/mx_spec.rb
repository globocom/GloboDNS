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

describe MX, "when new" do
  before(:each) do
    @mx = MX.new
  end

  it "should be invalid by default" do
    @mx.should_not be_valid
  end

  it "should require a priority" do
    @mx.should have(1).error_on(:prio)
  end

  it "should only allow positive, numeric priorities, between 0 and 65535 (inclusive)" do
    @mx.prio = -10
    @mx.should have(1).error_on(:prio)

    @mx.prio = 65536
    @mx.should have(1).error_on(:prio)

    @mx.prio = 'low'
    @mx.should have(1).error_on(:prio)

    @mx.prio = 10
    @mx.should have(:no).errors_on(:prio)
  end

  it "should require content" do
    @mx.should have(2).error_on(:content)
  end

  it "should not accept IP addresses as content" do
    @mx.content = "127.0.0.1"
    @mx.should have(1).error_on(:content)
  end

  it "should not accept spaces in content" do
    @mx.content = 'spaced out.com'
    @mx.should have(1).error_on(:content)
  end

  it "should support priorities" do
    @mx.supports_prio?.should be_true
  end

end
