#!/usr/bin/env ruby

lmbda = 0.15
fromDoc = 0
file = File.open("link_small.xml", "r")
fromHash = Hash.new
deltaHash = Hash.new(1)

def LinksOut(doc)
  rightDoc = 0
  File.open("link_small.xml", "r") do |inFile|
    while (line = inFile.gets)
      if line =~ (/document id="#{doc}"/)
        out = 0
        rightDoc = 1
      end
      if line =~ (/link_to/) && rightDoc == 1
        out += 1
      elsif line =~ (/<\/document>/) && rightDoc == 1
        return out
      end
    end
  end
end

def RankHash(fromHash, file)
  linkFrom = Array.new
  fromIndex = 0
  lmbda = 0.15
  delta = 1
  while (line = file.gets)
    if line =~ (/document id="([0-9]*)"/)
      linkFrom = Array.new
      fromIndex = 0
      docID = Integer($1)
    elsif line =~ (/linked_from id="([0-9]*)"/)
      fromDoc = Integer($1)
      linkFrom[fromIndex] = fromDoc
      fromIndex += 1
    elsif line =~ (/<\/document>/)
      fromHash[docID] = linkFrom
    end
  end
end

def UpdateRank(fromHash, deltaHash, docRanks, bigD)
  go = 1
  keepGoing = 0
  iters = 0
  lmbda = 0.15
  while go == 1
    iters += 1
    for i in (1..bigD)
      newRank = lmbda/bigD
      fromArray = fromHash[i]
    if fromArray != nil
      fromArray.each do |d|
        newRank += (1 - lmbda)*(docRanks[d]/LinksOut(d))
      end
    end
      deltaHash[i] = (docRanks[i] - newRank).abs
      docRanks[i] = newRank
    end
    go = 0
    for i in (1..bigD)
      if deltaHash[i] > 0.0000001
        go = 1
      end

    end
  end
  puts "it took #{iters} iterations to converge"
end

RankHash(fromHash, file)
bigD = fromHash.size
docRanks = Hash.new(1/bigD)
UpdateRank(fromHash, deltaHash, docRanks, bigD)
f = File.new("PageRanks.txt", "w+")
docRanks.sort{|a,b| b[0]<=>a[0]}.each { |elem|
  f.puts "#{elem[0]} #{(elem[1])}"
}
#UpdateRank(fromHash, deltaHash, docRanks, bigD)

