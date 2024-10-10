import random

# Notes in the musical scale to choose from, ensuring variety but musicality
notes = ["a", "a", "b", "c", "c", "d", "e", "e", "e", "e", "e", "f", "g"]
chords = [
    ["c", "e", "g"],
    ["g", "b", "d"],
    ["a", "c", "e"],
    ["d", "f", "a"],
    ["f", "a", "c"],
]
chord_times = [
    3,
    3,
    10,
    6,
    6,
]
octaves = ["4", "5", "6", "6", "6", "7"]

# Generating new melody
new_melody = []
for chordi, chord in enumerate(chords):
    random_note = random.choice(chord) + random.choice(octaves)
    for i in range(chord_times[chordi]):
        new_melody.append(random_note)

print(" ".join(new_melody))
