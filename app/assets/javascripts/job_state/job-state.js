(function() {

  var self = JobState = {};

  self.startPolling = function(options) {
    self._jobUuid = options.jobUuid;
    self._updateFn = options.update;
    self._successFn = options.success;
    self._errorFn = options.error;
    self._pollingPeriod = options.pollingPeriod || 1000;
    self._poll();
  };

  self._poll = function() {
    setTimeout(function() {
      $.ajax({
        url: '/job_state/job_states/' + self._jobUuid,
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          if (data.job_state == 'success') {
            if (self._successFn) {
              self._successFn(data);
            }
          }
          else if (data.job_state == 'error') {
            if (self._errorFn) {
              self._errorFn(data);
            }
          }
          else {
            if (self._updateFn) {
              self._updateFn(data);
            }
            self._poll(self._jobUuid);
          }
        }
      });
    }, self._pollingPeriod);
  };

}());
