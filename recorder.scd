(
s.waitForBoot({
	Routine {
		var s=Server.default;
		OSCFunc({ arg msg, time, addr, recvPort;
			[msg, time, addr, recvPort].postln;

		}, '/conductor');

		s.sync;
		"ready".postln;
	}.play;

});
)

NetAddr("127.0.0.1", NetAddr.langPort).sendMsg("/conductor",1,2)