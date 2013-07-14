require 'wires'
require_relative '../lib/wires-inotify'

require 'minitest/autorun'
require 'minitest/spec'

include Wires


describe NotifyHub do
  
  it "is alive when and only when the Hub is." do
    
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
  
end