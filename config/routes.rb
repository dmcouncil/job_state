JobState::Engine.routes.draw do
  resources :job_states, :only => [:show] do
    member do
      post 'kill'
    end
  end
end
