(
s.waitForBoot({
	Routine {
		o=Ouroboros2.new(Server.default);
		o.set("metronome","tempo",480*2);
		o.record("loop1",2);

		OSCFunc({ arg msg, time, addr, recvPort;
			[msg, time, addr, recvPort].postln;
		}, '/conductor');
	}.play;
});
)

o.set("one","db",-12)
o.free;
