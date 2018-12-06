require 'singleton'

module DomainOwnership
  class API
    include Singleton

    def initialize
    end

    def has_permission?(name, user, action = @permissions_action)
      false
    end

    def users_permissions_info(user)
      {:sub_components => [["sub_component_name_1", "sub_component_id_1"],["sub_component_name_n", "sub_component_id_n"]]}
    end

    def get_sub_components_from_user(user)
      [["sub_component_name_1", "sub_component_id_1"],["sub_component_name_n", "sub_component_id_n"]]
    end

    # ARTEMIA
    def patch_domain_ownership_info(id, name, sub_component, classifier)
    end

    def post_domain_ownership_info(name, sub_component_id, classifier, user)
    end

    def get_domain_ownership_info(name)
      { sub_component: "sub_component", sub_component_id: "sub_component_id", id: "id" }
    end
  end
end
