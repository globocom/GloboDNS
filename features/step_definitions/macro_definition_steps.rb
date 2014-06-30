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

Given /^I have a domain$/ do
  @domain = Factory(:domain)
end

Given /^I have a domain named "([^\"]*)"$/ do |name|
  @domain = Factory(:domain, :name => name)
end

Given /^I have a macro$/ do
  @macro = Factory(:macro)
end

When /^I apply the macro$/ do
  @macro.apply_to( @domain )
  @domain.reload
end

Given /^the macro "([^\"]*)" an? "([^\"]*)" record for "([^\"]*)" with "([^\"]*)"$/ do |action, type, name, content|
  # clean up the action by singularizing the components
  action.gsub!(/s$/,'').gsub!('s_', '_')

  MacroStep.create!(:macro => @macro, :action => action, :record_type => type, :name => name, :content => content)
end

Given /^the macro "([^\"]*)" an "([^\"]*)" record for "([^\"]*)"$/ do |action, type, name|
  # clean up the action by singularizing the components
  action.gsub!(/s$/,'').gsub!(/s_/, '')

  MacroStep.create!(:macro => @macro, :action => action, :record_type => type, :name => name)
end

Given /^the macro "([^\"]*)" an "([^\"]*)" record with "([^\"]*)" with priority "([^\"]*)"$/ do |action, type, content, prio|
  # clean up the action by singularizing the components
  action.gsub!(/s$/,'').gsub!(/s_/, '')

  MacroStep.create!(:macro => @macro, :action => action, :record_type => type, :content => content, :prio => prio)
end

Given /^the domain has an? "([^\"]*)" record for "([^\"]*)" with "([^\"]*)"$/ do |type, name, content|
  type.constantize.create!( :domain => @domain, :name => name, :content => content )
end

Then /^the domain should have an? "([^\"]*)" record for "([^\"]*)" with "([^\"]*)"$/ do |type, name, content|
  records = @domain.send("#{type.downcase}_records", true)

  records.should_not be_empty

  records.detect { |r| r.name =~ /^#{name}\./ && r.content == content }.should_not be_nil
end

Then /^the domain should have an? "([^\"]*)" record with priority "([^\"]*)"$/ do |type, prio|
  records = @domain.send("#{type.downcase}_records", true)

  records.should_not be_empty

  records.detect { |r| r.prio == prio.to_i }.should_not be_nil
end

Then /^the domain should not have an? "([^\"]*)" record for "([^\"]*)" with "([^\"]*)"$/ do |type, name, content|
  records = @domain.send("#{type.downcase}_records", true)

  records.detect { |r| r.name =~ /^#{name}\./ && r.content == content }.should be_nil
end

Then /^the domain should not have an "([^\"]*)" record for "([^\"]*)"$/ do |type, name|
  records = @domain.send("#{type.downcase}_records", true)

  records.detect { |r| r.name =~ /^#{name}\./ }.should be_nil
end
