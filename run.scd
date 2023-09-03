(
s.waitForBoot({
	o=Ouroboros2.new(Server.default);

	m=Miti.new(Server.default,240,"
c4 b b c
e4 e e g g g f e
g4 g d a
-
g5 g g f
e5 e d c
c5 b b a
-
e6 e e d c c c
c6 b b a
g6 g g f
-
c4 e g c c4 e g c b4 e g f b4 e g f b d g a b d g g f a c a f a d a
");
	m.setCallbackNote({ arg note;
		["note",note].postln;
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		o.trig(measure);
	});
	m.start();
	Routine {
		1.1.wait;
		o.prime("loop1",2);
	}.play;


	OSCFunc({ arg msg, time, addr, recvPort;
		// [msg, time, addr, recvPort].postln;
		var hand=msg[1];
		var gesture=msg[2];
		var x=msg[3].asFloat;
		var y=msg[4].asFloat;
		[hand,gesture,x,y].postln;
	}, '/conductor');

});
)

// m.setPhrase(3)
// m.stop()