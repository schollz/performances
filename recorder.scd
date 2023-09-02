(
s.waitForBoot({
	var s=Server.default;
	var tempoBPM = 120;
	var syn = Dictionary.new();
	var bus = Dictionary.new();
	var buf = Dictionary.new();
	var par = Dictionary.new();

	var measures = 0;
	Routine {

		// output effects
		SynthDef("output",{
			arg busIn, busOut, db=0;
			var snd;

			snd = In.ar(busIn,2);

			snd = snd * EnvGen.ar(Env.adsr(1,1,1,1));

			Out.ar(busOut,snd * db.dbamp);
		}).send(s);

		SynthDef("input",{
			arg busOut,lpf=135;
			var snd;

			snd = SoundIn.ar([0,1]);

			lpf = Clip.kr(lpf,20,135);

			snd = RLPF.ar(snd,lpf.midicps,0.707);

			Out.ar(busOut,snd);
		}).send(s);

		// metronome pulses at the beginning of each phrase
		SynthDef("metronome",{
			arg busOut, tempo=120;
			var trig;

			trig = Impulse.kr(1/((60/tempo)*4*4));
			SendReply.kr(trig,"/metronome",1);

			Out.kr(busOut,trig);
		}).send(s);

		SynthDef("recorder",{
			arg busIn, buf, db=0;
			var snd;
			snd = In.ar(busIn,2);
			snd = snd * EnvGen.ar(Env.adsr(0.1,1,1,1));
			RecordBuf.ar(snd, buf, loop: 0, doneAction: 2);
			Out.ar(0,Silent.ar(2));
		}).send(s);

		SynthDef("looper",{
			// arg id,buf,t_trig=0,busReverb,busCompress,busNoCompress,db=0,done=0;
			// var amp = VarLag.kr(db,30,warp:\sine).dbamp;
			// var playhead = ToggleFF.kr(t_trig);
			// var snd0 = PlayBuf.ar(1,buf,rate:BufRateScale.ir(buf),loop:1,trigger:1-playhead);
			// var snd1 = PlayBuf.ar(1,buf,rate:BufRateScale.ir(buf),loop:1,trigger:playhead);
			// var snd = SelectX.ar(Lag.kr(playhead,xfade),[snd0,snd1]);
			// var reverbSend = 0.0;
			// snd = snd * amp * EnvGen.ar(Env.adsr(3,1,1,3),1-done,doneAction:2);
			// snd = snd * (LFNoise2.kr(1/Rand(8,12)).range(12.neg,0).dbamp); // amplitude lfo
			// snd = Pan2.ar(snd,LFNoise2.kr(1/Rand(6,20),mul:0.9));
			// Out.ar(busCompress,0*snd);
			// Out.ar(busNoCompress,(1-reverbSend)*snd);
			// Out.ar(busReverb,reverbSend*snd);
		}).send(s);



		OSCFunc({ arg msg, time, addr, recvPort;
			[msg, time, addr, recvPort].postln;

		}, '/conductor');

		OSCFunc({ arg msg, time, addr, recvPort;
			[msg, time, addr, recvPort].postln;
measures = measures + 1;
			measures.postln;
		}, '/metronome');

		s.sync;

		bus.put("input",Bus.audio(s,2));
		bus.put("metronome",Bus.control(s,1));

		syn.put("metronome",Synth.head(s,"metronome",[\tempo,tempoBPM,\busOut,bus.at("metronome")]));
		"ready".postln;
	}.play;

});
)
135.midicps

NetAddr("127.0.0.1", NetAddr.langPort).sendMsg("/conductor",1,2)

