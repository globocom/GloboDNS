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

describe User do

  it 'suspends user' do
    quentin = Factory(:quentin)
    quentin.suspend!
    quentin.should be_suspended
  end

  it 'does not authenticate suspended user'

  it 'deletes user' do
    quentin = Factory(:quentin)
    quentin.deleted_at.should be_nil
    quentin.delete!
    #quentin.deleted_at.should_not be_nil
    quentin.should be_deleted
  end

  it 'does not authenticate deleted users'

  describe "being unsuspended" do

    before do
      @user = Factory(:quentin)
      @user.suspend!
    end

    it 'reverts to active state' do
      @user.unsuspend!
      @user.should be_active
    end

  end

protected
  def create_user(options = {})
    User.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
  end
end

describe User, "as owner" do

  before(:each) do
    @user = Factory(:quentin, :auth_tokens => true)
    Factory(:domain, :user => @user)
    Factory(:zone_template, :user => @user)
  end

  it "should have domains" do
    @user.domains.should_not be_empty
  end

  it "should have templates" do
    @user.zone_templates.should_not be_empty
  end

  it "should not have auth_tokens" do
    @user.auth_tokens?.should be_false
  end
end

describe User, "as admin" do

  before(:each) do
    @admin = Factory(:admin, :auth_tokens => true)
  end

  it "should not own domains" do
    @admin.domains.should be_empty
  end

  it "should not own zone templates" do
    @admin.zone_templates.should be_empty
  end

  it "should have auth tokens" do
    @admin.auth_tokens?.should be_true
  end
end

describe User, "and roles" do

  it "should have a admin boolean flag" do
    Factory( :admin ).admin.should be_true
    Factory( :quentin ).admin.should be_false
  end

  it "should have a way to easily find active owners" do
    Factory(:quentin)
    candidates = User.active_owners
    candidates.each do |user|
      user.should be_active
      user.should_not be_admin
    end
  end
end

describe User, "and audits" do

  it "should have username persisted in audits when removed" do
    admin = Factory(:admin)
    Audit.as_user( admin ) do
      domain =Factory(:domain)
      audit = domain.audits.first

      audit.user.should eql( admin )
      audit.username.should be_nil

      admin.destroy
      audit.reload

      audit.user.should eql( 'admin' )
      audit.username.should eql('admin')
    end
  end
end
