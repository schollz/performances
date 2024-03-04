
(
t = Server.default.options;
t.numInputBusChannels = 2;
s.waitForBoot({
	var bpm = 90;
	var recCount = 0;
	var doRecord = true;
	var loopNum = 0;
	var loopNumMax = 80;
	var loopRecordMax = 8;
	var scale=Array.new;
	var cscale=Scale.major.degrees;
	var handOctave = 0;
	var handNote = 0;
	var noteLast = 0;

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
	p.putAll("output[4].action='{  to(10,"++(60/bpm/8)++",logarithmic), to(0.25,"++(60/bpm/4)++",exponential) }';\n");


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

	// melody.py
	m=Miti.new(Server.default,bpm,"
c6 e6 c6 g6 c6 e6 g6 e6 g6 c6 e6 c6 g6 c6 g6 c6 e6 g6 d6 b6 g6 b6 d6 b6 g6 b6 d6 g6 b6 d6 b6 g6 b6 g6 d6 g6 c6 a6 e6 a6 e6 a6 c6 a6 c6 e6 c6 a6 e6 c6 a6 c6 a6 e6 c6 a6 c6 a6 c6 e6 c6 e6 c6 a6 e6 a6 e6 c6 a6 e6 a6 e6 c6 e6 a6 e6 a6 e6 c6 e6 c6 e6 c6 a6 e6 a6 c6 a6 e6 a6 e6 c6 a6 c6 a6 e6 d6 a6 f6 a6 f6 d6 f6 a6 d6 f6 d6 f6 d6 a6 d6 a6 d6 f6 d6 a6 d6 f6 d6 a6 d6 f6 a6 d6 f6 d6 f6 d6 a6 f6 d6 a6 f6 a6 c6 f6 c6 f6 c6 a6 f6 a6 c6 f6 c6 f6 c6 a6 c6 a6 f6 c6 f6 a6 c6 f6 c6 a6 f6 c6 a6 c6 a6 c6 a6 c6 a6 f6
    c4 c4 c4 b4 b4 b4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 d4 d4 d4 d4 d4 d4 f4 f4 f4 f4 f4 f4
	e6 e6 e6 g6 g6 g6 c6 c6 c6 c5 c6 c6 c6 c6 c6 c6 f5 f5 f5 f5 f5 f5 a5 a5 a5 a5 a5 a5
	g6 g6 g6 d7 d7 d7 e7 e7 e7 e5 e7 e7 e7 e7 e7 e7 a6 a6 a6 a6 a6 a6 c7 c7 c7 c7 c7 c7
	c3 c3 c3 g3 g3 g3 a3 a3 a3 a3 a3 a3 a3 c4 c4 c4 d4 d4 d4 e4 e4 e4 f3 f3 f3 f3 f3 f3
	e4 e4 e4 d6 d6 d6 c6 c6 c6 c6 c6 c6 c6 c6 c6 c6 f5 f5 f5 f5 f5 f5 f6 f6 f6 f6 f6 f6
	g6 g6 g6 b4 b4 b4 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a6 a6 a6 a6 a6 a6
    e7
    g7 g7 g7 g7 g7 g7 g7 g7 f7 f7 f7 f7 f7 f7 f7 f7 g7 g7 g7 g7 a7 a7 b7 b7
    c8
c8 e7 g8 c8 e8 g8 e8 g8 e8 c7 g6 e8 c8 g7 c8 c7 g8 e8 b8 d8 g8 b8 g7 b7 g8 b8 d8 g8 b8 g8 b8 d8 g8 d8 b8 b7 a8 c7 e8 a8 e8 a7 c8 c6 e7 c8 c7 a8 c8 e7 a8 c8 a8 c8 e8 c6 c8 e8 c8 e8 c8 e8 c8 e8 e7 a8 a6 a7 e6 c8 e8 e6 e8 c8 e8 a8 c8 e6 c7 c8 e8 a8 c8 e8 c6 a8 c8 a8 e7 a8 c6 c8 a8 c7 c8 e8 a8 f6 d8 f8 d7 a8 a6 f8 a8 f8 d7 f7 d8 f6 a8 f8 d8 a8 f7 a8 d8 a7 a6 a8 d8 a8 f8 a8 d8 f8 f6 f7 d8 a8 f8 a8 f8 a8 f8 a8 f8 a8 f8 c8 a8 c7 f8 c8 f8 f7 c6 f8 a8 c8 f6 f8 c8 f8 a8 c8 f8 c6 a8 f8 a8 c8 a6 f8 a8 f6 c8 a8
c8 e7 g8 c8 e8 g8 e8 g8 e8 c7 g6 e8 c8 g7 c8 c7 g8 e8 b8 d8 g8 b8 g7 b7 g8 b8 d8 g8 b8 g8 b8 d8 g8 d8 b8 b7 a8 c7 e8 a8 e8 a7 c8 c6 e7 c8 c7 a8 c8 e7 a8 c8 a8 c8 e8 c6 c8 e8 c8 e8 c8 e8 c8 e8 e7 a8 a6 a7 e6 c8 e8 e6 e8 c8 e8 a8 c8 e6 c7 c8 e8 a8 c8 e8 c6 a8 c8 a8 e7 a8 c6 c8 a8 c7 c8 e8 a8 f6 d8 f8 d7 a8 a6 f8 a8 f8 d7 f7 d8 f6 a8 f8 d8 a8 f7 a8 d8 a7 a6 a8 d8 a8 f8 a8 d8 f8 f6 f7 d8 a8 f8 a8 f8 a8 f8 a8 f8 a8 f8 c8 a8 c7 f8 c8 f8 f7 c6 f8 a8 c8 f6 f8 c8 f8 a8 c8 f8 c6 a8 f8 a8 c8 a6 f8 a8 f6 c8 a8
c6 g6 c6 g6 c6 e6 c6 e6 g6 c6 e6 g6 e6 g6 c6 g6 c6 e6 c6 g6 e6 g6 c6 e6 c6 g6 e6 g6 c6 g6 c6 g6 c6 g6 c6 e6 g6 d6 b6 g6 b6 g6 d6 g6 b6 g6 b6 g6 b6 d6 b6 g6 d6 g6 b6 g6 b6 g6 b6 d6 b6 g6 d6 b6 g6 b6 g6 b6 g6 d6 b6 g6 e6 c6 e6 a6 e6 a6 e6 c6 e6 a6 e6 a6 e6 c6 e6 a6 e6 c6 e6 c6 a6 e6 a6 c6 a6 c6 e6 c6 a6 c6 a6 e6 a6 c6 e6 a6 e6 a6 e6 c6 e6 a6 c6 e6 a6 c6 a6 e6 c6 a6 e6 c6 a6 c6 a6 e6 c6 a6 c6 e6 c6 e6 a6 e6 a6 e6 c6 e6 a6 c6 e6 c6 e6 c6 a6 e6 a6 c6 a6 e6 c6 a6 e6 c6 a6 c6 a6 c6 e6 a6 e6 c6 e6 a6 c6 a6 e6 c6 a6 e6 c6 e6 a6 e6 c6 a6 e6 a6 e6 c6 a6 c6 a6 c6 a6 c6 e6 c6 a6 c6 f6 d6 f6 a6 f6 a6 d6 f6 a6 f6 a6 d6 f6 d6 f6 a6 d6 f6 a6 d6 f6 a6 f6 d6 f6 a6 d6 a6 f6 d6 f6 d6 f6 a6 d6 a6 d6 a6 f6 d6 f6 a6 f6 d6 f6 d6 f6 d6 f6 a6 f6 a6 f6 d6 f6 d6 f6 d6 f6 a6 d6 a6 d6 a6 d6 f6 a6 d6 f6 a6 f6 d6 a6 c6 a6 c6 f6 a6 c6 f6 c6 a6 f6 c6 f6 c6 a6 f6 c6 a6 c6 a6 f6 a6 c6 a6 c6 f6 a6 f6 c6 f6 c6 f6 c6 f6 a6 f6 a6 f6 c6 a6 f6 a6 f6 a6 f6 a6 f6 c6 a6 f6 a6 c6 a6 f6 a6 f6 c6 f6 c6 f6 a6 f6 c6 a6 f6 c6 f6 c6 f6 a6 c6 a6
c6 g6 c6 g6 c6 e6 c6 e6 g6 c6 e6 g6 e6 g6 c6 g6 c6 e6 c6 g6 e6 g6 c6 e6 c6 g6 e6 g6 c6 g6 c6 g6 c6 g6 c6 e6 g6 d6 b6 g6 b6 g6 d6 g6 b6 g6 b6 g6 b6 d6 b6 g6 d6 g6 b6 g6 b6 g6 b6 d6 b6 g6 d6 b6 g6 b6 g6 b6 g6 d6 b6 g6 e6 c6 e6 a6 e6 a6 e6 c6 e6 a6 e6 a6 e6 c6 e6 a6 e6 c6 e6 c6 a6 e6 a6 c6 a6 c6 e6 c6 a6 c6 a6 e6 a6 c6 e6 a6 e6 a6 e6 c6 e6 a6 c6 e6 a6 c6 a6 e6 c6 a6 e6 c6 a6 c6 a6 e6 c6 a6 c6 e6 c6 e6 a6 e6 a6 e6 c6 e6 a6 c6 e6 c6 e6 c6 a6 e6 a6 c6 a6 e6 c6 a6 e6 c6 a6 c6 a6 c6 e6 a6 e6 c6 e6 a6 c6 a6 e6 c6 a6 e6 c6 e6 a6 e6 c6 a6 e6 a6 e6 c6 a6 c6 a6 c6 a6 c6 e6 c6 a6 c6 f6 d6 f6 a6 f6 a6 d6 f6 a6 f6 a6 d6 f6 d6 f6 a6 d6 f6 a6 d6 f6 a6 f6 d6 f6 a6 d6 a6 f6 d6 f6 d6 f6 a6 d6 a6 d6 a6 f6 d6 f6 a6 f6 d6 f6 d6 f6 d6 f6 a6 f6 a6 f6 d6 f6 d6 f6 d6 f6 a6 d6 a6 d6 a6 d6 f6 a6 d6 f6 a6 f6 d6 a6 c6 a6 c6 f6 a6 c6 f6 c6 a6 f6 c6 f6 c6 a6 f6 c6 a6 c6 a6 f6 a6 c6 a6 c6 f6 a6 f6 c6 f6 c6 f6 c6 f6 a6 f6 a6 f6 c6 a6 f6 a6 f6 a6 f6 a6 f6 c6 a6 f6 a6 c6 a6 f6 a6 f6 c6 f6 c6 f6 a6 f6 c6 a6 f6 c6 f6 c6 f6 a6 c6 a6
e5 g5 e5 c5 g5 e5 g5 c5 g5 b5 d5 b5 d5 g5 b5 d5 b5 d5 e5 c5 a5 c5 e5 a5 e5 c5 a5 c5 a5 e5 c5 e5 a5 e5 c5 a5 e5 a5 c5 e5 a5 c5 e5 c5 a5 c5 a5 c5 d5 a5 d5 f5 d5 a5 f5 d5 f5 d5 a5 f5 a5 d5 f5 a5 d5 f5 c5 a5 c5 a5 c5 f5 c5 a5 f5 c5 f5 c5 f5 c5 f5 a5 f5 c5
e5 g5 e5 c5 g5 e5 g5 c5 g5 b5 d5 b5 d5 g5 b5 d5 b5 d5 e5 c5 a5 c5 e5 a5 e5 c5 a5 c5 a5 e5 c5 e5 a5 e5 c5 a5 e5 a5 c5 e5 a5 c5 e5 c5 a5 c5 a5 c5 d5 a5 d5 f5 d5 a5 f5 d5 f5 d5 a5 f5 a5 d5 f5 a5 d5 f5 c5 a5 c5 a5 c5 f5 c5 a5 f5 c5 f5 c5 f5 c5 f5 a5 f5 c5
g6 e6 g6 c6 g6 c6 g6 b6 g6 d6 g6 d6 a6 c6 a6 e6 a6 e6 a6 e6 c6 e6 c6 a6 e6 a6 e6 a6 c6 e6 a6 e6 a6 d6 f6 a6 f6 d6 a6 d6 f6 d6 a6 f6 c6 f6 c6 f6 c6 f6 c6 f6 a6 f6 a6 c6
g6 e6 g6 c6 g6 c6 g6 b6 g6 d6 g6 d6 a6 c6 a6 e6 a6 e6 a6 e6 c6 e6 c6 a6 e6 a6 e6 a6 c6 e6 a6 e6 a6 d6 f6 a6 f6 d6 a6 d6 f6 d6 a6 f6 c6 f6 c6 f6 c6 f6 c6 f6 a6 f6 a6 c6
c7 e7 c7 e7 c7 e7 g7 c7 e7 c6 e6 g6 e7 g7 e7 g7 c7 g7 b7 d7 b7 g7 d6 g7 d6 b7 d7 g7 d7 b7 g7 d7 b6 g7 b7 g7 c7 a6 c7 a7 e7 e6 a7 c7 a7 c7 a7 e7 a7 e6 e7 a7 e7 c7 a7 e7 c7 e7 e6 a7 e7 a7 e7 c6 a7 c7 a7 c7 e7 c7 e6 e7 c7 e7 c7 e7 a7 e7 a7 e6 c7 a7 c7 a7 c7 a7 e7 a7 e7 a7 e7 a7 e7 a7 c7 e6 d7 a7 d7 a7 f7 d7 f7 d7 a6 f7 d7 f6 d7 a7 f7 d7 a7 f7 a7 f7 a7 f7 d7 a7 d7 f7 a6 d7 a7 f7 a7 d7 f6 f7 a6 f7 c7 a7 f7 c7 f7 c7 a7 f7 a7 f7 a6 f7 c6 f7 c7 a7 c7 a7 c7 a6 f7 a7 f7 a7 c7 f7 c6 a6 f7 a7 c7 c6 a6 f7 c7 a7
c7 e7 c7 e7 c7 e7 g7 c7 e7 c6 e6 g6 e7 g7 e7 g7 c7 g7 b7 d7 b7 g7 d6 g7 d6 b7 d7 g7 d7 b7 g7 d7 b6 g7 b7 g7 c7 a6 c7 a7 e7 e6 a7 c7 a7 c7 a7 e7 a7 e6 e7 a7 e7 c7 a7 e7 c7 e7 e6 a7 e7 a7 e7 c6 a7 c7 a7 c7 e7 c7 e6 e7 c7 e7 c7 e7 a7 e7 a7 e6 c7 a7 c7 a7 c7 a7 e7 a7 e7 a7 e7 a7 e7 a7 c7 e6 d7 a7 d7 a7 f7 d7 f7 d7 a6 f7 d7 f6 d7 a7 f7 d7 a7 f7 a7 f7 a7 f7 d7 a7 d7 f7 a6 d7 a7 f7 a7 d7 f6 f7 a6 f7 c7 a7 f7 c7 f7 c7 a7 f7 a7 f7 a6 f7 c6 f7 c7 a7 c7 a7 c7 a6 f7 a7 f7 a7 c7 f7 c6 a6 f7 a7 c7 c6 a6 f7 c7 a7
c7 e7 c7 e7 c7 e7 g7 c7 e7 c6 e6 g6 e7 g7 e7 g7 c7 g7 b7 d7 b7 g7 d6 g7 d6 b7 d7 g7 d7 b7 g7 d7 b6 g7 b7 g7 c7 a6 c7 a7 e7 e6 a7 c7 a7 c7 a7 e7 a7 e6 e7 a7 e7 c7 a7 e7 c7 e7 e6 a7 e7 a7 e7 c6 a7 c7 a7 c7 e7 c7 e6 e7 c7 e7 c7 e7 a7 e7 a7 e6 c7 a7 c7 a7 c7 a7 e7 a7 e7 a7 e7 a7 e7 a7 c7 e6 d7 a7 d7 a7 f7 d7 f7 d7 a6 f7 d7 f6 d7 a7 f7 d7 a7 f7 a7 f7 a7 f7 d7 a7 d7 f7 a6 d7 a7 f7 a7 d7 f6 f7 a6 f7 c7 a7 f7 c7 f7 c7 a7 f7 a7 f7 a6 f7 c6 f7 c7 a7 c7 a7 c7 a6 f7 a7 f7 a7 c7 f7 c6 a6 f7 a7 c7 c6 a6 f7 c7 a7
c7 e7 c7 e7 c7 e7 g7 c7 e7 c6 e6 g6 e7 g7 e7 g7 c7 g7 b7 d7 b7 g7 d6 g7 d6 b7 d7 g7 d7 b7 g7 d7 b6 g7 b7 g7 c7 a6 c7 a7 e7 e6 a7 c7 a7 c7 a7 e7 a7 e6 e7 a7 e7 c7 a7 e7 c7 e7 e6 a7 e7 a7 e7 c6 a7 c7 a7 c7 e7 c7 e6 e7 c7 e7 c7 e7 a7 e7 a7 e6 c7 a7 c7 a7 c7 a7 e7 a7 e7 a7 e7 a7 e7 a7 c7 e6 d7 a7 d7 a7 f7 d7 f7 d7 a6 f7 d7 f6 d7 a7 f7 d7 a7 f7 a7 f7 a7 f7 d7 a7 d7 f7 a6 d7 a7 f7 a7 d7 f6 f7 a6 f7 c7 a7 f7 c7 f7 c7 a7 f7 a7 f7 a6 f7 c6 f7 c7 a7 c7 a7 c7 a6 f7 a7 f7 a7 c7 f7 c6 a6 f7 a7 c7 c6 a6 f7 c7 a7
");


	p.putAll("output[3].action='pulse();'\n");
	m.setCallbackClock({ arg clockIndex;
		p.putAll("output[3]();\n");
	});
	m.setCallbackNote({ arg note;
		["note",note].postln;
		if (noteLast!=note,{
			"output4".postln;
			p.putAll("output[4]();\n");
			noteLast = note;
		});
		if (loopNum<loopNumMax,{
			~crowSet.(1,(note-36)/12);
		});
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		o.set("metronome","t_trig",1);
		loopNum = loopNum + 1;

		if (loopNum<loopRecordMax,{
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



	//ServerMeter.new(s,2, 2);

	p.putAll("output[4].slew=0.1;\n");
	m.start();

	Routine {
		if (u.notNil,{
			u.free;
		});
		u=	OSCFunc({ arg msg, time, addr, recvPort;
			var index=msg[1].asInteger;
			var value=msg[2].asFloat;
			[index,value].postln;
			switch(index)
			{ 0 } { o.set("main","reverb",value/100); }
			{ 1 } {
				if (value<10,{
					o.set("main","dbNoVerb",-96);
				},{
					o.set("main","dbNoVerb",value.linlin(10,100,0,24));
				});
			}
			{ o.set("loop"++(index-1),"db",value.linlin(0,100,-36,0)); }
			{ };
			// o.set("main","reverb",0.5);
			// o.set("input","db",0.neg);

		}, '/slider',);
		0.1.wait;
		o.set("main","reverb",0.2);
		o.set("main","dbNoVerb",-96);
	}.play;
});
)