1.Home directory includes:
 
1.1 src
 
	--- VHDL codes implementing RSA Public Key Cypher, along with a testbench. 

1.2 BasicRSA-T400.pdf 


2.Trojan
  
Trojan Description
	Trojan leaks inExp (private key exponent (e)), and after a certain number of encryption Trojan replaces the secret key to deny the service. The adversary would be the only entity would understand the message.


Trojan Taxonomy
	Insertion phase: Design
	Abstraction level: Register-transfer level 
	Activation mechanism: Internally time based
	Effects: Leak information, Denial of service
	Location: Processor
	Physical characteristics: Functional

3. Implementation
	The RSA Public Key Cypher was evaluated in Xilinx ISE Design Suite 13.3.
