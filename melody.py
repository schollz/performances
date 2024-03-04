import random

# Notes in the musical scale to choose from, ensuring variety but musicality
notes = ["a", "a", "b", "c", "c", "d", "e", "e", "e", "e", "e", "f", "g"]
chords = [
    ["c", "e", "g"],
    ["c", "e", "g"],
    ["c", "e", "g"],
    ["g", "b", "d"],
    ["g", "b", "d"],
    ["g", "b", "d"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["a", "c", "e"],
    ["d", "f", "a"],
    ["d", "f", "a"],
    ["d", "f", "a"],
    ["d", "f", "a"],
    ["d", "f", "a"],
    ["d", "f", "a"],
    ["f", "a", "c"],
    ["f", "a", "c"],
    ["f", "a", "c"],
    ["f", "a", "c"],
    ["f", "a", "c"],
    ["f", "a", "c"],
]
octaves = ["7", "8", "8", "8", "8", "8", "6"]

# Generating new melody
# Generating new melody
new_melody = []
last_note = 0
last_octave = 0
for chord in chords:
    for i in range(6):
        octave = random.choice(octaves)

        random_note = random.choice(chord) + octave
        while random_note == last_note:
            random_note = random.choice(chord) + octave

        last_note = random_note
        new_melody.append(random_note)

print(" ".join(new_melody))
