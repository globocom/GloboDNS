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

describe AAAA, "when new" do

  before(:each) do
    @aaaa = AAAA.new
  end

  it "should be invalid by default" do
    @aaaa.should_not be_valid
  end

  it "should only accept IPv6 address as content"

  it "should not act as a CNAME" do
    @aaaa.content = 'google.com'
    @aaaa.should have(1).error_on(:content)
  end

  it "should accept a valid ipv6 address" do
    @aaaa.content = "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
    @aaaa.should have(:no).error_on(:content)
  end

  it "should not accept new lines in content" do
    @aaaa.content = "2001:0db8:85a3:0000:0000:8a2e:0370:7334\nHELLO WORLD"
    @aaaa.should have(1).error_on(:content)
  end

end
