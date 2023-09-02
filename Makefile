run:
	go build -v
	./conductor

reset:
	rm -rf right.learn left.learn 
	touch right.learn left.learn