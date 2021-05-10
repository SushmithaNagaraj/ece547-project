f = open("fault0.temp", "r")
f_out = open("fault0_out.temp", "w")

raw_fault = f.read()
match = "Current fault classification = DS (detected_by_simulation)"

if match in raw_fault:
	print "Fault detected for 0"
	f_out.write("detected")
else:
	print "Fault NOT detected for 0"
	f_out.write("not_fault")
