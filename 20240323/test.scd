(
s.waitForBoot({
	var crow;
	// setup crow
	SerialPort.devices.postln;
	// p = SerialPort.new(
	// 	"/dev/cu.usbmodem3474366F35381",
	// 	baudrate: 115200
	// );
	crow = {
		arg out,volts;
		"output["++out++"].volts="++volts++";\n".postln;
	};
	4.do({arg v,i;
		crow.(i+1,0);
	});
	Routine {
		// 	// setup ouroboros
		// 	o=Ouroboros2.new(Server.default);
		// 	o.set("metronome","tempo",480);
		// 	1.wait;
		// 	o.prime("loop1",2);
		// 	o.prime("loop2",3);
		//
		//
		//
		//
		// 	OSCFunc({ arg msg, time, addr, recvPort;
		// 		// [msg, time, addr, recvPort].postln;
		// 		var hand=msg[1];
		// 		var gesture=msg[2];
		// 		var x=msg[3].asFloat;
		// 		var y=msg[4].asFloat;
		// 		[hand,gesture,x,y].postln;
		// 	}, '/conductor');
	}.play;
});
)

// c e g
// b e g
// b d g
// f a c


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
});
)

m.setPhrase(2)
m.setPhrase(0)


SerialPort.devices

o.set("one","db",-12)
o.free;


