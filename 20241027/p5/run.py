import threading

from pythonosc import dispatcher, osc_server
import p5


# Variables similar to SuperCollider ones
windata = [(0, 0)] * 128  # Initialize list of tuples
height = 400
width = 800
radius = height / 10  # Assuming a similar ratio for the circles


# OSC setup
def handle_osc(address, *args):
    loopid = int(args[0])
    x = min(max(args[1], -1), 1)  # Clipping to -1 to 1
    y = min(max(args[2], -1), 1)
    windata[loopid] = (x, y)  # Update windata


dispatcher = dispatcher.Dispatcher()
dispatcher.map("/loopinfo", handle_osc)

server = osc_server.ThreadingOSCUDPServer(("127.0.0.1", 8123), dispatcher)
server_thread = threading.Thread(target=server.serve_forever)
server_thread.start()


# P5 setup
def setup():
    p5.size(width, height)
    p5.stroke_weight(2)
    # frame_rate(3)


def draw():
    p5.background(255, 253, 215)  # Using a color similar to #FFFAD7
    p5.blend_mode(p5.EXCLUSION)

    for x, y in windata:
        if x != 0 and y != 0:  # Check if data is not the initialized value
            mapped_x = ((x + 1) / 2) * (
                width - 2 * radius
            ) + radius  # Map from -1 to 1 into 0 to width
            mapped_y = ((y + 1) / 2) * (
                height - 2 * radius
            ) + radius  # Map from -1 to 1 into 0 to height
            p5.fill(233, 119, 119, 17)  # Similar to #E9777711 with alpha
            p5.arc((mapped_x, mapped_y), radius * 2, radius * 2, 0, 360)


if __name__ == "__main__":
    p5.run()
