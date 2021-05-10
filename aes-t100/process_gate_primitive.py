f = open("Primitive.temp", "r")

gate_info = f.read().splitlines()

gate_info = gate_info[0].split()[1][1:-1]

f_out = open("Primitive_out.temp", "w")

f_out.write(gate_info)

#print gate_info
