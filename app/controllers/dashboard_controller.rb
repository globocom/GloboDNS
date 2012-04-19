class DashboardController < ApplicationController
    def index
        @latest_domains = Domain.nonreverse.order('created_at DESC').limit(5)
    end
end
