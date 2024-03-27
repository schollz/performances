
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
	var lastNote = 0;
	// s.record;

	7.do({ arg octave;
		cscale.do({arg v;
			scale=scale.add(24+v+(octave*12));
		});
	});


	SynthDef("jp",{ | out=0,amp=1,freq = 523.3572, detune = 0.5,lpf=10,t_trig=0|
		var in, local;
		var detuneCurve = { |x|
			(10028.7312891634*x.pow(11)) -
			(50818.8652045924*x.pow(10)) +
			(111363.4808729368*x.pow(9)) -
			(138150.6761080548*x.pow(8)) +
			(106649.6679158292*x.pow(7)) -
			(53046.9642751875*x.pow(6)) +
			(17019.9518580080*x.pow(5)) -
			(3425.0836591318*x.pow(4)) +
			(404.2703938388*x.pow(3)) -
			(24.1878824391*x.pow(2)) +
			(0.6717417634*x) +
			0.0030115596
		};
		var centerGain = { |x| (-0.55366 * x) + 0.99785 };
		var sideGain = { |x| (-0.73764 * x.pow(2)) + (1.2841 * x) + 0.044372 };

		var center = Mix.new(LFSaw.ar(Lag.kr(freq,LFNoise2.kr(1/3).range(0.01,1)), Rand()));
		var detuneFactor = freq * detuneCurve.(LFNoise2.kr(1/3).range(0.3,0.7));
		var freqs = [
			(freq - (detuneFactor * Rand(0.10,0.12))),
			(freq - (detuneFactor * Rand(0.05,0.07))),
			(freq - (detuneFactor * Rand(0.01,0.03))),
			// (freq + (detuneFactor * 0)),
			(freq + (detuneFactor * Rand(0.01,0.03))),
			(freq + (detuneFactor * Rand(0.05,0.07))),
			(freq + (detuneFactor * Rand(0.09,0.11)))
		];
		var side = Array.fill(6, { |n|
			Saw.ar(freqs[n], Rand(0, 2))
		});
		var mix = LFNoise2.kr(1/3).range(0.1,0.9);
		var sig = (center * centerGain.(mix)) + (side * sideGain.(mix));

		sig = Splay.ar(sig);
		sig = HPF.ar(sig, freq);
		sig = BLowPass.ar(sig,MouseX.kr(30,125).midicps,LFNoise2.kr(1/3).range(0.4,1.0));
		sig = BLowPass.ar(sig,freq*4);
		sig = BHiPass.ar(sig,freq/2);
		sig = sig * (1-EnvGen.ar(Env.perc(0.05,1),gate:t_trig));

		// tape delay
		in = sig;
		in = in * (Amplitude.kr(Mix.ar(in)) > 0.02); // noise gate
		local = LocalIn.ar(2)*LFNoise2.kr(1/3).range(0,1.3);
		local = OnePole.ar(local, LFNoise2.kr(1/3).range(0.2,0.5));
		local = OnePole.ar(local, -0.08);
		local = Rotate2.ar(local[0], local[1], LFNoise2.kr(1/3).range(0.1,0.3));
		local = DelayN.ar(local, 0.25, 0.25);
		local = LeakDC.ar(local);
		local = ((local + in) * LFNoise2.kr(1/3).range(0.75,1.25)).softclip;
		LocalOut.ar(DelayC.ar(local,0.5,Slew.kr(Lag.kr(LFNoise0.kr(1/11).range(0.2,0.5),3)).poll));

		Out.ar(out,local*amp);
	}).send(s);



	o=Ouroboros2.new(s);

	m=Miti.new(Server.default,bpm,"
a2 f2 c2 g2
a3 a3 c4 b4
c4 c4 g4 g4
e5 f5 e5 d5
e6 e6 g6 b6
c5 c5 c5 d5
e4 d4 e4 b5
c6 c6 a5 a5 c6 c6 f6 f6 e6 e6 e6 e6 g6 g6 b6 b6
c6 c6 a5 a5 c6 c6 f6 f6 e6 e6 e6 e6 g6 g6 b6 b6
c7 c7 c7 d7
c6 c6 a5 a5 c6 c6 f6 f6 e6 e6 e6 e6 g6 g6 b6 b6
c6 e6 a5 b5 c6 a6 a6 f6 e6 g6 c6 g6 g5 b5 d5 b5
e6
");

	m.setCallbackNote({ arg note;
		note = note + 12;
		["note",note].postln;
		if (loopNum<loopNumMax,{
			if (lastNote-note==0,{
			},{
				a.set(\freq,note.midicps,\t_trig,1);
				lastNote = note;
			})
		});
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		o.set("metronome","t_trig",1);
		loopNum = loopNum + 1;
		if (loopNum<loopRecordMax,{
			o.record("loop"++loopNum.mod(8),16.0 * 60 / bpm);
		});
	});

	Routine {
		s.sync;
		a = Synth.new("jp",[\amp,-12.dbamp,\out,o.buses.at("record"),\freq,60.midicps,\detune,0.5]);
		1.wait;
		m.start();
		o.set("main","reverb",0.4);
	}.play;
});
)

o.set("main","reverb",0.7);
