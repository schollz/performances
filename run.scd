
(
s.waitForBoot({
	var bpm = 90;
	var recCount = 0;
	var doRecord = true;
	var loopNum = 1;
	var crowSet = {
		arg port, volts;
		p.putAll("output["++port++"].volts="++volts++";\n");
	};
	s.record;
	// crow stuff

	p = SerialPort.new(
		"/dev/ttyACM2",
		baudrate: 115200
	);

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
		crowSet.(port,env);
	}, '/env');


	o=Ouroboros2.new(Server.default);

	m=Miti.new(Server.default,bpm,"
e5 f g e
c5 a4 c5 b4
a6 c7 e6 g6
a3 f3 c3 e3
a5 f5 g e5
c6 a5 c6 b5
e7 c7 e6 g6
c7 c a6 g c7 c c b6
c7 a6 c7 b6
c7 a6 c7 b6
a6 c e c a7 c e c a6 c e c a7 c b c f a c a5 f a c a6 f a c a f a c a c e7 g e c e g e c e6 g e c e g e5 b g e g b g e g b g e g b g e g
a6 c e c a7 c d c a6 c e c a7 c e8 c f a c a5 f a c a6 f a c a f a c a c e7 g e c e g e c e6 g e c e g e5 b g e g b g e g b g5 e g b g e g
a6 c e c a7 c e c a6 c e c a7 d e c e a c a5 f a c a6 f a c a f a c a7 c e7 g e c e g e c e6 g e c e g e5 b g e g b g4 e g b g e g b g e g
a6 c e4 c a7 c e c a6 c e c a7 c e3 c f a c a5 f a c a6 f a c a f a c a c e7 g e c e g e c e6 g e c6 e g e5 b g e g b g e g b g e7 g b g e g
a6 c e c a7 c e c a6 b e c a7 c e c f a c a5 f a c a6 f a c a f a c a c e7 g e c e g e c e6 g e c e g e5 b g e g b6 g e g b g e g b g e g
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
		crowSet.(1,(note-36)/12);
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		if (loopNum<7,{
			o.record("loop"++loopNum,16.0 * 60 / bpm);
			loopNum = loopNum + 1;
		});
		o.set("metronome","t_trig",1)
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
		if (hand.asString=="right",{
			crowSet.(3,x.linlin(0.55,1,0,10));
			crowSet.(4,y.linlin(0.0,1,0,10));

		});
		if (hand.asString=="left",{
			crowSet.(2,x.linlin(0,0.45,10,0));
			o.set("main","reverb",y);
			// crowSet.(4,y.linlin(0,1,0,10));
		});
	}, '/conductor');



	ServerMeter.new(s, 2, 2);

	o.set("main","reverb",0.6);

	p.putAll("output[2].slew=0.1;\n");
	p.putAll("output[3].slew=0.1;\n");
	p.putAll("output[4].slew=0.1;\n");
	m.start();



});
)

0.5.linlin(0,1,0,10)

s.show

o.set("main","reverb",0.5);
o.set("main","db",64.neg);
o.set("metronome","t_trig",1)

// m.setPhrase(3)
// m.stop()

// o.bufs.at("loop1").plot;
