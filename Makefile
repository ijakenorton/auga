auga:
	odin build .

array: auga 
	./auga array.auga

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
