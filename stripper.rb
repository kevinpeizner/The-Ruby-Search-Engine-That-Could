#!/usr/bin/env ruby

# Authors: Tyson Larimer, Skylar Hiebert

require 'nokogiri'

class PlainTextExtractor < Nokogiri::XML::SAX::Document
	attr_reader :plaintext
	
	def initialize
		@plaintext = ""
		@tag_list = Array.new
		# Elements that we want to aggressively remove
		@bad_tags = ["style", "script", "object", "embed", "applet", "noframes", "noscript", "comment"]
		@valid_tag = false
		@count = 0
	end

	def start_element(name, attrs = [])
		@tag_list.unshift name
		@bad_tags.index(name).nil? ? @valid_tag = true : @valid_tag = false
	end

	def end_element(name, attrs = [])
		@tag_list.shift if @tag_list[0] == name
	end

	def characters(string)
		begin
			if(@valid_tag)
				newstring = string.encode("us-ascii").strip.gsub(/[!-&]|[(-@]|[\[-`]|[{-~]|[']|\n|\t|\r/i){""}
			 	#newstring.gsub!(/[\b*]|[\W*]|[_*]/){" "} 
				#newstring = string.gsub(/[\s*]|[\W*]|[_*]/i){" "}.strip
				#if (@count < 100)
				#	@count += 1
				#	p "string: #{string} --- newstring: #{newstring.strip}"	
				#end
			end
		rescue => ex
			newstring = ""
		end
		@plaintext << newstring.downcase.strip + " " unless newstring.nil? || newstring == ""
	end

	def clear
		@plaintext = ""
	end
end

pte = PlainTextExtractor.new
parser = Nokogiri::HTML::SAX::Parser.new(pte)

t = Time.now
Dir.glob('/mnt/html/*.html') do |doc|
	pte.clear
	parser.parse_file doc
	File.open("/mnt/docs/" + File.basename(doc, ".*") + ".txt", 'w+') {|file| file.write(pte.plaintext)}
end
p "Stripper.rb took #{Time.now - t} seconds to complete"
