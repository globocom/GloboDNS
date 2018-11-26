require 'singleton'

module DomainOwnership
  class API
    include Singleton

    def initialize
    end

    def post_domain_ownership_info(name, component_id, sub_component_id)
    end

    def get_domain_ownership_info(name)
      { component_id:  "id_component", sub_component_id: "id_sub_component" }
    end

    def get_components_ids
      [["name1", "id1"],["nameN", "idN"]]
    end

    def get_sub_components_ids
      [["name1", "id1"],["nameN", "idN"]]
    end

    def get_component_name(id)
      "component name"
    end

    def get_sub_component_name(id)
      "sub component name"
    end
  end
end
