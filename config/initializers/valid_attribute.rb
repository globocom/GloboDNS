ActiveRecord::Base.class_eval do
  def valid_attribute(attr)
    (self.valid?) ? self.send(attr) : self.send(attr.to_s + '_was')
  end
end
