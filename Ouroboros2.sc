Ouroboros2 {

	var server;
	var bufs;
	var buses;
	var syns;
	var oscs;
	var params;

	*new { arg argServer;
		^super.new.init(argServer);
	}

	play {
		arg id;
		if (bufs.at(id).notNil,{
			var args=[
				buf: bufs.at(id),
				busOut: buses.at("main"),
				busMetronome: buses.at("metronome"),
			];
			// update with current volumes, etc
			if (params.at(id).notNil,{
				params.at(id).keysValuesDo({ arg k, v;
					args=args++[k,v];
				});
			});
			["[ouro] play args:",args].postln;

			if (syns.at(id).notNil,{
				["[ouro] sending done to loop",id].postln;
				syns.at(id).set(\done,1);
			});
			["[ouro] started playing loop",id].postln;
			syns.put(id,Synth.after(syns.at("metronome"),"looper",args).onFree({
				["[ouro] stopped playing loop",id].postln;
			}));
			NodeWatcher.register(syns.at(id));
		});
	}

	record {
		arg id, seconds;
		var xfade = 2.0;
		seconds = seconds.asFloat + 2.0;

		// initiate a routine to automatically start playing loop
		Routine {
			(seconds-2).wait;
			if (syns.at(id).notNil,{
				if (syns.at(id).isRunning,{
					syns.at(id).set(\gate,0);
				});
			});
			this.play(id);
		}.play;

		// allocate buffer and record the loop
		Buffer.alloc(server,seconds*server.sampleRate,2,completionMessage:{ arg buf;
			bufs.put(id,buf);
			["[ouro] started recording loop",id].postln;
			syns.put("record"++id,Synth.head(server,"recorder",[
				id: id,
				buf: buf,
			]).onFree({
				["[ouro] finished recording loop",id].postln;
				// buf.write(filename,headerFormat: "wav", sampleFormat: "int16",numFrames:seconds*server.sampleRate,completionMessage:{
				// 	["[ouro] finished writing",filename].postln;
				// 	Routine{
				// 		1.wait;
				// 		NetAddr("127.0.0.1", 10111).sendMsg("recorded",msg[1],msg[3],filename);
				// 	}.play;
				// });
			}));
		});
	}

	set {
		arg name,k,v;
		if (syns.at(name).isNil,{
			^0
		});
		if (syns.at(name).isRunning,{
			["[ouro] set",name,k,v].postln;
			syns.at(name).set(k,v);
		});
	}

	init {
		arg argServer;

		server = argServer;

		// initialize variables
		syns = Dictionary.new();
		buses = Dictionary.new();
		bufs = Dictionary.new();
		oscs = Dictionary.new();
		params = Dictionary.new();

		// main output
		SynthDef("main",{
			arg busIn, busOut, db=0;
			var snd;

			snd = In.ar(busIn,2);

			snd = snd * EnvGen.ar(Env.adsr(1,1,1,1));

			Out.ar(busOut,snd * db.dbamp);
		}).send(server);

		SynthDef("input",{
			arg busOut,lpf=135;
			var snd;

			snd = SoundIn.ar([0,1]);

			lpf = Clip.kr(lpf,20,135);

			snd = RLPF.ar(snd,lpf.midicps,0.707);

			Out.ar(busOut,snd);
		}).send(server);

		// metronome pulses at the beginning of each phrase
		SynthDef("metronome",{
			arg busOut, tempo=120;
			var trig;

			trig = Impulse.kr(1/((60/tempo)*4*4));
			SendReply.kr(trig,"/metronome",1);

			Out.kr(busOut,trig);
		}).send(server);

		SynthDef("recorder",{
			arg busIn, buf, db=0;
			var snd;
			snd = In.ar(busIn,2);
			snd = snd * EnvGen.ar(Env.adsr(0.1,1,1,1));
			RecordBuf.ar(snd, buf, loop: 0, doneAction: 2);
			Out.ar(0,Silent.ar(2));
		}).send(server);

		SynthDef("looper",{
			arg busMetronome, busOut, buf, db=0, gate=1;
			var playhead, snd0, snd1, snd;
			db = VarLag.kr(db,30,warp:\sine);
			playhead = ToggleFF.kr(In.kr(busMetronome,1));
			snd0 = PlayBuf.ar(2,buf,rate:BufRateScale.ir(buf),loop:1,trigger:1-playhead);
			snd1 = PlayBuf.ar(2,buf,rate:BufRateScale.ir(buf),loop:1,trigger:playhead);
			snd = SelectX.ar(VarLag.kr(playhead,1,warp:\sine),[snd0,snd1]);
			Out.ar(busOut,snd*db.dbamp);
		}).send(server);

		// setup oscs
		oscs.put("metronome",OSCFunc({ arg msg, time, addr, recvPort;
			[msg, time, addr, recvPort].postln;
		}, '/metronome'));

		server.sync;

		// setup buses
		buses.put("input",Bus.audio(server,2));
		buses.put("metronome",Bus.control(server,1));
		buses.put("main",Bus.audio(server,2));

		// setup synths
		syns.put("metronome",Synth.head(server,"metronome",[\tempo,120,\busOut,buses.at("metronome")]));
		syns.put("main",Synth.tail(server,"main",[\busOut,0,\busIn,buses.at("main")]));
		syns.keysValuesDo({ arg k, val;
			NodeWatcher.register(val);
		});

		server.sync;
		"ready".postln;
	}


	free {
		bufs.keysValuesDo({ arg k, val;
			val.free;
		});
		oscs.keysValuesDo({ arg k, val;
			val.free;
		});
		syns.keysValuesDo({ arg k, val;
			val.free;
		});
		buses.keysValuesDo({ arg k, val;
			val.free;
		});
	}
}
