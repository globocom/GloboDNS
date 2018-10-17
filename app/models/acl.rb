class Acl < ActiveRecord::Base
  attr_accessible :name, :content, :acl_type, :country, :region, :city

  validates :name, presence: true, uniqueness: true
  validate :validate_name
  validate :validate_geoip
  validate :validate_newtwork_block
  validate :validate_not_reserved_word

  has_many :acl_relationships


  def relation_with_parent(parent)
    AclRelationship.where(acl: parent, child:self).first
  end

  def acls
    Acl.find(AclRelationship.where(acl_id: self.id).collect{|child| child.child_id})
  end

  def can_be_deleted?
    ViewAcl.where(acl: self).empty?
  end

  def clients
    acls = self.acls
    return "any;" if acls.empty?
    acls.collect{ |acl| acl.name}.join("; ").concat(";")
  end

  def available_acls
    Acl.where.not(id: AclRelationship.where(acl_id: self.id).collect{|child| child.child_id}).where.not(id: self)
  end

  def children
    children = []
    self.acl_relationships.each do |relation|
      children.push relation.child
    end
    children
  end

  def types
    %w[acl geoip network]
  end

  def geoip?
    self.acl_type.downcase.eql? "geoip"
  end

  def acl?
    self.acl_type.downcase.eql? "acl"
  end

  def network_blocks?
    self.acl_type.downcase.eql? "network blocks"
  end


  def to_bind9_conf(indent = '')
    str  = ""
    if defined? GloboDns::Config::ENABLE_VIEW and GloboDns::Config::ENABLE_VIEW and self.should_be_exported?
      str << "#{indent}acl \"#{self.name}\" {\n"
      if self.geoip?
        str << "#{indent} geoip country \"#{self.country}\";\n"
        str << "#{indent} geoip region \"#{self.region}\";\n" if self.region?
        str << "#{indent} geoip city \"#{self.city}\";\n" if self.city?
      elsif self.acl?
        str << "#{indent} #{self.clients}\n" unless self.acls.empty?
      elsif self.network_blocks?
        str << "#{indent} #{self.content}\n" if self.content?
      end
      str << "#{indent}};\n\n"
    end
    str
  end

  def should_be_exported?
    if self.geoip?
      return self.country?
    elsif self.network_blocks?
      return self.content?
    elsif self.acl?
      return !self.acls.empty?
    end
    false
  end

  def validate_not_reserved_word
    reserved_words = ["any", "none", "localhost", "localnets"]
    if reserved_words.include? self.name
      errors.add(:name, "can't be a reserved word")
    end
  end

  def validate_name
    unless self.name =~ /^(?!\-)[a-zA-Z0-9\-_.]{,63}(?<!\-)$/
      errors.add(:name, "is invalid")
    end
  end

  def validate_geoip
    if self.geoip? and self.country.empty?
      errors.add(:country, "can't be blank")
    end
  end

  def validate_newtwork_block
    if self.network_blocks?
      if self.content.empty?
        errors.add(:content, "can't be blank")
      elsif (self.content =~ /^((\d{1,3}.){3}\d{1,3}\/\d{1,2};){1,}$/).nil?
        errors.add(:content, "must be network blocks separeted by semicolon")
      end
    end
  end
end
