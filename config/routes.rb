JobState::Engine.routes.draw do
  resources :job_states, :only => [:show]
end
