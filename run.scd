(
s.waitForBoot({
	var bpm = 360;
	var doRecord = true;
	var loopNum = 1;
	o=Ouroboros2.new(Server.default);

	m=Miti.new(Server.default,bpm,"
g3 g b f
c5 b b a
e4 e d d
-
c2 e g d
-
g5 g b  a
c6 b d  d
e7 e g6 d6
");
	m.setCallbackNote({ arg note;
		["note",note].postln;
	});
	m.setCallbackMeasure({ arg measure;
		["measure",measure].postln;
		if (doRecord,{
			o.record("loop"++loopNum,16.0 * 60 / bpm);
			loopNum = loopNum + 1;
		});
	});
	m.setCallbackScore({
		["callbackScore"].postln;
		doRecord = false;
	});
	m.start();
	//Routine {
	//	1.1.wait;
	//	o.prime("loop1",2);
	//}.play;


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

// m.setPhrase(3)
// m.stop()
