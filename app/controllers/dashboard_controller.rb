class DashboardController < ApplicationController
    def index
        @latest_domains = Domain.nonreverse.reorder('created_at DESC').limit(5)
    end
end
