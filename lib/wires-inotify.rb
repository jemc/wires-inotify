require 'rb-inotify'

module Wires
  
  class NotifyEvent < Event; end
  
  class NotifyHub
    
    class << self
      
      def state;  @state         end
      def alive?; @state==:alive end
      def dead?;  @state==:dead  end
      
      def class_init()
        @notifier = INotify::Notifier.new
        
        @state = :dead
        
        Hub.after_run(retain:true) do
          @state = :alive
          @thread = Thread.new { while alive?; thread_iter; end }
        end
        
        Hub.before_kill(retain:true) do
          @state = :dead
          sleep 0 while @thread.status
          @thread = nil
        end
        
      end
      
    private
      
      def thread_iter
        puts "alive!!!"
      end
      
    end
    
    class_init
  end
  
end