auga:
	odin build .

for: auga 
	./auga for.auga

run_all: auga
	./auga even.auga && ./auga for.auga && ./auga return.auga && ./auga scope.auga && ./auga test.auga
# build:
# 	odin build . 
# 	`p
