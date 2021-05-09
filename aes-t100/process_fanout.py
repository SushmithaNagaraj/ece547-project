f = open("FanoutFinal.temp", "r")

fanout = f.read().splitlines()

#remove first and last lines
fanout = fanout[1:-1]
fanout_final = []
for net in fanout:
	fanout_final.append(net.split()[0])

fanout_final = "\n".join(fanout_final)


f_out = open("FanoutFinal_out.temp", "w")
f_out.write(fanout_final)
