module JobState
  class JobStatesController < ApplicationController

    respond_to :html, :json

    before_action :fetch_job_state, only: [:show]

    def show
      respond_to do |format|
        format.json do
          render json: @job_state.full_info
        end
      end
    end

  private

    def fetch_job_state
      @job_state = JobState::Base.find(params[:id])
    end

  end
end
