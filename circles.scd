(
var windata=Array.newClear(128);
var height=400,width=800,spacing=20,padding=20;
var w,a;
var lastHeight=height;
var lastWidth=width;
var lastNum=0;
var changed=true;
var debounce=0;
var win = Window.new("web",Rect(0,0,width,height)).front;
if (~winosc.notNil,{
	~winosc.free;
});
~winosc=OSCFunc({ |msg|
	var loopid = msg[3].asInteger;
	var x = msg[4].clip(-1,1);
	var y = msg[5].clip(-1,1);
	windata.put(loopid,[x,y]);
}, '/loopinfo');
AppClock.sched(0,{
	var colors=[
		Color.fromHexString("#FFFAD7"),
		Color.fromHexString("#FCDDB0"),
		Color.fromHexString("#FF9F9F"),
		Color.fromHexString("#E97777"),
	];

	w=win;
	w.view.background_(colors[0]);
	w.drawFunc = {
		Pen.use{
			Pen.beginTransparencyLayer;
			windata.do{ arg v,note;
				if (v.notNil,{
					var radius = w.bounds.height/10;
					var x = v[0].linlin(-1,1,radius,w.bounds.width-radius).asInteger;
					var y = v[1].linlin(-1,1,radius,w.bounds.height-radius).asInteger;

					//Pen.blendMode = 11;
					Pen.color = Color.fromHexString("#E9777711");
					Pen.setShadow(2@2, 10, Color.black);
					Pen.addArc(Point(x,y),radius,0,360);
					Pen.fill;
				});
			};
			Pen.endTransparencyLayer;
		};
	};
});

AppClock.sched(0,{
	if (w.notNil,{
		if (w.isClosed.not,{
			w.refresh;
		});
	});
	0.04
});
)

