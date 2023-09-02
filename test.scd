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

SerialPort.devices

o.set("one","db",-12)
o.free;

(
x={ arg i;
	i.postln;
};
)

c.(1,2)

x.(2)

