import sys

f = open("FanIn.temp", "r")

fanin = f.read()
fanin_raw = fanin.splitlines()

# multiple fanins? probably not for confidentiality but maybe for integrity?
fanin_out = fanin_raw[1].split()[0]

if (len(fanin_raw) > 3):
	print "---------- WARNING: MULTIPLE FANIN!!! ---------------"

f_out = open("FanIn_out.temp", "w")

#print sys.argv[1]
#print fanin_out

if (sys.argv[1] in fanin):
	f_out.write("STOP")
else:
	f_out.write(fanin_out)
