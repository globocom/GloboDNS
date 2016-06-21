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
require 'bcrypt'
require 'digest/sha1'

class User < ActiveRecord::Base

    if GloboDns::Application.config.omniauth
      validates :email, presence: true
      devise :omniauthable, :omniauth_providers => [:oauth_provider]
    else
      before_save   :ensure_authentication_token
      devise :database_authenticatable, :rememberable, :validatable, :encryptable, :encryptor => :restful_authentication_sha1

    end

    attr_accessible :name, :email, :role, :active, :password, :password_confirmation, :oauth_token, :oauth_expires_at, :uid, :password_salt, :provider

    ROLES = define_enum(:role, [:ADMIN, :OPERATOR, :VIEWER])

    def self.from_api(auth)
      user = User.where(uid: auth['id']).first
      if user.nil?
        user = User.new({
          active: false,
          uid: auth['id'],
          email: 'api@example.com',
          name: auth['name'],
          password: Devise.friendly_token[0,20],
          provider: :oauth_provider,
          oauth_token: auth['token'],
          oauth_expires_at: Time.now + 5.minutes
        })
        user.save!
      else
        user.update_attributes({
          name: auth['name'],
          password: Devise.friendly_token[0,20],
          oauth_token: auth['token'],
          oauth_expires_at: Time.now + 5.minutes
        })
      end
      user
    end

    def self.from_omniauth(auth)
      user = User.where(email: auth.info.email).first
      if user.nil? # Doesnt exist yet. Lets create it
        user = User.new({
          active: false,
          uid: auth.uid,
          email: auth.info.email,
          name: auth.info.name,
          password: Devise.friendly_token[0,20],
          provider: :oauth_provider,
          oauth_token: auth.credentials.token,
          oauth_expires_at: Time.at(auth.credentials.expires_at)
        })
        user.save!
      else # Already created. lets update it
        user.update_attributes({
          uid: auth.uid,
          email: auth.info.email,
          name: auth.info.name,
          password: Devise.friendly_token[0,20],
          oauth_token: auth.credentials.token,
          oauth_expires_at: Time.at(auth.credentials.expires_at)
        })
      end
      user
    end

    def ensure_authentication_token
      if authentication_token.blank?
        self.authentication_token = generate_authentication_token
      end
    end

    def auth_json
      self.to_json(:root => false, :only => [:id, :authentication_token])
    end

    def valid_password?(password, pepper = Devise.pepper, salt = self.password_salt)
      digest = pepper
      valid = false

      for i in 0..Devise.stretches-1
        digest = Digest::SHA1.hexdigest([digest, salt, password, pepper].flatten.join('--'))
        valid =  true if digest == self.encrypted_password
        # puts digest
      end
      return valid
    end


    protected
    def persist_audits
      quoted_login = ActiveRecord::Base.connection.quote(self.login)
      Audit.update_all(
          "username = #{quoted_login}",
          [ 'user_type = ? AND user_id = ?', self.class.name, self.id ]
      )
    end

    private
    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end
end
