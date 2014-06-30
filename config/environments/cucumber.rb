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

config.cache_classes = true # This must be true for Cucumber to operate correctly!

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

config.gem "cucumber",    :lib => false,        :version => ">=0.3.11" unless File.directory?(File.join(Rails.root, 'vendor/plugins/cucumber'))
config.gem "webrat",      :lib => false,        :version => ">=0.4.4" unless File.directory?(File.join(Rails.root, 'vendor/plugins/webrat'))
config.gem "rspec",       :lib => false,        :version => ">=1.2.6" unless File.directory?(File.join(Rails.root, 'vendor/plugins/rspec'))
config.gem "rspec-rails", :lib => 'spec/rails', :version => ">=1.2.6" unless File.directory?(File.join(Rails.root, 'vendor/plugins/rspec-rails'))
