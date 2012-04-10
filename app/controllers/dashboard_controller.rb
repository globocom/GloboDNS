class DashboardController < ApplicationController
    def index
        @latest_domains = Domain.order('created_at DESC').limit(5)
    end
end
