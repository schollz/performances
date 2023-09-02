(
s.waitForBoot({
	Routine {
		o=Ouroboros2.new(Server.default);
		o.set("metronome","tempo",480*2);
		o.record("loop1",2);

		OSCFunc({ arg msg, time, addr, recvPort;
			// [msg, time, addr, recvPort].postln;
			var hand=msg[1];
			var gesture=msg[2];
			var x=msg[3].asFloat;
			var y=1.0-msg[4].asFloat;
			[hand,gesture,x,y].postln;
		}, '/conductor');
	}.play;
});
)

o.set("one","db",-12)
o.free;
