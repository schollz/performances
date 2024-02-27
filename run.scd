
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
		"/dev/ttyACM1",
		baudrate: 115200
	);
	~crowSet = {
		arg port, volts;
		p.putAll("output["++port++"].volts="++volts++";\n");
	};
	p.putAll("output[4].action='{  to(10,"++(60/bpm/8)++",logarithmic), to(0.25,"++(60/bpm/2)++",exponential) }';\n");


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

	m=Miti.new(Server.default,bpm,"
a2 f2 c2 g2
a3 a3 c4 b4
c4 c4 g4 g4
e5 f5 e5 d5
e6 e6 g6 b6
c7 c7 c7 d7
e7 d7 e7 b6
c6 c6 a5 a5 c6 c6 f6 f6 e6 e6 e6 e6 g6 g6 b6 b6
c6 c6 a5 a5 c6 c6 f6 f6 e6 e6 e6 e6 g6 g6 b6 b6
c7 c7 c7 d7
c6 c6 a5 a5 c6 c6 f6 f6 e6 e6 e6 e6 g6 g6 b6 b6
c6 e6 a5 b5 c6 a6 a6 f6 e6 g6 c6 g6 g5 b5 d5 b5
e6
a6 e4 a4 a5 c4 c5 e6 g6 c6 c6 a4 c6 f4 c6 a5 c6 c6 c6 g6 g6 c6 c6 g6 g5 b5 g6 d4 d5 d4 g6 b6 d6
c5 e6 c5 g5 c6 a6 a4 a6 a5 a6 f6 a4 e5 f6 a6 c6 e6 c4 g6 e4 c6 c6 g6 c6 g5 d5 d6 b5 d5 d4 b6 d6
e4 a6 a6 c6 c6 a6 c6 a5 f5 c5 f6 c6 e6 f6 a4 c6 g5 c4 c4 e6 c4 g5 g6 c5 g6 g6 g6 g6 b4 b4 g4 b5
c5 g6 e6 c6 c4 c4 e6 e6 c6 c4 a4 e6 e6 a6 f6 e6 e4 c6 g6 e5 g6 c6 g6 e6 b5 d5 b6 g6 g6 d6 b6 b6
a4 c6 g4 a6 g6 a6 e5 g6 e4 a6 a6 e6 e6 e6 a5 c5 f6 f4 f6 a4 f5 f5 f6 c6 a4 a5 a6 f6 f5 c6 c6 c6 g4 c5 e6 c6 g6 g6 g5 e6 c6 g6 e6 g6 c5 g6 c5 g5 g6 b6 b6 g6 g6 g4 d6 b4 d6 g6 d6 g5 g6 b4 d5 g6
c5 a6 a4 a6 e6 c5 a6 a6 a5 e6 a6 e5 c6 e6 c6 c5 a5 a6 c4 g6 a5 a5 c4 e6 e5 e4 c5 a6 g6 a5 a6 c5 f6 a6 a6 e4 f6 c6 c4 f6 f6 e5 e4 f5 a6 a6 a4 f6 c5 c6 c6 c6 f4 c5 f6 a6 a6 c6 f4 f4 a6 f4 a5 c4 c6 c6 g4 g5 c6 c6 c6 c5 e6 c6 c6 g5 g4 e6 g6 g6 g6 c6 g6 c6 g6 c6 e5 g6 e4 g5 g5 e6 g4 c6 e6 g4 d6 g6 g4 b4 g4 d6 b6 g6 d6 b4 g4 b6 d6 g5 g6 d6 d6 d6 b6 d4 b5 g4 b6 d5 g6 b6 d5 d5 d5 g6 d4 g6
e4 a6 a6 c6 c6 a6 c6 a5 f5 c5 f6 c6 e6 f6 a4 c6 g5 c4 c4 e6 c4 g5 g6 c5 g6 g6 g6 g6 b4 b4 g4 b5
c5 g6 e6 c6 c4 c4 e6 e6 c6 c4 a4 e6 e6 a6 f6 e6 e4 c6 g6 e5 g6 c6 g6 e6 b5 d5 b6 g6 g6 d6 b6 b6
");

	/*	m=Miti.new(Server.default,bpm,"
	d5  a5  a5  e5  g#5 f#5 f#5 f#6 c#6 f#6 f#6 g#6 a6  d7
	a3  f#3 f#3 f#3 c#3 a3  a3  d3  f#3 c#3 c#3 c#3 f#3 f#3
	f#6 c#7 c#7 a6  e6  d6  d6  a6  a6  a5  a5  e6  d6  a5
	a4  a4  a4  e4  g#4 a5  a5  d5  f#5 d5  c#5 c#5 f#5 f#5
	d7  f#7 f#7 a7  e7  d7  d7  d7  f#7 c#7 f#7 e7  d7  a7
	a7  a7  a7  e7  g#7 f#7 f#7 a7  a7  a7  a7  e7  a7  d7
	");*/
	/*	m=Miti.new(Server.default,bpm,"
	d5 e5  a4 a4  f4 f4  c5 c5
	b4 c5  d4 d4  a5 a5  e5 e5
	g6 a6  f6 f6  c6 c6  g5 g5
	");*/

	// melody.py
	m=Miti.new(Server.default,bpm,"
c4 c4 c4 b4 b4 b4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 d4 d4 d4 d4 d4 d4 f4 f4 f4 f4 f4 f4
e6 e6 e6 g6 g6 g6 c6 c6 c6 c5 c6 c6 c6 c6 c6 c6 f5 f5 f5 f5 f5 f5 a5 a5 a5 a5 a5 a5
g6 g6 g6 d7 d7 d7 e7 e7 e7 e5 e7 e7 e7 e7 e7 e7 a6 a6 a6 a6 a6 a6 c7 c7 c7 c7 c7 c7
c3 c3 c3 g3 g3 g3 a3 a3 a3 a3 a3 a3 a3 c4 c4 c4 d4 d4 d4 e4 e4 e4 f3 f3 f3 f3 f3 f3

e4 e4 e4 d6 d6 d6 c6 c6 c6 c6 c6 c6 c6 c6 c6 c6 f5 f5 f5 f5 f5 f5 f6 f6 f6 f6 f6 f6
g6 g6 g6 b4 b4 b4 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a5 a6 a6 a6 a6 a6 a6
c7 c7 c7 b5 b5 b5 a6 a6 a6 a6 a6 a6 a6 a6 a6 a6 d6 d6 d6 d6 d6 d6 f6 c6 c6 c6 c6 c6

e6 e5 c6 c6 c6 c6 b6 b6 g6 b5 d6 g6 e6 a6 e6 a5 c6 e6 a6 a4 c5 e5 a5 c5 e6 c6 a5 a6 a6 e5 a5 e4 d6 d6 a6 d6 a5 a5 f6 a6 d6 a5 a6 f5 c6 f6 c4 f4 c5 c6 a6 c4 f4 f6 a5 f4
g5 e5 g6 g6 c6 c6 d6 g5 b6 b6 d6 g4 c5 c5 a6 c5 a6 e5 e6 e6 a4 c6 c6 a6 e6 e6 a6 c5 c6 a6 e6 e6 f6 d4 d6 d6 a6 d4 d6 d6 a6 d6 f4 d5 c6 a6 c6 f4 c6 c6 a6 c6 a4 a5 c4 f6
g6 c4 e6 c6 g4 g6 b5 b6 d6 b6 d6 d6 c6 a6 a6 c6 c6 c4 c6 c6 c6 e5 c5 a6 c5 c6 c4 e4 e6 a6 a5 e6 a5 d4 d6 d6 f5 a6 d4 a6 d4 a4 f6 f6 c6 a5 a6 f6 f5 a6 c4 c6 f6 f6 c6 a6
g6 g5 c6 e6 c6 e4 g5 e6 g6 e6 g6 g6 d6 b6 g4 d4 d5 g4 g4 d5 d6 d6 b6 d6 e5 a6 e4 e5 e4 a6 e6 e6 a5 c4 c6 c6 a4 c4 a6 e6 e6 c6 e6 e4 c6 c5 a6 a6 c4 c5 c6 a6 a5 c4 a4 c5 a6 a6 c5 c6 a6 c6 c6 c5 f6 d6 d6 a6 d5 f6 d4 a5 f6 d6 d6 a4 a6 a6 d6 a6 f6 d6 d6 d5 a5 d5 d6 a6 c5 a6 c4 a6 a4 c4 c6 f6 f6 f6 c6 c6 c6 a6 a4 c5 c6 a6 c6 a4 c6 c6 c5 f6
");

/*	// melody2.py
	m=Miti.new(Server.default,bpm,"
b6 b6 b6 e5 e5 e5 e5 e5 c6 c6 c6 c6 b5 b5 b5 b5 e5 e5 e5 e5 e5 e5 e5 e5 c5 c5 c5 c5 d5 d5 d5 d5
e5 e5 e5 a6 a6 a6 a6 a6 a6 a6 a6 a6 d6 d6 d6 d6 g6 g6 g6 g6 g6 g6 g6 g6 a6 a6 a6 a6 b6 b6 b6 b6
d7 d7 d7 c7 c7 c7 c7 c7 f7 f7 f7 f7 g7 g7 g7 g7 c7 c7 c7 c7 c7 c7 c7 c7 e6 e6 e6 e6 g6 g6 g6 g6
e3 e3 e3 a3 a3 a3 a3 a3 f3 f3 f3 f3 g3 g3 g3 g3 c3 c3 c3 c3 e3 e3 e3 e3 a3 a3 a3 a3 g3 g3 g3 g3
");*/

/*	// melody3.py
	// Am G F Em7
	m=Miti.new(Server.default,bpm,"
e5    d5    f5    e5
c5    g4    a4    b4
a3 a3 g3 e3 f3 f3 e3 e3
a6 a6 b6 d7 c7 c7 b6 b6
e7 e7 d7 g7 f7 f7 g7 g7
a7    b7    c7    d7
c6 a5 e4 c5 e4 a6 e6 g4 g5 b4 g6 b4 b6 g4 d6 d5 e5 a6 c6 e4 a6 f6 f6 a6 g6 e4 b6 g6 g6 g4 e6 g4
e6 e6 c6 g6 c6 a6 c6 a6 g4 g4 b6 d6 b4 d6 d6 g4 c5 f6 e6 e6 e6 f5 c4 a6 b6 g6 g6 g6 g5 e5 b4 b6
e6 c4 g6 g4 e4 e6 e6 e6 b7 b6 b7 b4 d4 d6 b4 g6 f6 f7 c6 f5 c7 a4 a5 c6 b6 b6 b6 e6 g4 b7 b6 e7
");*/

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

	p.putAll("output[2].slew=0.1;\n");
	p.putAll("output[3].slew=0.1;\n");
	p.putAll("output[4].slew=0.1;\n");
	m.start();

	// Buffer.read(s,"/home/zns/Music/spliceloop2/drums-ambient/70/dt_70_drum_loop_tromb_kick_key_bpm70_beats8_.flac",action:{
	// Buffer.read(s,"/home/zns/Music/spliceloop2/drums-ambient/90/AG_90_drum_loop_stood_kick_key_bpm90_beats16_.flac",action:{
	// 	arg buf;
	// 	o.playAudio("drums",buf);
	// 	// Synth.head(o.buses("main")
	// });

	Routine {
		0.1.wait;
		o.set("main","reverb",0.4);
	}.play;
});
)
o.set("main","reverb",0.4);
o.set("input","db",0.neg);
(
8.do({ arg v;
	var loop=(v+1);
	o.set("loop"++loop,"db",-96);
});
)

(
// Define the number of loops
var numLoops = 7;

// Initialize the GUI window
var window = Window("Loop Controller", Rect(100, 100, 400,220));
var sliders = Array.newClear(numLoops);
var labels = Array.newClear(numLoops);
var sliderSpec = ControlSpec(-96, 0, \linear, 0.01);
// Create sliders and labels for each loop
numLoops.do { |i|
	var loopIndex = i + 1; // Adjust for human-readable loop numbering
	var xPosition = i * 50 + 10; // Position sliders vertically

	// Create a label for the loop
	labels[i] = StaticText(window, Rect(xPosition, 10, 50, 20))
	.string_(loopIndex)
	.align_(\center);

	sliders[i] = Slider(window, Rect(xPosition+15, 50, 20,150))
	.focusColor_(Color.red(alpha:0.2))
	.background_(Color.rand)
	.value_(1)
	.action_({
		labels[i].string_(sliderSpec.map(sliders[i].value));
		o.set("loop"++loopIndex,"db",sliderSpec.map(sliders[i].value));
	});
};

// Show the window
window.front;
)