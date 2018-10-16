class AclRelationship < ActiveRecord::Base
  belongs_to :acl
  belongs_to :child, :class_name => "Acl", :foreign_key => "child_id"

  attr_accessible :acl_id, :child_id
end
