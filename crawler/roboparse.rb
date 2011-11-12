#!/usr/bin/env ruby
#
#
#Once the array returns, you should check to see if the item in dList[0] =~ /crawl-delay/i
#If so, do tokens = dList[0].split(' ') and set your crawl speed to tokens[1]
#
#
require 'open-uri'
class RoboParser
	def roboparse(domain)
		dList = Array.new
		roboInfo = Array.new
		curAgent = ""
		seenGooglebot = 0
		delay = 0
		begin
			open(domain + "/robots.txt") do |file|
				while line = file.gets
					if line =~ /user-agent: (\*|.*googlebot.*)/i && $1 != curAgent 
						if seenGooglebot == 1
							roboInfo << delay
							roboInfo << dList
							#p roboInfo
							return roboInfo
							exit
						end
						dList.clear
						curAgent = $1
					elsif line =~ /user-agent:/i && !(line =~ /user-agent: (\*|.*googlebot.*)/i)
						curAgent = ""
					end
					if curAgent =~ (/\*|.*googlebot.*/i)
						seenGooglebot = 1 if curAgent =~ /.*googlebot.*/i
						if line =~ /crawl-delay:/i
							delToks = line.split(' ');
							delay = delToks[1].to_i
						end
						if line =~ /disallow:/i
							toks = line.split(' ');
							#puts toks[0]
							#puts toks[1]
							dList << toks[1] if toks[0] != nil
						end
					end
				end
				roboInfo << delay
				roboInfo << dList
				#puts roboInfo
				return roboInfo
			end
		rescue Exception => ex
			roboInfo << delay
			roboInfo << dList
			return roboInfo
		end
		#rescue OpenURI::HTTPError => the_error
		#	roboInfo << delay
		#	roboInfo << dList
		#	return roboInfo
		#rescue OpenURI::HTTPRedirect => the_error2
		#	roboInfo << delay
		#	roboInfo << dList
		#	return roboInfo
		#end
	end
end
#myRobo = RoboParser.new
#p myRobo.roboparse("http://portal.eclipse.org/")



