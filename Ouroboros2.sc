Ouroboros2 {

	var server;
	var <bufs;
	var buses;
	var syns;
	var oscs;
	var primed;
	var params;
	var measures;
	var saveDir;

	*new { arg argServer;
		^super.new.init(argServer);
	}

	play {
		arg id;
		if (bufs.at(id).notNil,{
			Routine {
				var bufdisk = Buffer.alloc(server,65536, 2);
				var filename = saveDir++"/loop_"++id++"_1";
				filename = filename.asString.standardizePath;
				while { File.exists(filename ++ ".wav") } {
					filename = PathName(filename).nextName;
					filename = filename.asString.standardizePath;
				};
				filename = filename ++".wav";

				server.sync;
				bufdisk.postln;
				["[ouro] loop saving to file: "++filename].postln;
				bufdisk.write(filename.standardizePath, "wav", "int16", 0, 0, true,{
					arg bdisk;
					var args=[
						buf: bufs.at(id),
						busOut: buses.at("main"),
						busMetronome: buses.at("metronome"),
						busCount: buses.at("count"),
						bufDisk: bdisk,
					];
					if (params.at(id).notNil,{
						params.at(id).keysValuesDo({ arg k, v;
							args=args++[k,v];
						});
					});
					["[ouro] play args:",args].postln;

					if (syns.at(id).notNil,{
						["[ouro] sending done to loop",id].postln;
						syns.at(id).set(\gate,0);
					});
					["[ouro] started playing loop",id].postln;
					syns.put(id,Synth.after(syns.at("metronome"),"looperAudio",args).onFree({
						["[ouro] stopped playing loop",id].postln;
						// close the buffer for the written file
						bdisk.close;
						bdisk.free;
					}));
					NodeWatcher.register(syns.at(id));
				});
			}.play;
		});
	}

	prime {
		arg id, seconds;
		["[ouro] primed",id,"to record for",seconds].postln;
		primed.put(id,seconds);
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
			syns.put("record"++id,Synth.after(syns.at("input"),"recorderAudio",[
				id: id,
				busIn: buses.at("input"),
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

	recordCV {
		arg id, seconds;

		// allocate buffer and record the loop
		Buffer.alloc(server,seconds*server.sampleRate,1,completionMessage:{ arg buf;
			bufs.put(id,buf);
			["[ouro] started recording cv",id].postln;
			syns.put("cv"++id,Synth.head(server,"recorderCV",[
				id: id,
				buf: buf,
				busMetronome: buses.at("metronome"),
			]).onFree({
				["[ouro] finished cv recorder",id].postln;
			}));
			NodeWatcher.register(syns.at("cv"++id));
		});
	}

	setCV {
		arg id, data;
		if (syns.at("cv"++id).notNil,{
			if (syns.at("cv"++id).isRunning,{
				//["settings cv",id,"data=",data].postln;
				syns.at("cv"++id).set(\data,data);
			});
		});
	}

	set {
		arg name,k,v;
		if (syns.at(name).isNil,{
			^0
		});
		if (params.at(name).isNil,{
			params.put(name,Dictionary.new());
		});

		if (syns.at(name).isRunning,{
			//["[ouro] set",name,k,v].postln;
			syns.at(name).set(k,v);
			params.at(name).put(k,v);
		});
	}

	trig { arg argMeasures;
		measures = argMeasures-1;
		syns.at("metronome").set(\t_trig,1);
	}

	init {
		arg argServer;

		server = argServer;
		measures = 0;

		// initialize variables
		syns = Dictionary.new();
		buses = Dictionary.new();
		bufs = Dictionary.new();
		oscs = Dictionary.new();
		params = Dictionary.new();
		primed = Dictionary.new();

		// main output
		SynthDef("main",{
			arg busIn, busOut, busCount, db=0, reverb=0;
			var snd;
			var count;
			count = Clip.kr(In.kr(busCount,1)/5,1,30);
			snd = In.ar(busIn,2);

			snd = (snd/count) + LPF.ar(SoundIn.ar([0,1]),19000);

			snd = snd * EnvGen.ar(Env.adsr(10,1,1,1));

			snd = AnalogTape.ar(snd,0.9,0.9,0.7,2);

			snd = SelectX.ar(Lag.kr(reverb,1),[snd,
				Fverb.ar(snd[0],snd[1],200,
					tail_density: LFNoise2.kr(1/3).range(50,90),
					decay: LFNoise2.kr(1/3).range(50,90),
				)
			]);

			Out.ar(busOut,snd * Lag.kr(db,30).dbamp);
		}).send(server);

		SynthDef("input",{
			arg busOut,busRecord,lpf=135;
			var snd, incomingFreq, hasFreq, freq;

			snd = SoundIn.ar([0,1]);

			// filter the input baesd on bandpass filter around the detected pitch
			# freq, hasFreq = Pitch.kr(Mix.new(snd), ampThreshold: 0.02, median: 7);
			incomingFreq = Lag.kr(Latch.kr(freq,hasFreq),3);
			snd = BPF.ar(snd, incomingFreq, 1);
			// TODO add other bpf harmonics?

			lpf = Clip.kr(lpf,20,135);

			snd = RLPF.ar(snd,lpf.midicps,0.707);


			Out.ar(busRecord,snd);
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

		SynthDef("metronomeManual",{
			arg busOut, t_trig=0;
			var trig;
			// trig = Trig.kr(t_trig,0.02);
			SendReply.kr(t_trig,"/metronome",1);
			Out.kr(busOut,t_trig);
		}).send(server);

		SynthDef("recorderAudio",{
			arg busIn, buf, db=0;
			var snd;
			snd = In.ar(busIn,2);
			snd = snd * EnvGen.ar(Env.adsr(0.01,1,1,1));
			RecordBuf.ar(snd, buf, loop: 0, doneAction: 2);
			Out.ar(0,Silent.ar(2));
		}).send(server);

		SynthDef("recorderCV",{
			arg id=0, busMetronome, buf, data=0, gate=1;
			var snd;
			var tr=In.kr(busMetronome,1);
			var record=Lag.kr(Trig.kr(Changed.kr(data),1),0.5);
			data = Lag.kr(data,0.1);
			RecordBuf.ar(K2A.ar(data), buf, offset: 44, recLevel: record, preLevel: 1-record,loop: 1, trigger: tr);
			snd = PlayBuf.ar(1,buf,1.0,tr,loop:1);
			snd = snd * EnvGen.ar(Env.adsr(1,1,1,1),gate);
			SendReply.kr(Impulse.kr(10),"/cv",[id,snd.poll]);
		}).send(server);

		SynthDef("looperAudio",{
			arg busMetronome, busOut, busCount, buf, db=0, pan=0, gate=1, bufDisk;
			var playhead, snd0, snd1, snd;
			var tr=In.kr(busMetronome,1);
			db = VarLag.kr(db,30,warp:\sine);
			playhead = ToggleFF.kr(tr);
			snd0 = PlayBuf.ar(2,buf,rate:BufRateScale.ir(buf),loop:1,trigger:1-playhead);
			snd1 = PlayBuf.ar(2,buf,rate:BufRateScale.ir(buf),loop:1,trigger:playhead);
			snd = SelectX.ar(VarLag.kr(playhead,1.0,warp:\linear),[snd0,snd1]);

			// random amplitude
			snd = snd * SinOsc.kr(1.0/Rand(5,11)).range(9.neg,3).dbamp;

			// random pan
			snd = Balance2.ar(snd[0],snd[1],pan + SinOsc.kr(1/Rand(5,11),mul:1));

			DiskOut.ar(bufDisk, snd * db.dbamp);
			// adsr
			snd = snd * EnvGen.ar(Env.adsr(2,1,1,10),gate:gate,doneAction:2);

			SendReply.kr(Changed.kr(playhead),"/playhead",[buf]);

			Out.kr(busCount,DC.kr(1));
			Out.ar(busOut,snd*db.dbamp);
		}).send(server);

		// setup oscs
		oscs.put("metronome",OSCFunc({ arg msg, time, addr, recvPort;
			// [msg, time, addr, recvPort].postln;
			measures = measures + 1;
			["[ouro] measure",measures].postln;
			primed.keysValuesDo({arg id,seconds;
				["[ouro] recording primed",id,seconds].postln;
				this.record(id,seconds);
			});
			primed=Dictionary.new();
		}, '/metronome'));
		// setup playhead listener
		oscs.put("playhead",OSCFunc({ arg msg, time, addr, recvPort;
			[msg, time, addr, recvPort].postln;
		}, '/playhead'));
		oscs.put("cv",OSCFunc({ arg msg, time, addr, recvPort;
			var id=msg[3].asInteger;
			var data=msg[4].asFloat;
			// ["cv id=",id,"data=",data].postln;
		}, '/cv'));

		server.sync;

		// setup buses
		buses.put("input",Bus.audio(server,2));
		buses.put("record",Bus.audio(server,2));
		buses.put("metronome",Bus.control(server,1));
		buses.put("main",Bus.audio(server,2));
		buses.put("count",Bus.control(server,1));

		// setup synths
		syns.put("metronome",Synth.head(server,"metronomeManual",[\tempo,120,\busOut,buses.at("metronome")]));
		syns.put("main",Synth.tail(server,"main",[\busOut,0,\busIn,buses.at("main")]));
		syns.put("input",Synth.head(syns.at("main"),"input",[
			busOut: buses.at("main"),
			busRecord: buses.at("record"),
			busCount: buses.at("count"),
		]));

		syns.keysValuesDo({ arg k, val;
			NodeWatcher.register(val);
		});

		// create ouroborous directory for saving recordings
		saveDir = Platform.userAppSupportDir ++ "/ouroboros/" ++ Date.getDate.stamp;
		File.mkdir(saveDir);
		// ("mkdir -p "++saveDir).unixCmdGetStdOut;
		"[ouro] saving data to".postln;
		saveDir.postln;

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


