require 'wires'
require_relative '../lib/wires-inotify'

require 'minitest/autorun'
require 'minitest/spec'

include Wires


describe NotifyHub do
  
  # it "is alive when and only when the Hub is." do
    
  #   NotifyHub.alive?.must_equal Hub.alive?
  #   NotifyHub.dead?.must_equal  Hub.dead?
  #   NotifyHub.state.must_equal :dead
  #   NotifyHub.instance_variable_get(:@thread).must_be_nil
    
  #   Hub.run
    
  #   NotifyHub.alive?.must_equal Hub.alive?
  #   NotifyHub.dead?.must_equal  Hub.dead?
  #   NotifyHub.state.must_equal :alive
  #   NotifyHub.instance_variable_get(:@thread).wont_be_nil
  #   NotifyHub.instance_variable_get(:@thread).status.wont_equal false
    
  #   Hub.kill
    
  #   NotifyHub.alive?.must_equal Hub.alive?
  #   NotifyHub.dead?.must_equal  Hub.dead?
  #   NotifyHub.state.must_equal :dead
  #   NotifyHub.instance_variable_get(:@thread).must_be_nil
    
  #   Hub.run
    
  #   NotifyHub.alive?.must_equal Hub.alive?
  #   NotifyHub.dead?.must_equal  Hub.dead?
  #   NotifyHub.state.must_equal :alive
  #   NotifyHub.instance_variable_get(:@thread).wont_be_nil
  #   NotifyHub.instance_variable_get(:@thread).status.wont_equal false
    
  #   Hub.kill
    
  #   NotifyHub.alive?.must_equal Hub.alive?
  #   NotifyHub.dead?.must_equal  Hub.dead?
  #   NotifyHub.state.must_equal :dead
  #   NotifyHub.instance_variable_get(:@thread).must_be_nil
    
  # end
  
  
  
end

# empty_event = INotify::Native::Event.new

on :notify, %r{/tmp/*} do |e|
  p e
end
on :notify, %r{/tmprr/*} do |e|
  puts "NEVER HERE"
end

Hub.run
sleep 0.1
inotify_watch("/tmp/foo", :recursive)
sleep 100
Hub.kill


# p NotifyHub.class_variable_get(:@@vestigial_events)
# p NotifyHub.class_variable_get(:@@vestigial_events_as_flags)

# p EventRegistry.list.select{ |x| 
#   (x<NotifyEvent) and
#   (ObjectSpace.each_object(Class).select { |c| c < x }.empty?)
# }