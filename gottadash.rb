#!/usr/bin/env ruby
# GottaDash

$config = {
  :dash => "10:00",
  :break => "2:00",
  :cycles => 5,
  :dash_start_sound => File.join(File.dirname(__FILE__), 'static', 'alarm.mp3'),
  :dash_complete_sound => File.join(File.dirname(__FILE__), 'static', 'alarm.mp3'),
  :break_start_sound => File.join(File.dirname(__FILE__), 'static', 'alarm.mp3'),
}

### Exceptions
class InvalidCounterFormat < Exception; end
class InvalidCycleFormat < Exception; end


### The counter
class Counter
  
  def self.format(seconds)
    seconds.divmod(60).map {|e| e.to_s.rjust(2, '0')}.join(':')
  end

  def initialize(duration)
    @duration = duration
    raise InvalidCounterFormat unless @duration =~ /\d+:(\d{2})/ && $1.to_i < 60
    m, s = @duration.split(':').map {|e| e.to_i }
    @seconds_left = m*60 + s
  end
  
  attr_accessor :seconds_left
  
  def to_s
    Counter.format(@seconds_left)
  end
  
end


### Shoes app!

Shoes.app :title => "GottaDash", :width => 340, :height => 360, :resizable => false do
  
  # gui elements
  background "#000".."#222"
  
  # alarms! should be hidden, but it seems shoes cannot play hidden videos
  flow :width => 1, :height => 1 do
    background "#000"
    @videos = {
      :dash_start => video($config[:dash_start_sound]),
      :break_start => video($config[:break_start_sound]),
      :dash_complete => video($config[:dash_complete_sound]),
    }
  end
  
  stack :margin_left => 75, :margin_top => 20 do
    @countdown = banner $config[:dash], :stroke => white, :margin_left => 10, :margin_bottom => 0
    @status = title "---------", :stroke => yellow, :margin_left => 25
  end
  
  # the form (how does one make a table in Shoes?)
  @want_stack = stack :margin_top => 10, :margin_left => 105 do

    stack do
      flow do
        flow(:width => 70) { para "Dash: ", :stroke => "888" }
        @dash = edit_line $config[:dash], :width => 40
      end
  
      flow do
        flow(:width => 70) { para "Break: ", :stroke => "888" }
        @break = edit_line $config[:break], :width => 40
      end
  
      flow do
        flow(:width => 70) { para "Cycles: ", :stroke => "888" }
        @cycles = edit_line $config[:cycles].to_s, :width => 40
      end
    end
  
  end
  
  # the buttons
  flow :margin_left => 100, :margin_top => 10 do
    
    @start_button = button "Start"
    
    def enable_start_button
      @start_button.click do
        begin
          raise InvalidCycleFormat unless @cycles.text =~ /\d+/ and @cycles.text.to_i > 0
          @cycle_count = @cycles.text.to_i
          disable_start_button
          start_dash_timer
        rescue InvalidCounterFormat
          alert "Invalid Timer Format. Timers should be in mm:ss format."
        rescue InvalidCycleFormat
          alert "Invalid cycle value. Cycles should be an integer greater than zero."
        end
      end
    end

    def disable_start_button
      @start_button.click {}
    end
    
    enable_start_button

    @stop_button = button "Stop" do
      reset_timers
      enable_start_button
    end
    
  end
  
  # end of elements
  
  ### functions!
  
  def reset_timers
    reset_dash_timer if @dash_timer
    reset_break_timer if @break_timer
    @status.text = "---------"
  end
  
  def on_dash_finish
    @cycle_count -= 1
    if @cycle_count == 0
      reset_timers
      notify("Congratulations!", :dash_complete)
      enable_start_button
    else
      reset_dash_timer
      notify("Take a break!", :break_start)
      start_break_timer
    end
  end
  
  def on_break_finish
    reset_break_timer
    notify("Work! Work!", :dash_start)
    start_dash_timer
  end
  
  def reset_dash_timer
    @dash_timer.stop
    @dash_timer.remove
    @dash_timer = nil
  end
  
  def reset_break_timer
    @break_timer.stop
    @break_timer.remove
    @break_timer = nil
  end
  
  def start_break_timer
    counter = Counter.new(@break.text)
    @status.text = "BREAK"
    @countdown.text = counter.to_s
    @break_timer = every(1) do
      counter.seconds_left -= 1
      @countdown.text = counter.to_s
      on_break_finish if counter.seconds_left == 0
    end
  end
  
  def start_dash_timer
    @status.text = "WORK"
    counter = Counter.new(@dash.text)
    @countdown.text = counter.to_s
    @dash_timer ||= every(1) do
      counter.seconds_left -= 1
      @countdown.text = counter.to_s
      on_dash_finish if counter.seconds_left == 0
    end
  end
  
  def notify(alert_message = nil, vid = nil)
    play(vid) if vid
    alert(alert_message) if alert_message
    stop(vid) if vid
  end
  
  def play(v)
    @videos[v].play()
  end
  
  def stop(v)
    @videos[v].stop()
  end
  
end
