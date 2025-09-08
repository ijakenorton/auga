auga: *.odin
	odin build .

shell: auga 
	./auga shell.auga

array: auga 
	./auga array.auga
	
to_string: auga to_string.auga
	./auga to_string.auga

for: auga 
	./auga for.auga

lt: auga 
	./auga lt.auga

run_all: auga
	./auga even.auga &&\
	./auga for.auga &&\
	./auga return.auga &&\
	./auga scope.auga &&\
	./auga test.auga
