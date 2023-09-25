
(
s.waitForBoot({
	var bpm = 90;
	var recCount = 0;
	var doRecord = true;
	var loopNum = 0;
	var loopNumMax = 8;
	var scale=Array.new;
	var cscale=Scale.major.degrees;
	2.do({ arg octave;
		cscale.do({arg v;
			scale=scale.add(36+v+(octave*12));
		});
	});

	// crow stuff
	// p = SerialPort.new(
	// 	"/dev/ttyACM0",
	// 	baudrate: 115200
	// );
	~crowSet = {
		arg port, volts;
		// p.putAll("output["++port++"].volts="++volts++";\n");
	};


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


	o=Ouroboros2.new(Server.default);

	m=Miti.new(Server.default,bpm,"
a3 f3 c3 e3
c7 a6 c7 b6
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

");
	// g3 g b f
	// c5 b b a
	// e4 e d d
	// -
	// c2 d e e g e d d
	// -
	// g6 g b  a
	// c6 b d  d
	// e7 d e g6 d d6 e
	//
	// ");
	m.setCallbackNote({ arg note;
		["note",note].postln;
		if (loopNum<loopNumMax,{
			~crowSet.(1,(note-36)/12);
		});
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		o.set("metronome","t_trig",1);
		loopNum = loopNum + 1;
		if (loopNum<loopNumMax,{
			o.record("loop"++loopNum.mod(8),16.0 * 60 / bpm);
			if (loopNum==1,{
				o.recordCV(1,16.0 * 60 / bpm);
			});
		});
	});
	m.setCallbackScore({
		// ["callbackScore"].postln;
		// doRecord = false;

	});



	OSCFunc({ arg msg, time, addr, recvPort;
		// [msg, time, addr, recvPort].postln;
		var hand=msg[1].asString;
		var gesture=msg[2].asString;
		var x=msg[3].asFloat;
		var y=msg[4].asFloat;
		var data=x.linlin(0.55,1,0,10);
		if (hand.asString=="right",{
			var note = scale[y.linlin(0.0,1,0,scale.size).round];
			var octave = 0;
			if (gesture.asString=="closed",{
				o.setCV(1,data);
				^0
			});
			if (gesture.asString=="one",{
				octave = 1;
			});
			if (gesture.asString=="two",{
				octave = 2;
			});
			if (gesture.asString=="three",{
				octave = 3;
			});
			if (gesture.asString=="four",{
				octave = 4;
			});
			if (note.notNil,{
				if (loopNum>loopNumMax,{
					if (octave>0,{
						~crowSet.(1,(note-36+(octave*12))/12);
					});
				});
			});
			~crowSet.(3,data);
		});
		if (hand.asString=="left",{
			~crowSet.(2,x.linlin(0,0.45,10,0));
			o.set("main","reverb",y);
			// ~crowSet.(4,y.linlin(0,1,0,10));
		});
	}, '/conductor');



	ServerMeter.new(s, 2, 2);

	o.set("main","reverb",0.6);

	// p.putAll("output[2].slew=0.1;\n");
	// p.putAll("output[3].slew=0.1;\n");
	// p.putAll("output[4].slew=0.1;\n");
	m.start();



});
)

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

