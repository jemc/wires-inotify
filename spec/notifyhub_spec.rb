require 'wires'
require_relative '../lib/wires/inotify'

require 'pry'

require 'minitest/autorun'
require 'minitest/spec'
require 'turn'
Turn.config.format = :outline
Turn.config.natural = true
Turn.config.trace = 5

include Wires

describe NotifyHub do
  
  it "is alive when and only when the Hub is." do
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :dead
    NotifyHub.state.must_equal :dsdfj
    NotifyHub.instance_variable_get(:@thread).must_be_nil
    
    Hub.run
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :alive
    NotifyHub.instance_variable_get(:@thread).wont_be_nil
    NotifyHub.instance_variable_get(:@thread).status.wont_equal false
    
    Hub.kill
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :dead
    NotifyHub.instance_variable_get(:@thread).must_be_nil
    
    Hub.run
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :alive
    NotifyHub.instance_variable_get(:@thread).wont_be_nil
    NotifyHub.instance_variable_get(:@thread).status.wont_equal false
    
    Hub.kill
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :dead
    NotifyHub.instance_variable_get(:@thread).must_be_nil
    
  end
  
  it "something" do
    sleep 1
  end
  it "something2" do
    sleep 1
  end
  it "something23" do
    sleep 1
  end
  it "something25" do
    sleep 1
  end
  it "something243" do
    sleep 1
  end
  
  
end

# empty_event = INotify::Native::Event.new

# on :notify, %r{/tmp/*} do |e|
#   p e
#   Hub.kill
# end
# on :notify, %r{/tmprr/*} do |e|
#   puts "NEVER HERE"
# end

# Hub.run
# sleep 0.1
# inotify_watch("/tmp/foo", :recursive)

# Thread.new do sleep 0.5; Hub.kill end
# sleep 100


# p NotifyHub.class_variable_get(:@@vestigial_events)
# p NotifyHub.class_variable_get(:@@vestigial_events_as_flags)

# p EventRegistry.list.select{ |x| 
#   (x<NotifyEvent) and
#   (ObjectSpace.each_object(Class).select { |c| c < x }.empty?)
# }