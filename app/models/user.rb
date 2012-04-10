require 'digest/sha1'

class User < ActiveRecord::Base

    devise :database_authenticatable,
           :token_authenticatable,
           :rememberable,
           :validatable,
           :encryptable,
           :encryptor => :restful_authentication_sha1
           # :recoverable,
           # :confirmable,

    #validates_presence_of     :login, :email
    #validates_presence_of     :password,                   :if => :password_required?
    #validates_presence_of     :password_confirmation,      :if => :password_required?
    #validates_length_of       :password, :within => 4..40, :if => :password_required?
    #validates_confirmation_of :password,                   :if => :password_required?
    #validates_length_of       :login,    :within => 3..40
    #validates_length_of       :email,    :within => 3..100
    #validates_uniqueness_of   :login, :email, :case_sensitive => false

    # before_save :check_auth_tokens
    before_save   :ensure_authentication_token
    after_destroy :persist_audits

    # prevents a user from submitting a crafted form that bypasses activation
    # anything else you want your user to change should be added here.
    attr_accessible :login, :email, :password, :password_confirmation, :role, :authentication_token

    has_many :audits, :as => :user

    ROLES = [:ADMIN, :MANAGER, :VIEWER].inject(Hash.new) do |hash, role|
        role_str = role.to_s.sub(/^ROLE_/, '')[0]
        const_set(('ROLE_' + role.to_s).to_sym, role_str)
        hash[role_str] = role
        hash
    end

    def admin?
        role == ROLE_ADMIN
    end

    def manager?
        role == ROLE_MANAGER
    end

    def viewer?
        role == ROLE_VIEWER
    end

    def auth_json
        self.to_json(:root => false, :only => [:id, :authentication_token])
    end

    protected

    def persist_audits
        quoted_login = ActiveRecord::Base.connection.quote(self.login)
        Audit.update_all(
            "username = #{quoted_login}",
            [ 'user_type = ? AND user_id = ?', self.class.name, self.id ]
        )
    end

    def check_auth_tokens
        self.auth_tokens = false unless self.admin?
        nil # Don't halt callback chain
    end
end
