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

if GloboDns::Application.config.omniauth
	# configure default user admin from the oauth provider
	ADMIN_USER = 'api@example.com'
	user = User.find_by_email(ADMIN_USER) || User.new(:email => ADMIN_USER)
	user.role = "A"
	user.save

	puts <<-EOF
	-------------------------------------------------------------------------------
	Congratulations on setting up your GloboDns on Rails database. 

	If '#{ADMIN_USER}' isn't your admin's email for omniauth provider, please change it ('ADMIN_USER') at file 'db/seeds.rb'.

	Thanks for trying out GloboDns
	-------------------------------------------------------------------------------
	EOF
else
	# default user admin
	FIRST_USER = 'admin@example.com'
	FIRST_PASS = 'password'

	# Create our admin user
	user = User.find_by_email(FIRST_USER) || User.new(:email => FIRST_USER)
	user.name                 = 'admin'    # not used anymore
	user.password              = FIRST_PASS
	user.password_confirmation = FIRST_PASS
	user.role                  = User::ADMIN
	user.save!

	puts <<-EOF
	-------------------------------------------------------------------------------
	Congratulations on setting up your GloboDns on Rails database. You can now
	start the server by running the command below, and then pointing your browser
	to http://localhost:3000/

	$ ./script/rails s

	You can then login with "#{FIRST_USER}" using the password "#{FIRST_PASS}".

	Thanks for trying out GloboDns
	-------------------------------------------------------------------------------
	EOF
end


if Rails.env == "development"
	# Create an example doman template
	domain_template     = DomainTemplate.find_by_name('Example Template') || DomainTemplate.new(:name => 'Example Template')
	domain_template.ttl = '86400'
	domain_template.soa_record_template.primary_ns = 'ns1.%ZONE%'
	domain_template.soa_record_template.contact    = 'globodns.globoi.com'
	domain_template.soa_record_template.refresh    = '10800'
	domain_template.soa_record_template.retry      = '7200'
	domain_template.soa_record_template.expire     = '604800'
	domain_template.soa_record_template.minimum    = '10800'
	domain_template.soa_record_template.ttl        = '86400'
	domain_template.save!

	# Clean and re-populate the domain template
	domain_template.record_templates.where('type != ?', 'SOA').destroy_all

	# NS records
	RecordTemplate.create!({
	  :domain_template => domain_template,
	  :type            => 'NS',
	  :name            => '@',
	  :content         => 'ns1.%ZONE%',
	  :ttl             => 86400
	})
	RecordTemplate.create!({
	  :domain_template => domain_template,
	  :type            => 'NS',
	  :name            => '@',
	  :content         => 'ns2.%ZONE%',
	  :ttl             => 86400
	})

	# Assorted A records
	RecordTemplate.create!({
	  :domain_template => domain_template,
	  :type            => 'A',
	  :name            => 'ns1',
	  :content         => '10.0.0.1',
	  :ttl             => 86400
	})
	RecordTemplate.create!({
	  :domain_template => domain_template,
	  :type            => 'A',
	  :name            => 'ns2',
	  :content         => '10.0.0.2',
	  :ttl             => 86400
	})
	RecordTemplate.create!({
	  :domain_template => domain_template,
	  :type            => 'A',
	  :name            => 'host1',
	  :content         => '10.0.0.3',
	  :ttl             => 86400
	})
	RecordTemplate.create!({
	  :domain_template => domain_template,
	  :type            => 'A',
	  :name            => 'mail',
	  :content         => '10.0.0.4',
	  :ttl             => 86400
	})
	RecordTemplate.create!({
	  :domain_template => domain_template,
	  :type            => 'MX',
	  :name            => '@',
	  :content         => 'mail',
	  :prio            => 10,
	  :ttl             => 86400
	})

	# And add our example.com records
	# domain = Domain.find_by_name('example.com') || Domain.new(:name => 'example.com')
	# domain.ttl        = 84600
	# domain.type       = 'MASTER'
	# domain.primary_ns = 'ns1.example.com'
	# domain.contact    = 'admin@example.com'
	# domain.refresh    = 10800
	# domain.retry      = 7200
	# domain.expire     = 604800
	# domain.minimum    = 10800
	# domain.save!
	#
	# # Clear the records and start fresh
	# domain.records_without_soa.each(&:destroy)
	#
	# # NS records
	# NS.create!({
	#   :domain  => domain,
	#   :name    => '@',
	#   :content => 'ns1.%ZONE%'
	# })
	# NS.create!({
	#   :domain  => domain,
	#   :name    => '@',
	#   :content => 'ns2.%ZONE%'
	# })
	#
	# # Assorted A records
	# A.create!({
	#   :domain  => domain,
	#   :name    => 'ns1',
	#   :content => '10.0.0.1'
	# })
	# A.create!({
	#   :domain  => domain,
	#   :name    => 'ns2',
	#   :content => '10.0.0.2'
	# })
	# A.create!({
	#   :domain  => domain,
	#   :name    => '@',
	#   :content => '10.0.0.3'
	# })
	# A.create!({
	#   :domain  => domain,
	#   :name    => 'mail',
	#   :content => '10.0.0.4'
	# })
	# MX.create!({
	#   :domain  => domain,
	#   :name    => '@',
	#   :type    => 'MX',
	#   :content => 'mail',
	#   :prio    => 10
	# })


	

end
