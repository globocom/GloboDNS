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

describe "audits/domain.html.haml" do
  context "and domain audits" do

    before(:each) do
      @domain = Factory(:domain)
    end

    it "should handle no audit entries on the domain" do
      @domain.expects(:audits).returns( [] )
      assign(:domain, @domain)

      render

      rendered.should have_tag("em", :content => "No revisions found for the domain")
    end

    it "should handle audit entries on the domain" do
      audit = Audit.new(
        :auditable => @domain,
        :created_at => Time.now,
        :version => 1,
        :audited_changes => {},
        :action => 'create',
        :username => 'admin'
      )
      @domain.expects(:audits).at_most(2).returns( [ audit ] )

      assign(:domain, @domain)
      render

      rendered.should have_tag("ul > li > a", :content => "1 create by")
    end

  end

  context "and resource record audits" do

    before(:each) do
      Audit.as_user( 'admin' ) do
        @domain = Factory(:domain)
      end
    end

    it "should handle no audit entries" do
      @domain.expects(:associated_audits).at_most(2).returns( [] )
      assign(:domain, @domain)

      render

      rendered.should have_tag("em", :content => "No revisions found for any resource records of the domain")
    end

    it "should handle audit entries" do
      assign(:domain, @domain)

      render

      rendered.should have_tag("ul > li > a", :content => "1 create by admin")
    end

  end
end
