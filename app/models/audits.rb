class Audits < ActiveRecord::Base
    include SyslogHelper
    include BindTimeFormatHelper

    attr_accessible :time, :user_id, :from, :action, :entity, :association, :changes;

    # scopes
    default_scope             { order("#{self.table_name}.name") }
    # scope :updated_since,     -> (timestamp) {Domain.where("#{self.table_name}.updated_at > ? OR #{self.table_name}.id IN (?)", timestamp, Record.updated_since(timestamp).select(:domain_id).pluck(:domain_id).uniq) }
    scope :matching,			->(action) {Audited::Adapters::ActiveRecord::Audit.where("action = ?", action)}
    # scope :matching,          -> (userQuery){
    #                                 if userQuery.index('*')
    #                                     where("#{self.table_name}.name LIKE ?", userQuery.gsub(/\*/, '%'))
    #                                 else
    #                                     where("#{self.table_name}.name" => userQuery)
    #                                 end
    #                             }
end