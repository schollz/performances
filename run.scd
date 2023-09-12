
(
s.waitForBoot({
	var bpm = 90;
	var doRecord = true;
	var loopNum = 1;
	var crowSet = {
		arg port, volts;
		p.putAll("output["++port++"].volts="++volts++";\n");
	};
	// crow stuff

	p = SerialPort.new(
		"/dev/ttyACM1",
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
g3 g b f
c5 b b a
e4 e d d
-
c2 d e e g e d d
-
g6 g b  a
c6 b d  d
e7 d e g6 d d6 e

");
	m.setCallbackNote({ arg note;
		["note",note].postln;
		crowSet.(1,(note-36)/12);
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		if (doRecord,{
			o.record("loop"++loopNum,16.0 * 60 / bpm);
			loopNum = loopNum + 1;
		});
		o.set("metronome","t_trig",1)
	});
	m.setCallbackScore({
		["callbackScore"].postln;
		doRecord = false;

	});
	m.start();



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

o.set("main","reverb",0.9);
o.set("main","db",64.neg);
o.set("metronome","t_trig",1)

// m.setPhrase(3)
// m.stop()

// o.bufs.at("loop1").plot;
