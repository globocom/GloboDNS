# Create our admin user
user = User.find_by_email('admin@globoi.com') || User.new(:email => 'admin@globoi.com')
user.login                 = 'admin'    # not used anymore
user.password              = 'password'
user.password_confirmation = 'password'
user.role                  = User::ADMIN
user.save!

# Create an example doman template
domain_template     = DomainTemplate.find_by_name('Example Template') || DomainTemplate.new(:name => 'Example Template')
domain_template.ttl = '86400'
domain_template.soa_record_template.primary_ns = 'ns1.%ZONE%'
domain_template.soa_record_template.contact    = 'dnsapi.globoi.com'
domain_template.soa_record_template.refresh    = '10800'
domain_template.soa_record_template.retry      = '7200'
domain_template.soa_record_template.expire     = '604800'
domain_template.soa_record_template.minimum    = '10800'
domain_template.save!

# Clean and re-populate the domain template
domain_template.record_templates.where('record_type != ?', 'SOA').destroy_all

# NS records
RecordTemplate.create!({
  :domain_template => domain_template,
  :record_type     => 'NS',
  :name            => '@',
  :content         => 'ns1.%ZONE%'
})
RecordTemplate.create!({
  :domain_template => domain_template,
  :record_type     => 'NS',
  :name            => '@',
  :content         => 'ns2.%ZONE%'
})

# Assorted A records
RecordTemplate.create!({
  :domain_template => domain_template,
  :record_type     => 'A',
  :name            => 'ns1',
  :content         => '10.0.0.1'
})
RecordTemplate.create!({
  :domain_template => domain_template,
  :record_type     => 'A',
  :name            => 'ns2',
  :content         => '10.0.0.2'
})
RecordTemplate.create!({
  :domain_template => domain_template,
  :record_type     => 'A',
  :name            => 'host1',
  :content         => '10.0.0.3'
})
RecordTemplate.create!({
  :domain_template => domain_template,
  :record_type     => 'A',
  :name            => 'mail',
  :content         => '10.0.0.4'
})
RecordTemplate.create!({
  :domain_template => domain_template,
  :record_type     => 'MX',
  :name            => '@',
  :content         => 'mail',
  :prio            => 10
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

puts <<-EOF
-------------------------------------------------------------------------------
Congratulations on setting up your GloboDns on Rails database. You can now
start the server by running the command below, and then pointing your browser
to http://localhost:3000/

$ ./script/rails s

You can then login with "admin@globoi.com" using the password "password".

Thanks for trying out GloboDns
-------------------------------------------------------------------------------
EOF
