require 'wires'
require_relative '../lib/wires/inotify'

require 'minitest/autorun'
require 'minitest/spec'
# require 'turn'
# Turn.config.format  = :outline
# Turn.config.natural = true
# Turn.config.trace   = 5

include Wires


$testdir = "/tmp/wires-inotify-testdir-#{$$}"

describe NotifyHub do
  
  it "is alive when and only when the Hub is." do
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :dead
    NotifyHub.instance_variable_get(:@thread).must_be_nil
    
    Hub.run;
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :alive
    NotifyHub.instance_variable_get(:@thread).wont_be_nil
    NotifyHub.instance_variable_get(:@thread).status.wont_equal false
    
    Hub.kill;
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :dead
    NotifyHub.instance_variable_get(:@thread).must_be_nil
    
    Hub.run;
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :alive
    NotifyHub.instance_variable_get(:@thread).wont_be_nil
    NotifyHub.instance_variable_get(:@thread).status.wont_equal false
    
    Hub.kill;
    
    NotifyHub.alive?.must_equal Hub.alive?
    NotifyHub.dead?.must_equal  Hub.dead?
    NotifyHub.state.must_equal :dead
    NotifyHub.instance_variable_get(:@thread).must_be_nil
    
  end
  
  it "fires a Wires::NotifyEvent for each received inotify event" do
    
    caught_events = []
    on :notify do |e|
      caught_events << e.class.codestring.to_sym
    end
    
    `mkdir -p #{$testdir}`; sleep 0.1
    
    Hub.run
    NotifyHub.watch($testdir)
    
    `touch #{$testdir}/testfile`; sleep 0.1
    caught_events.sort.must_equal \
      [:notify_attrib, :notify_close_write, :notify_create, :notify_open]
    caught_events.clear
    
    `echo "something" > #{$testdir}/testfile`; sleep 0.1
    caught_events.sort.must_equal \
      [:notify_close_write, :notify_modify, :notify_modify, :notify_open]
    caught_events.clear
    
    `cat #{$testdir}/testfile`; sleep 0.1
    caught_events.sort.must_equal \
      [:notify_access, :notify_close_nowrite, :notify_open]
    caught_events.clear
    
    `mkdir #{$testdir}/subdir`; sleep 0.1
    caught_events.sort.must_equal [:notify_create]
    caught_events.clear
    
    `mv #{$testdir}/testfile #{$testdir}/subdir/testfile`; sleep 0.1
    caught_events.sort.must_equal [:notify_moved_from]
    caught_events.clear
    
    `mv #{$testdir}/subdir/testfile #{$testdir}/testfile`; sleep 0.1
    caught_events.sort.must_equal [:notify_moved_to]
    caught_events.clear
    
    `chmod 777 #{$testdir}/testfile`; sleep 0.1
    caught_events.sort.must_equal [:notify_attrib]
    caught_events.clear
    
    `rm #{$testdir}/testfile`; sleep 0.1
    caught_events.sort.must_equal [:notify_delete]
    caught_events.clear
    
    `mv #{$testdir} #{$testdir}-foo`; sleep 0.1
    caught_events.sort.must_equal [:notify_move_self]
    caught_events.clear
    
    `rm -rf #{$testdir}-foo`; sleep 0.1
    caught_events.sort.must_include :notify_delete_self
    caught_events.clear
    
    # NotifyHub.close_all
    Hub.kill
    
  end
  
  # it "close_all" do
  #   NotifyHub.close_all
  # end
  
  # it "close_matching" do
  #   Hub.run
  #   `mkdir -p #{$testdir}`; sleep 0.1
  #   NotifyHub.watch $testdir, :modify, :dont_follow
  #   # puts NotifyHub.matching(/test/, :modify)
  #   # puts NotifyHub.list
  #   puts NotifyHub.close_matching(/test/, :modify)
  #   puts NotifyHub.list
  #   Hub.kill
  # end
  
end
