CopyWorldModel
==============

Copy the contents of one running world model into another.

The copy_wm.rb script will connect to a source world model over the network and copy its data to another world model on the network.
	copy_wm.rb <source ip> <source client port> <destination ip> <destination solver port>

The copy_sqlite_dump.rb script will read dumped insert statements from a sqlite3 world model's database and send that data to another world model on the network. Insert statements should be of the form:
	INSERT INTO "attributes" VALUES('identifier','attribute',creation,expiration,'origin',X'hex data');
The command should be run as follows:
	copy_sqlite_dump.rb <dump file> <destination ip> <destination solver port>
