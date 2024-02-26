import random

# Notes in the musical scale to choose from, ensuring variety but musicality
notes = ["a", "a", "b", "c", "c", "d", "e", "e", "e", "e", "e", "f", "g"]
chords = [
    ["a", "c", "e", "a", "c", "e", "g"],
    ["f", "a", "c", "f", "a", "c", "f", "a", "c", "e"],
    ["c", "e", "g"],
    ["g", "b", "d"],
]
octaves = ["4", "5", "6", "6", "6"]

# Generating new melody
new_melody = []
for chord in chords:
    for i in range(4 * 2):
        new_melody.append(random.choice(chord) + random.choice(octaves))

print(" ".join(new_melody))
