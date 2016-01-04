Rails.application.routes.draw do

  mount JobState::Engine => "/job_state"
end
