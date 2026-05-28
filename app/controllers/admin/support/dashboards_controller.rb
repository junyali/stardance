class Admin::Support::DashboardsController < Admin::ApplicationController
  def show
    authorize [ :admin, :support, :dashboard ]
  end
end
