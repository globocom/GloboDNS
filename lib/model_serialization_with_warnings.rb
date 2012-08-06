# Complement the functionality provided by the 'validation_scopes' plugin.
# We rely on the 'validation_scope :warning' construct to define validations
# that don't block model persistence. But the plugin doesn't add the warnings
# to the serialized forms (json & xml) of the resources where the validation
# scopes are defined.
#
# This model provides a half-baked solution to this. It overrides the 'as_json'
# and 'as_xml' methods, adding a 'warnings' property when appropriate.

module ModelSerializationWithWarnings
    extend ActiveSupport::Concern

    included do
        def as_json(options = nil)
            self.warnings.any? ? super.merge!('warnings' => self.warnings.as_json) : super
        end

        def to_xml(options = {})
            self.warnings.any? ? super(:methods => [:warnings]) : super
        end

        def becomes(klass)
            became = super(klass)
            became.instance_variable_set("@warnings", @warnings)
            became
        end
    end
end
