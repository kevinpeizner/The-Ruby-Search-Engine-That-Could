#!/usr/bin/env ruby

# Author: Skylar Hiebert

require 'uri' 
require 'open-uri'
require 'nokogiri'
require 'timeout'
require_relative 'parsestats.rb'
require_relative 'roboparse.rb'

class Host
	attr_reader :protocol, :domain
	attr_accessor :delay, :disallow_list, :last_visited

	def initialize(url)
		begin
			#p "URL: #{url}"
			@protocol = URI.parse(url).scheme
			@domain = URI.parse(url).host
			@disallow_list = nil
			@delay = 0
			@last_visited = nil
		rescue Exception => ex
			@protocol = nil
			@domain = nil
		end
	end

	def host
		@protocol.nil? || @domain.nil? ?	nil : @protocol + "://" + @domain 
	end

	def allowed?(path)
		dList.each do |disallow_path|
			return false if disallow_path == path 
		end
		return true
	end

	def roboparse
		parser = RoboParser.new
		robo = parser.roboparse(@protocol + "://" + @domain)
		@delay = robo[0]
		@disallow_list = robo[1]
	end

	def last_visited
		@last_visited.nil? ? @last_visited = Time.now : @last_visited
	end

	def visit
		@last_visited = Time.now
	end

	def ==(x)
		@protocol == x.protocol and @domain == x.domain
	end

end

class Page
	attr_accessor :url

	def make_absolute(href, host)
		begin #return nil if href.nil?
			uri = URI.parse(href)
			uri = URI.parse(host).merge(href.to_s) if uri.relative?
			uri.to_s
		rescue Exception => ex
			return nil
		end
	end

	def scrub_url(url)
		return nil if url =~ %r{#} or url.nil?
			make_absolute(url, @url)
	end

	def initialize(url)
		@timeout = false
		@valid = true
		begin
			@url = url
			status = Timeout::timeout(0.75) {
				@page = Nokogiri::HTML(open(@url, 'r', :read_timeout=>0.6)) do |config|
				config.noerror
				end
			}
			@timeout = true if @page.nil?
			return @page
		rescue Timeout::Error => ex
			@timeout = true
		rescue ArgumentError => ex
			p "Argument Error #{url}, dropping"
			@valid = false
		rescue StandardError => ex
			#p "Unknown Error: #{ex}"
			@valid = false
		rescue Exception => ex
			@valid = false
		end
	end

	def get_links
		link_list = Array.new 
		@page.css('a').map do |link|
			new_link = scrub_url(link.attributes['href'])
			link_list << new_link unless new_link.nil?
		end
		return link_list
	end

	def store(filename)
		begin
			#time = Time.now
			File.delete(filename) if File.exists?(filename)
			File.open(filename, "w") {|file| file.write(@page.to_html)}
		rescue ArgumentError => ex
			p "Argument Error could not save #{@url}: #{ex}"
			return nil
			#p "Time to store file #{filename} took #{Time.now - time} seconds"
		end
	end
	def valid?
		@valid
	end

	def timeout?
		@timeout
	end

	def nil?
		@page.nil?
	end
end

class LinkQueue

	def initialize
		@queue = Hash.new
	end

	def enqueue(url)
		begin
			host = Host.new(url)
			path = URI.parse(url).path
		rescue
			host = nil
			path = nil
		end

		roboparse = Fiber.new do
			host.roboparse
			Fiber.yield
		end

		if host.nil? 
			return
		elsif @queue.has_key?(host.host)
			@queue[host.host][1] << path unless @queue[host.host][1].index(path)
		elsif @queue.size < 250000
			#time = Time.now
			#host.roboparse
			#roboparse.resume 
			@queue[host.host] = [host, [path]]
			#p "It took #{Time.now - time} to roboparse #{host.host}"
		end
	end

	def dequeue
		@queue.size.times do
			tuple = @queue.shift
			host = tuple[1][0]
			path = tuple[1][1].shift
			#p "HOST: #{host.host} PATH: #{path}"
			@queue[host.host] = [host, tuple[1][1]] # Place host back into queue
			return [host, path] unless path.nil?
		end
		return nil
	end

	def has_host?(host)
		has_host = false
		@queue.each_key do |key|
			return true if host =~ key.host 
		end
	end

	def size
		sum = 0
		@queue.each_value { |value| sum += value[1].size }
		return sum
	end
end

class PidMap
	attr_accessor :filename, :current_id

	def initialize(filename = "pid_map.dat", mode = "w+")
		@filename = filename
		File.delete(filename) if File.exists?(filename) 
		file = File.new(filename, mode)
	  	#last_line = `tail -n 1 #{filename}`
		#@current_id = last_line.split(":")[0].to_i	
		#@current_id = 0 if @current_id.nil?
		file.close unless file == nil
	end

	def url_visited?(url)
		File.open(@filename, "r") do |file| 
			while line = file.gets
				regex = Regexp.new(Regexp.escape(url), Regexp::IGNORECASE)
				return true if line =~ regex				
			end
		end
	end

	def add_url(file_id, url)
		#@current_id = file_id
		File.open(@filename, "a") {|file| file.write("#{file_id}:#{url}\n")} 
	end

	def get_unique_pages(start_index, end_index) 
		pages = Hash.new(0)
		File.open(@filename, "r") do |file|
			while line = file.gets
				sline = line.split(":")
				line_number = sline[0].to_i
				host = URI.parse(sline[1]).host
				next if line_number < start_index 
				if line_number <= end_index 
					pages[host] += 1 
				else
					return pages
				end
			end
		end	
	end

end

seed_url = ARGV[0] unless ARGV[0].nil?
page_threshold = ARGV[1].to_i unless ARGV[1].nil?

if page_threshold.nil? || seed_url.nil?
	puts  "Usage: crawler seed_url page_threshold"
	exit
end

mutex = Mutex.new
pid_map = PidMap.new
l_queue = LinkQueue.new
stats = ParseStat.new(page_threshold)
#stats.T = pid_map.current_id
current_interval = 1
#p "Enqueueing Seed #{seed_url}"
l_queue.enqueue(seed_url)

startTime = Time.now
loop do
	if stats.T >= page_threshold || l_queue.size == 0
		break
	end
	link = l_queue.dequeue
	#Drop link if there is no disallow_list or the link exists in the disallow_list
	next if !link[0].disallow_list.nil? && link[0].disallow_list.index(link[1])	
	#Drop if the host is nil (invalid)
	link[0].host.nil? ? next : url = link[0].host + link[1]
	#link[0].last_visited = Time.now if link[0].last_visited == nil 
	#Politeness Policy
	if link[0].delay > 0 && Time.now - link[0].last_visited < link[0].delay 
		l_queue.enqueue(url)
	else
		link[0].visit
	end	
	unless pid_map.url_visited?(url)
		page = nil
		page = Page.new(url)
		#p "Page == url? #{page == url} url: #{url} page: #{page}"
		if(!page.valid?) # Problem loading page, dropping
			stats.inc_drops
			next
		elsif(page.timeout?) # Page Timeout occurred
			#p "Re-Enqueueing(Timeout): #{url}"
			stats.inc_timeouts
			#l_queue.enqueue(url)
			next
		else # Valid page opened
			pid_map.add_url(stats.T, url)
			page.get_links.each {|new_link| l_queue.enqueue(new_link)}
			stored = page.store("./html/Document#{stats.T}.html") unless page.nil?
			stats.inc_T unless stored.nil?
		end
	else
		stats.inc_D
	end
	if stats.interval > current_interval && !stored.nil?
		stats.print_interval(current_interval)
		current_interval += 1
	end
end
#end
#end

#threads.each(&:join)
stats.agg_print_stats
p Time.now - startTime
#queue = Hash.new
#page.get_links.each do |link|
#	host = URI.parse(link).host
#	path = URI.parse(link).path
#	if(queue.has_key?(host))
#		queue[host] << path
#	else
#		queue[host] = [path]
#	end
#end
#
#begin
#	pair = queue.shift
#	p pair[0] + pair[1].shift unless pair[1].empty?
#	t += 1
#	unless(pair[1].empty?)
#		if(queue.has_key?(pair[0]))
#			queue[pair[0]] << pair[1]
#		else
#			queue[pair[0]] = [pair[1]]
#		end
#	end
#end while !queue.empty? && t < page_threshold

#	queue.each do |key, val| while 
#		p !queue.empty?
#		p t < page_threshold
#		p !queue.empty? && t < page_threshold
#		p !queue.empty? and page_threshold
#		p !queue.empty? or page_threshold + ":" + !queue.empty? || page_threshold
#		p t.to_s + " of " + page_threshold.to_s + ":" + key + val.shift
#		t += 1
#		queue.delete(key) if val.empty?
#	end !queue.empty? && t < page_threshold

#|key, val| = queue.shift unless queue.empty?
#p key.to_s + ":" + val.to_s

# Methods to parse URL, require 'uri'
#s = URI.parse("http://www.testurl.com/somepath/index.htm")
#p s.host
#p s.path

