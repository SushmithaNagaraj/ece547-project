# ece547-project

To compile AES netlist, do the following:
```bash
cd aes-t100
```

```bash
dc_shell -f do_synthesis.tcl
```
The script takes a few minutes to run, there's some warnings that show up but I don't think they're relevant.
Netlist will be output to file "aes_netlist.v"

Once the netlist is created, Tetramax comes up with testing which will be used to generate algorithms.
