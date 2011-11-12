#!/usr/bin/env ruby

# Author: Skylar Hiebert

class ParseStat
  attr_accessor :threshold, :T
  attr_reader :interval

  def initialize(threshold)
    @begin_time = Time.now
    @times = Array.new
    @threshold = threshold
    @T = 0
    @D = Array.new(11, 0)
	 @timeouts = Array.new(11, 0)
    @drops = Array.new(11, 0)
	 @interval = 1
    @times[0] = @begin_time
  end

  def inc_D
    @D[@interval - 1] += 1
  end

  def inc_timeouts
	  @timeouts[@interval - 1] += 1
  end

  def inc_drops
	  @drops[@interval - 1] += 1
  end

  def inc_T
    @T += 1
    #puts @T
    #puts "begin time: " + @begin_time.to_s
    if @T % (threshold > 10 ? threshold / 10 : 1) == 0
      @times[@interval] = Time.now
      # p @times
      @interval += 1
    end

  end

  def print_interval(interval)
    puts "Interval #{(interval-1) * 10}% to #{interval * 10}% took #{@times[interval] - @times[interval-1]} seconds"
    puts "Number of unique pages visited in this interval: #{@threshold / 10}"
    puts "Number of timeouts and pages re-enqueued in this interval: #{@timeouts[interval-1]}"
	 puts "Number of dropped pages in this interval: #{@drops[interval-1]}"
	 puts "Number of duplicate pages encountered in this interval: #{@D[interval-1]}"
    puts "Total number of pages visited in this interval: #{@threshold / 10 + @D[interval-1] + @timeouts[interval-1] + @drops[interval-1]}"
    puts "----------------------------------------"
  end

def agg_print_stats
    if @interval == 11
      dupsum = 0
		dropsum = 0
		timeoutsum = 0
      for i in 1...11
			dropsum += @drops[i]
			timeoutsum += @timeouts[i]
        dupsum += @D[i]
      end
      puts "Total time: #{@times[10] - @times[0]} seconds"
      puts "Total number of pages visited: #{@threshold + dupsum + dropsum + timeoutsum}"
   	puts "Number of timeouts and pages re-enqueued: #{timeoutsum}"
	 	puts "Number of dropped pages: #{dropsum}"
      puts "Total number of duplicates visited: #{dupsum}"
      puts "Total number of unique pages visited: #{@T} (should be equal to #{threshold})"
    end
  end
end
#myParseStat = ParseStat.new(20)
#myParseStat.threshold.times do
#  myParseStat.inc_T
#  myParseStat.inc_D
#  sleep 1
#end
#myParseStat.print_stats
#myParseStat.print_interval(1)
#myParseStat.print_interval(2)
#myParseStat.print_interval(3)
#myParseStat.agg_print_stats

