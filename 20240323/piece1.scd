
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
	p.putAll("output[4].action='{  to(10,"++(60/bpm/8)++",logarithmic), to(0.25,"++(60/bpm)++",exponential) }';\n");


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



	// melody3.py
	// Am G F Em7
	m=Miti.new(Server.default,bpm,"
e5    d5    f5    e5
c5    g4    a4    b4
a3 a3 g3 e3 f3 f3 e3 g3
a6 a6 b6 d7 c7 c7 b6 b6
c4    b3    c4    g4
e7 e7 d7 g7 f7 f7 g7 g7
a7    b7    c7    d7
c6 a5 e4 c5 e4 a6 e6 g4 g5 b4 g6 b4 b6 g4 d6 d5 e5 a6 c6 e4 a6 f6 f6 a6 g6 e4 b6 g6 g6 g4 e6 g4
c6 a5 e4 c5 e4 a6 e6 g4 g5 b4 g6 b4 b6 g4 d6 d5 e5 a6 c6 e4 a6 f6 f6 a6 g6 e4 b6 g6 g6 g4 e6 g4
e6 e6 c6 g6 c6 a6 c6 a6 g4 g4 b6 d6 b4 d6 d6 g4 c5 f6 e6 e6 e6 f5 c4 a6 b6 g6 g6 g6 g5 e5 b4 b6
e6 e6 c6 g6 c6 a6 c6 a6 g4 g4 b6 d6 b4 d6 d6 g4 c5 f6 e6 e6 e6 f5 c4 a6 b6 g6 g6 g6 g5 e5 b4 b6
c7 c4 e5 a6 a4 e6 e5 a7 c6 a7 e5 a6 g6 a5 a4 g5 b4 b7 g6 b6 g7 g7 g4 b7 d7 g5 d7 b5 d6 b6 d4 g6 a5 c7 c6 f5 c4 c6 a6 a7 e7 a4 c4 a5 c6 a7 c4 a6 g4 g6 g6 b6 e6 b6 g7 g6 b7 g6 g6 b7 e4 e6 g6 e7
c7 c4 e5 a6 a4 e6 e5 a7 c6 a7 e5 a6 g6 a5 a4 g5 b4 b7 g6 b6 g7 g7 g4 b7 d7 g5 d7 b5 d6 b6 d4 g6 a5 c7 c6 f5 c4 c6 a6 a7 e7 a4 c4 a5 c6 a7 c4 a6 g4 g6 g6 b6 e6 b6 g7 g6 b7 g6 g6 b7 e4 e6 g6 e7
c6 e5 a4 c6 e6 a4 g4 e4 e6 g6 a4 c4 e6 e6 g6 e6 a6 a4 e4 e4 e4 c4 a6 c4 e5 e4 g6 a6 a4 e6 e6 c5 d4 g4 b6 d6 d4 d6 g5 b5 b4 g6 b5 g6 g4 b6 d6 d6 b6 g6 b5 g5 d4 g4 g6 d4 g6 g6 b6 b6 g4 d6 d6 g6 c5 f4 c4 a6 c6 c6 a4 a5 e6 a4 c6 c6 c4 e5 f4 c4 f6 c6 c6 a4 c5 f6 a5 c4 f4 c4 a4 f4 c4 c5 f6 a5 g4 b6 b5 g4 b4 b4 g6 b4 b4 g6 g6 b4 e4 g4 b6 g6 b4 e4 g4 e6 g6 b5 b4 e5 g6 g5 b5 e4 e6 g6 e4 b6
c6 e5 a4 c6 e6 a4 g4 e4 e6 g6 a4 c4 e6 e6 g6 e6 a6 a4 e4 e4 e4 c4 a6 c4 e5 e4 g6 a6 a4 e6 e6 c5 d4 g4 b6 d6 d4 d6 g5 b5 b4 g6 b5 g6 g4 b6 d6 d6 b6 g6 b5 g5 d4 g4 g6 d4 g6 g6 b6 b6 g4 d6 d6 g6 c5 f4 c4 a6 c6 c6 a4 a5 e6 a4 c6 c6 c4 e5 f4 c4 f6 c6 c6 a4 c5 f6 a5 c4 f4 c4 a4 f4 c4 c5 f6 a5 g4 b6 b5 g4 b4 b4 g6 b4 b4 g6 g6 b4 e4 g4 b6 g6 b4 e4 g4 e6 g6 b5 b4 e5 g6 g5 b5 e4 e6 g6 e4 b6
e5 e5 d5 c5 f5 g5 e5 e5
d5 c5 g4    a4    b4
a6 a6 b6 d7 c7 c7 b6 b6
c6 a4 e6 c4 a6 c6 g6 e4 e6 e4 a4 e6 a6 e5 e6 e4 c6 e4 c4 e4 e6 c4 a6 e6 a6 a4 c6 a6 a6 a6 e4 a6 b6 g5 b4 b5 g4 b5 d4 g6 b4 b4 g6 g4 b5 b5 b6 d6 g6 b4 g4 d4 g6 d4 b5 b6 b6 g4 d4 b6 d4 d5 d6 b5 f6 f6 c5 a6 e6 c6 a4 c6 f5 c6 f6 f6 c6 c5 c6 f5 f5 e5 a4 c6 c5 a4 f6 c6 f4 e6 a6 a6 f6 e6 c4 e5 b6 g4 e4 b6 b6 b6 b5 b6 g6 e6 b6 e6 b5 g6 e4 b6 e6 b5 e4 b6 g6 b6 e5 e6 e6 e6 g6 e4 e6 e6 b4 b5
c6 a4 e6 c4 a6 c6 g6 e4 e6 e4 a4 e6 a6 e5 e6 e4 c6 e4 c4 e4 e6 c4 a6 e6 a6 a4 c6 a6 a6 a6 e4 a6 b6 g5 b4 b5 g4 b5 d4 g6 b4 b4 g6 g4 b5 b5 b6 d6 g6 b4 g4 d4 g6 d4 b5 b6 b6 g4 d4 b6 d4 d5 d6 b5 f6 f6 c5 a6 e6 c6 a4 c6 f5 c6 f6 f6 c6 c5 c6 f5 f5 e5 a4 c6 c5 a4 f6 c6 f4 e6 a6 a6 f6 e6 c4 e5 b6 g4 e4 b6 b6 b6 b5 b6 g6 e6 b6 e6 b5 g6 e4 b6 e6 b5 e4 b6 g6 b6 e5 e6 e6 e6 g6 e4 e6 e6 b4 b5
c5 a5 e5 a5 c5 e5 a5 c5 a5 g5 e5 g5 a5 c5 g5 c5 a5 c5 e5 a5 g5 e5 c5 e5 c5 a5 g5 a5 e5 a5 c5 a5 g5 c5 g5 a5 g5 c5 a5 c5 g5 c5 e5 c5 a5 g5 c5 e5 a5 e5 c5 g5 e5 a5 e5 c5 e5 a5 g5 c5 g5 a5 e5 g5 d5 b5 g5 b5 g5 b5 d5 g5 d5 b5 g5 d5 g5 d5 g5 b5 d5 b5 g5 b5 d5 g5 b5 g5 b5 d5 g5 d5 b5 d5 g5 d5 b5 d5 g5 d5 b5 d5 g5 d5 g5 b5 g5 b5 d5 b5 d5 b5 g5 d5 b5 d5 b5 d5 b5 g5 d5 b5 g5 b5 d5 g5 b5 d5 a5 f5 a5 f5 e5 a5 e5 c5 a5 f5 c5 a5 f5 a5 e5 c5 a5 c5 f5 a5 c5 f5 c5 a5 c5 e5 c5 a5 f5 e5 a5 c5 a5 f5 c5 f5 c5 f5 e5 a5 e5 a5 c5 a5 f5 c5 a5 f5 a5 f5 e5 a5 c5 f5 e5 a5 f5 c5 f5 c5 a5 c5 a5 f5 g5 e5 b5 g5 b5 g5 e5 g5 e5 b5 g5 b5 g5 e5 g5 e5 g5 b5 g5 b5 e5 g5 b5 e5 b5 e5 g5 b5 g5 e5 g5 b5 e5 g5 e5 b5 g5 e5 b5 e5 b5 g5 e5 b5 e5 b5 g5 b5 g5 e5 g5 b5 e5 b5 e5 b5 e5 g5 e5 g5 b5 g5 b5 g5
c6 e6 g6 e6 a6 e6 c6 a6 c6 e6 g6 a6 g6 a6 e6 a6 e6 c6 e6 c6 e6 c6 a6 c6 a6 g6 a6 e6 g6 e6 a6 c6 e6 c6 g6 e6 c6 g6 c6 e6 a6 c6 e6 c6 e6 c6 e6 a6 e6 c6 e6 a6 c6 e6 c6 e6 c6 a6 e6 a6 e6 c6 e6 c6 d6 g6 b6 d6 g6 b6 g6 b6 g6 b6 d6 g6 b6 d6 g6 b6 g6 d6 g6 b6 d6 b6 g6 d6 b6 g6 b6 d6 b6 g6 d6 b6 g6 d6 b6 d6 b6 g6 d6 g6 d6 g6 d6 g6 b6 d6 b6 d6 g6 d6 g6 d6 b6 d6 b6 g6 b6 g6 d6 b6 d6 b6 d6 b6 a6 c6 a6 f6 c6 f6 a6 c6 a6 e6 f6 c6 e6 c6 a6 f6 e6 f6 e6 f6 a6 f6 a6 f6 a6 c6 a6 c6 f6 a6 c6 e6 f6 c6 e6 c6 f6 a6 f6 c6 e6 a6 c6 a6 f6 a6 c6 a6 c6 e6 a6 c6 f6 c6 e6 f6 c6 a6 c6 f6 a6 e6 f6 a6 e6 b6 e6 b6 g6 b6 e6 b6 e6 g6 b6 g6 e6 b6 g6 e6 b6 e6 b6 e6 g6 b6 g6 b6 e6 b6 e6 b6 e6 g6 e6 b6 g6 e6 b6 e6 g6 b6 g6 e6 b6 g6 b6 e6 g6 e6 b6 e6 g6 e6 g6 b6 e6 g6 b6 e6 g6 b6 g6 e6 g6 b6 e6 g6
e7 c7 a7 c7 e7 a7 c7 a7 e7 g7 e7 g7 a7 g7 a7 e7 c7 a7 g7 e7 a7 c7 a7 e7 g7 c7 e7 g7 e7 a7 e7 a7 e7 c7 e7 a7 c7 e7 c7 g7 e7 c7 a7 g7 c7 e7 c7 a7 c7 g7 c7 e7 g7 c7 a7 c7 e7 g7 c7 e7 c7 e7 c7 g7 d7 g7 b7 g7 b7 d7 g7 d7 g7 b7 d7 b7 d7 g7 d7 g7 b7 g7 b7 d7 b7 g7 d7 g7 d7 b7 d7 g7 d7 g7 d7 b7 d7 g7 d7 b7 g7 d7 b7 g7 d7 b7 d7 g7 b7 d7 g7 d7 g7 b7 g7 d7 g7 b7 g7 b7 g7 d7 g7 d7 b7 d7 b7 g7 a7 c7 f7 c7 e7 c7 e7 f7 e7 c7 f7 a7 f7 c7 a7 c7 a7 c7 f7 c7 f7 a7 c7 a7 c7 a7 f7 c7 a7 c7 f7 c7 a7 c7 a7 c7 a7 f7 a7 f7 c7 a7 e7 a7 e7 a7 f7 c7 e7 c7 a7 f7 e7 a7 f7 c7 f7 a7 f7 e7 c7 a7 e7 f7 b7 g7 e7 g7 b7 e7 g7 b7 g7 b7 e7 b7 e7 g7 e7 g7 b7 g7 b7 e7 b7 e7 b7 e7 g7 e7 b7 g7 b7 e7 b7 e7 b7 g7 b7 g7 e7 b7 e7 b7 g7 e7 b7 e7 g7 b7 g7 e7 g7 e7 g7 b7 g7 e7 g7 e7 g7 e7 g7 b7 e7 g7 e7 b7

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
					o.set("main","dbNoVerb",value.linlin(10,100,-12,24));
				});
			}
			{ o.set("loop"++(index-1),"db",value.linlin(0,100,-36,0)); }
			{ };
			// o.set("main","reverb",0.5);
			// o.set("input","db",0.neg);

		}, '/slider',recvPort:7771);
		0.1.wait;
		o.set("main","reverb",0.4);
		o.set("main","dbNoVerb",-2);
		1.wait;
		m.start();
	}.play;
});
)



