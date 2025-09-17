auga: *.odin
	odin build .

shell: shell.auga auga 
	./auga shell.auga

array: array.auga auga 
	./auga array.auga
	
to_string: to_string.auga auga 
	./auga to_string.auga debug 

for: for.auga auga 
	./auga for.auga

ltgt: ltgt.auga auga 
	./auga ltgt.auga

all: shell array to_string for ltgt

.PHONY: shell array to_string for ltgt
