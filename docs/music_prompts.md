# Music prompts (Suno)

Eight tracks, one per place in the game. Make each one **instrumental** (turn
on Instrumental in Suno), and send back the MP3s with these file names. I'll
trim them so they loop cleanly, even out their loudness and drop them into
`assets/audio/music/`. Any track that's missing simply stays silent, so they
can come one at a time.

The sound effects are bright marimba, kalimba and soft synth bells, so the
music works best in the same world: warm, bouncy, tropical and cute, never
aggressive. Every prompt below shares that palette, so the tracks sound like
one game.

Tips:

- Generate a few takes of each and pick the one with the steadiest groove.
  Loops get repetitive fast if a take has a big intro or a fade.
- Ask for no vocal chops, no lyrics and no spoken words. They get old fast on
  a loop and clash with the dialog blips.
- About 1:30 to 2:30 is plenty for a loop.

---

## 1. `home.mp3`: the gym (home screen)

**Title:** Banana Gym

**Style:**
> upbeat tropical lo-fi workout groove, 105 bpm, marimba and kalimba melody,
> warm plucked bass, soft brushed drums with a gentle four-on-the-floor kick,
> ukulele strums, cute and motivating, sunny jungle gym vibe, instrumental,
> steady loopable groove, no intro, no fade out

## 2. `island.mp3`: the island

**Title:** Monkey Island Morning

**Style:**
> relaxed tropical island theme, 95 bpm, steel drum and marimba melody,
> ukulele, light shakers and bongos, soft ocean-breeze pads, playful and
> cozy, cozy village builder game music, instrumental, seamless loop, no
> intro, no fade out

## 3. `jungle.mp3`: the jungle clearing

**Title:** Deep in the Canopy

**Style:**
> mysterious but friendly jungle exploration music, 90 bpm, kalimba and
> wooden flute melody, hand drums and log drums, soft rainforest ambience,
> plucked strings, curious adventure mood, cute game soundtrack,
> instrumental, seamless loop, no intro, no fade out

## 4. `story.mp3`: cutscenes and the Jungle Trek map

**Title:** The Trek Begins

**Style:**
> warm adventurous storybook theme, 85 bpm, pizzicato strings, marimba,
> soft french horn and flute melody, light hand percussion, hopeful and a
> little mischievous, animated movie cutscene underscore, gentle so dialog
> sits on top, instrumental, loopable, no fade out

## 5. `challenge.mp3`: daily quest challenges

**Title:** Pushup Challenge

**Style:**
> energetic tropical game challenge music, 125 bpm, punchy marimba riff,
> bouncy synth bass, tight funky drums with claps, steel drum stabs, rising
> energy, fun timed minigame vibe, motivating workout track, instrumental,
> steady loop, no intro, no fade out

## 6. `battle.mp3`: Jungle Trek fights

**Title:** Lizard Rumble

**Style:**
> playful jungle battle theme, 135 bpm, driving tribal drums and taiko,
> marimba and xylophone riffs, brass stabs, bouncy bass, heroic but cute,
> cartoon rpg battle music, energetic and rhythmic for doing pushups,
> instrumental, seamless loop, no intro, no fade out

## 7. `boss.mp3`: the duel with King Komo

**Title:** Throne of Scales

**Style:**
> epic but cartoony boss battle, 140 bpm, big taiko drums, low brass and
> choir-like synth pads (no words), menacing marimba ostinato, gong hits,
> royal lizard king theme with a mischievous twist, high stakes rpg boss
> fight, instrumental, seamless loop, no intro, no fade out

## 8. `victory.mp3`: winning a stage or quest (plays once)

**Title:** Bananas for Everyone

**Style:**
> short triumphant victory fanfare, 120 bpm, marimba and brass, bright
> cymbal swell, celebratory steel drums, cute rpg level clear jingle, ends
> on a happy held chord, instrumental

Then trim it to the first 5 to 8 seconds, or send the whole take and I'll cut
it.

---

# More tracks (2.0 and the island roadmap)

Same palette and rules as above: **instrumental**, no vocals or chops, warm
and cute, tropical percussion, marimba, kalimba and soft bells. Loops have
no intro and no fade out; the ones marked **(plays once)** are short cues
that may start and end.

Right now the game plays one track per place (the eight above). The tracks
below are for places that don't have their own music yet: the island intro
film, the Trek's seven stages, the daily quest locations and the island at
night (#70). Once the MP3s are in `assets/audio/music/` with these names,
each one gets wired to its place, and a missing one falls back to the
general track (`story`, `battle`, `challenge` or `island`).

## Island intro film

### 9. `intro_village.mp3`: banana night in the village

**Title:** Banana Night

**Style:**
> joyful tribal campfire party, 112 bpm, bouncy log drums and bongos,
> marimba melody, kalimba, hand claps, playful whistle-like flute, warm
> sunset jungle celebration, monkeys dancing round a fire, cute and silly,
> cartoon game soundtrack, instrumental, seamless loop, no intro, no fade out

### 10. `intro_storm.mp3`: the storm and the tornado

**Title:** Here Comes the Twister

**Style:**
> dramatic but cartoony storm music, 128 bpm, rolling timpani and taiko,
> swirling pizzicato strings, rising woodwind runs, low brass stabs,
> howling wind synth, tense and exciting, a little comedic, like a
> family animated film chase, no horror, instrumental, seamless loop, no
> intro, no fade out

### 11. `intro_beach.mp3`: waking up on the beach

**Title:** Washed Up

**Style:**
> gentle hopeful morning on a tropical beach, 80 bpm, soft kalimba and
> harp melody, light ukulele, distant steel drum, soft ocean-wave pads,
> a little lonely at first then warm and determined, tender storybook
> moment, instrumental, seamless loop, no intro, no fade out

### 12. `intro_title.mp3`: "Long ago, deep in the jungle…" (plays once)

**Title:** Long Ago

**Style:**
> short storybook opening cue, 70 bpm, soft music-box celesta and harp
> arpeggio, warm low strings swell, gentle wind chime, once-upon-a-time
> feeling, 8 to 12 seconds, ends on a soft open chord, instrumental

## Island

### 13. `island.mp3` (alternative take): the island by day

Only if the first take gets repetitive.

**Title:** Rebuild the Island

**Style:**
> cozy upbeat island builder theme, 100 bpm, steel drums and marimba
> trading the melody, ukulele chops, soft shaker and cajon groove, warm
> plucked bass, sunny optimistic tropical village, light and endlessly
> loopable, cute game soundtrack, instrumental, seamless loop, no intro,
> no fade out

### 14. `island_night.mp3`: the island at night (2.1, day and night)

**Title:** Fireflies over Monkey Island

**Style:**
> sleepy tropical night lullaby, 72 bpm, soft kalimba and vibraphone,
> gentle nylon guitar, quiet crickets and waves ambience, warm pads,
> fireflies and lanterns, calm and dreamy, cozy game soundtrack,
> instrumental, seamless loop, no intro, no fade out

## Daily quests, one per place

The quest's challenge still uses `challenge.mp3`. These play during the
story before and after it, at each quest's location.

### 15. `quest_volcano.mp3`: the volcano

**Title:** Hot Hot Hiccups

**Style:**
> playful volcano adventure, 100 bpm, deep log drums and bubbling
> marimba, low tuba bass, steam-whistle flute, warm and a bit cheeky,
> rumbling but friendly, cartoon adventure game music, instrumental,
> seamless loop, no intro, no fade out

### 16. `quest_moon_beach.mp3`: the moonlit beach

**Title:** Moonlit Wishes

**Style:**
> dreamy night beach theme, 84 bpm, celesta and kalimba melody, soft
> steel drum, slow shaker, shimmering pads, gentle waves, magical and
> calm, starry sky, cute game soundtrack, instrumental, seamless loop, no
> intro, no fade out

### 17. `quest_temple.mp3`: the temple of the golden banana

**Title:** Temple of the Golden Banana

**Style:**
> mysterious ancient jungle temple, 92 bpm, wooden marimba and pan
> flute, tabla-like hand drums, plucked koto-like strings, soft gong,
> curious treasure-hunt mood, friendly not scary, adventure game
> soundtrack, instrumental, seamless loop, no intro, no fade out

### 18. `quest_sky_island.mp3`: the island in the clouds

**Title:** Above the Clouds

**Style:**
> light airy floating island theme, 96 bpm, bright glockenspiel and
> harp, ukulele, soft whistled-flute melody, breezy pads, light bells,
> carefree and soaring, whimsical game soundtrack, instrumental,
> seamless loop, no intro, no fade out

## Jungle Trek: one theme per stage

These replace `battle.mp3` on their stage. All of them are fights, so they
keep a strong steady beat for pushups (125 to 140 bpm) and change only the
colour of the place. King Komo keeps `boss.mp3`.

### 19. `trek_fern_trail.mp3`: stage 1, Fern Trail

**Title:** First Steps on the Fern Trail

**Style:**
> bright jungle adventure battle, 125 bpm, bouncy marimba riff, bongos
> and congas, plucky ukulele, cheerful brass hits, sunny and
> encouraging, first level of a cute rpg, energetic for workouts,
> instrumental, seamless loop, no intro, no fade out

### 20. `trek_canopy.mp3`: stage 2, Canopy Bridge

**Title:** Rope Bridge Rumble

**Style:**
> high treetop battle theme, 130 bpm, swinging xylophone runs, tribal
> drums, twangy plucked strings, birdsong-like flute trills, airy and
> daring, a bit of vertigo, cute rpg battle music, instrumental,
> seamless loop, no intro, no fade out

### 21. `trek_swamp.mp3`: stage 3, Misty Swamp

**Title:** Bog Brawl

**Style:**
> murky swamp battle, 126 bpm, squelchy bass clarinet and tuba groove,
> muted marimba, frog-croak-like percussion, low hand drums, foggy and
> sneaky but funny, cartoon rpg battle music, instrumental, seamless
> loop, no intro, no fade out

### 22. `trek_lake.mp3`: stage 4, Lake Snapjaw

**Title:** Raft Wars

**Style:**
> rolling lake battle on a raft, 130 bpm, steel drums and marimba,
> splashy cymbals, swaying 6/8 feel, bold brass melody, pirate-ish but
> cute, waves and adventure, cartoon rpg battle music, instrumental,
> seamless loop, no intro, no fade out

### 23. `trek_temple.mp3`: stage 5, Temple of Scales

**Title:** Scales and Stones

**Style:**
> ancient temple battle, 132 bpm, heavy taiko and stone-like wood
> blocks, marimba ostinato, pan flute melody, low choir-like synth pads
> (no words), gong accents, mysterious and powerful, rpg battle music,
> instrumental, seamless loop, no intro, no fade out

### 24. `trek_gorge.mp3`: stage 6, Serpent Gorge

**Title:** Rattle in the Gorge

**Style:**
> hot desert canyon battle, 136 bpm, driving frame drums and shakers
> like rattles, twangy guitar and marimba riff, snake-charmer flute
> melody, brass stabs, dusty and tense but cute, rpg battle music,
> instrumental, seamless loop, no intro, no fade out

### 25. `trek_map.mp3`: the Trek map between stages

**Title:** Onward, Carlos

**Style:**
> hopeful adventure map theme, 92 bpm, marching snare and soft timpani,
> french horn and flute melody, marimba, plucked strings, brave and
> curious, journey ahead, storybook rpg overworld music, instrumental,
> seamless loop, no intro, no fade out

## Short cues (play once)

### 26. `level_up.mp3`: Carlos levels up in the Trek

**Title:** Stronger!

**Style:**
> short level up fanfare, 130 bpm, rising marimba and glockenspiel run,
> brass hit, cymbal swell, bright and proud, 3 to 5 seconds,
> instrumental

### 27. `defeat.mp3`: losing a stage or quest

**Title:** Try Again, Bro

**Style:**
> short gentle comedic defeat cue, slow descending tuba and marimba
> notes, soft "womp" brass, kind and encouraging rather than sad, 3 to
> 5 seconds, instrumental
