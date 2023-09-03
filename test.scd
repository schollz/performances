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
		// 		var y=1.0-msg[4].asFloat;
		// 		[hand,gesture,x,y].postln;
		// 	}, '/conductor');
	}.play;
});
)

// c e g
// a c e


(
s.waitForBoot({
	o=Ouroboros2.new(Server.default);

	m=Miti.new(Server.default,240,"
c c c c
d d d d
e e e e
f f f f
-
c8 d e f g a# c8 d e f g a# c8 d e f g a# c8 d e f g a# c8 d e f g a# c8 d e f g a# c8 d e f g a# c8 d e f g a#

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

m.setPhrase(1)
m.setPhrase(0)


SerialPort.devices

o.set("one","db",-12)
o.free;


