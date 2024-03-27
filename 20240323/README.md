# for the theatre of the flat imagination

this repository consists of a set of three pieces composed for a performance on March 23rd, 2023.

to run this code you will need:

- computer
- SuperCollider
- [golang](https://go.dev/doc/install)
- a monome crow connected to SuperCollider
- an external synth

## setup

the crow outputs a pitch on the first channel and a envelope on the fourth channel, and a clock on the third channel. connect these how you see fit. connect the output sound of the synthesizer (which could be sequenced by crow) to the input of the computer. now run either `piece1.scd`, `piece2.scd`, or `piece3.scd`. (_note:_ you may need to change the port of the crow from `/dev/ttyACM0` to your own port on line 25 of these files.)

once those are running, go into the `p5` directory and build it using `go build`. now just run it by typing `./p5` and open a browser to `localhost:8098`. this consits of a visualizer and controls connected to the SuperCollider instance running.