
(
t = Server.default.options;
t.numInputBusChannels = 2;
s.waitForBoot({
	var bpm = 90;
	var recCount = 0;
	var doRecord = true;
	var loopNum = 0;
	var loopNumMax = 7;
	var scale=Array.new;
	var cscale=Scale.major.degrees;
	var handOctave = 0;
	var handNote = 0;
	s.record;

	7.do({ arg octave;
		cscale.do({arg v;
			scale=scale.add(24+v+(octave*12));
		});
	});

	p = SerialPort.new(
		"/dev/ttyACM0",
		baudrate: 115200
	);
	~crowSet = {
		arg port, volts;
		p.putAll("output["++port++"].volts="++volts++";\n");
	};
	p.putAll("output[4].action='{  to(10,"++(60/bpm/2)++",logarithmic), to(0,"++(60/bpm)++",exponential) }';\n");


	// synthdefs
	SynthDef("env1",{
		arg port=2,attack=1,decay=1,sustain=0.5,release=1,dur=1;
		var env = EnvGen.kr(Env.adsr(attack,decay,sustain,release),EnvGen.kr(Env.new([0,0,1],[dur,0.1])),10,doneAction:2);
		SendReply.kr(Impulse.kr(10),"/env",[port,env]);
	}).add;
	OSCFunc({ arg msg, time, addr, recvPort;
		// [msg, time, addr, recvPort].postln;
		var port=msg[3].asInteger;
		var env=msg[4].asFloat;
		[port,env].postln;
		~crowSet.(port,env);
	}, '/env');



	o=Ouroboros2.new(s);
	o.setCVCallback({ arg id, data;
		// ~crowSet.(2,data);
	});


	/*	m=Miti.new(Server.default,bpm,"
	a3 f3 c3 e3
	c7 a6 c7 b6
	a2 f2 c2 e2
	e5 f g e
	c5 a4 c5 b4
	a6 c7 e6 g6

	c7 f7 c7 e7
	e6 c6 e6 g6
	a3 f3 c3 e3
	a5 f5 g e5
	c6 a5 c6 b5

	e7 c7 e6 g6
	c7 a6 c7 b6
	a5 a c e
	a3 f3 c3 e3

	e5 f g e
	a5 a5 c c5
	c6 c6 e6 b5

	");*/
	// m=Miti.new(Server.default,bpm,"
	// 	g5 e5 g5 c5
	// 	b4 g4 b4 f4
	// 	g2 g2 g2 a2
	// 	e5 e5 d5 d5
	// 	e6 c6 d6 d6
	// 	b6 c6 d6 f6
	// 	e5 c5 d5 a5
	// ");
		m=Miti.new(Server.default,bpm,"
	c4 c4 g4 g4
	e5 f5 e5 d5
	a3 a3 c4 b4
	a2 f2 c2 g2
	e5 c5 e5 d5
	e6 e6 g6 b6
	a2 f2 c2 g2
	c6
	d6
	");
		m=Miti.new(Server.default,bpm,"
	c4 c4 g4 g4
	e5 f5 e5 d5
	a3 a3 c4 b4
	a2 f2 c2 g2
	e6 e6 g6 b6
	c6
	d6
	");
	// F Am Am Am Am7 Em7 F F F Am Am Am7 Em F F
	// m=Miti.new(Server.default,bpm,"
	// 	a4 a4 a4 a4 e4 e4 c4 f4 f4 c4 c4 c4 e4 f4 f5
	// 	c5 c5 e5 e6 c5 g5 f5 a5 a6 a5 a5 a5 g6 a4 a4
	// 	f3 e3 c3 c3 a3 d3 a3 c3 c3 e3 e3 e3 d3 c3 c3
	// 	f6 c7 a6 a6 g6 g6 f6 f6 f6 a6 a6 g6 g6 f6 f6
	// ");

	m.setCallbackNote({ arg note;
		["note",note].postln;
		if (loopNum<loopNumMax,{
			~crowSet.(1,(note-36)/12);
		});
		p.putAll("output[4]();\n");
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		o.set("metronome","t_trig",1);
		loopNum = loopNum + 1;
		if (loopNum<loopNumMax,{
			o.record("loop"++loopNum.mod(8),16.0 * 60 / bpm);
			/*			if (loopNum==1,{
			o.recordCV(1,16.0 * 60 / bpm);
			});*/
		});
	});
	m.setCallbackScore({
		// ["callbackScore"].postln;
		// doRecord = false;

	});



	~scale=scale;
	OSCFunc({ arg msg, time, addr, recvPort;
		// [msg, time, addr, recvPort].postln;
		var hand=msg[1].asString;
		var gesture=msg[2].asString;
		var x=msg[3].asFloat;
		var y=msg[4].asFloat;
		var data=x.linlin(0.54,1,0,10);
		var note;
		if (hand.asString=="right",{
			// right hand controls pitches
			// left hand steps in triads
			handNote = y.linlin(0.0,1,-7,7).round;
			note = scale[handNote+(handOctave*3)];
			if (x>0.9,{
				note = note + 12;
			});
			if (x<0.7,{
				note = note - 12;
			});
			if (note.notNil,{
				if (gesture.asString=="closed",{
				},{
					note.postln;
					~crowSet.(1,(note-36)/12);
				});
			});
		});
		if (hand.asString=="left",{
			handOctave = y.linlin(0.0,1,0,12).round;
			// if (loopNum>loopNumMax,{
			// 	~crowSet.(1,(handNote-48+(handOctave*5))/12);
			// });

			// crow 2 ->  FM 1. FM1 knob fully CW
			~crowSet.(2,x.linlin(0,0.5,0,10));
			// crow 3 -> GAIN. GAIN knob at 8pm
			~crowSet.(3,x.linlin(0,1,0,4));
		});
	}, '/conductor');



	ServerMeter.new(s,2, 2);

	p.putAll("output[2].slew=0.1;\n");
	p.putAll("output[3].slew=0.1;\n");
	p.putAll("output[4].slew=0.1;\n");
	m.start();



	Routine {
		1.wait;
		o.set("main","reverb",0.4);
	}.play;
});
)
o.set("main","reverb",0.6);

a=[1,2,5,12]
a[a.indexIn(1.1)]

~scale.postln
// 0.5.linlin(0,1,0,10)
//
// s.show
//
// o.set("main","reverb",0.5);
// o.set("main","reverb",0);
// o.set("main","db",64.neg);
// o.set("metronome","t_trig",1)
//
// o.set("loop1","gate",0);
// o.set("loop2","gate",0);
// o.set("loop3","gate",0);
// o.set("loop4","gate",0);
// o.set("loop5","gate",0);
//
// ~crowSet.(1,(74-36)/12);

