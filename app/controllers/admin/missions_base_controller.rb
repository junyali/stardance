module Admin
  class MissionsBaseController < Admin::ApplicationController
    before_action :set_mission
    before_action :authorize_mission_management

    private

    def set_mission
      @mission = Mission.with_deleted.find_by!(slug: params[:mission_slug])
    end

    def authorize_mission_management
      authorize @mission, :update?
    end
  end
end
