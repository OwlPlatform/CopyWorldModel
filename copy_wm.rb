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

################################################################################
#Copy one world model's data to another using the world model protocols.
#
#This program will connect to a world model at a user-provided address and port,
#request all of its data, and will send that data to another user-specified
#world model.
################################################################################

#Require rubygems for old (pre 1.9 versions of Ruby and Debian-based systems)
require 'rubygems'
require 'libowl'

if (ARGV.length != 4)
  puts "This program needs 4 arguments: the ip address and client port of a world model to transfer data from and the ip address and solver port of a world model to send the data to."
  exit
end

src_wmip = ARGV[0]
src_port = ARGV[1]

dest_wmip = ARGV[2].to_i
dest_port = ARGV[3].to_i

#Connect to the world model as a client
src_wm = ClientWorldConnection.new(src_wmip, src_port)

if (not src_wm.connected)
	puts "Could not connect to the source world model!"
	exit
end

test_wm = SolverWorldModel.new(dest_wmip, dest_port, "world model copier")
if (not test_wm.connected)
	puts "Could not connect to the destination world model! Aborting!"
	src_wm.close()
	exit
end
test_wm.close()

puts "Gathering data from the world model..."
origin_to_data = Hash.new(Hash.new([]))
first_created = Hash.new

#Min and max are the minimum and maximum values of an unsigned 64 bit integer
min_possible = -(2**63)
max_possible = 2**63 - 1
query =  src_wm.rangeRequest('.*', ['.*'], min_possible, max_possible)
while (not query.isComplete())
	result = query.next()
	result.each_pair {|uri, attributes|
		attributes.each {|attr|
			if (not origin_to_data.has_key? attr.origin)
				origin_to_data[attr.origin] = Hash.new
			end
			if (not origin_to_data[attr.origin].has_key? uri)
				origin_to_data[attr.origin][uri] = []
			end
			origin_to_data[attr.origin][uri].push WMAttribute.new(attr.name, attr.data, attr.creation)
			#If this was the first time this object had a value remember this as the creation time
			if (not first_created.has_key? uri)
				puts "Remembering new object #{uri}"
				first_created[uri] = attr.creation
			end
			#TODO Should also remember expiration times so that they are also copied
		}
	}
end

#Done with the client connection
src_wm.close()

#Connect to the world model as a solver with each attributes username
puts "Connecting to the destination world model to create objects"
dest_wm = SolverWorldModel.new(dest_wmip, dest_port, "world model copier")
if (not dest_wm.connected)
	puts "Error connecting to the destination world model! Aborting!"
	src_wm.close()
	exit
end

#Create all of the objects from the first world model in the second
first_created.each_pair {|id, creation|
	puts "Creating #{id}"
	dest_wm.createURI(id, creation)
}
dest_wm.close()

puts "Pushing attributes..."
#Connect once again for each origin and push attributes
origin_to_data.each_pair {|origin, uri_attrs|
	#Connect to the world model as a solver with each attributes username
	puts "Connecting to the destination world model to push data from origin #{origin}"
	#Connect individually for each uri -- pushing so many attributes at a time may lead to timeouts, whereas new connections will spawn new threads in the world model.
	dest_wm = SolverWorldModel.new(dest_wmip, dest_port, origin)
	if (not dest_wm.connected)
		puts "Error connecting to the destination world model! Aborting!"
		exit
	end
	#Push subsets of the the values 100 at a time
	uri_attrs.each_pair{|uri, attributes|
		#Push each set of attributes to the world model, autocreating the object if necessary
		puts "\tPushing data for #{uri} (#{attributes.length} values)"
		#Remember original total so progress can be recorded
		total = attributes.length
		pushed = 0.0
		#Send the attributes in batches of 100, shrinking the number left each time
		while (not attributes.empty?)
			#Send the first 100 elements
			to_push = attributes[0,100]
			dest_wm.pushData([WMData.new(uri, to_push)], true)
			pushed += to_push.length
			puts "\t\t(#{100*pushed / total}% complete)"
			#Clip off the front that we've just sent
			attributes = attributes.drop 100
		end
	}
	#Close the connection and open socket
	dest_wm.close()
}
 
