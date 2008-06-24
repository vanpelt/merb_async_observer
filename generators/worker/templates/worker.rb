# start me like merb -a runner -r this_script
# merb_async_observer - A Merb plugin to make using beanstalkd a cream dream

# Use the same pointer (and therefore same buffer) for stdout and stderr.
$VERBOSE = nil; STDERR = $stderr = STDOUT = $stdout; $VERBOSE = false

require 'time'
require 'merb_async_observer/worker'
Merb::AsyncObserver::Worker.new(binding).run()
