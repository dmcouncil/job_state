module JobState
  class Base

    def initialize(uuid)
      @job_uuid = uuid  # uuid from resque-status
    end

    # You generally call this on a subclass, for example
    #   job_state = JobState::RunMarathon.find(uuid)
    # instead of
    #   job_state = JobState::Base.find(uuid)
    # so that you can take advantage of the extra behavior of that
    # particular job state class.
    def self.find(job_uuid)
      self.new(job_uuid)
    end

    # Like find, you tend to call this on the subclass, not JobState::Base
    # itself.
    def self.all
      statuses = Resque::Plugins::Status::Hash.statuses
      statuses.select!{|s| s.options && s.options['job_kind'] == kind}
      statuses.map!{|s| self.new(s.uuid)}
      statuses.reject!{|s| filter_out(s)}
      statuses
    end

    # Allows you to locate specific resque jobs based on the job parameters
    # that were sent when the job was created.
    def self.find_all_by(job_params)
      all.select do |job_state|
        keep = true
        job_params.each do |name, value|
          keep = false if job_state.get_job_param(name).to_s != value.to_s
        end
        keep
      end
    end

    # to be sent up to JavaScript land as JSON
    def full_info
      hash = progress_metrics
      if success?
        hash[:job_state] = 'success'
      elsif error?
        hash[:job_state] = 'error'
      else
        hash[:job_state] = 'working'
      end
      hash
    end

    #**********************************************************************
    # PROGRESS METRICS
    #
    # This is how you communicate progress status updates to your Rails app.

    def progress_metrics
      HashWithIndifferentAccess.new(status_hash['progress'] || {})
    end

    def get_progress_metric(name)
      progress_metrics[name.to_s]
    end

    def set_progress_metric(name, value)
      progress_hash = progress_metrics
      progress_hash[name.to_s] = value.to_s
      # This is how we set a new value on a Status::Hash object.
      # This is not documented well in the resque-status gem's README.
      hash = Resque::Plugins::Status::Hash.get(@job_uuid)
      hash.merge!({ 'progress' => progress_hash })
      Resque::Plugins::Status::Hash.set(@job_uuid, hash.status, hash)
    end

    #**********************************************************************
    # JOB PARAMS
    #
    # This is the info you originally passed to the Resque job when it was
    # created.

    def job_params
      HashWithIndifferentAccess.new(status_hash.options || {})
    end

    def get_job_param(name)
      job_params[name]
    end

    #**********************************************************************
    # JOB PROCESS STATUS
    #
    # This wraps the process status info that comes from resque-status into
    # a more simpler state that notes whether the job is in progress,
    # completed successfully, or crashed.
    #
    # The resque-status gem has 5 statuses:
    #   queued working completed failed killed

    def success?
      status_hash.completed?
    end

    def error?
      h = status_hash
      h.failed? || h.killed?
    end

    def working?
      !success? && !error?
    end

    #**********************************************************************
    # IDs

    # to hook up easily with Rails' resource-oriented architecture
    def to_param
      @job_uuid
    end

    # the uuid from resque-status
    def uuid
      @job_uuid
    end

  private

    def status_hash
      # get a fresh version of the job status
      Resque::Plugins::Status::Hash.get(@job_uuid)
    end

    # Override this in your subclass to determine which jobs are available
    # to the find and all methods.
    def self.filter_out(csv_import_job_state)
      false
    end
    private_class_method :filter_out

    def self.kind
      self.to_s.split('::').last
    end
    private_class_method :kind

  end
end
