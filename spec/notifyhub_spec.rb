require 'wires'
require_relative '../lib/wires/inotify'

require 'minitest/autorun'
require 'minitest/spec'
require 'turn'
Turn.config.format  = :outline
Turn.config.natural = true
Turn.config.trace   = 5


describe Wires do
  it "encapsulates the right things" do
    Wires.constants.must_include :NotifyHub
    Wires.constants.must_include :NotifyEvent
    Wires::NotifyHub.class_variable_get(:@@events).values
      .map  { |cls| cls.name.gsub(/(.*)::/, "").to_sym }
      .each { |sym| Wires.constants.must_include sym}
  end
  
  it "doesn't encapsulate the other things" do
    Object.private_methods.include? :inotify_on
    Object.private_methods.include? :inotify_watch
  end
end


include Wires

$testdir = "/tmp/wires-inotify-testdir-#{$$}"


describe NotifyHub do
  
  it "is alive when and only when the Hub is" do
    
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
  
  
  it "can add an inotify watch and return the INotify::Watcher object" do
    `mkdir -p #{$testdir}`
    
    w = NotifyHub.watch($testdir)
    w.must_be_instance_of INotify::Watcher
    w.close
    
    `rm -rf #{$testdir}`
  end
  
  
  it "can add more than one watch .list open watches, and .close_all of them" do
    count = 20
    ws = 1.upto(count).map do |i| 
      `mkdir -p #{$testdir}-#{i}`
      NotifyHub.watch("#{$testdir}-#{i}")
    end
    
    ws.each { |w| w.must_be_instance_of INotify::Watcher }
    
    NotifyHub.list.size.must_equal count
    (ws-NotifyHub.list).must_equal []
    (NotifyHub.list-ws).must_equal []
    
    NotifyHub.close_all.must_equal count # returns number of watchers closed
    
    NotifyHub.list.size.must_equal 0
    
    1.upto(count).map { |i| `rm -rf #{$testdir}-#{i}` }
  end
  
  
  it "won't complain if you manually #close a few before .close_all" do
    count = 10
    ws = 1.upto(count).map do |i| 
      `mkdir -p #{$testdir}-#{i}`
      NotifyHub.watch("#{$testdir}-#{i}")
    end
    
    NotifyHub.list.size.must_equal count
    (ws-NotifyHub.list).must_equal []
    (NotifyHub.list-ws).must_equal []
    
    (indices = [0,2,7]).each { |i| ws[i].close }
    
    NotifyHub.list.size.must_equal count-indices.size
    (ws-NotifyHub.list).must_equal indices.map { |i| ws[i] }
    (NotifyHub.list-ws).must_equal []
    NotifyHub.close_all.must_equal count-indices.size
    
    NotifyHub.list.size.must_equal 0
    
    1.upto(count).map { |i| `rm -rf #{$testdir}-#{i}` }
  end
  
  
  it "can return only .matching watchers from its .list" do
    count = 6
    1.upto(count) { |i| `mkdir -p #{$testdir}/#{i}` }
    
    Hub.run
    
    a = NotifyHub.watch "#{$testdir}/1", :modify
    b = NotifyHub.watch "#{$testdir}/2", :modify
    c = NotifyHub.watch "#{$testdir}/3", :modify, :dont_follow
    d = NotifyHub.watch "#{$testdir}/4", :modify, :access
    e = NotifyHub.watch "#{$testdir}/5", :access
    f = NotifyHub.watch "#{$testdir}/6", :close
    
    matches = NotifyHub.matching
    [a,b,c,d,e,f].each{ |w| matches.must_include w}
    
    matches = NotifyHub.matching(/.*/)
    [a,b,c,d,e,f].each{ |w| matches.must_include w}
    
    matches = NotifyHub.matching(%r{/[124]})
    [a,b,d]      .each{ |w| matches.must_include w}
    [c,e,f]      .each{ |w| matches.wont_include w}
    
    matches = NotifyHub.matching(/.*/, :modify)
    [a,b,c,d]    .each{ |w| matches.must_include w}
    [e,f]        .each{ |w| matches.wont_include w}
    
    matches = NotifyHub.matching(%r{/[1356]}, :modify)
    [a,c]        .each{ |w| matches.must_include w}
    [b,d,e,f]    .each{ |w| matches.wont_include w}
    
    matches = NotifyHub.matching(/.*/, :modify, :dont_follow)
    [c]          .each{ |w| matches.must_include w}
    [a,b,d,e,f]  .each{ |w| matches.wont_include w}
    
    matches = NotifyHub.matching(/.*/, :modify, :access)
    [d]          .each{ |w| matches.must_include w}
    [a,b,c,e,f]  .each{ |w| matches.wont_include w}
    
    NotifyHub.close_all
    Hub.kill
    
    1.upto(count) { |i| `rm -rf #{$testdir}/#{i}` }
  end
  
  
  it "can .close_matching watchers from its .list" do
    count = 6
    1.upto(count) { |i| `mkdir -p #{$testdir}/#{i}` }
    
    Hub.run
    
    a = NotifyHub.watch "#{$testdir}/1", :modify
    b = NotifyHub.watch "#{$testdir}/2", :modify
    c = NotifyHub.watch "#{$testdir}/3", :modify, :dont_follow
    d = NotifyHub.watch "#{$testdir}/4", :modify, :access
    e = NotifyHub.watch "#{$testdir}/5", :access
    f = NotifyHub.watch "#{$testdir}/6", :close
    
    NotifyHub.close_matching(%r{/[1356]}, :modify)
    [a,c]        .each { |w| NotifyHub.list.wont_include w }
    [b,d,e,f]    .each { |w| NotifyHub.list.must_include w }
    
    NotifyHub.close_all
    Hub.kill
    
    1.upto(count) { |i| `rm -rf #{$testdir}/#{i}` }
  end
  
  
  it "injects the closed? method and relevant tracking into each Watcher" do
    `mkdir -p #{$testdir}`
    
    w = NotifyHub.watch $testdir
    w.closed?.must_equal false
    w.close
    w.closed?.must_equal true
    
    w = NotifyHub.watch $testdir
    w.closed?.must_equal false
    NotifyHub.close_all
    w.closed?.must_equal true
    
    w = NotifyHub.watch $testdir
    w.closed?.must_equal false
    NotifyHub.close_matching
    w.closed?.must_equal true
    
    w = NotifyHub.watch $testdir
    NotifyHub.list[0].closed?.must_equal false
    NotifyHub.list[0].close
    NotifyHub.list[0].must_be_nil
    
    `rm -rf #{$testdir}`
  end
  
  
  it "fires a Wires::NotifyEvent for each received inotify event" do
    
    caught_events = []
    caught_events.clear
    on :notify do |e|
      caught_events << e.class.codestring.to_sym
    end
    
    `mkdir -p #{$testdir}`; sleep 0.1
    
    Hub.run
    NotifyHub.watch($testdir)
    
    sleep 0.1; caught_events.clear
    
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
    
    NotifyHub.close_all
    Hub.kill
    
  end
  
end

