(
s.waitForBoot({
	Routine{
		o = Ouroboros2.new(Server.default);
		1.wait;
		o.recordCV(1,2);
		1.wait;
		o.setCV(1,1,5);
		0.25.wait;
		o.setCV(1,1,4);
		0.25.wait;
		o.setCV(1,1,3);
		0.25.wait;
		o.setCV(1,1,2);
		1.25.wait;
		o.setCV(1,0,2);
	}.play;

});
)

