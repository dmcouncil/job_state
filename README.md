# JobState

## Purpose

JobState allows your users to see real-time updates of tasks that you've sent to Resque.

JobState is a Rails engine that houses the boilerplate Ajax and [resque-status](https://github.com/quirkey/resque-status) setup you would have to rewrite for every page you wanted to have this behavior.

## Installing

Add the engine to your Gemfile like this:

    gem 'job_state', path: 'lib/job_state'

Mount the engine in your routes file like this:

    mount JobState::Engine, :at => "/job_state", :constraints => RouteConstraint::LoggedIn

Notice that you should restrict which users have access to the job_state resources.

If you wish to [use JobState data in JavaScript](#Ajax), include the job-state.js file in your application. You can include it in your view manually with `javascript_include_tag "job_state/job-state", or include it in your manifest file like so:

    //= require job_state/job-state


## Communicating with a Job

Your Rails app and a Resque job are two different Ruby processes.  A JobState class is present in both Ruby processes and it serves as a real-time communication connection between them.

                  ,-------------------------,
               ,--*  JobState::RunMarathon  *--,
               |  '-------------------------'  |
               |                               |
    ,----------*--------------,    ,-----------*------,
    |  RunMarathonController  |    |  RunMarathonJob  |
    |       (Rails app)       |    |     (Resque)     |
    '-------------------------'    '------------------'

The actual mechanism that is used to communicate is the resque-status gem which ultimately uses Redis to ferry information back and forth between the two processes.

## Setting Up a JobState Class

Each Resque job needs a separate JobState class.  First, hook up resque-status to your job class.  Make sure to send the job state object down to the Ruby code that's being run in your job:

    class RunMarathonJob
      include Resque::Plugins::Status
      @queue = :hopkinton

      def perform
        job_state = JobState::RunMarathon.find(self.uuid)
        runner = Runner.new(job_state)
        runner.run!
      end
    end

Now, in your application, create a folder called app/jobs/job_state.  Add a class called JobState::RunMarathon (it must be named after your job class, without the Job at the end):

    module JobState
      class RunMarathon < Base
      end
    end

Most likely you'll keep this class empty, but it's a useful place to add job state behavior that's specific to the RunMarathonJob.

When you actually use resque-status to invoke the job, you must include an option called 'job_kind' and it must be set to the name of your job state class (without the JobState namespace).

    RunMarathonJob.create('job_kind' => 'RunMarathon')

## Communicating with a JobState Object

Any Ruby code that's run inside of your job can set status information to be made available to your Rails app.  It does this through a job state object.

    class Runner
      def initialize(job_state)
        @job_state = job_state
        @miles = 0
      end

      def run!
        while @miles < 26.2
          @miles += 0.01
          @job_state.set_progress_metric(:miles_run, @miles)
          sleep 5
        end
      end
    end

A job state object holds three kinds of information: the job parameters used to initialize the job, progress metrics that represent the changing progress of the job as it runs, and information about the running state of the job (whether it's still running, crashed due to an error, etc.)

Refer to the JobState::Base class to see how to access this information from a job state object.


## Showing Real-time Updates Using Ajax<a name='Ajax'></a>

You can access a job state's data from JavaScript. To do this, first include the JobState JavaScript file in your application. All you need to do is have the Resque job's uuid available in your JavaScript:

    JobState.startPolling({
      jobUuid: jobUuidThatYouPassedInFromYourController,
      pollingPeriod: 500, // twice a second
      update: function(data) {
        $('.distance-run-so-far').text(data.miles_run);
      },
      success: function() {
        location.reload();
      },
      error: function() {
        alert('The job done failed.');
      }
    });

The data object contains one attribute per progress metric that you set and it also contains an attribute called job_state that is either 'success', 'error' or 'working'.

## Issues

The way this is currently designed, you can only have one job status being polled at a time on any given page.

## Contributors

Swatches was originally developed by [Wyatt Greene](/techiferous) and is maintained by [District Management Group][1].

[1]: https://dmgroupK12.com/
