require 'wires'
require 'rb-inotify'

def inotify_watch(path, *flags)
  Wires::NotifyHub.watch(path, *flags)
end

def inotify_on(flags, channels='*', &codeblock)
  flags    = [flags]    unless flags.is_a?    Array
  channels = [channels] unless channels.is_a? Array
  for channel in channels
    Wires::NotifyHub.watch(channel, *flags)
    events = flags.map!{|x| ("notify_"+x.to_s).to_sym}
                  .map!{|x| x==:notify_all_events ? :notify : x }
    Wires::Channel.new(channel).register(events, codeblock)
  end
nil end

module Wires
  
  class NotifyEvent             < Event; end
  
  class NotifyAccessEvent       < NotifyEvent; end
  class NotifyAttribEvent       < NotifyEvent; end
  class NotifyModifyEvent       < NotifyEvent; end
  class NotifyOpenEvent         < NotifyEvent; end
  class NotifyCreateEvent       < NotifyEvent; end
  class NotifyDeleteEvent       < NotifyEvent; end
  class NotifyDeleteSelfEvent   < NotifyEvent; end
  class NotifyMoveSelfEvent     < NotifyEvent; end
  class NotifyIgnoredEvent      < NotifyEvent; end
  
  class NotifyCloseEvent        < NotifyEvent; end
  class NotifyCloseWriteEvent   < NotifyCloseEvent; end
  class NotifyCloseNowriteEvent < NotifyCloseEvent; end
  
  class NotifyMoveEvent         < NotifyEvent; end
  class NotifyMovedFromEvent    < NotifyMoveEvent; end
  class NotifyMovedToEvent      < NotifyMoveEvent; end
  
  class NotifyHub
    
    class << self
      
      attr_accessor :notifier
      attr_reader   :state
      def alive?; @state==:alive end
      def dead?;  @state==:dead  end
      
      def class_init
        
        # @@events_init = EventRegistry.list.select{ |x| (x < NotifyEvent) }
        @@events = Hash.new
        EventRegistry.list.select{ |x| (x < NotifyEvent) }.each do |cls|
          @@events[cls.codestring.gsub(/^notify_/, "").to_sym] = cls
        end
        
        @state = :dead
        @notifier = INotify::Notifier.new
        
        Hub.after_run(retain:true) do
          @state = :alive
          @thread = Thread.new { while alive?; thread_iter; Thread.pass; end }
        end
        
        Hub.before_kill(retain:true) do
          @state = :dead
          @thread.kill
          @thread = nil
        end
      end
      
      def watch(path, *flags, &block)
        flags << :all_events if (flags & @@events.keys).empty?
        inject_a_watcher(@notifier.watch(path, *flags, &block))
      end
      
      def list
        @notifier.watchers.values
                 .map { |w| inject_a_watcher(w)} # Inject new methods into obj
                 .reject { |w| w.closed? } # Exclude closed watchers from list
      end
      
      def matching(path=/.*/, *flags)
        list.select { |w| (path.is_a?(Regexp)) ? 
                            (path=~w.path) : 
                            (path.to_s==w.path) }
            .reject { |w| flags.detect{ |f| not flag_match(f, w.flags) } }
      end
      
      # Close all watchers and returns number of watchers closed
      def close_all
        s = list.size
        list.each { |w| w.close }
        s>0 ? s : nil
      end
      
      # Close watchers matching args and returns number of watchers closed
      def close_matching(*args) # :args: path=/.*/, *flags
        matches = matching(*args)
        matches.each { |w| w.close }
        (s=matches.size)>0 ? s : nil
      end
      
      threadlock (public_methods-superclass.public_methods)
      
      
    private
      
      # Determine if flag is implied (or explied) by flags array
      def flag_match(testflag, flags)
        return true if flags.include? :all_events
        
        !!flags.detect{ |f| testflag==f or
                            (@@events[testflag] and 
                             @@events[f] and 
                             @@events[testflag]<=@@events[f]) }
      end
      
      # Open metaclass of w to add close state tracking and return obj
      def inject_a_watcher(watcher)
        return watcher if watcher.public_methods.include? :closed?
        
        watcher.instance_variable_set(:@closed, false)
        class << watcher
          alias :_old_close :close
          def close(*args)
            self.instance_variable_set(:@closed, true)
            begin; _old_close(*args)
            rescue SystemCallError; end # If error, assume already closed
          end
          def closed?; self.instance_variable_get(:@closed); end
        end
        
        watcher
      end
      
      # Called repeatedly in inotify event processing thread
      def thread_iter
        @notifier.read_events.each { |e| process_event(e); e.callback! }
      end
      
      # Fire a wires event for inotify event e
      def process_event(e)
        return if dead?
        
        if (common_flags = (e.flags & @@events.keys)).empty?
          raise NotImplementedError, \
            "No Wires::NotifyEvent for flags #{e.flags}"
        end
        
        cls = Event.from_codestring("notify_"+common_flags.first.to_s)
        
        Channel.new(e.watcher.path)
               .fire(cls.new(*e.flags,
                            name:          e.name,
                            absolute_name: e.absolute_name,
                            watchpath:     e.watcher.path))
      end
      
    end
    
    class_init
  end
  
end