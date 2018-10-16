class ViewAcl < ActiveRecord::Base
  belongs_to :view
  belongs_to :acl

  attr_accessible :acl_id, :view_id, :denied

  def name
    return "!#{self.acl.name}" if self.denied?
    self.acl.name
  end

end
