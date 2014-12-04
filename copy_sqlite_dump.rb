#    Copyright (C) 2014  Bernhard Firner
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#


################################################################################
# Copy a sqlite3 dump with a world model's data into a running world model
# over the network.
#
# This program will connect to a world model at a user-provided address and
# port, request all of its data, and will send that data to another
# user-specified world model. The program expects the name of a .dump file from
# a sqlite3 world model with statements of the form:
#   INSERT INTO "attributes" VALUES('identifier','attribute',creation,expiration,'origin',X'hex data');
#
# This program will spawn a new thread and connection for each new origin, and
# will preserve the original origin names and timestamps of the attributes.
################################################################################

#Require rubygems for old (pre 1.9 versions of Ruby and Debian-based systems)
require 'rubygems'
require 'libowl'

if (ARGV.length != 3)
	puts "This program needs 3 arguments: the dump file to read data from and "+
	"the ip address and solver port of a world model to send the data to."
  exit
end

#Source file for the data dump
src_file = ARGV[0]

#Destination world model's ip address and solver port
dest_wmip = ARGV[1].to_i
dest_port = ARGV[2].to_i

##Checking to make sure that the destination world model is reachable
#dest_wm = SolverWorldModel.new(dest_wmip, dest_port, "world model copier")
#if (not dest_wm.connected)
#	puts "Could not connect to the destination world model! Aborting!"
#	exit
#end
##We will open new connections with matching origins from the actual sources
#dest_wm.close()

#Read in data from the dump file, uploading to the connection as we go
#This causes more network traffic overall, but amortizes the networking
#latency. We need to be sure that we do not overwhelm the network
#though, as throughput reading from the file will be greater than writing to
#the world model through the network.

puts "Gathering data from the world model..."
origin_to_connection = Hash.new

#New hashmap of origins to world model connections
origin_connection = Hash.new
#Hold the last data for each origin-identifier-attribute. Once we can see the
#next data for the same key value verify that the expiration of this one
#matches the creation of the next. If they don't match then we need to manually
#send the expire command
last_attribute_buffer = Hash.new

#Loop through the file line by line
File.open(src_file) do |handle|
	handle.each_line do |line|
		#If this matches the expect insert statement syntax then create a message
		#and push to the world model
		if (line =~ /INSERT INTO "attributes" VALUES\('(.*)','(.*)',(.*),(.*),'(.*)',X'(.*)'\);/)
			#We matched the identifier, attribute name, creation date, expiration
			#date, origin, and data
			id, at_name, origin = $1, $2, $5
			creation, expiration = $3.to_i, $4,to_i
			#Map the hex function onto pairs of characters to convert from a string to a byte array
			data = str.scan(/../).map(&:hex)
			#WMAttribute.new(attr.name, attr.data, attr.creation)
			attr = WMAttribute(at_name, data, creation)
		end
	end
end

#Now send everything left in the last_attribute_buffer

#Now close all of the connections to the world model




#Connect to the world model as a solver with each attributes username
#puts "Connecting to the destination world model to create objects"
#dest_wm = SolverWorldModel.new(dest_wmip, dest_port, "world model copier")
#if (not dest_wm.connected)
#	puts "Error connecting to the destination world model! Aborting!"
#	src_wm.close()
#	exit
#end
#
##Create all of the objects from the first world model in the second
#first_created.each_pair {|id, creation|
#	puts "Creating #{id}"
#	dest_wm.createURI(id, creation)
#}
#dest_wm.close()
#
#puts "Pushing attributes..."
##Connect once again for each origin and push attributes
#origin_to_data.each_pair {|origin, uri_attrs|
#	#Connect to the world model as a solver with each attributes username
#	puts "Connecting to the destination world model to push data from origin #{origin}"
#	#Connect individually for each uri -- pushing so many attributes at a time may lead to timeouts, whereas new connections will spawn new threads in the world model.
#	dest_wm = SolverWorldModel.new(dest_wmip, dest_port, origin)
#	if (not dest_wm.connected)
#		puts "Error connecting to the destination world model! Aborting!"
#		exit
#	end
#	#Push subsets of the the values 100 at a time
#	uri_attrs.each_pair{|uri, attributes|
#		#Push each set of attributes to the world model, autocreating the object if necessary
#		puts "\tPushing data for #{uri} (#{attributes.length} values)"
#		#Remember original total so progress can be recorded
#		total = attributes.length
#		pushed = 0.0
#		#Send the attributes in batches of 100, shrinking the number left each time
#		while (not attributes.empty?)
#			#Send the first 100 elements
#			to_push = attributes[0,100]
#			dest_wm.pushData([WMData.new(uri, to_push)], true)
#			pushed += to_push.length
#			puts "\t\t(#{100*pushed / total}% complete)"
#			#Clip off the front that we've just sent
#			attributes = attributes.drop 100
#		end
#	}
#	#Close the connection and open socket
#	dest_wm.close()
#}
 
