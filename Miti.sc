Miti {

	var server;
	var mitiText;
	var callbackNote;
	var callbackMeasure;
        var callbackScore;
	var phrase;
	var phraseNew;
	var line;
	var index;
	var tempo;
	var phrasesText;
	var phrasesMidi;
	var measures;
	var dostop;

	phraseToNotes {
		arg p;
		var phraseNoteArray=Array.new();
		p.split($\n).do { |line|
			var parts = line.stripWhiteSpace.split($ );
			var notes=Array.new(parts.size);
			var synths=Array.new(parts.size*2);
			var j=0;
			var lastOctave = 4;
			if (parts[0].size > 0) {
				parts.do { |part,i|
					var note, octave;
					note="c#d#ef#g#a#b".indexOf(part[0]);
					octave=part[1].asString.asInteger;
					if (octave==0,{ octave = lastOctave; });
					lastOctave = octave;
					note=note+(12*octave);
					notes.insert(i,note);
				};
				phraseNoteArray = phraseNoteArray.add(notes);
			};
		};
		^phraseNoteArray
	}

	*new { arg argServer, argTempo, argMiti;
		^super.new.init(argServer, argTempo, argMiti);
	}

	init {
		arg argServer, argTempo, argMiti;

		server = argServer;
		mitiText = argMiti;
		tempo = argTempo;

		phraseNew = -1;
		phrase = 0;
		line = 0;
		index = 0;
		measures = 0;
		dostop = true;

		server.sync;

		phrasesText = mitiText.split($-);
		phrasesMidi = Array.new(phrasesText.size);
		phrasesText.size.do({ |i|
			var midis;
			i.postln;
			phrasesText[i].stripWhiteSpace.postln;
			midis = this.phraseToNotes(phrasesText[i]);
			midis.postln;
			phrasesMidi = phrasesMidi.add(midis);

		});
		phrasesMidi.postln;
		"ready".postln;
	}

	stop {
		dostop = true;
	}

	start {
		dostop = false;
		callbackMeasure.(measures);
		Routine {
			while({ dostop.not },{
				var l;
				if (dostop,{
					^0
				});
				if (phraseNew>1.neg,{
					phrase = phraseNew;
					line = measures.mod(phrasesMidi[phrase].size);
					phraseNew = -1;
				});
				l=phrasesMidi[phrase][line];
				if (callbackNote.notNil,{
					if (l[index].notNil,{
						callbackNote.(l[index]);
					});
				});
				index = index + 1;
				if (index>=l.size,{
				        measures = measures + 1;
					index = 0;
                                        line = line + 1;
                                        if (line >= phrasesMidi[phrase].size,{
                                          phrase = phrase + 1;
                                          if (phrase >= phrasesMidi.size,{
                                            phrase = 0;
                                            if (callbackScore.notNil,{
                                              callbackScore.();

                                            });
                                          });
                                          line = 0;
                                        });
				});
				(16*60/tempo/l.size).wait;
				if (index==0,{
					if (callbackMeasure.notNil,{
						callbackMeasure.(measures);
					});
				});
			});
		}.play;

	}
	setTempo { arg argTempo;
		tempo = argTempo;
	}

	setPhrase { arg argPhrase;
		phraseNew = argPhrase.mod(phrasesMidi.size);
	}

	setCallbackNote { arg callback;
		callbackNote = callback;
	}

	setCallbackMeasure { arg callback;
		callbackMeasure = callback;
	}

        setCallbackScore { arg callback;
                callbackScore = callback;
        }

	free {
	}
}
