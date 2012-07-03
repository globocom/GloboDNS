# see https://github.com/rails/rails/pull/3023

ActiveRecord::Base.class_eval do
    # Returns an instance of the specified +klass+ with the attributes of the
    # current record. This is mostly useful in relation to single-table
    # inheritance structures where you want a subclass to appear as the
    # superclass. This can be used along with record identification in
    # Action Pack to allow, say, <tt>Client < Company</tt> to do something
    # like render <tt>:partial => @client.becomes(Company)</tt> to render that
    # instance using the companies/company partial instead of clients/client.
    #
    # Note: The new instance will share a link to the same attributes as the original class.
    # So any change to the attributes in either instance will affect the other.
    def becomes(klass)
        became = klass.new
        became.instance_variable_set("@attributes", @attributes)
        became.instance_variable_set("@attributes_cache", @attributes_cache)
        became.instance_variable_set("@new_record", new_record?)
        became.instance_variable_set("@destroyed", destroyed?)
        became.instance_variable_set("@errors", errors)
        became
    end

    # Wrapper around +becomes+ that also changes the instance's sti column value.
    # This is especially useful if you want to persist the changed class in your
    # database.
    #
    # Note: The old instance's sti column value will be changed too, as both objects
    # share the same set of attributes.
    def becomes!(klass)
        became = becomes(klass)
        became.send("#{klass.inheritance_column}=", klass.sti_name) unless self.class.descends_from_active_record?
        became
    end
end
