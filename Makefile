run:
	sclang run.scd & 
	sleep 10
	./conductor

build:
	go build -v
	./conductor --build

learn:
	go build -v
	./conductor --learn open

reset:
	rm -rf right.learn left.learn 
	touch right.learn left.learn

links:
	ln Miti.sc ~/.local/share/SuperCollider/Extensions/Miti.sc
	ln Ouroboros2.sc ~/.local/share/SuperCollider/Extensions/Ouroboros2.sc

stop:
	pkill -f sclang

perform: startjack
	./conductor &

startjack:
	jackd -R -P 95 -d alsa -P hw:5 -C hw:5