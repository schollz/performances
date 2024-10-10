import random

# Notes in the musical scale to choose from, ensuring variety but musicality
notes = ["a", "a", "b", "c", "c", "d", "e", "e", "e", "e", "e", "f", "g"]
chords = [
    ["a", "c", "e", "a", "c", "e", "g"],
    ["g", "b", "d"],
    ["f", "a", "c", "f", "a", "c", "f", "a", "c", "e"],
    ["b", "e", "g"],
]
octaves = ["7"]

# Generating new melody
new_melody = []
last_note = 0
for chord in chords:
    for i in range(64):
        random_note = random.choice(chord) + random.choice(octaves)
        while random_note == last_note:
            random_note = random.choice(chord) + random.choice(octaves)
        last_note = random_note
        new_melody.append(random_note)

print(" ".join(new_melody))
