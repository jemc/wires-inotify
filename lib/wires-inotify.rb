require 'rb-inotify'

def inotify_watch(*args)
  Wires::NotifyHub.watch(*args)
end

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
  
  class NotifyCloseEvent        < NotifyEvent; end
  class NotifyCloseWriteEvent   < NotifyCloseEvent; end
  class NotifyCloseNowriteEvent < NotifyCloseEvent; end
  
  class NotifyMoveEvent         < NotifyEvent; end
  class NotifyMovedFromEvent    < NotifyMoveEvent; end
  class NotifyMovedToEvent      < NotifyMoveEvent; end
  
  class NotifyHub
    
    @@events = EventRegistry.list.select{ |x| (x<NotifyEvent) }
    
    @@vestigial_events = @@events.select{ |x| 
      (ObjectSpace.each_object(Class).select { |c| c < x }.empty?) }
    
    class << self
      
      def state;  @state         end
      def alive?; @state==:alive end
      def dead?;  @state==:dead  end
      
      def class_init()
        
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
      
      def watch(path, *flags)
        flags << :all_events if (flags&events_to_flags(@@events)).empty?
        @notifier.watch("/tmp/foo", *flags)
      end
      
    private
      
      def events_to_flags(list)
        list.map{|x| x.codestring.gsub(/^notify_/, "").to_sym}
      end
      
      def thread_iter
        @notifier.read_events.each { |e| process_event(e) }
      end
      
      def process_event(e)
        cls = nil
        if (common = (e.flags&events_to_flags(@@vestigial_events))).empty?
          raise NotImplementedError, \
            "No Wires::NotifyEvent for flags #{e.flags}"
        else
          cls = Event.from_codestring("notify_"+common.first.to_s)
          
          Channel.new(e.watcher.path)
                 .fire(cls.new(*e.flags,
                              name:          e.name,
                              absolute_name: e.absolute_name,
                              watchpath:     e.watcher.path))
        end
      end
      
    end
    
    class_init
  end
  
end