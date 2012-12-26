#!/usr/bin/env ruby
# encoding: utf-8
# Program that looks for duplicate files.
# Author: MaG, http://newbieshell.blogspot.com

require 'digest/sha2'
require 'find'
require 'mp3info'

class FileRecord
     attr_reader :file, :sum, :duplicates
     def initialize(path, sum)
          @file = path
          @sum = sum
          @duplicates = []
     end

     def has_duplicates?
          not @duplicates.empty?
     end

     def add(path)
          @duplicates.push path
     end
end

if ARGV[0].nil? or not File.directory? ARGV[0]
     $stderr.puts "Use: #$0 <directory>"
     exit 1
end


print 'Working, '
$file_count = 0
Thread.new do
        len = 0
        ['-', '\\', '|', '/'].cycle do |char|
                print "\b"*len, ' '*len, "\b"*len
                str = "#$file_count files procesed... #{char}  "
                len = str.length
                print str
                sleep 0.27
        end
end

hsh = {}
EMPTY_STRING_SUM = Digest::SHA256.hexdigest ''

Find.find(ARGV[0]) do|path|
     next unless File.file? path

     $file_count += 1

     sum = nil
     if path =~ /\.mp3$/i
          begin
               mp3 = Mp3Info.new(path)
               pos, length = mp3.audio_content
               mp3.close
          rescue
               next # discard this problematic file
          end

          File.open(path) do|file|
               file.pos = pos
               sum = Digest::SHA256.hexdigest(file.read(length))
          end
     else
          sum = Digest::SHA256.file(path).hexdigest
     end

     next if sum == EMPTY_STRING_SUM

     # nah!, let's use +unless+
     unless hsh[sum]
          hsh[sum] = FileRecord.new(path, sum)
     else
          file_record = hsh[sum]
          file_record.add(path)
     end
end

print "\n\nduplicates!\n\n"

hsh.each_value do|record|
     next unless record.has_duplicates?

     print "#{record.file}:\n->"
     print record.duplicates.join("\n-> "), "\n\n"
end
