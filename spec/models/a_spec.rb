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

describe A, "when new" do
  before(:each) do
    @a = A.new
  end

  it "should be invalid by default" do
    @a.should_not be_valid
  end
  
  it "should only accept valid IPv4 addresses as content" do
    @a.content = '10'
    @a.should have(1).error_on(:content)
    
    @a.content = '10.0'
    @a.should have(1).error_on(:content)
    
    @a.content = '10.0.0'
    @a.should have(1).error_on(:content)
    
    @a.content = '10.0.0.9/32'
    @a.should have(1).error_on(:content)
    
    @a.content = '256.256.256.256'
    @a.should have(1).error_on(:content)
    
    @a.content = '10.0.0.9'
    @a.should have(:no).error_on(:content)
  end
  
  it "should not accept new lines in content" do 
    @a.content = "10.1.1.1\nHELLO WORLD"
    @a.should have(1).error_on(:content)
  end
  
  it "should not act as a CNAME" do
    @a.content = 'google.com'
    @a.should have(1).error_on(:content)
  end
  
end
