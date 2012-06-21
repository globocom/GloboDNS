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

    ROLES = define_enum([:ADMIN, :OPERATOR, :VIEWER], :role)

    # before_save :check_auth_tokens
    before_save   :ensure_authentication_token
    # after_destroy :persist_audits

    # has_many :audits, :as => :user

    # ROLES = [:ADMIN, :OPERATOR, :VIEWER].inject(Hash.new) do |hash, role|
    #     role_str = role.to_s[0]
    #     const_set(('ROLE_' + role.to_s).to_sym, role_str)
    #     hash[role_str] = role
    #     hash
    # end

    # prevents a user from submitting a crafted form that bypasses activation
    # anything else you want your user to change should be added here.
    attr_accessible :login, :email, :password, :password_confirmation, :role, :authentication_token

    # def admin?
    #     role == ROLE_ADMIN
    # end

    # def operator?
    #     role == ROLE_OPERATOR
    # end

    # def viewer?
    #     role == ROLE_VIEWER
    # end

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
end
