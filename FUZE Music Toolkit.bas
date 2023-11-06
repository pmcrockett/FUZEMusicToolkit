/*  FUZE    1.0.10
   Music       __
 Toolkit ___---  |
      --- ___--  |
     |  --     | |
     | "Rule   | |
     | | of    | |
     | |Six"---  |
     | |   /     |
  ---  | by\____/
 /     |Petra
 \____/Crockett */

// Changelog:
//
// v1.0.10
// * Added transport controls (pause, seek, chase, loop).
// * Added the ability to set a specific start time via setAudioQueueStartTime().
// * Event culling can now be disabled during assembly.
// * Fixed a bug that could cause final events in a sequence to hang.
// * Fixed a bug that could cause a tempo hiccup when starting playback.

setMode(640, 360)
var g_freezeFile = false // Set to true to prevent writing changes to the text file
array g_chVis[0] // Data about the music visualization

// This function returns the basic arrays that will be used to build the audio sequence. The arrays are stored
// in a function to ensure that they won't persist as global arrays once they are no longer needed.
function buildAudio()
	var audioClips = [
		// ----------------------------------------------------------------
		// INSTRUMENT DEFINITIONS
		[
			"drmKick", // Handle for references to this data from elsewhere in the array
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1] ], // Parameters exposed to higher array levels
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playAudio", .ch = ["ch", 0], .sampleIdx = 3, .vol = ["vol", 5, "*"], 
				.pan = 0.5, .spd = 1, .loops = 0, .root = "c3", .pitch = "c1" ],
			[ .func = "setFilter", .type = 1, .cutoff = 250 ],
			[ .func = "setClipper", .thresh = 0.6, .strength = 80 ],
			[ .func = "setEnvelope", .spd = 15 ]
		],
		[
			"drmSnare",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playAudio", .ch = ["ch", 0], .sampleIdx = 2, .vol = ["vol", 2, "*"], 
				.pan = 0.25, .spd = 1, .loops = 0, .root = "c3", .pitch = "g3" ],
			[ .func = "setEnvelope", .spd = 30 ],
			[ .func = "setModulator", .wave = 3, .freq = 100, .scale = 0.3 ],
			[ .func = "setFilter", .type = 2, .cutoff = 300 ],
			[ .func = "setReverb", .delay = 50, .atten = 0.5 ],
			
			[ .func = "playNote", .ch = ["ch", 1], .wave = 4, .freq = 7800, 
				.vol = ["vol", 0.2, "*"], .spd = 25, .pan = 0.25 ],
			[ .func = "setClipper", .thresh = 2.5, .strength = 3 ],
			[ .func = "setAuto", .ch = ["ch", 1], .rate = 0.032, .interpType = linear, .events = [
					[ .timePos = 0, .func = "setFilter", .type = 1, .cutoff = 10000 ],
					[ .timePos = 0.15, .type = 1, .cutoff = 500 ]
				]
			],
			[ .func = "setAuto", .rate = 0.032, .interpType = linear, .events = [
					[ .timePos = 0, .func = "setFrequency", .freq = 7800 ],
					[ .timePos = 0.1, .freq = 800 ]
				]
			]
		],
		[
			"drmHatClosed",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playNote", .ch = ["ch", 0], .wave = 1, .freq = 4500, 
				.vol = ["vol", 0.3, "*"], .spd = 230, .pan = 0.2 ],
			[ .func = "setClipper", .thresh = 0, .strength = 0 ],
			[ .func = "setFilter", .type = 2, .cutoff = 7000 ],
			[ .func = "setModulator", .wave = 3, .freq = 0, .scale = 0 ],
			[ .func = "setReverb", .delay = 20, .atten = 0.3 ]
		],
		[
			"drmTom",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playAudio", .ch = ["ch", 0], .sampleIdx = 1, .vol = ["vol", 3.25, "*"], 
				.pan = 0.6, .spd = 1, .loops = 0, .root = "c3", .pitch = ["pitch", 0] ],
			[ .func = "setFilter", .type = 2, .cutoff = 200 ],
			[ .func = "setClipper", .thresh = 0.1, .strength = 30 ],
			[ .func = "setModulator", .wave = 3, .freq = 0, .scale = 0 ],
			[ .func = "setEnvelope", .spd = 20 ],
			[ .func = "setReverb", .delay = 10, .atten = 0.2 ]
		],
		[
			"drmHatOpen",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1] ],
			
			[ .timePos = 0, .ch = ["ch", 0], .func = "setModulator", .wave = 3, .freq = 0, .scale = 0 ],
			[ .beatPos = ["beatPos", {0, 0}], .func = "playNote", .ch = ["ch", 0], .wave = 1, .freq = 2500, 
				.vol = ["vol", 0.3, "*"], .spd = 30, .pan = 0.2 ],
			[ .func = "setClipper", .thresh = 0, .strength = 0 ],
			[ .func = "setFilter", .type = 2, .cutoff = 7000 ]
		],
		[
			"drmSplash",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1] ],
			
			[ .timePos = 0, .ch = ["ch", 0], .func = "setModulator", .wave = 3, .freq = 70, .scale = 400 ],
			[ .beatPos = ["beatPos", {0, 0}], .func = "playNote", .ch = ["ch", 0], .wave = 1, .freq = 2500, 
				.vol = ["vol", 0.3, "*"], .spd = 18, .pan = 0.8 ],
			[ .func = "setClipper", .thresh = 0, .strength = 0 ],
			[ .func = "setFilter", .type = 2, .cutoff = 8000 ]
		],
		[
			"drmCrash",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .func = "playNote", .ch = ["ch", 0], .wave = 1, .freq = 2500, 
				.vol = ["vol", 0.5, "*"], .spd = 8, .pan = 0.8 ],
			[ .func = "setModulator", .wave = 3, .freq = 0, .scale = 0 ],
			[ .func = "setFilter", .type = 2, .cutoff = 7000 ],
			[ .func = "setClipper", .thresh = 0, .strength = 0 ],
				
			[ .func = "playNote", .ch = ["ch", 1], .wave = 4, .freq = 18000, 
				.vol = ["vol", 0.75, "*"], .spd = 10, .pan = 0.8 ]
		],
		[
			"lead",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0], ["spd", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playAudio", .ch = ["ch", 0], .sampleIdx = 5, .vol = ["vol", 4.25, "*"], 
				.pan = 0.45, .spd = 1, .loops = 0, .root = "a3", .pitch = ["pitch", 0] ],
			[ .func = "setReverb", .delay = 90, .atten = 0.3 ],
			[ .func = "setEnvelope", .spd = 10 ],
			
			
			[ .timePos = 0.06, .func = "playAudio", .sampleIdx = 5, .vol = ["vol", 3.25, "*"], 
				.pan = 0.45, .spd = 0.98, .loops = 0, .root = "a3", .pitch = ["pitch", 0] ],
			
			[ .timePos = 0.12, .func = "playAudio", .sampleIdx = 5, .vol = ["vol", 2.25, "*"], 
				.pan = 0.45, .spd = 1.02, .loops = 0, .root = "a3", .pitch = ["pitch", 0] ],
				
			[ .timePos = 0.18, .func = "playAudio", .sampleIdx = 5, .vol = ["vol", 1.25, "*"], 
				.pan = 0.45, .spd = 0.98, .loops = 0, .root = "a3", .pitch = ["pitch", 0] ],
				
			[ .timePos = 0.24, .func = "playAudio", .sampleIdx = 5, .vol = ["vol", 0.75, "*"], 
				.pan = 0.45, .spd = 1.02, .loops = 0, .root = "a3", .pitch = ["pitch", 0] ]
		],
		[
			"lead2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0], ["spd", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playNote", .ch = ["ch", 0], .wave = 0, .pitch = ["pitch", 0], 
				.vol = ["vol", 0.06, "*"], .spd = 5.5, .pan = 0.55 ],
			[ .func = "setAuto", .rate = 0.2, .interpType = linear, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "setModulator", .ch = ["ch", 0], .wave = 3, .freq = 6, .scale = 1 ],
				[ .timePos = 1.8, .wave = 3, .freq = 2, .scale = 15 ]
				]
			]
		],
		[
			"bass",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playAudio", .ch = ["ch", 0], .sampleIdx = 0, .vol = ["vol", 1, "*"], 
				.pan = 0.5, .spd = 1, .loops = 0, .root = "eb2", .pitch = ["pitch", -12] ],
			[ .timePos = 0, .func = "setEnvelope", .spd = 20 ],
			[ .timePos = 0.06, .func = "setEnvelope", .spd = 5 ],
			[ .func = "setAuto", .rate = 0.032, .interpType = linear, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0.3, .func = "setVolume", .ch = ["ch", 0], .vol = ["vol", 2, "*"] ],
				[ .timePos = 0.7, .vol = 0.001 ]
				]
			],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playNote", .ch = ["ch", 1], .wave = 1, .pitch = ["pitch", -12], 
				.vol = ["vol", 0.3, "*"], .spd = 6, .pan = 0.5 ],
			[ .func = "setClipper", .thresh = 2, .strength = 4 ],
			[ .func = "setReverb", .delay = 30, .atten = 0.2 ],
			[ .func = "setFilter", .type = 1, .cutoff = 3000 ]
		],
		[
			"piano",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0], ["spd", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playAudio", .ch = ["ch", 0], .sampleIdx = 4, .vol = ["vol", 3.25, "*"], 
				.pan = 0.5, .spd = 1, .loops = 0, .root = "db6", .pitch = ["pitch", 0] ],
			[ .func = "setEnvelope", .spd = ["spd", 6] ],
			[ .func = "setReverb", .delay = 80, .atten = 0.4 ],
			[ .func = "setModulator", .wave = 3, .freq = 6, .scale = 0.001 ]
		],
		[
			"beep",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0], ["spd", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playNote", .ch = ["ch", 0], .wave = 3, .pitch = ["pitch", 0], 
				.vol = ["vol", 0.06, "*"], .spd = 60, .pan = ["pan", 0] ],
			[ .func = "setEnvelope", .spd = ["spd", 25] ],
			[ .func = "setReverb", .delay = 80, .atten = 0.5 ],
			[ .func = "setFilter", .type = 1, .cutoff = 3000 ]
		],
		[
			"swell",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0], ["spd", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playNote", .ch = ["ch", 0], .wave = 2, .pitch = ["pitch", 0], 
				.vol = 0.01, .spd = ["spd", 2], .pan = ["pan", 0] ],
			[ .func = "setReverb", .delay = 80, .atten = 0.3 ],
			[ .func = "setClipper", .thresh = 0, .strength = 0 ],
			[ .func = "setAuto", .rate = 0.032, .interpType = linear, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "setFilter", .ch = ["ch", 0], .type = 1, .cutoff = 0 ],
				[ .beatPos = ["beatPos", {1, 0}], .cutoff = 2000 ]
				]
			],
			[ .func = "setAuto", .rate = 0.032, .interpType = expo_in, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "setVolume", .ch = ["ch", 0], .vol = 0.01 ],
				[ .beatPos = ["beatPos", {1, 0}], .timePos = 0, .vol = ["vol", 0.7, "*"] ]
				]
			],
			[ .func = "setAuto", .rate = 0.2, .interpType = expo_in, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "setModulator", .ch = ["ch", 0], .wave = 3, .freq = 7, .scale = 1 ],
				[ .beatPos = ["beatPos", {1, 0}], .scale = 15 ]
				]
			],
			[ .func = "setReverb", .delay = 0, .atten = 0 ] // Stop reverb so we don't get the tail at the start of the next note
		],
		[
			"swellMid",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0], ["spd", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playNote", .ch = ["ch", 0], .wave = 2, .pitch = ["pitch", 0], 
				.vol = 0.2, .spd = ["spd", 2], .pan = ["pan", 0] ],
			[ .func = "setReverb", .delay = 80, .atten = 0.3 ],
			[ .func = "setClipper", .thresh = 0, .strength = 0 ],
			[ .func = "setAuto", .rate = 0.032, .interpType = linear, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "setFilter", .ch = ["ch", 0], .type = 1, .cutoff = 0 ],
				[ .beatPos = ["beatPos", {0, 3.5}], .cutoff = 2000 ]
				]
			],
			[ .func = "setAuto", .rate = 0.032, .interpType = expo_in, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "setVolume", .ch = ["ch", 0], .vol = 0.01 ],
				[ .beatPos = ["beatPos", {0, 3.5}], .timePos = 0, .vol = ["vol", 0.5, "*"] ]
				]
			],
			[ .func = "setAuto", .rate = 0.2, .interpType = expo_in, .events = [
				[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "setModulator", .ch = ["ch", 0], .wave = 3, .freq = 7, .scale = 1 ],
				[ .beatPos = ["beatPos", {0, 3.5}], .scale = 15 ]
				]
			],
			[ .func = "setReverb", .delay = 0, .atten = 0 ] // Stop reverb so we don't get the tail at the start of the next note
		],
		[
			"swellShort",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 1], ["pitch", 0], ["spd", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .timePos = 0, .func = "playNote", .ch = ["ch", 0], .wave = 2, .pitch = ["pitch", 0], 
				.vol = ["vol", 0.09, "*"], .spd = ["spd", 12], .pan = ["pan", 0] ],
			[ .func = "setReverb", .delay = 80, .atten = 0.3 ],
			[ .func = "setClipper", .thresh = 0, .strength = 0 ],
			[ .func = "setModulator", .wave = 3, .freq = 7, .scale = 7 ],
			[ .func = "setFilter", .type = 1, .cutoff = 2000 ]
		],
		// ----------------------------------------------------------------
		// DRUM PATTERNS
		[
			"3BeatDrum1",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			
			[ [ ["beatPos", {0, 0.25}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 1}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 2}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ]
		],
		[
			"1BeatDrum1",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ]
		],
		[
			"1BeatDrum2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "d4"] ], "drmTom" ],
			[ [ ["beatPos", {0, 0.125}], ["ch", 2], ["vol", 0], ["pitch", "d4"] ], "drmTom" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 2], ["vol", 0], ["pitch", "d4"] ], "drmTom" ],
			
			[ [ ["beatPos", {0, 0.75}], ["ch", 2], ["vol", 0] ], "drmSnare" ]
		],
		[ // Full block
			"1mDrum1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum1" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0] ], "1BeatDrum1" ]
		],
		[ // Full block
			"1mDrum1B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum1" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0] ], "1BeatDrum1" ]
		],
		[ // Full block
			"1mDrum1C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum1" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "1BeatDrum2" ]
		],
		[ // Full block
			"1mDrum1F",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum1" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 4], ["vol", 0] ], "drmSplash" ]
		],
		[ // Full block
			"1mDrum1G",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum1" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0] ], "1BeatDrum1" ]
		],
		[
			"7BeatKick",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 4}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0] ], "drmKick" ]
		],
		[
			"6BeatDrum2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "7BeatKick" ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 2}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "d4"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 2], ["vol", 0], ["pitch", "b3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 4}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 4}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 5}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 4], ["vol", 0] ], "drmSplash" ]
		],
		[ // Full block
			"7BeatDrum2A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "6BeatDrum2" ],
			[ [ ["beatPos", {0, 6}], ["ch", 2], ["vol", 0], ["pitch", "b3"] ], "drmTom" ]
		],
		[ // Full block
			"7BeatDrum2B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "6BeatDrum2" ],
			[ [ ["beatPos", {0, 6}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 6.5}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ]
		],
		[ // Full block
			"7BeatDrum2C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "6BeatDrum2" ],
			[ [ ["beatPos", {0, 6}], ["ch", 2], ["vol", 0], ["pitch", "b3"] ], "drmTom" ]
		],
		[
			"3BeatDrum2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 1}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 2}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			
			[ [ ["beatPos", {0, 0.25}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0] ], "drmSnare" ]
		],
		[ // Full block
			"4BeatDrum2A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum2" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "d4"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 2], ["vol", 0], ["pitch", "b3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "b3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ]
		],
		[ // Full block
			"4BeatDrum2B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum2" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 2], ["vol", 0] ], "drmSnare" ]
		],
		[
			"5BeatDrum3",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "7BeatKick" ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 1}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 2}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 3}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 4}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ]
		],
		[ // Full block
			"7BeatDrum3A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "5BeatDrum3" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			[ [ ["beatPos", {0, 6}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 6.5}], ["ch", 4], ["vol", 0] ], "drmHatClosed" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 2], ["vol", 0] ], "drmSnare" ]
		],
		[ // Full block
			"7BeatDrum3B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "5BeatDrum3" ],
			
			[ [ ["beatPos", {0, 6.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 6}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 6.5}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 6}], ["ch", 2], ["vol", 0] ], "drmSnare" ]
		],
		[ // Full block
			"7BeatDrum3C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "5BeatDrum3" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 6}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 6.5}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ]
		],
		[ // Full block
			"1mDrum1D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "3BeatDrum1" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "d4"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 2], ["vol", 0], ["pitch", "d4"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "b3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3.625}], ["ch", 2], ["vol", 0], ["pitch", "b3"] ], "drmTom" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 2], ["vol", 0], ["pitch", "g3"] ], "drmTom" ]
		],
		[
			"2BeatDrum4",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 1}], ["ch", 4], ["vol", 0] ], "drmSplash" ]
		],
		[ // Full block
			"4BeatDrum4A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "2BeatDrum4" ],
			
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 2}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0] ], "drmSnare" ]
		],
		[ // Full block
			"4BeatDrum4B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0] ], "2BeatDrum4" ],
			
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0] ], "drmKick" ],
			
			[ [ ["beatPos", {0, 2}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3}], ["ch", 4], ["vol", 0] ], "drmSplash" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 4], ["vol", 0] ], "drmHatOpen" ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0] ], "drmSnare" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 2], ["vol", 0] ], "drmSnare" ]
		],
		// ----------------------------------------------------------------
		// LEAD PATTERNS
		[ // Full block
			"1mLead1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "bb4"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", "c4"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "f3"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db5"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "c5"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "bb4"], ["pan", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mLeadDbl1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", "lead"] ], "1mLead1A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", 0], ["inst", "lead2"] ], "1mLead1A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", 12], ["inst", "lead"] ], "1mLead1A" ]
		],
		[ // Full block
			"1mLead1Ba",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "bb4"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", "ab4"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "bb4"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db5"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "c5"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "bb4"], ["pan", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mLeadDbl1Ba",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", "lead"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", 0], ["inst", "lead2"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", 12], ["inst", "lead"] ], "1mLead1Ba" ]
		],
		[ // Full block
			"1mLead1Bb",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "f3"], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "f3"], ["pan", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mLeadDbl1Bb",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", "lead"] ], "1mLead1Bb" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", 0], ["inst", "lead2"] ], "1mLead1Bb" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", 12], ["inst", "lead"] ], "1mLead1Bb" ]
		],
		[ // Full block
			"1mLead1C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "bb4"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "db5"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", "e5"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "f5"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "db5"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "ab4"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "ab4"] ], ["inst", ""] ]
		],
		[ // Full block
			"1mLeadDbl1C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", "lead"] ], "1mLead1C" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", 0], ["inst", "lead2"] ], "1mLead1C" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", 12], ["inst", "lead"] ], "1mLead1C" ]
		],
		[ // Full block
			"1mLead2A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "bb4"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "bb4"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "bb4"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "bb4"] ], ["inst", ""] ]
		],
		[ // Full block
			"1mLeadDbl2A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", "lead"] ], "1mLead2A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", 0], ["inst", "lead2"] ], "1mLead2A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", 12], ["inst", "lead"] ], "1mLead2A" ]
		],
		[ // Full block
			"1mLead2B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "c5"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "c5"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "c5"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "c5"] ], ["inst", ""] ]
		],
		[ // Full block
			"1mLeadDbl2B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", "lead"] ], "1mLead2B" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", 0], ["inst", "lead2"] ], "1mLead2B" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", 12], ["inst", "lead"] ], "1mLead2B" ],
			[ .beatPos = ["beatPos", {1, 0}], .ch = ["ch", 0], .func = "stopChannel" ],
			[ .beatPos = ["beatPos", {1, 0}], .ch = ["ch", 1], .func = "stopChannel" ],
			[ .beatPos = ["beatPos", {1, 0}], .ch = ["ch", 2], .func = "stopChannel" ]
		],
		[
			"7BeatLead3",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", -0.1], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", -0.15], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", -0.2], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", -0.25], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", -0.3], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", -0.35], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 4}], ["ch", 0], ["vol", -0.4], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", -0.45], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 5}], ["ch", 0], ["vol", -0.5], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 5.5}], ["ch", 0], ["vol", -0.55], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", -0.6], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 6.5}], ["ch", 0], ["vol", -0.65], ["pitch", 0] ], ["inst", ""]],
			
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel" ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "setReverb", .delay = 0, .atten = 0 ] // Stop reverb so we don't get the tail at the start of the next note
		],
		[
			"4BeatLead3",
			[ ["beatPos", {0, 0}], ["ch", 0], ["tol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", -0.1], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", -0.1], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", -0.1], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", -0.15], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", -0.2], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", -0.25], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", -0.3], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", -0.35], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", -0.4], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", -0.45], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", -0.5], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", -0.55], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", -0.6], ["pitch", 0] ], ["inst", ""]],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", -0.65], ["pitch", 0] ], ["inst", ""]],
			
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel" ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "setReverb", .delay = 0, .atten = 0 ] // Stop reverb so we don't get the tail at the start of the next note
		],
		[ // Full block
			"7BeatLeadDbl3A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["inst", "lead"] ], "7BeatLead3" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "bb4"], ["inst", "lead2"] ], "7BeatLead3" ]
		],
		[ // Full block
			"7BeatLeadDbl3B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["inst", "lead"] ], "7BeatLead3" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["inst", "lead2"] ], "7BeatLead3" ]
		],
		[ // Full block
			"7BeatLeadDbl3C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["inst", "lead"] ], "7BeatLead3" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["inst", "lead2"] ], "7BeatLead3" ]
		],
		[ // Full block
			"7BeatLeadDbl3D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["inst", "lead"] ], "4BeatLead3" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["inst", "lead2"] ], "4BeatLead3" ]
		],
		[ // Full block
			"1mBass2C(Lead)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass1A(Lead)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ]
		],
		// ----------------------------------------------------------------
		// BASS PATTERNS
		[ // Full block
			"1mBass1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0.5], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass1B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass1C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "db4"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.333}], ["ch", 0], ["vol", 0], ["pitch", "db2"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass1D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 1] ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "eb3"] ], "bass" ],
			[ [ ["beatPos", {0, 3.67}], ["ch", 0], ["vol", 0], ["pitch", "c3"] ], "bass" ],
			[ [ ["beatPos", {0, 3.83}], ["ch", 0], ["vol", 0], ["pitch", "b2"] ], "bass" ]
		],
		[ // Full block
			"1mBass2C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass2D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 1] ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "db4"] ], "bass" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", 0], ["pitch", "db4"] ], "bass" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db4"] ], "bass" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "db4"] ], "bass" ]
		],
		[ // Full block
			"1mBass3D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 1] ]
		],
		[ // Full block
			"1mBass4A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ]
		],
		[ // Full block
			"1mBass4C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0] ], "bass" ]
		],
		[ // Full block
			"1mBass4D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "f2"] ], "bass" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0], ["pitch", "bb3"] ], "bass" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "f2"] ], "bass" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "f2"] ], "bass" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "bb3"] ], "bass" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "f2"] ], "bass" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "bb3"] ], "bass" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "bb3"] ], "bass" ]
		],
		[ // Full block
			"7BeatBass5A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", -12], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "bb3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "bb2"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 4}], ["ch", 0], ["vol", 0], ["pitch", "c3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 0], ["vol", 0], ["pitch", "f3"] ], ["inst", ""] ]
		],
		[ // Full block
			"7BeatBass5B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", -12], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "c3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "bb2"] ], ["inst", ""] ]
		],
		[ // Full block
			"7BeatBass6A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", -12], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "c4"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "c3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 4}], ["ch", 0], ["vol", 0], ["pitch", "d3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", 0], ["pitch", "eb3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 0], ["vol", 0], ["pitch", "ab3"] ], ["inst", ""] ]
		],
		[ // Full block
			"4BeatBass6B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", -12] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb3"] ], "bass" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "d3"] ], "bass" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], "bass" ]
		],
		[ // Full block
			"1mBass7D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 1] ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "d#3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.67}], ["ch", 0], ["vol", 0], ["pitch", "e3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.83}], ["ch", 0], ["vol", 0], ["pitch", "f#3"] ], ["inst", ""] ]
		],
		[ // Full block
			"7BeatBass7C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ .beatPos = ["beatPos", {0, 4}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 4}], .func = "stopChannel", .ch = ["ch", 1] ]
		],
		[ // Full block
			"1mBass8A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", -12] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", 0], ["pitch", -5] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", 0] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass8B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 1] ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "bb3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "ab3"] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass9A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ]
		],
		[ // Full block
			"1mBass9B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 1] ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ]
		],
		// ----------------------------------------------------------------
		// PIANO PATTERNS
		[
			"4BeatPiano1",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 0.67}], ["ch", 0], ["vol", 0], ["pitch", "ab5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 0.83}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.67}], ["ch", 0], ["vol", 0], ["pitch", "ab5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.83}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 2.67}], ["ch", 0], ["vol", 0], ["pitch", "ab5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 2.83}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ]
		],
		[ // Full block
			"1mPiano1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", -13] ], "4BeatPiano1" ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["spd", 0] ], "piano" ]
		],
		[ // Full block
			"1mPiano1B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", -13] ], "4BeatPiano1" ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "db5"], ["spd", 0] ], "piano" ],
			
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["spd", -10] ], "piano" ],
			[ .beatPos = ["beatPos", {1, 3}], .func = "stopChannel", .ch = ["ch", 0] ]
		],
		[ // Full block
			"1mPiano1C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", -13] ], "4BeatPiano1" ],
			
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "c#4"], ["spd",  0] ], "piano" ],
			[ [ ["beatPos", {0, 3.67}], ["ch", 0], ["vol", 0], ["pitch", "d#4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.83}], ["ch", 0], ["vol", 0], ["pitch", "e4"], ["spd", 0] ], "piano" ],
			
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["spd", -10] ], "piano" ],
			
			[ [ ["beatPos", {1, 3}], ["ch", 0], ["vol", 0], ["pitch", "e4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {1, 3}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {1, 3}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {1, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "e4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {1, 3.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {1, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ]
		],
		[ // Full block
			"7BeatPiano2A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "e4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "e4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", 0], ["pitch", "e4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", "e4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ]
		],
		[ // Full block
			"7BeatPiano2B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["spd",0] ], "piano" ]
		],
		[ // Full block
			"7BeatPiano2C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 4.5}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 6}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["spd", 0] ], "piano" ]
		],
		[
			"2BeatPiano3",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ]
		],
		[ // Full block
			"4BeatPiano3A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 0] ], "2BeatPiano3" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 7] ], "piano" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 7] ], "piano" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 7] ], "piano" ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 2] ]
		],
		[ // Full block
			"4BeatPiano3B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", -13] ], "2BeatPiano3" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ]
		],
		[ // Full block
			"4BeatPiano3C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", 13] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["spd", -13] ], "2BeatPiano3" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 1], ["vol", 0], ["pitch", "g4"], ["spd", 0] ], "piano" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 2], ["vol", 0], ["pitch", "b4"], ["spd", 0] ], "piano" ]
		],
		[ // Full block
			"4BeatPiano4",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "a5"] ], "piano" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "a#5"] ], "piano" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "b5"] ], "piano" ]
		],
		[ // Full block
			"1mBass9B(Piano)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["inst", ""] ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "db3"] ], ["inst", ""] ],
			
			[ .beatPos = ["beatPos", {0, 2}], .func = "stopChannel", .ch = ["ch", 0] ]
		],
		// ----------------------------------------------------------------
		// BEEP PATTERNS
		[
			"1/2BeatBeep1",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ]
		],
		[
			"1BeatBeep1",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.125}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pan", 0] ], "1/2BeatBeep1" ]
		],
		[
			"1BeatBeep2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.125}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ]
		],
		[
			"1BeatBeep3",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ]
		],
		[
			"1mBeep1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "1BeatBeep1" ],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "1BeatBeep2" ],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "1BeatBeep3" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "1BeatBeep2" ]
		],
		[ // Full block
			"1mBeepDbl1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "1mBeep1A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "1mBeep1A" ]
		],
		[ // Full block
			"1mBeepDbl1Aa",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pan", 0] ], "1/2BeatBeep1" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 1], ["pitch", 5], ["vol", 0], ["pan", 1] ], "1/2BeatBeep1" ],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pan", 0] ], "1BeatBeep2" ],
			[ [ ["beatPos", {0, 1}], ["ch", 1], ["pitch", 5], ["vol", 0], ["pan", 1] ], "1BeatBeep2" ],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pan", 0] ], "1BeatBeep3" ],
			[ [ ["beatPos", {0, 2}], ["ch", 1], ["pitch", 5], ["vol", 0], ["pan", 1] ], "1BeatBeep3" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pan", 0] ], "1BeatBeep2" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["pitch", 5], ["vol", 0], ["pan", 1] ], "1BeatBeep2" ]
		],
		[
			"1mBeep1B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "1BeatBeep3" ],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "1BeatBeep2" ],
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "1BeatBeep3" ]
		],
		[ // Full block
			"1mBeepDbl1B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "1mBeep1B" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "1mBeep1B" ]
		],
		[
			"arpBeep2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.042}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.083}], ["ch", 0], ["vol", 0], ["pitch", "bb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.125}], ["ch", 0], ["vol", 0], ["pitch", "eb7"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.167}], ["ch", 0], ["vol", 0], ["pitch", "gb7"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.21}], ["ch", 0], ["vol", 0], ["pitch", "bb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "ab5"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"arpBeepDbl2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "arpBeep2" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "arpBeep2" ]
		],
		[
			"7BeatBeep3A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6.25}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6.5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ]
		],
		[
			"7BeatBeep3A(78)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "7BeatBeep3A" ],
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {1, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"7BeatBeepDbl3A(78)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "7BeatBeep3A(78)" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "7BeatBeep3A(78)" ]
		],
		[
			"7BeatBeep3A(44)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "7BeatBeep3A" ],
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {1, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"7BeatBeepDbl3A(44)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "7BeatBeep3A(44)" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "7BeatBeep3A(44)" ]
		],
		[
			"7BeatBeep3B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6.25}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6.5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ]
		],
		[
			"7BeatBeep3B(78)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "7BeatBeep3B" ],
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {1, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"7BeatBeepDbl3B(78)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "7BeatBeep3B(78)" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "7BeatBeep3B(78)" ]
		],
		[
			"7BeatBeep3B(44)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ], "7BeatBeep3B" ],
			[ [ ["beatPos", {1, 0}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {1, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"7BeatBeepDbl3B(44)",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "7BeatBeep3B(44)" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "7BeatBeep3B(44)" ]
		],
		[
			"4BeatBeep3C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.125}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.125}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.125}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"4BeatBeepDbl3C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "4BeatBeep3C" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "4BeatBeep3C" ]
		],
		[
			"4BeatBeep3D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.125}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", 0], ["pitch", "ab6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"4BeatBeepDbl3D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "4BeatBeep3D" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "4BeatBeep3D" ]
		],
		[
			"4BeatBeep3E",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.125}], ["ch", 0], ["vol", 0], ["pitch", "a5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.125}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "gb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", 0], ["pitch", "gb6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.125}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "gb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "gb6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"4BeatBeepDbl3E",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "4BeatBeep3E" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "4BeatBeep3E" ]
		],
		[
			"4BeatBeep3F",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "gb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.125}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "gb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", 0], ["pitch", "gb6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"4BeatBeepDbl3F",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "4BeatBeep3F" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "4BeatBeep3F" ]
		],
		[
			"4BeatBeep3G",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.125}], ["ch", 0], ["vol", 0], ["pitch", "ab5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "bb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.125}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.25}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "d6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", 0], ["pitch", "d6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.125}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.25}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "d6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.75}], ["ch", 0], ["vol", 0], ["pitch", "d6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"4BeatBeepDbl3G",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "4BeatBeep3G" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "4BeatBeep3G" ]
		],
		[
			"7BeatBeep3H",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "d6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "d6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", "f5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "d6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 6.5}], ["ch", 0], ["vol", 0], ["pitch", "e6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"7BeatBeepDbl3H",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "7BeatBeep3H" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "7BeatBeep3H" ]
		],
		[
			"7BeatBeep3I",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 2}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "bb5"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 2.5}], ["ch", 0], ["vol", 0], ["pitch", "db6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "bb6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "bb6"], ["pan", 0] ], "beep" ],
			
			[ [ ["beatPos", {0, 5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ],
			[ [ ["beatPos", {0, 5.5}], ["ch", 0], ["vol", 0], ["pitch", "f6"], ["pan", 0] ], "beep" ]
		],
		[ // Full block
			"7BeatBeepDbl3I",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["pan", 0] ], "7BeatBeep3I" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["pitch", -5], ["pan", 1] ], "7BeatBeep3I" ]
		],
		// ----------------------------------------------------------------
		// SWELL PATTERNS
		[ // Full block
			"1mSwellDbM7",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swell" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swell" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["pan", 0.85] ], "swell" ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 2] ]
		],
		[ // Full block
			"1mSwellFm7",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swell" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swell" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["pan", 0.85] ], "swell" ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {1, 0}], .func = "stopChannel", .ch = ["ch", 2] ]
		],
		[ // Full block
			"1mSwellFm7Short",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swell" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swell" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["pan", 0.85] ], "swell" ],
			[ .beatPos = ["beatPos", {0, 3}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 3}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 3}], .func = "stopChannel", .ch = ["ch", 2] ]
		],
		[ // Full block
			"1mSwellArp",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0], ["spd", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "g6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.25}], ["ch", 0], ["vol", 0], ["pitch", "g6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "g6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.917}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.083}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.75}], ["ch", 0], ["vol", 0], ["pitch", "g6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.917}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.083}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.75}], ["ch", 0], ["vol", 0], ["pitch", "g6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.917}], ["ch", 0], ["vol", 0], ["pitch", "eb6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 3.083}], ["ch", 0], ["vol", 0], ["pitch", "c6"], ["pan", 0.55], ["spd", 0] ], "swellShort" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "eb5"], ["pan", 0.55], ["spd", 0] ], "swellShort" ]
		],
		[ // Full block
			"1mSwellBbmLong",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellMid" ]
		],
		[ // Full block
			"1mSwellBbmEnd",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 3.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 3.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 3.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0.55] ], "swellShort" ]
		],
		[ // Full block
			"1mSwellFm7Long",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "c6"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 2], ["vol", 0], ["pitch", "c6"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "c6"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0], ["pitch", "c6"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "gb3"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "c6"], ["pan", 0.85] ], "swellShort" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "gb3"], ["pan", 0.55] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "c6"], ["pan", 0.85] ], "swellMid" ]
		],
		[ // Full block
			"1mSwellFm7End",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 3.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 3.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 3.5}], .func = "stopChannel", .ch = ["ch", 2] ]
		],
		[ // Full block
			"1mSwellDbM7Long",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 0.625}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0.625}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 0.625}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellShort" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 1], ["vol", 0], ["pitch", "f4"], ["pan", 0.7] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "bb5"], ["pan", 0.85] ], "swellMid" ]
		],
		[ // Full block
			"1mSwellFm7Long2",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ [ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0}], ["ch", 2], ["vol", 0], ["pitch", "eb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 0.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 0.75}], ["ch", 2], ["vol", 0], ["pitch", "eb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 1.5}], ["ch", 2], ["vol", 0], ["pitch", "eb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 1.75}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 2.25}], ["ch", 2], ["vol", 0], ["pitch", "eb5"], ["pan", 0.85] ], "swellShort" ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 1] ],
			[ .beatPos = ["beatPos", {0, 2.5}], .func = "stopChannel", .ch = ["ch", 2] ],
			[ [ ["beatPos", {0, 3}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0.55] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["pan", 0.7] ], "swellShort" ],
			[ [ ["beatPos", {0, 3}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["pan", 0.85] ], "swellShort" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 0], ["vol", 0], ["pitch", "f4"], ["pan", 0.55] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 1], ["vol", 0], ["pitch", "ab4"], ["pan", 0.7] ], "swellMid" ],
			[ [ ["beatPos", {0, 3.5}], ["ch", 2], ["vol", 0], ["pitch", "c5"], ["pan", 0.85] ], "swellMid" ]
		],
		[ // Full block
			"7BeatSwell1A",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 2] ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swell" ],
			[ [ ["beatPos", {0, 1}], ["ch", 2], ["vol", 0], ["pitch", "bb4"], ["pan", 0.85] ], "swell" ]
		],
		[ // Full block
			"7BeatSwell1B",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 2] ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "db4"], ["pan", 0.55] ], "swell" ],
			[ [ ["beatPos", {0, 1}], ["ch", 2], ["vol", 0], ["pitch", "ab4"], ["pan", 0.85] ], "swell" ]
		],
		[ // Full block
			"7BeatSwell1C",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 2] ],
			
			[ [ ["beatPos", {0, 1}], ["ch", 0], ["vol", 0], ["pitch", "eb4"], ["pan", 0.55] ], "swell" ],
			[ [ ["beatPos", {0, 1}], ["ch", 2], ["vol", 0], ["pitch", "ab4"], ["pan", 0.85] ], "swell" ]
		],
		[ // Full block
			"7BeatSwell1D",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 0] ],
			[ .beatPos = ["beatPos", {0, 0}], .func = "stopChannel", .ch = ["ch", 2] ],
			
			[ [ ["beatPos", {0, 0.5}], ["ch", 0], ["vol", 0], ["pitch", "d4"], ["pan", 0.55] ], "swell" ],
			[ [ ["beatPos", {0, 0.5}], ["ch", 2], ["vol", 0], ["pitch", "g4"], ["pan", 0.85] ], "swell" ]
		],
		// ----------------------------------------------------------------
		// FULL MUSIC SEQUENCE
		[
			"Rule of Six",
			[ ["beatPos", {0, 0}], ["ch", 0], ["vol", 0], ["pitch", 0], ["pan", 0] ],
			
			// m. 0
			[ [ ["beatPos", {0, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 7] ], "1mPiano1A" ],
			[ [ ["beatPos", {0, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			"forceWrite",
			// m. 1
			[ [ ["beatPos", {1, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {1, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {1, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {1, 0}], ["ch", 10] ], "1mSwellDbM7" ],
			"forceWrite",
			// m. 2
			[ [ ["beatPos", {2, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {2, 0}], ["ch", 5], ["inst", "bass"] ], "1mBass1C" ],
			[ [ ["beatPos", {2, 0}], ["ch", 7] ], "1mPiano1B" ],
			[ [ ["beatPos", {2, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			"forceWrite",
			// m. 3
			[ [ ["beatPos", {3, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {3, 0}], ["ch", 5] ], "1mBass1D" ],
			[ [ ["beatPos", {3, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {3, 0}], ["ch", 10] ], "1mSwellFm7" ],
			"forceWrite",
			// m. 4
			[ [ ["beatPos", {4, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {4, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {4, 0}], ["ch", 7] ], "1mPiano1A" ],
			[ [ ["beatPos", {4, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			"forceWrite",
			// m. 5
			[ [ ["beatPos", {5, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {5, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {5, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {5, 0}], ["ch", 10] ], "1mSwellDbM7" ],
			"forceWrite",
			// m. 6
			[ [ ["beatPos", {6, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {6, 0}], ["ch", 5], ["pitch", "db3"], ["inst", "bass"] ], "1mBass2C" ],
			[ [ ["beatPos", {6, 0}], ["ch", 7] ], "1mPiano1C" ],
			[ [ ["beatPos", {6, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			"forceWrite",
			// m. 7
			[ [ ["beatPos", {7, 0}], ["ch", 0] ], "1mDrum1F" ],
			[ [ ["beatPos", {7, 0}], ["ch", 5] ], "1mBass2D" ],
			[ [ ["beatPos", {7, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {7, 0}], ["ch", 10] ], "1mSwellFm7Short" ],
			"forceWrite",
			// m. 8
			[ [ ["beatPos", {8, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {8, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {8, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			"forceWrite",
			// m. 9
			[ [ ["beatPos", {9, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {9, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {9, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {9, 0}], ["ch", 10] ], "1mSwellDbM7" ],
			[ [ ["beatPos", {9, 0}], ["ch", 13] ], "1mLeadDbl1A" ],
			"forceWrite",
			// m. 10
			[ [ ["beatPos", {10, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {10, 0}], ["ch", 5], ["pitch", "db3"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {10, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			[ [ ["beatPos", {10, 0}], ["ch", 13] ], "1mLeadDbl1Bb" ],
			"forceWrite",
			// m. 11
			[ [ ["beatPos", {11, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {11, 0}], ["ch", 5] ], "1mBass3D" ],
			[ [ ["beatPos", {11, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {11, 0}], ["ch", 10] ], "1mSwellFm7" ],
			[ [ ["beatPos", {11, 0}], ["ch", 13] ], "1mLeadDbl1Ba" ],
			"forceWrite",
			// m. 12
			[ [ ["beatPos", {12, 0}], ["ch", 0] ], "1mDrum1G" ],
			[ [ ["beatPos", {12, 0}], ["ch", 5], ["pitch", "bb2"] ], "1mBass4A" ],
			[ [ ["beatPos", {12, 0}], ["ch", 8] ], "arpBeepDbl2" ],
			[ [ ["beatPos", {12, 0}], ["ch", 8] ], "1mBeepDbl1Aa" ],
			"forceWrite",
			// m. 13
			[ [ ["beatPos", {13, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {13, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {13, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {13, 0}], ["ch", 10] ], "1mSwellDbM7" ],
			[ [ ["beatPos", {13, 0}], ["ch", 13] ], "1mLeadDbl1C" ],
			"forceWrite",
			// m. 14
			[ [ ["beatPos", {14, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {14, 0}], ["ch", 5], ["pitch", "db3"] ], "1mBass4C" ],
			[ [ ["beatPos", {14, 0}], ["ch", 7] ], "1mPiano1A" ],
			[ [ ["beatPos", {14, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			"forceWrite",
			// m. 15
			[ [ ["beatPos", {15, 0}], ["ch", 0] ], "1mDrum1C" ],
			[ [ ["beatPos", {15, 0}], ["ch", 5] ], "1mBass4D" ],
			[ [ ["beatPos", {15, 0}], ["ch", 7] ], "1mPiano1A" ],
			[ [ ["beatPos", {15, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {15, 0}], ["ch", 10] ], "1mSwellArp" ],
			"forceWrite",
			// m. 16
			[ [ ["beatPos", {16, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {16, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {16, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			[ [ ["beatPos", {16, 0}], ["ch", 10] ], "1mSwellBbmLong" ],
			"forceWrite",
			// m. 17
			[ [ ["beatPos", {17, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {17, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {17, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {17, 0}], ["ch", 10] ], "1mSwellBbmEnd" ],
			[ [ ["beatPos", {17, 0}], ["ch", 13] ], "1mLeadDbl1A" ],
			"forceWrite",
			// m. 18
			[ [ ["beatPos", {18, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {18, 0}], ["ch", 5], ["pitch", "db3"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {18, 0}], ["ch", 7], ["vol", 1], ["inst", "piano"] ], "1mLead1A" ], // Piano
			[ [ ["beatPos", {18, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			[ [ ["beatPos", {18, 0}], ["ch", 10] ], "1mSwellFm7Long" ],
			[ [ ["beatPos", {18, 0}], ["ch", 13] ], "1mLeadDbl1Bb" ],
			"forceWrite",
			// m. 19
			[ [ ["beatPos", {19, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {19, 0}], ["ch", 5] ], "1mBass3D" ],
			[ [ ["beatPos", {19, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {19, 0}], ["ch", 10] ], "1mSwellFm7End" ],
			[ [ ["beatPos", {19, 0}], ["ch", 13] ], "1mLeadDbl1Ba" ],
			"forceWrite",
			// m. 20
			[ [ ["beatPos", {20, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {20, 0}], ["ch", 5], ["pitch", "bb2"] ], "1mBass4A" ],
			[ [ ["beatPos", {20, 0}], ["ch", 7], ["vol", 1], ["inst", "piano"] ], "1mLead1Ba" ], // Piano
			[ [ ["beatPos", {20, 0}], ["ch", 8] ], "arpBeepDbl2" ],
			[ [ ["beatPos", {20, 0}], ["ch", 8] ], "1mBeepDbl1Aa" ],
			[ [ ["beatPos", {20, 0}], ["ch", 10] ], "1mSwellDbM7Long" ],
			"forceWrite",
			// m. 21
			[ [ ["beatPos", {21, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {21, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {21, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {21, 0}], ["ch", 10] ], "1mSwellBbmEnd" ],
			[ [ ["beatPos", {21, 0}], ["ch", 13] ], "1mLeadDbl1C" ],
			"forceWrite",
			// m. 22
			[ [ ["beatPos", {22, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {22, 0}], ["ch", 5], ["pitch", "db3"] ], "1mBass4C" ],
			[ [ ["beatPos", {22, 0}], ["ch", 8] ], "1mBeepDbl1A" ],
			[ [ ["beatPos", {22, 0}], ["ch", 10] ], "1mSwellFm7Long2" ],
			[ [ ["beatPos", {22, 0}], ["ch", 13] ], "1mLeadDbl2A" ],
			"forceWrite",
			// m. 23
			[ [ ["beatPos", {23, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {23, 0}], ["ch", 5] ], "1mBass4D" ],
			[ [ ["beatPos", {23, 0}], ["ch", 8] ], "1mBeepDbl1B" ],
			[ [ ["beatPos", {23, 3.5}], ["ch", 8] ], "arpBeepDbl2" ],
			[ [ ["beatPos", {23, 0}], ["ch", 10] ], "1mSwellFm7End" ],
			[ [ ["beatPos", {23, 0}], ["ch", 13] ], "1mLeadDbl2B" ],
			[ .beatPos = {24, 0}, .ch = 5, .func = "stopChannel" ],
			[ .beatPos = {24, 0}, .ch = 6, .func = "stopChannel" ],
			[ .beatPos = {24, 0}, .ch = 8, .func = "stopChannel" ],
			[ .beatPos = {24, 0}, .ch = 9, .func = "stopChannel" ],
			[ .beatPos = {24, 0}, .ch = 13, .func = "stopChannel" ],
			"forceWrite",
			// m. 24
			[ [ ["beatPos", {24, 0}], ["ch", 0] ], "7BeatDrum2A" ],
			[ [ ["beatPos", {24, 0}], ["ch", 7] ], "7BeatPiano2A" ],
			"forceWrite",
			// m. 25
			[ [ ["beatPos", {25, 0}], ["ch", 0] ], "7BeatDrum2B" ],
			[ [ ["beatPos", {25, 0}], ["ch", 7] ], "7BeatPiano2B" ],
			"forceWrite",
			// m. 26
			[ [ ["beatPos", {26, 0}], ["ch", 0] ], "7BeatDrum2C" ],
			[ [ ["beatPos", {26, 0}], ["ch", 7] ], "7BeatPiano2C" ],
			"forceWrite",
			// m. 27
			[ [ ["beatPos", {27, 0}], ["ch", 0] ], "4BeatDrum2A" ],
			[ [ ["beatPos", {27, 0}], ["ch", 7] ], "4BeatPiano3A" ],
			"forceWrite",
			// m. 28
			[ [ ["beatPos", {28, 0}], ["ch", 0] ], "7BeatDrum2A" ],
			[ [ ["beatPos", {28, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5A" ],
			[ [ ["beatPos", {28, 0}], ["ch", 8] ], "7BeatBeepDbl3A(78)" ],
			[ [ ["beatPos", {28, 0}], ["ch", 10] ], "7BeatSwell1A" ],
			[ [ ["beatPos", {28, 0}], ["ch", 13] ], "7BeatPiano2A" ],
			"forceWrite",
			// m. 29
			[ [ ["beatPos", {29, 0}], ["ch", 0] ], "7BeatDrum2B" ],
			[ [ ["beatPos", {29, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5B" ],
			[ [ ["beatPos", {29, 0}], ["ch", 10] ], "7BeatSwell1B" ],
			[ [ ["beatPos", {29, 0}], ["ch", 13] ], "7BeatPiano2B" ],
			"forceWrite",
			// m. 30
			[ [ ["beatPos", {30, 0}], ["ch", 0] ], "7BeatDrum2C" ],
			[ [ ["beatPos", {30, 0}], ["ch", 8] ], "7BeatBeepDbl3A(44)" ],
			[ [ ["beatPos", {30, 0}], ["ch", 10] ], "7BeatSwell1C" ],
			[ [ ["beatPos", {30, 0}], ["ch", 13] ], "7BeatPiano2C" ],
			"forceWrite",
			// m. 31
			[ [ ["beatPos", {31, 0}], ["ch", 0] ], "4BeatDrum2A" ],
			[ [ ["beatPos", {31, 3.5}], ["ch", 8] ], "arpBeepDbl2" ],
			[ [ ["beatPos", {31, 0}], ["ch", 10] ], "7BeatSwell1D" ],
			[ [ ["beatPos", {31, 0}], ["ch", 13] ], "4BeatPiano3B" ],
			"forceWrite",
			// m. 32
			[ [ ["beatPos", {32, 0}], ["ch", 0] ], "7BeatDrum2A" ],
			[ [ ["beatPos", {32, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5A" ],
			[ [ ["beatPos", {32, 0}], ["ch", 8] ], "7BeatBeepDbl3B(78)" ],
			[ [ ["beatPos", {32, 0}], ["ch", 10], ["pitch", 12] ], "7BeatSwell1A" ],
			[ [ ["beatPos", {32, 0}], ["ch", 13] ], "7BeatPiano2A" ],
			"forceWrite",
			// m. 33
			[ [ ["beatPos", {33, 0}], ["ch", 0] ], "7BeatDrum2B" ],
			[ [ ["beatPos", {33, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5B" ],
			[ [ ["beatPos", {33, 0}], ["ch", 10], ["pitch", 12] ], "7BeatSwell1B" ],
			[ [ ["beatPos", {33, 0}], ["ch", 13] ], "7BeatPiano2B" ],
			"forceWrite",
			// m. 34
			[ [ ["beatPos", {34, 0}], ["ch", 0] ], "7BeatDrum2C" ],
			[ [ ["beatPos", {34, 0}], ["ch", 8] ], "7BeatBeepDbl3B(44)" ],
			[ [ ["beatPos", {34, 0}], ["ch", 10], ["pitch", 12] ], "7BeatSwell1C" ],
			[ [ ["beatPos", {34, 0}], ["ch", 13] ], "7BeatPiano2C" ],
			"forceWrite",
			// m. 35
			[ [ ["beatPos", {35, 0}], ["ch", 0] ], "4BeatDrum2B" ],
			[ [ ["beatPos", {35, 0}], ["ch", 10], ["pitch", 12] ], "7BeatSwell1D" ],
			[ [ ["beatPos", {35, 0}], ["ch", 13] ], "4BeatPiano3C" ],
			"forceWrite",
			// m. 36
			[ .beatPos = {36, 0}, .ch = 10, .func = "stopChannel" ],
			[ .beatPos = {36, 0}, .ch = 12, .func = "stopChannel" ],
			[ [ ["beatPos", {36, 0}], ["ch", 0] ], "7BeatDrum3A" ],
			[ [ ["beatPos", {36, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5A" ],
			[ [ ["beatPos", {36, 0}], ["ch", 8] ], "7BeatBeepDbl3A(78)" ],
			[ [ ["beatPos", {36, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3A" ],
			"forceWrite",
			// m. 37
			[ [ ["beatPos", {37, 0}], ["ch", 0] ], "7BeatDrum3A" ],
			[ [ ["beatPos", {37, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5B" ],
			[ [ ["beatPos", {37, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3B" ],
			"forceWrite",
			// m. 38
			[ [ ["beatPos", {38, 0}], ["ch", 0] ], "7BeatDrum3A" ],
			[ [ ["beatPos", {38, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass6A" ],
			[ [ ["beatPos", {38, 0}], ["ch", 8] ], "7BeatBeepDbl3A(44)" ],
			[ [ ["beatPos", {38, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3C" ],
			"forceWrite",
			// m. 39
			[ [ ["beatPos", {39, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {39, 0}], ["ch", 5] ], "4BeatBass6B" ],
			[ [ ["beatPos", {39, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3D" ],
			"forceWrite",
			// m. 40
			[ [ ["beatPos", {40, 0}], ["ch", 0] ], "7BeatDrum3A" ],
			[ [ ["beatPos", {40, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5A" ],
			[ [ ["beatPos", {40, 0}], ["ch", 7], ["vol", 0.25], ["pitch", 36], ["inst", "piano"] ], "7BeatBass5A" ], // Piano
			[ [ ["beatPos", {40, 0}], ["ch", 8] ], "7BeatBeepDbl3B(78)" ],
			[ [ ["beatPos", {40, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3A" ],
			"forceWrite",
			// m. 41
			[ [ ["beatPos", {41, 0}], ["ch", 0] ], "7BeatDrum3A" ],
			[ [ ["beatPos", {41, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass5B" ],
			[ [ ["beatPos", {41, 0}], ["ch", 7], ["vol", 0.25], ["pitch", 36], ["inst", "piano"] ], "7BeatBass5B" ],
			[ [ ["beatPos", {41, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3B" ],
			"forceWrite",
			// m. 42
			[ [ ["beatPos", {42, 0}], ["ch", 0] ], "7BeatDrum3A" ],
			[ [ ["beatPos", {42, 0}], ["ch", 5], ["inst", "bass"] ], "7BeatBass6A" ],
			[ [ ["beatPos", {42, 0}], ["ch", 7], ["vol", 0.25], ["pitch", 36], ["inst", "piano"] ], "7BeatBass6A" ],
			[ [ ["beatPos", {42, 0}], ["ch", 8] ], "7BeatBeepDbl3B(44)" ],
			[ [ ["beatPos", {42, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3C" ],
			"forceWrite",
			// m. 43
			[ [ ["beatPos", {43, 0}], ["ch", 0] ], "1mDrum1D" ],
			[ [ ["beatPos", {43, 0}], ["ch", 5] ], "4BeatBass6B" ],
			[ [ ["beatPos", {43, 0}], ["ch", 7], ["vol", 0.25] ], "4BeatPiano4" ],
			[ [ ["beatPos", {43, 0}], ["ch", 13], ["vol", -0.3] ], "7BeatLeadDbl3D" ],
			"forceWrite",
			// m. 44
			[ [ ["beatPos", {44, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {44, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {44, 0}], ["ch", 8] ], "4BeatBeepDbl3C" ],
			"forceWrite",
			// m. 45
			[ [ ["beatPos", {45, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {45, 0}], ["ch", 5], ["pitch", "bb2"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {45, 0}], ["ch", 8] ], "4BeatBeepDbl3D" ],
			[ [ ["beatPos", {45, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "bb3"], ["inst", "lead"] ], "1mBass1A" ], // Lead
			"forceWrite",
			// m. 46
			[ [ ["beatPos", {46, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {46, 0}], ["ch", 5], ["inst", "bass"] ], "1mBass1C" ],
			[ [ ["beatPos", {46, 0}], ["ch", 7], ["vol", 0.5], ["pitch", "bb4"], ["inst", "piano"] ], "1mBass1A" ], // Piano
			[ [ ["beatPos", {46, 0}], ["ch", 8] ], "4BeatBeepDbl3C" ],
			[ [ ["beatPos", {46, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "bb3"], ["inst", "lead"] ], "1mBass1B" ], // Lead
			"forceWrite",
			// m. 47
			[ [ ["beatPos", {47, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {47, 0}], ["ch", 5], ["inst", "bass"] ], "1mBass7D" ],
			[ [ ["beatPos", {47, 0}], ["ch", 7], ["vol", 0.5], ["pitch", "bb4"], ["inst", "piano"] ], "1mBass1B" ], // Piano
			[ [ ["beatPos", {47, 0}], ["ch", 8] ], "4BeatBeepDbl3D" ],
			[ [ ["beatPos", {47, 0}], ["ch", 13], ["vol", 0.1], ["pitch", 12], ["inst", "lead"] ], "1mBass1C" ], // Lead
			"forceWrite",
			// m. 48
			[ [ ["beatPos", {48, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {48, 0}], ["ch", 5], ["pitch", "g3"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {48, 0}], ["ch", 7], ["vol", 0.5], ["pitch", 24], ["inst", "piano"] ], "1mBass1C" ], // Piano
			[ [ ["beatPos", {48, 0}], ["ch", 8] ], "4BeatBeepDbl3E" ],
			[ [ ["beatPos", {48, 0}], ["ch", 13], ["vol", 0.1], ["pitch", 12], ["inst", "lead"] ], "1mBass7D" ], // Lead
			"forceWrite",
			// m. 49
			[ [ ["beatPos", {49, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {49, 0}], ["ch", 5], ["pitch", "g3"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {49, 0}], ["ch", 7], ["vol", 0.5], ["pitch", 24], ["inst", "piano"] ], "1mBass7D" ], // Piano
			[ [ ["beatPos", {49, 0}], ["ch", 8] ], "4BeatBeepDbl3F" ],
			[ [ ["beatPos", {49, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "g4"], ["inst", "lead"] ], "1mBass1A" ], // Lead
			"forceWrite",
			// m. 50
			[ [ ["beatPos", {50, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {50, 0}], ["ch", 5], ["pitch", "e3"], ["inst", "bass"] ], "1mBass2C" ],
			[ [ ["beatPos", {50, 0}], ["ch", 7], ["vol", 0.5], ["pitch", "g5"], ["inst", "piano"] ], "1mBass1A" ], // Piano
			[ [ ["beatPos", {50, 0}], ["ch", 8] ], "4BeatBeepDbl3G" ],
			[ [ ["beatPos", {50, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "g4"], ["inst", "lead"] ], "1mBass1B" ], // Lead
			"forceWrite",
			// m. 51
			[ [ ["beatPos", {51, 0}], ["ch", 0] ], "7BeatDrum3B" ],
			[ [ ["beatPos", {51, 0}], ["ch", 5] ], "7BeatBass7C" ],
			[ [ ["beatPos", {51, 0}], ["ch", 7], ["vol", 0.5] ], "7BeatBass7C" ], // Piano, doesn't need inst param because only note off
			[ [ ["beatPos", {51, 0}], ["ch", 8] ], "7BeatBeepDbl3H" ],
			[ [ ["beatPos", {51, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "e4"], ["inst", "lead"] ], "1mBass2C(Lead)" ], // Lead
			"forceWrite",
			// m. 52
			[ [ ["beatPos", {52, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {52, 0}], ["ch", 5], ["pitch", "bb3"], ["inst", "bass"] ], "1mBass8A" ],
			[ [ ["beatPos", {52, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1A" ],
			[ [ ["beatPos", {52, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1A" ],
			// Note off for lead?
			"forceWrite",
			// m. 53
			[ [ ["beatPos", {53, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {53, 0}], ["ch", 5], ["inst", "bass"] ], "1mBass8B" ],
			[ [ ["beatPos", {53, 0}], ["ch", 8] ], "4BeatBeepDbl3C" ],
			[ [ ["beatPos", {53, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1Bb" ],
			[ [ ["beatPos", {53, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1Bb" ],
			[ [ ["beatPos", {53, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "bb4"], ["inst", "lead"] ], "1mBass8A" ], // Lead
			"forceWrite",
			// m. 54
			[ [ ["beatPos", {54, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {54, 0}], ["ch", 5], ["pitch", "f3"], ["inst", "bass"] ], "1mBass8A" ],
			[ [ ["beatPos", {54, 0}], ["ch", 7], ["vol", 0.5], ["pitch", "bb5"], ["inst", "piano"] ], "1mBass8A" ], // Piano
			[ [ ["beatPos", {54, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {54, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {54, 0}], ["ch", 13], ["vol", 0.1], ["pitch", 12], ["inst", "lead"] ], "1mBass8B" ], // Lead
			"forceWrite",
			// m. 55
			[ [ ["beatPos", {55, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {55, 0}], ["ch", 5] ], "1mBass3D" ],
			[ [ ["beatPos", {55, 0}], ["ch", 7], ["vol", 0.5], ["pitch", 24], ["inst", "piano"] ], "1mBass8B" ], // Piano
			[ [ ["beatPos", {55, 0}], ["ch", 8] ], "4BeatBeepDbl3C" ],
			[ [ ["beatPos", {55, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "f4"], ["inst", "lead"] ], "1mBass8A" ], // Lead
			"forceWrite",
			// m. 56
			[ [ ["beatPos", {56, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {56, 0}], ["ch", 5], ["inst", "bass"] ], "1mBass9A" ],
			[ [ ["beatPos", {56, 0}], ["ch", 7], ["vol", 0.5], ["pitch", "f5"], ["inst", "piano"] ], "1mBass8A" ], // Piano
			[ [ ["beatPos", {56, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1A" ],
			[ [ ["beatPos", {56, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1A" ],
			[ [ ["beatPos", {56, 0}], ["ch", 13], ["vol", 0.1], ["pitch", 12] ], "1mBass3D" ], // Lead, doesn't need inst param because only note off
			"forceWrite",
			// m. 57
			[ [ ["beatPos", {57, 0}], ["ch", 0] ], "1mDrum1B" ],
			[ [ ["beatPos", {57, 0}], ["ch", 5], ["inst", "bass"] ], "1mBass9B" ],
			[ [ ["beatPos", {57, 0}], ["ch", 7], ["vol", 0.5], ["pitch", 24] ], "1mBass3D" ], // Piano
			[ [ ["beatPos", {57, 0}], ["ch", 8] ], "4BeatBeepDbl3C" ],
			[ [ ["beatPos", {57, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1Bb" ],
			[ [ ["beatPos", {57, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1Bb" ],
			[ [ ["beatPos", {57, 0}], ["ch", 13], ["pitch", 12], ["vol", -0.3], ["inst", "lead"] ], "1mBass9A" ], // Lead
			"forceWrite",
			// m. 58
			[ [ ["beatPos", {58, 0}], ["ch", 0] ], "1mDrum1A" ],
			[ [ ["beatPos", {58, 0}], ["ch", 5], ["pitch", "f3"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {58, 0}], ["ch", 7], ["vol", 0.5], ["pitch", 24], ["inst", "piano"] ], "1mBass9A" ], // Piano
			[ [ ["beatPos", {58, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {58, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {58, 0}], ["ch", 13], ["vol", 0.1], ["pitch", 12], ["inst", "lead"] ], "1mBass9B" ], // Lead
			"forceWrite",
			// m. 59
			[ [ ["beatPos", {59, 0}], ["ch", 0] ], "7BeatDrum3C" ],
			[ [ ["beatPos", {59, 0}], ["ch", 5] ], "7BeatBass7C" ],
			[ [ ["beatPos", {59, 0}], ["ch", 7], ["vol", 0.5], ["pitch", 24], ["inst", "piano"] ], "1mBass9B(Piano)" ], // Piano
			[ [ ["beatPos", {59, 0}], ["ch", 8] ], "7BeatBeepDbl3I" ],
			[ [ ["beatPos", {59, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "f4"], ["inst", "lead"] ], "1mBass1A(Lead)" ], // Lead
			"forceWrite",
			// m. 60
			[ [ ["beatPos", {60, 0}], ["ch", 0] ], "4BeatDrum4A" ],
			[ [ ["beatPos", {60, 0}], ["ch", 5], ["pitch", "bb3"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {60, 0}], ["ch", 7], ["vol", 0], ["pitch", "bb5"], ["inst", "piano"] ], "1mBass1A" ], // Piano
			[ [ ["beatPos", {60, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1A" ],
			[ [ ["beatPos", {60, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1A" ],
			[ [ ["beatPos", {60, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "bb4"], ["inst", "lead"] ], "1mBass1A" ], // Lead
			"forceWrite",
			// m. 61
			[ [ ["beatPos", {61, 0}], ["ch", 0] ], "4BeatDrum4A" ],
			[ [ ["beatPos", {61, 0}], ["ch", 5], ["pitch", "bb3"], ["inst", "bass"] ], "1mBass1B" ],
			[ [ ["beatPos", {61, 0}], ["ch", 7], ["vol", 0], ["pitch", "bb5"], ["inst", "piano"] ], "1mBass1B" ], // Piano
			[ [ ["beatPos", {61, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "bb4"], ["inst", "lead"] ], "1mBass1B" ], // Lead
			"forceWrite",
			// m. 62
			[ [ ["beatPos", {62, 0}], ["ch", 0] ], "4BeatDrum4A" ],
			[ [ ["beatPos", {62, 0}], ["ch", 5], ["pitch", "f3"], ["inst", "bass"] ], "1mBass1A" ],
			[ [ ["beatPos", {62, 0}], ["ch", 7], ["vol", -0.5], ["pitch", "f6"], ["inst", "piano"] ], "1mBass1A" ], // Piano
			[ [ ["beatPos", {62, 0}], ["ch", 10], ["vol", 0.75], ["pan", 0.55], ["inst", "swellShort"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {62, 0}], ["ch", 11], ["vol", 0.75], ["pan", 0.85], ["pitch", 12], ["inst", "swellShort"] ], "1mLead1Ba" ],
			[ [ ["beatPos", {62, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "f4"], ["inst", "lead"] ], "1mBass1A" ], // Lead
			"forceWrite",
			// m. 63
			[ [ ["beatPos", {63, 0}], ["ch", 0] ], "4BeatDrum4A" ],
			[ [ ["beatPos", {63, 0}], ["ch", 5] ], "1mBass3D" ],
			[ [ ["beatPos", {63, 0}], ["ch", 7], ["vol", -0.5] ], "1mBass3D" ], // Piano
			[ [ ["beatPos", {63, 0}], ["ch", 13], ["vol", 0.1] ], "1mBass3D" ], // Lead
			"forceWrite",
			// m. 64
			[ [ ["beatPos", {64, 0}], ["ch", 0] ], "4BeatDrum4A" ],
			[ [ ["beatPos", {64, 0}], ["ch", 8], ["vol", 0.75], ["pan", 0], ["inst", "beep"] ], "1mLead1A" ],
			[ [ ["beatPos", {64, 0}], ["ch", 9], ["vol", 0.75], ["pan", 1], ["pitch", -5], ["inst", "beep"] ], "1mLead1A" ],
			[ [ ["beatPos", {64, 0}], ["ch", 10], ["pan", 0.55], ["pitch", "db3"], ["inst", "swellShort"] ], "1mBass1A" ], // Swell
			[ [ ["beatPos", {64, 0}], ["ch", 13], ["vol", 0.1], ["pitch", "db4"], ["inst", "lead"] ], "1mBass1A" ], // Lead
			"forceWrite",
			// m. 65
			[ [ ["beatPos", {65, 0}], ["ch", 0] ], "4BeatDrum4A" ],
			[ [ ["beatPos", {65, 0}], ["ch", 10], ["pan", 0.55], ["pitch", "db4"], ["inst", "swellShort"] ], "1mBass3D" ], // Swell
			[ [ ["beatPos", {65, 0}], ["ch", 13], ["vol", 0.1], ["inst", "lead"] ], "1mBass3D" ], // Lead
			"forceWrite",
			// m. 66
			[ [ ["beatPos", {66, 0}], ["ch", 0] ], "4BeatDrum4A" ],
			[ [ ["beatPos", {66, 0}], ["ch", 8], ["vol", 0.75], ["pitch", "c6"], ["pan", -0.5], ["inst", "beep"] ], "1mBass1A" ],
			[ [ ["beatPos", {66, 0}], ["ch", 9], ["vol", 0.75], ["pan", 0.5], ["pitch", "g5"], ["inst", "beep"] ], "1mBass1A" ],
			"forceWrite",
			// m. 67
			[ [ ["beatPos", {67, 0}], ["ch", 0] ], "4BeatDrum4B" ],
			[ [ ["beatPos", {67, 0}], ["ch", 8] ], "1mBass3D" ],
			[ [ ["beatPos", {67, 3.5}], ["ch", 8] ], "arpBeepDbl2" ],
			"forceWrite"
		]
	]
	
	// ----------------------------------------------------------------
	// SAMPLES
	var samples = [
		"Gijs De Mik/FX_Retro_Car_02", // 0 Bass
		"Gijs De Mik/FX_BombDrop_01", // 1 Tom
		"Gijs De Mik/FX_Laser_15", // 2 Snare
		"Gijs De Mik/FX_Laser_32", // 3 Kick
		"Gijs De Mik/FX_Misc_12", // 4 Piano
		"Gijs De Mik/FX_Misc_35" // 5 Lead
	]
	
	// ----------------------------------------------------------------
	// TEMPO MAP
	var tempoMap = [
		[
			.beatPos = {0, 0}, // Measure, beat
			.bpm = 116,
			.timeSig = 4
		],
		[
			.beatPos = {24, 0},
			.bpm = 232,
			.timeSig = 7
		],
		[
			.beatPos = {27, 0},
			.bpm = 116,
			.timeSig = 4
		],
		[
			.beatPos = {28, 0},
			.bpm = 232,
			.timeSig = 7
		],
		[
			.beatPos = {31, 0},
			.bpm = 116,
			.timeSig = 4
		],
		[
			.beatPos = {32, 0},
			.bpm = 232,
			.timeSig = 7
		],
		[
			.beatPos = {35, 0},
			.bpm = 116,
			.timeSig = 4
		],
		[
			.beatPos = {36, 0},
			.bpm = 232,
			.timeSig = 7
		],
		[
			.beatPos = {39, 0},
			.bpm = 116,
			.timeSig = 4
		],
		[
			.beatPos = {40, 0},
			.bpm = 232,
			.timeSig = 7
		],
		[
			.beatPos = {43, 0},
			.bpm = 116,
			.timeSig = 4
		],
		[
			.beatPos = {51, 0},
			.bpm = 232,
			.timeSig = 7
		],
		[
			.beatPos = {52, 0},
			.bpm = 116,
			.timeSig = 4
		],
		[
			.beatPos = {59, 0},
			.bpm = 232,
			.timeSig = 7
		],
		[
			.beatPos = {60, 0},
			.bpm = 116,
			.timeSig = 4
		]
	]
	
	var result = [
		.clips = audioClips,
		.samples = samples,
		.tempoMap = tempoMap
	]
return result

// UNCOMMENT THIS LINE TO REASSEMBLE THE MUSIC DATA AND SAVE IT TO THE TEXT FILE
//assembleAudioSequence("Rule of Six", "MusicTrack", buildAudio())

var g_file = open()

// UNCOMMENT THESE LINES TO DELETE THE MUSIC DATA SAVED IN THE TEXT FILE
//deleteAudioSequence("MusicTrack")
//close(g_file)

// UNCOMMENT THIS LINE TO VIEW THE MUSIC DATA SAVED IN THE TEXT FILE
//debugFile(g_file)

var g_queue = initAudioQueue("MusicTrack", g_file)

// ----------------------------------------------------------------
// MAIN LOOP

loop
	streamAudioQueue(g_queue, g_file)
	visualizeAudioEvents(g_queue.lastAudio)
repeat

// ----------------------------------------------------------------
// AUDIO ENGINE

	// ----------------------------------------------------------------
	// PUBLIC FUNCTIONS

// Saves an audio clip defined in buildAudio() to the text file for future streaming.
function assembleAudioSequence(_clipName, _saveAsName, _buildResult)
return assembleAudioSequence(_clipName, _saveAsName, _buildResult, true)

function assembleAudioSequence(_clipName, _saveAsName, _buildResult, _cullRepeatedEvents)
	textSize(gheight() * 0.05)
	clear()
	printAt(0, 0, "Loading assembler ...")
	update()
	
	var file = open()
	var fileInsertIdx = -1
	var spool = getAudioClipByName(_buildResult.clips, _clipName)
	var idx = 2
	var spoolLegend  = [ [ .params = spool[1], .len = len(spool) - 2 ] ]
	var timer = time()
	var queue = []
	var lastClipValues = []
	var lastClipRemaining = 0
	var totalPruned = 0
	var totalCulled = 0
	var totalEvents = 0
	var elapsed = 0
	
	// Defaults for when a previous event doesn't exist
	var recent = [
		.lastFunc = "playNote",
		.lastCh = 0,
		.lastBeatPos = {0, 0},
		.lastTimePos = 0,
		.playAudio = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "playAudio", .arg = [ -1, 1, 0.5, 1, -1 ] ],
		.playNote = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "playNote", .arg = [ 3, 440, 1, 25, 0.5 ] ],
		.setClipper = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "setClipper", .arg = [ 1, 50 ] ],
		.setEnvelope = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "setEnvelope", .arg = [ 0, 25 ] ],
		.setFilter = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "setFilter", .arg = [ 0, 1000 ] ],
		.setFrequency = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "setFrequency", .arg = [ 440 ] ],
		.setModulator = [ .beatPos = {0, 0}, .timePos = 0.00, .ch = 0, .func = "setModulator", .arg = [ 3, 5, 1 ] ],
		.setPan = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "setPan", .arg = [ 0.5 ] ],
		.setReverb = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "setReverb", .arg = [ 60, 1 ] ],
		.setVolume = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "setVolume", .arg = [ 1 ] ],
		.startChannel = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "startChannel", .arg = [] ],
		.stopChannel = [ .beatPos = {0, 0}, .timePos = 0.0, .ch = 0, .func = "stopChannel", .arg = [] ]
	]
	
	var lastEventTime = -1
	
	writeTempoMap(_saveAsName, file, _buildResult.tempoMap, true)
	writeSamples(_saveAsName, file, _buildResult.samples, false)
	
	while idx < len(spool) loop
		var elemType = getType(spool[idx])
		if elemType == "array" then
			var isHeader
			var legendAtIdx
			
			// Is this a parameter header?
			if getType(spool[idx][0][0]) != "array" then
				isHeader = true
				legendAtIdx = spool[idx]
			else
				isHeader = false
				legendAtIdx = spool[idx][0]
			endif
			
			var i
			var j
			
			// Apply current spoolLegend to new spoolLegend
			var spoolLegendEndIdx = len(spoolLegend) - 1
			var legendResult = combineLegends(spoolLegend[spoolLegendEndIdx], legendAtIdx, _buildResult.tempoMap)
			
			spoolLegend[spoolLegendEndIdx] = legendResult.old
			legendAtIdx = legendResult.new
			
			if isHeader then
				spoolLegend = push(spoolLegend, [ .params = spool[idx][0], .len = len(subArr) - 1 ])
			else
				// Special case: parameter used to select audio clip
				if getType(spool[idx][1]) == "array" then
					var found = false
					var instHeader = legendResult.old.params
					
					var i
					for i = 0 to len(instHeader) loop
						if instHeader[i][0] == spool[idx][1][0] then
							spool[idx][1] = instHeader[i][1]
							found = true
						endif
					repeat
					
					if !found then
						debugPrint(999, [spool[idx][1][1] + " isn't a valid audio clip."])
					endif
				endif
				
				var subArr = getAudioClipByName(_buildResult.clips, spool[idx][1])
				subArr = remove(subArr, 0) // Remove subArr's name entry
				
				legendResult = combineLegends([ .params = legendAtIdx, .len = 0 ], subArr[0], _buildResult.tempoMap) // Apply subArr's header
				spoolLegend = push(spoolLegend, [ .params = legendResult.new, .len = len(subArr) - 1 ])
				
				spool = remove(spool, idx) // Remove reference entry
				spool = insertArray(spool, subArr, idx) // Don't include header from subArr
				
				// Cull old spool entries occasionally to prevent reaching variable limit
				if idx > 100 then
					spool = splitEndOnly(spool, idx)
					idx = 0
				endif
			endif
		else if elemType == "struct" then
			var parsedResult = parseSndData(spool[idx], recent, spoolLegend[len(spoolLegend) - 1].params, _buildResult.samples, 
				_buildResult.tempoMap, -1, -1)
			var parsed = parsedResult.parsed
			recent = parsedResult.recent
			
			var queueStartIdx = len(queue) - 1
			var i
			for i = 0 to len(parsed) loop
				var queueResult
				
				if i == 0 then
					queueResult = addFirstQueuedSnd(parsed[i], queue, _buildResult.tempoMap)
					totalPruned += queueResult.pruned
					queue = queueResult.queue
					
					if queueResult.pruned then
						array cleanQueue[len(queue) - queueResult.pruned]
						var cleanIdx = 0
						
						var j
						for j = 0 to len(queue) loop
							if getType(queue[j]) == "struct" then
								cleanQueue[cleanIdx] = queue[j]
								cleanIdx += 1
							endif
						repeat
						
						queue = cleanQueue
					endif
				else
					queueResult = addAdditionalQueuedSnd(parsed[i], queue, queueStartIdx, _buildResult.tempoMap)
					queue = queueResult.queue
				endif
				
				queueStartIdx = queueResult.idx
				lastEventTime = getTimeFromTempoMap(_buildResult.tempoMap, parsed[i].beatPos) + parsed[i].timePos
			repeat
			
			spoolLegend[len(spoolLegend) - 1].len -= 1
		else // String
			if str(spool[idx]) == "forceWrite" then
				var split = split(queue, floor(lastClipRemaining + (len(queue) - lastClipRemaining) / 2))
				
				var cullResult = updateLastClipValues(split[0], lastClipValues, _cullRepeatedEvents)
				split[0] = cullResult.queue
				lastClipValues = cullResult.lastClipValues
				totalCulled += cullResult.culled
				
				fileInsertIdx = writeAudioSequence(_saveAsName, file, split[0], fileInsertIdx, false)
				totalEvents += len(split[0])
				lastClipRemaining = len(split[1])
				queue = split[1]
				
				spoolLegend[len(spoolLegend) - 1].len -= 1
			endif
		endif endif
		
		// If we've passed the entries this spoolLegend applies to, remove it
		if len(spoolLegend) then
			while spoolLegend[len(spoolLegend) - 1].len <= 0 loop
				spoolLegend = remove(spoolLegend, len(spoolLegend) - 1)
				
				if !len(spoolLegend) then break endif
			repeat
		endif
		
		idx += 1
		
		if time() >= timer + 0.1 then
			elapsed += time() - timer
			var prog = len(str(split(spool, idx + 1)[0]))
			clear()
			var sec = str(elapsed % 60)
			
			if len(sec) == 1 then
				sec = "0" + sec
			endif
			
			printAt(0, 0, "Assembling audio data. This may take a while.")
			printAt(0, 2, "Elapsed: " + int(elapsed / 60) + ":" + sec)
			if len(queue) then
				printAt(0, 3, "Event: " + recent.lastFunc)
				printAt(0, 4, "Beat position: " + str(recent.lastBeatPos))
				printAt(0, 5, "Channel: " + str(recent.lastCh))
				printAt(0, 6, "Sort buffer length: " + len(queue))
			endif
			timer = time()
			update()
		endif
	repeat
	
	if len(queue) then
		var cullResult = updateLastClipValues(queue, lastClipValues, _cullRepeatedEvents)
		queue = cullResult.queue
		writeAudioSequence(_saveAsName, file, queue, fileInsertIdx, false)
		totalCulled += cullResult.culled
		totalEvents += len(queue)
	endif
	
	var sec = str(elapsed % 60)
	if len(sec) == 1 then
		sec = "0" + sec
	endif
	
	close(file)
	
	playNote(0, 3, note2Freq(84), 0.5, 15, 0.5)
	debugPrint(0, ["Audio assembly finished in " + int(elapsed / 60) + ":" + sec + "." + chr(10),
		"Audio events written: " + totalEvents,
		"Duplicate audio events pruned: " + totalPruned,
		"Repeated audio events culled: " + totalCulled])
return void

// Reads data incrementally from the text file and plays audio events that
// are due. Info about position in the file is retained within _queue.
function streamAudioQueue(ref _queue, _file)
	_queue.queueDeferCount = 0
	_queue.lastAudio = []
	var loadTimer = time()
	
	if _queue.pauseTime < 0 and _queue.endedTime < 0 then
		if _queue.queueIdx >= len(_queue.queue) and _queue.queueDeferCount <= _queue.queueDeferLimit then
			while _queue.queueIdx >= len(_queue.queue) and _queue.queueDeferCount <= _queue.queueDeferLimit loop
				// If start time hasn't been set, default to current time
				if _queue.startTime == float_min then
					_queue.startTime = time()
				endif
				
				var streamResult = streamAudioSequence(_queue, _file, 10)
				
				_queue = streamResult.queue
				var newQueueElems = streamResult.elems
				
				_queue.queue = newQueueElems
				_queue.queueIdx = 0
				
				var updateResult = updateSndQueue(_queue)
				_queue.lastAudio = insertArray(_queue.lastAudio, updateResult)
				
				_queue.queueDeferCount += 1
			repeat
		else
			_queue.lastAudio = updateSndQueue(_queue)
		endif
	else
		if _queue.endedTime >= 0 and _queue.pauseTime < 0 then
			if time() - _queue.endedTime >= _queue.loopTail and (_queue.loopIdx < _queue.loops or _queue.loops < 0)then
				_queue.loopIdx += 1
				reinitAudioQueue(_queue, _file)
				
				if _queue.loopStartTime > 0 then
					_queue = seekPosInAudioSequence(_queue, _file, _queue.loopStartTime)
				endif
			endif
		endif
	endif
return _queue

// Initializes the audio streaming queue that streamAudioQueue() will read data
// into.
function initAudioQueue(_name, _file)
return initAudioQueue(_name, _file, 0, 1)

function initAudioQueue(_name, _file, _timeOffset)
return initAudioQueue(_name, _file, _timeOffset, 1)

function initAudioQueue(_name, _file, _timeOffset, _deferLimit)
	var audioQueue = [
		.fileDat = [ .section = -1, .block = [ .idx = -1 ], .unit = -1, .field = -1, .elem = -1 ],
		.queue = [],
		.queueIdx = 0,
		.lastAudio = [],
		.playheadOffset = _timeOffset,
		.queueDeferLimit = 1,
		.queueDeferCount = 0,
		.tempoMap = readTempoMap(_name, _file),
		.samples = readSamples(_name, _file),
		.name = _name,
		.startTime = float_min,
		.pauseTime = -1,
		.pauseStopCh = [],
		.endedTime = -1,
		.loops = 0,
		.loopTail = 0,
		.loopIdx = 0,
		.loopStartTime = 0
	]
	
	var i
	for i = 0 to len(audioQueue.samples) loop
		audioQueue.samples[i] = loadAudio(audioQueue.samples[i])
	repeat
return audioQueue

// Reinitializes the audio queue. This resets the queue so that playback will begin from
// the start of the audio sequence but does not reload samples or reset the loop counter.
function reinitAudioQueue(ref _queue, _file)
return reinitAudioQueue(_queue, _file, _queue.playheadOffsset)

function reinitAudioQueue(ref _queue, _file, _timeOffset)
	_queue.fileDat = [ .section = -1, .block = [ .idx = -1 ], .unit = -1, .field = -1, .elem = -1 ]
	_queue.queue = []
	_queue.queueIdx = 0
	_queue.lastAudio = []
	_queue.playheadOffset = _timeOffset
	_queue.queueDeferCount = 0
	_queue.startTime = float_min
	_queue.pauseTime = -1
	_queue.pauseStopCh = []
	_queue.endedTime = -1
return _queue

// Defines the loop behavior of the audio queue. By default, the audio sequence does not loop.
// _loops sets how many times to loop (-1 is infinite).
// _loopTail (default 0) is how long in seconds after the final event to wait before looping.
// _loopStartTime (default 0) is the position in the sequnce in seconds where the loop should begin. Added to
// 	the beat time of the loop start if both are present.
// _loopStartBeat (default {0, 0}) is the position in the sequnce in measures/beats where the loop should begin.
function setAudioQueueLoop(ref _queue, _loops)
return setAudioQueueLoop(_queue, _loops, 0, -1, {-1, -1})

function setAudioQueueLoop(ref _queue, _loops, _loopTail)
return setAudioQueueLoop(_queue, _loops, _loopTail, -1, {-1, -1})

function setAudioQueueLoop(ref _queue, _loops, _loopTail, _loopStartTime)
return setAudioQueueLoop(_queue, _loops, _loopTail, _loopStartTime, {-1, -1})

function setAudioQueueLoop(ref _queue, _loops, _loopTail, _loopStartTime, _loopStartBeat)
	_queue.loops = _loops
	_queue.loopTail = _loopTail
	_queue.loopIdx = 0
	
	if _loopStartBeat.x >= 0 and _loopStartBeat.y >= 0 then
		if _loopStartTime < 0 then
			_loopStartTime = 0
		endif
		
		_loopStartTime += getTimeFromTempoMap(_queue.tempoMap, _loopStartBeat, 0)
		_loopStartTime = max(_loopStartTime, 0)
	endif
		
	if _loopStartTime >= 0 then
		_queue.loopStartTime = _loopStartTime
	endif
return _queue
	
// Sets the tiime that the sequence shouuld begin playing.
function setAudioQueueStartTime(ref _queue, _startTime)
	_queue.startTime = _startTime
return _queue

// Pauses playback of the audio sequence. _stopCh is an optional array for channels on 
// which stopChannel() should be called in order to hard-cut audio.
function pauseAudioQueue(ref _queue)
return pauseAudioQueue(_queue, [])

function pauseAudioQueue(ref _queue, _stopCh)
	if _queue.pauseTime < 0 then
		_queue.pauseTime = time()
	endif
	
	var i
	for i = 0 to len(_stopCh) loop
		stopChannel(_stopCh[i])
	repeat
	
	_queue.pauseStopCh = _stopCh
return _queue

// Resumes paused playback. _restartCh is an array of channels to call startChannel() on. 
// Usually the same as pauseAudioQueue()'s _stopCh
function unpauseAudioQueue(ref _queue)
return unpauseAudioQueue(_queue, [])

function unpauseAudioQueue(ref _queue, _restartCh)
	if _queue.pauseTime >= 0 then
		_queue.startTime += time() - _queue.pauseTime
		
		if _queue.endedTime >= 0 then
			_queue.endedTime += time() - _queue.pauseTime
		endif
		
		_queue.pauseTime = -1
		
		var i
		for i = 0 to len(_restartCh) loop
			startChannel(_restartCh[i])
		repeat
	endif
return _queue

// Jumps playback a time and/or beat position. If both time and beat are given, time 
// is added to beat. Events are not chased, so parameter state may be incorrect.
function seekPosInAudioSequence(_queue, _file, _jumpToTime)
return seekPosInAudioSequence(_queue, _file, _jumpToTime, {-1, -1})

function seekPosInAudioSequence(_queue, _file, _jumpToTime, _jumpToBeat)
	if _jumpToBeat.x >= 0 and _jumpToBeat.y >= 0 then
		if _jumpToTime < 0 then
			_jumpToTime = 0
		endif
		
		_jumpToTime += getTimeFromTempoMap(_queue.tempoMap, _jumpToBeat, 0)
		_jumpToTime = max(_jumpToTime, 0)
	endif
	
	var chunk
	
	var sectionIdx = findFileSection(_file, "audioSequence" + _queue.name)
	
	var seekStartIdx = findFileChunk(_file, blockStr("events"), [ chr(31) ], sectionIdx.start, sectionIdx.end).start
	var seekEndIdx = sectionIdx.end
	
	chunk = getNextFileChunk(_file, seekStartIdx)
	
	_queue.fileDat = [ .section = sectionIdx, .block = chunk, .unit = -1, .field = -1, .elem = -1 ]
	
	var halfIdx = seekStartIdx + floor((seekEndIdx - seekStartIdx) / 2)
	var unitIdx = findFileChar(_file, chr(30), halfIdx)
	var lastSeekIdx = -1
	
	var pos
	
	while unitIdx >= 0 and unitIdx <= sectionIdx.end loop
		chunk = getNextFileChunk(_file, unitIdx)
		
		if lastSeekIdx == chunk.idx then
			break
		else
			lastSeekIdx = chunk.idx
			_queue.fileDat.unit = chunk
		endif
		
		var field
		var fieldIdx = -1
		pos = [ .beatPos = {float_min, float_min}, .timePos = float_min ]
		
		while inFileUnit(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
			_queue.fileDat.field = chunk
			field = chunk.dat
			fieldIdx = chunk.idx
			
			array elem[0]
			while inFileField(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
				_queue.fileDat.elem = chunk
				
				elem = push(elem, chunk.dat)
			repeat
			
			loop if field == "b" then
				pos.beatPos = decodeElem(elem)
				break endif
			if field == "t" then
				pos.timePos = decodeElem(elem)
				break
			endif break repeat
		repeat
		
		if pos.timePos != float_min then
			if getTimeFromTempoMap(_queue.tempoMap, pos.beatPos, 0) + pos.timePos >= _jumpToTime then
				seekEndIdx = fieldIdx
				halfIdx = seekStartIdx + floor((seekEndIdx - seekStartIdx) / 2)
				unitIdx = findFileChar(_file, chr(30), halfIdx)
			else
				seekStartIdx = chunk.idx
				halfIdx = seekStartIdx + floor((seekEndIdx - seekStartIdx) / 2)
				unitIdx = findFileChar(_file, chr(30), halfIdx)
			endif
		endif
	repeat
	
	if _jumpToTime >= 0 then
		if _queue.startTime == float_min then _queue.startTime = 0 endif
		_queue.startTime -= _jumpToTime - time()
	endif
return _queue

// Jumps playback a time and/or beat position. If both time and beat are given, time 
// is added to beat. Events are chased, so parameter state will be correct, but the 
// chase process is very slow -- use seekPosInAudioSequence() instead when possible.
function chasePosInAudioSequence(_queue, _file, _jumpToTime)
return chasePosInAudioSequence(_queue, _file, _jumpToTime, {-1, -1})

function chasePosInAudioSequence(_queue, _file, _jumpToTime, _jumpToBeat)
	if _jumpToBeat.x >= 0 and _jumpToBeat.y >= 0 then
		if _jumpToTime < 0 then
			_jumpToTime = 0
		endif
		
		_jumpToTime += getTimeFromTempoMap(_queue.tempoMap, _jumpToBeat, 0)
		_jumpToTime = max(_jumpToTime, 0)
	endif
	
	var chunk
	var sectionIdx = findFileSection(_file, "audioSequence" + _queue.name)
	var chunkIdx = findFileChunk(_file, blockStr("events"), [ chr(31) ], sectionIdx.start, sectionIdx.end)
	chunk = getNextFileChunk(_file, chunkIdx.start)
	
	_queue.fileDat = [ .section = sectionIdx, .block = chunk, .unit = -1, .field = -1, .elem = -1 ]
	
	array sndGroup[0]
	var field
	
	while inFileBlock(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
		_queue.fileDat.unit = chunk
		
		var ch = -1
		var newSnd = [ .ch = -1, .beatPos = {0, 0}, .timePos = 0, .func = "", .arg = [] ]
		
		while inFileUnit(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
			_queue.fileDat.field = chunk
			field = chunk.dat
			
			array elem[0]
			while inFileField(chunk) loop
				
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
				_queue.fileDat.elem = chunk
				elem = push(elem, chunk.dat)
			repeat
			
			loop if field == "b" then
				newSnd.beatPos = decodeElem(elem)
				break endif
			if field == "t" then
				newSnd.timePos = decodeElem(elem)
				break endif
			if field == "c" then
				newSnd.ch = decodeElem(elem)
				break endif
			if field == "f" then
				newSnd.func = decodeElem(elem)
				break endif
			if field == "a" then
				newSnd.arg = decodeElem(elem)
				break
			endif break repeat
		repeat
		
		playQueuedSnd(newSnd, _queue.samples)
		stopChannel(newSnd.ch)
		
		if getTimeFromTempoMap(_queue.tempoMap, newSnd.beatPos, 0) + newSnd.timePos >= _jumpToTime then
			break
		endif
	repeat
	
	if _queue.startTime == float_min then _queue.startTime = 0 endif
	_queue.startTime -= _jumpToTime - time()
return _queue

	// ----------------------------------------------------------------
	// TEMPO MAP FUNCTIONS

// Returns true if _pos1 is before _pos2.
function measurePosBefore(_pos1, _pos2)
	var result = false
	
	if _pos1.x < _pos2.x or
			(_pos1.x == _pos2.x and _pos1.y < _pos2.y) or
			(_pos1.x == _pos2.x and _pos1.y == _pos2.y and _pos1.z < _pos2.z) then
		result = true
	endif
return result

// Returns true if _pos1 is before or equal to _pos2.
function measurePosBeforeOrEqual(_pos1, _pos2)
return _pos1 == _pos2 or measurePosBefore(_pos1, _pos2)

// Returns true if _pos1 is after _pos2.
function measurePosAfter(_pos1, _pos2)
	var result = false
	
	if _pos1.x > _pos2.x or
			(_pos1.x == _pos2.x and _pos1.y > _pos2.y) or
			(_pos1.x == _pos2.x and _pos1.y == _pos2.y and _pos1.z > _pos2.z) then
		result = true
	endif
return result

// Returns true if _pos1 is after or equal to _pos2.
function measurePosAfterOrEqual(_pos1, _pos2)
return _pos1 == _pos2 or measurePosAfter(_pos1, _pos2)

// Adds two measure/beat positions. Adds measures first, then combines beats and overflows them into 
// new measures based on tempo map.
function measurePosAdd(_tempoMap, _pos1, _pos2)
	var newPos = {0, 0}
	
	newPos.y = _pos1.y + _pos2.y
	newPos.x = _pos1.x + _pos2.x
	
	var sig = getTempoSigAtMeasurePos(_tempoMap, {newPos.x, 0}).sig
	
	while newPos.y >= sig loop
		newPos.y -= sig
		newPos.x += 1
		
		sig = getTempoSigAtMeasurePos(_tempoMap, {newPos.x, 0}).sig
	repeat
return newPos

// Subtracts one measure/beat position from another. Subtracts measures first, then combines beats and 
// overflows them into new measures based on tempo map.
function measurePosSubtract(_tempoMap, _pos1, _pos2)
	var newPos = {0, 0}
	
	newPos.y = _pos1.y - _pos2.y
	newPos.x = _pos1.x - _pos2.x
	
	var sig = getTempoSigAtMeasurePos(_tempoMap, {newPos.x - 1, 0}).sig
	
	while newPos.y < 0 loop
		newPos.y += sig
		newPos.x -= 1
		
		sig = getTempoSigAtMeasurePos(_tempoMap, {newPos.x - 1, 0}).sig
	repeat
return newPos

// Adds clock time to a measure/beat position. Adds measures first, then combines beats and overflows them into 
// new measures based on tempo map.
function measurePosAddTime(_tempoMap, _pos1, _dur)
	var newPos = {0, 0}
	var sig = getTempoSigAtMeasurePos(_tempoMap, {newPos.x, 0}).sig
	var startTime = getTimeFromTempoMap(_tempoMap, _pos1)
	var measDatEnd = getTempoSigAtTime(_tempoMap, startTime + _dur)
	var tempoStartTime = getTimeFromTempoMap(_tempoMap, _tempoMap[measDatEnd.idx].beatPos)
	var timeSpan
	
	if tempoStartTime > startTime then
		timeSpan = startTime + _dur - tempoStartTime
		_pos1 = _tempoMap[measDatEnd.idx].beatPos
	else
		timeSpan = startTime + _dur - startTime
	endif
	
	var beatSpan = timeSpan * (measDatEnd.bpm / 60)
	var newPos = measurePosAdd(_tempoMap, _pos1, {0, beatSpan})
return newPos

// Gets tempo and time signature at a given measure/beat position.
function getTempoSigAtMeasurePos(_tempoMap, _pos)
	var sig = 0
	var tempo = 0
	var idx = 0
	
	// We default to the first sig entry for any position that falls before the first sig
	if len(_tempoMap) then
		sig = _tempoMap[0].timeSig
		tempo = _tempoMap[0].bpm
	endif
	
	var i
	for i = 1 to len(_tempoMap) loop
		if measurePosBefore(_pos, _tempoMap[i].beatPos) then
			break
		else
			sig = _tempoMap[i].timeSig
			tempo = _tempoMap[i].bpm
			idx = i
		endif
	repeat
	
	var result = [
		.sig = sig,
		.bpm = tempo,
		.idx = idx
	]
return result

// Gets tempo and time signature at a given time.
function getTempoSigAtTime(_tempoMap, _time)
	var sig = 0
	var tempo = 0
	var idx = 0
	
	// We default to the first sig entry for any position that falls before the first sig
	if len(_tempoMap) then
		sig = _tempoMap[0].timeSig
		tempo = _tempoMap[0].bpm
	endif
	
	var i
	for i = 1 to len(_tempoMap) loop
		if _time < getTimeFromTempoMap(_tempoMap, _tempoMap[i].beatPos) then
			break
		else
			sig = _tempoMap[i].timeSig
			tempo = _tempoMap[i].bpm
			idx = i
		endif
	repeat
	
	var result = [
		.sig = sig,
		.bpm = tempo,
		.idx = idx
	]
return result

// Gets clock time at a given measure/beat position.
function getTimeFromTempoMap(_tempoMap, _pos)
return getTimeFromTempoMap(_tempoMap, _pos, 0)

function getTimeFromTempoMap(_tempoMap, _pos, _baseTime)
	var clockTime = 0
	var secPerBeat
	
	var i
	for i = 1 to len(_tempoMap) + 1 loop
		secPerBeat = 60 / _tempoMap[i - 1].bpm
		
		// ((Measure difference * beats in a measure) + beats into end measure - beats into start measure) * seconds per beat = clock length of segment
		if measurePosBefore(_pos, _tempoMap[min(i, len(_tempoMap) - 1)].beatPos) or i == len(_tempoMap) then
			clockTime += (_tempoMap[i - 1].timeSig * (_pos.x - _tempoMap[i - 1].beatPos.x) 
				+ _pos.y - _tempoMap[i - 1].beatPos.y) * secPerBeat
				
			break
		else if i > 0 then
			clockTime += (_tempoMap[i - 1].timeSig * (_tempoMap[i].beatPos.x - _tempoMap[i - 1].beatPos.x) 
				+ _tempoMap[i].beatPos.y - _tempoMap[i - 1].beatPos.y) * secPerBeat
		endif endif
	repeat
return clockTime + _baseTime

	// ----------------------------------------------------------------
	// ASSEMBLER

// Converts friendly pitch notation into MIDI pitch. C4 = middle C. Supports C0-B9.
function pitch2Midi(_pitch)
	_pitch = lower(_pitch)
	var midi = 0
	
	loop if _pitch[0] == "c" then midi = 0 break endif
	if _pitch[0] == "d" then midi = 2 break endif
	if _pitch[0] == "e" then midi = 4 break endif
	if _pitch[0] == "f" then midi = 5 break endif
	if _pitch[0] == "g" then midi = 7 break endif
	if _pitch[0] == "a" then midi = 9 break endif
	if _pitch[0] == "b" then midi = 11 break endif
	break repeat
	
	if len(_pitch) > 2 then
		if _pitch[1] == "#" then midi += 1
		else midi -= 1 endif
	endif
	
	midi += (int(_pitch[len(_pitch) - 1]) + 1) * 12
return midi

// Examines string data and converts it to MIDI pitch only if it represents pitch.
function toMidiIfNeeded(_paramVal)
	if len(_paramVal) > 1 and len(_paramVal) < 4 then
		var low = lower(_paramVal)
		
		if chrVal(low[0]) >= chrVal("a") and chrVal(low[0]) <= chrVal("g") then
			if len(low) == 2 then
				if int(low[1]) >= 0 and int(low[1]) <= 9 then
					_paramVal = pitch2Midi(_paramVal)
				endif
			else
				if (low[1] == "b" or low[1] == "#") and int(low[2]) >= 0 and int(low[2]) <= 9 then
					_paramVal = pitch2Midi(_paramVal)
				endif
			endif
		endif
	endif
return _paramVal

// Converts struct data from the audio event array into a format that can be easily fed to audio functions.
// Also generates the events for automated paraameters.
function parseSndData(_snd, _recent, _legend, _sampleArr, _tempoMap, _autoRate, _autoInterpType)
	_snd = encloseInArray(_snd)
	var timer = time()
	var strSnd
	var parsed = [
		.beatPos = 0,
		.timePos = 0,
		.ch = 0,
		.func = "",
		.arg = []
	]

	array parsedArr[len(_snd)]
	
	var i
	for i = 0 to len(parsedArr) loop
		parsedArr[i] = parsed
	repeat
	
	for i = 0 to len(parsedArr) loop
		strSnd = str(_snd[i])
		
		if strContains(strSnd, ".func = ") then
			parsedArr[i].func = _snd[i].func
		else
			parsedArr[i].func = _recent.lastFunc
		endif
			
		if !strContains(strSnd, "setAuto") then
			if strContains(strSnd, ".ch = ") then
				parsedArr[i].ch = parseExposedParam(_snd[i].ch, _legend, _tempoMap)
			else
				parsedArr[i].ch = _recent.lastCh
			endif
			
			if strContains(strSnd, ".beatPos = ") then
				parsedArr[i].beatPos = parseExposedParam(_snd[i].beatPos, _legend, _tempoMap)
			else
				parsedArr[i].beatPos = _recent.lastBeatPos
			endif
			
			if strContains(strSnd, ".timePos = ") then
				parsedArr[i].timePos = float(parseExposedParam(_snd[i].timePos, _legend, _tempoMap))
			else
				parsedArr[i].timePos = _recent.lastTimePos
			endif
		endif
		
		loop if parsedArr[i].func == "playAudio" then
			parsedArr[i].arg = [ -1, -1, -1, -1, -1 ]
			
			if strContains(strSnd, ".sampleIdx = ") then
				parsedArr[i].arg[0] = parseExposedParam(_snd[i].sampleIdx, _legend, _tempoMap)
			else
				parsedArr[i].arg[0] = _recent.playAudio.arg[0]
			endif
			
			if strContains(strSnd, ".vol = ") then
				parsedArr[i].arg[1] = parseExposedParam(_snd[i].vol, _legend, _tempoMap)
			else
				parsedArr[i].arg[1] = _recent.playAudio.arg[1]
			endif
			
			if strContains(strSnd, ".pan = ") then
				parsedArr[i].arg[2] = float(parseExposedParam(_snd[i].pan, _legend, _tempoMap))
			else
				parsedArr[i].arg[2] = _recent.playAudio.arg[2]
			endif
			
			if strContains(strSnd, ".loops = ") then
				parsedArr[i].arg[4] = parseExposedParam(_snd[i].loops, _legend, _tempoMap)
			else
				parsedArr[i].arg[4] = _recent.playAudio.arg[4]
			endif
			
			if strContains(strSnd, ".pitch = ") then
				var param = toMidiIfNeeded(parseExposedParam(_snd[i].pitch, _legend, _tempoMap))
				var root = 60 // Root is assumed to be C4 if unspecified
				
				if strContains(strSnd, ".root = ") then
					root = toMidiIfNeeded(_snd[i].root)
				endif
				
				parsedArr[i].arg[3] = getFactorFromRootDif(root, param)
			else if strContains(strSnd, ".spd = ") then
				parsedArr[i].arg[3] = float(parseExposedParam(_snd[i].spd, _legend, _tempoMap))
			else
				parsedArr[i].arg[3] = _recent.playAudio.arg[3]
			endif endif
			
			break endif
		if parsedArr[i].func == "playNote" then
			parsedArr[i].arg = [ -1, -1, -1, -1, -1 ]
			
			if strContains(strSnd, ".wave = ") then
				parsedArr[i].arg[0] = parseExposedParam(_snd[i].wave, _legend, _tempoMap)
			else
				parsedArr[i].arg[0] = _recent.playNote.arg[0]
			endif
			
			if strContains(strSnd, ".pitch = ") then
				var param = parseExposedParam(_snd[i].pitch, _legend, _tempoMap)
				
				parsedArr[i].arg[1] = note2Freq(toMidiIfNeeded(param))
			else
				if strContains(strSnd, ".freq = ") then
					parsedArr[i].arg[1] = float(parseExposedParam(_snd[i].freq, _legend, _tempoMap))
				else
					parsedArr[i].arg[1] = _recent.playNote.arg[1]
				endif
			endif
			
			if strContains(strSnd, ".vol = ") then
				parsedArr[i].arg[2] = float(parseExposedParam(_snd[i].vol, _legend, _tempoMap))
			else
				parsedArr[i].arg[2] = _recent.playNote.arg[2]
			endif
			
			if strContains(strSnd, ".spd = ") then
				parsedArr[i].arg[3] = float(parseExposedParam(_snd[i].spd, _legend, _tempoMap))
			else
				parsedArr[i].arg[3] = _recent.playNote.arg[3]
			endif
			
			if strContains(strSnd, ".pan = ") then
				parsedArr[i].arg[4] = float(parseExposedParam(_snd[i].pan, _legend, _tempoMap))
			else
				parsedArr[i].arg[4] = _recent.playNote.arg[4]
			endif
			
			break endif
		if parsedArr[i].func == "setClipper" then
			parsedArr[i].arg = [ -1, -1 ]
			
			if strContains(strSnd, ".thresh = ") then
				parsedArr[i].arg[0] = float(parseExposedParam(_snd[i].thresh, _legend, _tempoMap))
			else
				parsedArr[i].arg[0] = _recent.setClipper.arg[0]
			endif
			
			if strContains(strSnd, ".strength = ") then
				parsedArr[i].arg[1] = float(parseExposedParam(_snd[i].strength, _legend, _tempoMap))
			else
				parsedArr[i].arg[1] = _recent.setClipper.arg[1]
			endif
			
			break endif
		if parsedArr[i].func == "setEnvelope" then
			parsedArr[i].arg = [ -1 ]
			
			if strContains(strSnd, ".spd = ") then
				parsedArr[i].arg[0] = float(parseExposedParam(_snd[i].spd, _legend, _tempoMap))
			else
				parsedArr[i].arg[0] = _recent.setEnvelope.arg[0]
			endif
			
			break endif
		if parsedArr[i].func == "setFilter" then
			parsedArr[i].arg = [ -1, -1 ]
			
			if strContains(strSnd, ".type = ") then
				parsedArr[i].arg[0] = parseExposedParam(_snd[i].type, _legend, _tempoMap)
			else
				parsedArr[i].arg[0] = _recent.setFilter.arg[0]
			endif
			
			if strContains(strSnd, ".cutoff = ") then
				parsedArr[i].arg[1] = float(parseExposedParam(_snd[i].cutoff, _legend, _tempoMap))
			else
				parsedArr[i].arg[1] = _recent.setFilter.arg[1]
			endif
			
			break endif
		if parsedArr[i].func == "setFrequency" then
			parsedArr[i].arg = [ -1 ]
			
			if strContains(strSnd, ".freq = ") then
				parsedArr[i].arg[0] = float(parseExposedParam(_snd[i].freq, _legend, _tempoMap))
			else
				parsedArr[i].arg[0] = _recent.setFrequency.arg[0]
			endif
			
			break endif
		if parsedArr[i].func == "setModulator" then
			parsedArr[i].arg = [ -1, -1, -1 ]
			
			if strContains(strSnd, ".wave = ") then
				parsedArr[i].arg[0] = parseExposedParam(_snd[i].wave, _legend, _tempoMap)
			else
				parsedArr[i].arg[0] = _recent.setModulator.arg[0]
			endif
			
			if strContains(strSnd, ".freq = ") then
				parsedArr[i].arg[1] = float(parseExposedParam(_snd[i].freq, _legend, _tempoMap))
			else
				parsedArr[i].arg[1] = _recent.setModulator.arg[1]
			endif
			
			if strContains(strSnd, ".scale = ") then
				parsedArr[i].arg[2] = float(parseExposedParam(_snd[i].scale, _legend, _tempoMap))
			else
				parsedArr[i].arg[2] = _recent.setModulator.arg[2]
			endif
			
			break endif
		if parsedArr[i].func == "setPan" then
			parsedArr[i].arg = [ -1 ]
			
			if strContains(strSnd, ".pan = ") then
				parsedArr[i].arg[0] = float(parseExposedParam(_snd[i].pan, _legend, _tempoMap))
			else
				parsedArr[i].arg[0] = _recent.setPan.arg[0]
			endif
			
			break endif
		if parsedArr[i].func == "setReverb" then
			parsedArr[i].arg = [ -1, -1 ]
			
			if strContains(strSnd, ".delay = ") then
				parsedArr[i].arg[0] = float(parseExposedParam(_snd[i].delay, _legend, _tempoMap))
			else
				parsedArr[i].arg[0] = _recent.setReverb.arg[0]
			endif
			
			if strContains(strSnd, ".atten = ") then
				parsedArr[i].arg[1] = float(parseExposedParam(_snd[i].atten, _legend, _tempoMap))
			else
				parsedArr[i].arg[1] = _recent.setReverb.arg[1]
			endif
			
			break endif
		if parsedArr[i].func == "setVolume" then
			parsedArr[i].arg = [ -1 ]
			
			if strContains(strSnd, ".vol = ") then
				//debugPrint(0.1, 15, [_snd[i].vol, _legend])
				parsedArr[i].arg[0] = float(parseExposedParam(_snd[i].vol, _legend, _tempoMap))
			else
				parsedArr[i].arg[0] = _recent.setVolume.arg[0]
			endif
			
			break endif
		if parsedArr[i].func == "startChannel" or parsedArr[i].func == "stopChannel" then
			parsedArr[i].arg = []
			
			break endif
		if parsedArr[i].func == "setAuto" then
			var rate = 0.032
			var interpType = linear
			
			if strContains(strSnd, ".rate = ") then
				rate = _snd[i].rate
			endif
			
			if strContains(strSnd, ".interpType = ") then
				interpType = _snd[i].interpType
			endif
			
			if strContains(strSnd, ".events = ") then
				if len(_snd[i].events) >= 2 then
					var parsedResult = parseSndData([ _snd[i].events[0], _snd[i].events[1] ], _recent, _legend, _sampleArr, 
						_tempoMap, rate, interpType)
					parsedArr = parsedResult.parsed
					_recent = parsedResult.recent
				endif
			endif
			
			break
		endif break repeat
		
		_recent = updateRecentSnd(_recent, parsedArr[0]) // Update _recent so the automation end will use cached parameters from the automation start
	repeat
	
	// If more than one _snd entry, then we're setting automation
	if len(parsedArr) > 1 and !strContains(strSnd, "setAuto") then
		_autoRate = max(_autoRate, 0.0166)
		var startTimeBeat = getTimeFromTempoMap(_tempoMap, parsedArr[0].beatPos)
		var endTimeBeat = getTimeFromTempoMap(_tempoMap, parsedArr[1].beatPos)
		
		var startTime = startTimeBeat + parsedArr[0].timePos
		var endTime = endTimeBeat + parsedArr[1].timePos
		
		var rampParsed
		array autoArr[0]
		var i = startTime
		var j
		
		while i < endTime loop
			var interpVal = (i - startTime) / (endTime - startTime)
			rampParsed = parsedArr[0]
			
			for j = 0 to len(parsedArr[0].arg) loop
				rampParsed.arg[j] = interpolate(_autoInterpType, parsedArr[0].arg[j], parsedArr[1].arg[j], interpVal)
			repeat
			
			rampParsed.beatPos = measurePosAddTime(_tempoMap, parsedArr[0].beatPos, (endTimeBeat - startTimeBeat) * interpVal)
			rampParsed.timePos = (parsedArr[1].timePos - parsedArr[0].timePos) * interpVal
			
			autoArr = push(autoArr, rampParsed)
			
			i += _autoRate
		repeat
		
		parsedArr = autoArr
	endif
	
	result = [
		.parsed = parsedArr,
		.recent = _recent
	]
return result

// Gives us the value to multiply a frequency by to change a root pitch to a new pitch.
function getFactorFromRootDif(_root, _pitch)
	var dif = _pitch - _root
return pow(2, dif / 12)

// Applies accumulated parameter data from _legend to modify a parameter value.
function parseExposedParam(_param, _legend, _tempoMap)
	var val
	
	if getType(_param) == "array" then
		var paramIdx = findAtSubIdx(_legend, _param[0], 0)
		
		if paramIdx > -1 then
			_param[1] = toMidiIfNeeded(_param[1])
			_legend[paramIdx][1] = toMidiIfNeeded(_legend[paramIdx][1])
			
			if strBeginsWith(str(_param[1]), "{") then
				if _param[1].x < 0 or _param[1].y < 0 then
					val = measurePosSubtract(_tempoMap, _legend[paramIdx][1], _param[1])
				else
					val = measurePosAdd(_tempoMap, _legend[paramIdx][1], _param[1])
				endif
			else
				val = applyLegend(_legend[paramIdx][1], _param)
			endif
		else
			// User references a parameter that hasn't been defined
			val = 0
		endif
	else
		// Not an exposed parmeter; pass the literal value unchanged
		val = _param
	endif
return val

// Applies the legend in the way specified by the parametwr.
// If no modifier is given in _param[2], the operation is addition.
// If _param[2] is "*", multiplication.
// If _param[2] is "/", legend is divided by param.
// If _param[2] is anything else, param is divided by legend.
function applyLegend(_legendVal, _param)
	var val
	if len(_param) < 3 then
		val = _legendVal + _param[1]
	else
		if _param[2] == "*" then
			val = _legendVal * _param[1]
		else if _param[2] == "/" then
			val = _legendVal / _param[1]
		else
			val = _param[1] / _legendVal
		endif endif
	endif
return val

// Returns the array element whose first element matches _name.
function getAudioClipByName(_clips, _name)
	var result = []
	var found = false
	var i
	for i = 0 to len(_clips) loop
		if _clips[i][0] == _name then
			result = _clips[i]
			found = true
			break
		endif
	repeat
	
	if !found then
		debugPrint(9999, ["Audio clip '" + _name + "' not found"])
	endif
return result

// Applies a higher level set of exposed parameter values to a lower level one.
function combineLegends(_oldLegend, _newLegend, _tempoMap)
	var i
	var j
	
	for i = 0 to len(_oldLegend.params) loop
		_oldLegend.params[i][1] = toMidiIfNeeded(_oldLegend.params[i][1])
		
		for j = 0 to len(_newLegend) loop
			if _oldLegend.params[i][0] == _newLegend[j][0] then
				_newLegend[j][1] = toMidiIfNeeded(_newLegend[j][1])
				
				var val
				if strBeginsWith(str(_newLegend[j][1]), "{") then
					if _newLegend[j][1].x < 0 or _newLegend[j][1].y < 0 then
						_newLegend[j][1] = measurePosSubtract(_tempoMap, _oldLegend.params[i][1], _newLegend[j][1])
					else
						_newLegend[j][1] = measurePosAdd(_tempoMap, _oldLegend.params[i][1], _newLegend[j][1])
					endif
				else
					_newLegend[j][1] = _oldLegend.params[i][1] + _newLegend[j][1]
				endif
			endif
		repeat
	repeat
	
	_oldLegend.len -= 1 // Array doesn't count in length consideration
	
	var result = [
		.new = _newLegend,
		.old = _oldLegend
	]
return result

// Removes repeated events of the same type/value that do nothing but increase queue length.
// _lastClipValues is an array of starting values that represent the state of the previous clip's end.
function updateLastClipValues(_queue, _lastClipValues, _cullEvents)
	var culled = 0
	
	if !len(_lastClipValues) then
		 var chDefault = [
			.setClipper = [ float_min, float_min ],
			.setEnvelope = [ float_min, float_min ],
			.setFilter = [ float_min, float_min ],
			.setFrequency = [ float_min ], // Also set by .playNote
			.setModulator = [ float_min, float_min, float_min ],
			.setPan = [ float_min ], // Also set by .playNote and .playAudio
			.setReverb = [ float_min, float_min ],
			.setVolume = [ float_min ], // Also set by .playNote and .playAudio
			.startChannel = [],
			.stopChannel = []
		]
		
		_lastClipValues = [
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault,
			chDefault
		]
	endif
	
	var oldLen = len(_queue)
	
	var i = 0
	while i < len(_queue) loop
		var ch = _queue[i].ch
		var vals = _lastClipValues[ch]
		
		loop if _queue[i].func == "playAudio" then
			_lastClipValues[ch].setVolume[0] = _queue[i].arg[1]
			_lastClipValues[ch].setPan[0] = _queue[i].arg[2]
			_lastClipValues[ch].setEnvelope[0] = _queue[i].arg[3]
			break endif
		if _queue[i].func == "playNote" then
			_lastClipValues[ch].setFrequency[0] = _queue[i].arg[1]
			_lastClipValues[ch].setVolume[0] = _queue[i].arg[2]
			_lastClipValues[ch].setEnvelope[0] = _queue[i].arg[3]
			_lastClipValues[ch].setPan[0] = _queue[i].arg[4]
			break endif
		if _queue[i].func == "setClipper" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setClipper) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setClipper = _queue[i].arg
			endif
			break endif
		if _queue[i].func == "setEnvelope" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setEnvelope) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setEnvelope = _queue[i].arg
			endif
			break endif
		if _queue[i].func == "setFilter" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setFilter) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setFilter = _queue[i].arg
			endif
			break endif
		if _queue[i].func == "setFrequency" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setFrequency) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setFrequency = _queue[i].arg
			endif
			break endif
		if _queue[i].func == "setModulator" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setModulator) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setModulator = _queue[i].arg
			endif
			break endif
		if _queue[i].func == "setPan" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setPan) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setPan = _queue[i].arg
			endif
			break endif
		if _queue[i].func == "setReverb" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setReverb) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setReverb = _queue[i].arg
			endif
			break endif
		if _queue[i].func == "setVolume" then
			if arrayEquals(_queue[i].arg, _lastClipValues[ch].setVolume) and _cullEvents then
				_queue = remove(_queue, i)
				i -= 1
				culled += 1
			else
				_lastClipValues[ch].setVolume = _queue[i].arg
			endif
			break
		endif break repeat
		
		i += 1
	repeat
	
	result = [
		.queue = _queue,
		.lastClipValues = _lastClipValues,
		.culled = culled
	]
return result

// Stores the most recent events of each type.
function updateRecentSnd(_recent, _lastParsed)
	_recent.lastFunc = _lastParsed.func
	_recent.lastCh = _lastParsed.ch
	_recent.lastBeatPos = _lastParsed.beatPos
	_recent.lastTimePos = _lastParsed.timePos
	
	loop if _lastParsed.func == "playAudio" then
		_recent.playAudio = _lastParsed
		break endif
	if _lastParsed.func == "playNote" then
		_recent.playNote = _lastParsed
		break endif
	if _lastParsed.func == "setClipper" then
		_recent.setClipper = _lastParsed
		break endif
	if _lastParsed.func == "setEnvelope" then
		_recent.setEnvelope = _lastParsed
		break endif
	if _lastParsed.func == "setFilter" then
		_recent.setFilter = _lastParsed
		break endif
	if _lastParsed.func == "setFrequency" then
		_recent.setFrequency = _lastParsed
		break endif
	if _lastParsed.func == "setModulator" then
		_recent.setModulator = _lastParsed
		break endif
	if _lastParsed.func == "setPan" then
		_recent.setPan = _lastParsed
		break endif
	if _lastParsed.func == "setReverb" then
		_recent.setReverb = _lastParsed
		break endif
	if _lastParsed.func == "setVolume" then
		_recent.setVolume = _lastParsed
		break endif
	if _lastParsed.func == "startChannel" then
		_recent.startChannel = _lastParsed
		break endif
	if _lastParsed.func == "stopChannel" then
		_recent.stopChannel = _lastParsed
		break
	endif break repeat
return _recent

	// ----------------------------------------------------------------
	// AUDIO QUEUE

// Schedules an audio event for a future time
function addFirstQueuedSnd(_snd, _queue, _tempoMap)
	var timer = time()
	var i = len(_queue) - 1
	var pruned = 0
	if len(_queue) then
		var sndBeatTime = _snd.beatPos
		sndBeatTime = getTimeFromTempoMap(_tempoMap, sndBeatTime)
		
		while i >= 0 loop
			if getType(_queue[i]) == "struct" then
				var queueBeatTime = _queue[i].beatPos
				queueBeatTime = getTimeFromTempoMap(_tempoMap, queueBeatTime)
				
				if queueBeatTime + _queue[i].timePos <= sndBeatTime + _snd.timePos then
					_queue = insert(_queue, _snd, i + 1)
					break
				else if _queue[i].func == _snd.func and _queue[i].ch == _snd.ch then
					_queue[i] = []
					pruned += 1
				endif endif
			endif
			
			if i == 0 then
				_queue = insert(_queue, _snd, 0)
			endif
			
			i -= 1
		repeat
	else
		_queue = [ _snd ]
	endif
	
	var result = [
		.queue = _queue,
		.idx = min(i + 1, len(_queue) - 1),
		.pruned = pruned
	]
return result

// Schedules additional audio events for future times. These are assumed to come after an event
// added with addFirstQueuedSnd() and will not delete conflicting events.
function addAdditionalQueuedSnd(_snd, _queue, _startIdx, _tempoMap)
	var timer = time()
	var i = _startIdx
	if len(_queue) then
		var sndBeatTime = _snd.beatPos
		sndBeatTime = getTimeFromTempoMap(_tempoMap, sndBeatTime)
		
		while i < len(_queue) loop
			if getType(_queue[i]) == "struct" then
				var queueBeatTime = _queue[i].beatPos
				queueBeatTime = getTimeFromTempoMap(_tempoMap, queueBeatTime)
				
				if queueBeatTime + _queue[i].timePos > sndBeatTime + _snd.timePos then
					_queue = insert(_queue, _snd, i)
					i -= 1
					break
				endif
			endif
			
			i += 1
			
			if i >= len(_queue) then
				_queue = push(_queue, _snd)
				break
			endif
		repeat
	else
		_queue = [ _snd ]
	endif
	
	var result = [
		.queue = _queue,
		.idx = min(i, len(_queue) - 1)
	]
return result

// Executes scheduled audio events that are due.
function updateSndQueue(ref _queue)
	var sndIsDue = false
	var played = []
	
	var i
	var j
	
	for i = 0 to len(_queue.queue) loop
		if _queue.queueIdx >= len(_queue.queue) then
			break
		endif
		
		while time() + _queue.playheadOffset >= getTimeFromTempoMap(_queue.tempoMap, _queue.queue[_queue.queueIdx].beatPos, _queue.startTime) + _queue.queue[_queue.queueIdx].timePos loop
			playQueuedSnd(_queue.queue[_queue.queueIdx], _queue.samples)
			played = push(played, _queue.queue[_queue.queueIdx])
			
			if !len(_queue.queue) then break endif
			
			_queue.queueIdx += 1
			
			if _queue.queueIdx >= len(_queue.queue) then break endif
		repeat
	repeat
return played

// Routes scheduled audio event data to the correct function.
function playQueuedSnd(_snd, _samples)
	loop if _snd.func == "playAudio" then
		playAudio(_snd.ch, _samples[_snd.arg[0]], _snd.arg[1], _snd.arg[2], _snd.arg[3], _snd.arg[4])
		break endif
	if _snd.func == "playNote" then
		playNote(_snd.ch, _snd.arg[0], _snd.arg[1], _snd.arg[2], _snd.arg[3], _snd.arg[4])
		break endif
	if _snd.func == "setClipper" then
		setClipper(_snd.ch, _snd.arg[0], _snd.arg[1])
		break endif
	if _snd.func == "setEnvelope" then
		setEnvelope(_snd.ch, _snd.arg[0])
		break endif
	if _snd.func == "setFilter" then
		setFilter(_snd.ch, _snd.arg[0], _snd.arg[1])
		break endif
	if _snd.func == "setFrequency" then
		setFrequency(_snd.ch, _snd.arg[0])
		break endif
	if _snd.func == "setModulator" then
		setModulator(_snd.ch, _snd.arg[0], _snd.arg[1], _snd.arg[2])
		break endif
	if _snd.func == "setPan" then
		setPan(_snd.ch, _snd.arg[0])
		break endif
	if _snd.func == "setReverb" then
		setReverb(_snd.ch, _snd.arg[0], _snd.arg[1])
		break endif
	if _snd.func == "setVolume" then
		setVolume(_snd.ch, _snd.arg[0])
		break endif
	if _snd.func == "startChannel" then
		startChannel(_snd.ch)
		break
	else // stopChannel
		stopChannel(_snd.ch)
		break
	endif break repeat
return void

	// ----------------------------------------------------------------
	// VISUALIZER

// Draws the visualizer for this frame's audio events
function visualizeAudioEvents(_sndArr)
	clear(black)
	updateVisData(_sndArr)
	
	var expired = 0
	var i
	
	for i = 0 to len(g_chVis) loop
		if time() - g_chVis[i].time > g_chVis[i].dur then
			expired += 1
			g_chVis[i].expired = true
		else
			var alphaRad = (time() - g_chVis[i].time) / g_chVis[i].dur
			var alphaCol = interpolate(expo_out, 1, 0, alphaRad)
			var rad = lerp(gwidth() / 512, g_chVis[i].endRad, alphaRad)
			var col = {g_chVis[i].col.r, g_chVis[i].col.g, g_chVis[i].col.b, alphaCol}
			
			if g_chVis[i].shape == "circle" then
				circle(g_chVis[i].pos.x, g_chVis[i].pos.y, rad, 6, col, false)
			else if g_chVis[i].shape == "boxV" then
				box(g_chVis[i].pos.x, g_chVis[i].pos.y, gwidth(), rad, col, false)
			else
				box(g_chVis[i].pos.x, g_chVis[i].pos.y, rad, gheight(), col, false)
			endif endif
		endif
	repeat
	
	// Remove visualizer entries that have expired
	if expired then
		array newChVis[len(g_chVis) - expired]
		var newArrIdx = 0
		var i
		
		for i = 0 to len(g_chVis) loop
			if !g_chVis[i].expired then
				newChVis[newArrIdx] = g_chVis[i]
				newArrIdx += 1
			endif
		repeat 
		
		g_chVis = newChVis
	endif
	
	update()
return void

// Sets visualizer parameters based on the channels of played notes.
function updateVisData(_sndArr)
	var i
	for i = 0 to len(_sndArr) loop
		if _sndArr[i].func == "playNote" or _sndArr[i].func == "playAudio" then
			loop if _sndArr[i].ch == 0 then // Kick
				g_chVis = push(g_chVis, [
					.endRad = gwidth(),
					.pos = {gwidth() * 0.5, gheight() * 0.5},
					.col = white,
					.time = time(),
					.shape = "circle",
					.dur = 2,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 2 then // Snare/Tom
				
				g_chVis = push(g_chVis, [
					.endRad = gwidth(),
					.pos = {gwidth() * 0.25, gheight() * 0.25},
					.col = jade,
					.time = time(),
					.shape = "circle",
					.dur = 3,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 4 then // Hat/Cymbal
				g_chVis = push(g_chVis, [
					.endRad = gwidth(),
					.pos = {gwidth() * 0.75, gheight() * 0.25},
					.col = amber,
					.time = time(),
					.shape = "circle",
					.dur = 0.5,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 5 then // Bass
				g_chVis = push(g_chVis, [
					.endRad = gheight() * -2,
					.pos = {0, gheight()},
					.col = indigo,
					.time = time(),
					.shape = "boxV",
					.dur = 4,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 7 then // Piano
				g_chVis = push(g_chVis, [
					.endRad = gwidth(),
					.pos = {gwidth() * 0.25, gheight() * 0.75},
					.col = azure,
					.time = time(),
					.shape = "circle",
					.dur = 2,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 8 then // Beep
				g_chVis = push(g_chVis, [
					.endRad = gwidth(),
					.pos = {0, 0},
					.col = hotPink,
					.time = time(),
					.shape = "boxH",
					.dur = 2,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 9 then // Beep
				g_chVis = push(g_chVis, [
					.endRad = gwidth() * -1,
					.pos = {gwidth(), 0},
					.col = hotPink,
					.time = time(),
					.shape = "boxH",
					.dur = 2,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 10 then // Swell
				g_chVis = push(g_chVis, [
					.endRad = gwidth(),
					.pos = {gwidth() * 0.75, gheight() * 0.75},
					.col = crimson,
					.time = time(),
					.shape = "circle",
					.dur = 6,
					.expired = false
				])
				break endif
			if _sndArr[i].ch == 13 then // Lead
				g_chVis = push(g_chVis, [
					.endRad = gwidth() * 0.5,
					.pos = {0, 0},
					.col = khaki,
					.time = time(),
					.shape = "boxV",
					.dur = 1,
					.expired = false
				])
				break 
			endif break repeat
		endif
	repeat
return void

	// ----------------------------------------------------------------
	// READ/WRITE

// Streams audio data from file.
function streamAudioSequence(_queue, _file, _actionLimit)
	var loading = _queue.fileDat.block.idx != -1
	var actionCount = 0
	var chunk
	
	if !loading then
		var sectionIdx = findFileSection(_file, "audioSequence" + _queue.name)
		var chunkIdx = findFileChunk(_file, blockStr("events"), [ chr(31) ], sectionIdx.start, sectionIdx.end)
		chunk = getNextFileChunk(_file, chunkIdx.start)
		
		_queue.fileDat = [ .section = sectionIdx, .block = chunk, .unit = -1, .field = -1, .elem = -1 ]
	else
		chunk = _queue.fileDat.block
	endif
	
	array sndGroup[0]
	var field
		
	while inFileBlock(chunk) loop
		if !loading then
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
			_queue.fileDat.unit = chunk
			
			if actionCount >= _actionLimit and _actionLimit > 0 then
				break
			endif
		else
			chunk = _queue.fileDat.unit
		endif
		
		loading = false
		var ch = -1
		var newSnd = [ .ch = -1, .beatPos = {0, 0}, .timePos = 0, .func = "", .arg = [] ]
		
		while inFileUnit(chunk) loop
			
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
			_queue.fileDat.field = chunk
			field = chunk.dat
			array elem[0]
			
			while inFileField(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
				_queue.fileDat.elem = chunk
				elem = push(elem, chunk.dat)
			repeat
			
			loop if field == "b" then
				newSnd.beatPos = decodeElem(elem)
				break endif
			if field == "t" then
				newSnd.timePos = decodeElem(elem)
				break endif
			if field == "c" then
				newSnd.ch = decodeElem(elem)
				break endif
			if field == "f" then
				newSnd.func = decodeElem(elem)
				break endif
			if field == "a" then
				newSnd.arg = decodeElem(elem)
				break
			endif break repeat
		repeat
		
		sndGroup = push(sndGroup, newSnd)
		actionCount += 1
		
		// If next idx overruns section bounds, the sequence is over
		if _queue.fileDat.elem.nextIdx >= _queue.fileDat.section.end then
			_queue.endedTime = time()
			break
		endif
	repeat
	
	var result = [
		.queue = _queue,
		.elems = sndGroup
	]
return result

// Loads a tempo map from the file.
function readTempoMap(_name, _file)
	var tempoMap = []
	
	var sectionIdx = findFileSection(_file, "audioSequence" + _name)
	var chunkIdx = findFileChunk(_file, blockStr("tempoMap"), [ chr(31) ], sectionIdx.start, sectionIdx.end)
		
	var chunk
	var field
	var unit
	
	chunk = getNextFileChunk(_file, chunkIdx.start) // Block
	
	while inFileBlock(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
		unit = chunk.dat
		
		tempoMap = push(tempoMap, [ .beatPos = {0, 0}, .bpm = 120, .timeSig = 4 ])
		
		var mapIdx = len(tempoMap) - 1
		
		while inFileUnit(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
			field = chunk.dat
			
			array elem[0]
			while inFileField(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
				elem = push(elem, chunk.dat)
			repeat
			
			if field == "beatPos" then
				tempoMap[mapIdx].beatPos = decodeElem(elem)
			else if field == "bpm" then
				tempoMap[mapIdx].bpm = decodeElem(elem)
			else if field == "timeSig" then
				tempoMap[mapIdx].timeSig = decodeElem(elem)
			endif endif endif
		repeat
	repeat
return tempoMap

// Loads a sample array from the file.
function readSamples(_name, _file)
	var samples = []
	
	var sectionIdx = findFileSection(_file, "audioSequence" + _name)
	var chunkIdx = findFileChunk(_file, blockStr("samples"), [ chr(31) ], sectionIdx.start, sectionIdx.end)
	
	var chunk
	var field
	var unit
	
	chunk = getNextFileChunk(_file, chunkIdx.start) // Block
	
	while inFileBlock(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
		unit = chunk.dat
		
		while inFileUnit(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
			field = chunk.dat
			
			array elem[0]
			while inFileField(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
				elem = push(elem, chunk.dat)
			repeat
			
			if field == "" then
				samples = push(samples, decodeElem(elem))
			endif
		repeat
	repeat
return samples

// Saves a sequence's tempo/time signature data to file.
function writeTempoMap(_name, _file, _tempoMap, _overwrite)
	var sectionIdx
	var writeStr = ""
	
	sectionIdx = findFileSection(_file, "audioSequence" + _name)
	if sectionIdx.start < 0 then
		sectionIdx.start = getEofIdx(_file)
		sectionIdx.end = sectionIdx.start
	endif
	
	if _overwrite then
		writeStr = sectionStr("audioSequence" + _name)
	endif
	
	writeStr += blockStr("tempoMap")
	
	var i
	for i = 0 to len(_tempoMap) loop
		writeStr += unitStr(str(i))
		writeStr += fieldStr("beatPos")
		writeStr += elemStr(_tempoMap[i].beatPos)
		writeStr += fieldStr("bpm")
		writeStr += elemStr(float(_tempoMap[i].bpm))
		writeStr += fieldStr("timeSig")
		writeStr += elemStr(_tempoMap[i].timeSig)
	repeat
	
	if _overwrite then
		writeFileSegment(_file, writeStr, sectionIdx.start, sectionIdx.end)
	else
		writeFileSegment(_file, writeStr, sectionIdx.end, sectionIdx.end)
	endif
return sectionIdx.start + len(writeStr)

// Saves a sequence's sample paths to file.
function writeSamples(_name, _file, _samples, _overwrite)
	var sectionIdx
	var writeStr = ""
	
	sectionIdx = findFileSection(_file, "audioSequence" + _name)
	
	if sectionIdx.start < 0 then
		sectionIdx.start = getEofIdx(_file)
		sectionIdx.end = sectionIdx.start
	endif
	
	if _overwrite then
		writeStr = sectionStr("audioSequence" + _name)
	endif
	
	writeStr += blockStr("samples")
	
	var i
	for i = 0 to len(_samples) loop
		writeStr += unitStr(str(i))
		writeStr += fieldStr("")
		writeStr += elemStr(_samples[i])
	repeat
	
	if _overwrite then
		writeFileSegment(_file, writeStr, sectionIdx.start, sectionIdx.end)
	else
		writeFileSegment(_file, writeStr, sectionIdx.end, sectionIdx.end)
	endif
return sectionIdx.start + len(writeStr)

// Saves audio sequence data to file.
function writeAudioSequence(_name, _file, _queue, _insertIdx, _overwrite)
	var sectionIdx
	var writeStr = ""
	
	if _insertIdx < 0 then
		sectionIdx = findFileSection(_file, "audioSequence" + _name)
		
		if sectionIdx.start < 0 then
			sectionIdx.start = getEofIdx(_file)
			sectionIdx.end = sectionIdx.start
			writeStr = sectionStr("audioSequence" + _name)
		else if _overwrite then
			writeStr = sectionStr("audioSequence" + _name)
		else
			sectionIdx.start = sectionIdx.end
		endif endif
		
		writeStr += blockStr("events")
	else
		sectionIdx = [ .start = _insertIdx, .end = _insertIdx + 1 ]
	endif
	
	var i
	for i = 0 to len(_queue) loop
		writeStr += unitStr("")
		writeStr += fieldStr("b")
		writeStr += elemStr(_queue[i].beatPos)
		writeStr += fieldStr("t")
		writeStr += elemStr(float(_queue[i].timePos))
		writeStr += fieldStr("c")
		writeStr += elemStr(float(_queue[i].ch))
		writeStr += fieldStr("f")
		writeStr += elemStr(_queue[i].func)
		writeStr += fieldStr("a")
		writeStr += elemStr(_queue[i].arg)
	repeat
	
	writeFileSegment(_file, writeStr, sectionIdx.start, sectionIdx.end)
return sectionIdx.start + len(writeStr)

// Deletes saved audio sequence data.
function deleteAudioSequence(_name)
return deleteAudioSequence(_name, -1, true)

function deleteAudioSequence(_name, _file)
return deleteAudioSequence(_name, _file, false)

function deleteAudioSequence(_name, _file, _needFileOpen)
	_file = openFileIfNeeded(_file, _needFileOpen)
	
	var sectionIdx = findFileSection(_file, "audioSequence" + _name)
	
	if sectionIdx.start >= 0 then
		writeFileSegment(_file, "", sectionIdx.start, sectionIdx.end)
	endif
	
	closeFileIfNeeded(_file, _needFileOpen)
return void

// ----------------------------------------------------------------
// UTILITY FUNCTIONS

	// ----------------------------------------------------------------
	// STRING FUNCTIONS

/* Converts string to lowercase. */
function lower(_str)
	var i
	var val = -1
	
	for i = 0 to len(_str) loop
		val = chrVal(_str[i])
		
		if val >= 65 and val <= 90 then
			_str[i] = chr(val + 32)
		endif
	repeat
return _str

/* The character at the _end index isn't included in the return string. */
function strSlice(_str, _start, _end)
	sliced  = ""
	
	if len(_str) > 0 and _start < len(_str) then
		if _end > len(_str) - 1 or _end < 0 then
			_end = len(_str)
		endif
		
		if _start < 0 then
			_start = 0
		endif
		
		var i
		for i = _start to _end loop
			sliced += _str[i]
		repeat
	endif
return sliced

/* Converts a float to a string with the given number of decimal places. */
function floatToStr(_f, _decimals)
	str fStr = str(_f)
	var decIdx = strFind(fStr, ".")
	
	if _decimals == 0 then
		fStr = strSlice(fStr, 0, decIdx)
	else if _decimals > 0 then
		fStr = strSlice(fStr, 0, decIdx + 1 + _decimals)
	endif endif
return fStr

/* Removes the trailing zeros and, if appropriate, the decimal point from a
stringified float. */
function strRemoveTrailingZeroes(ref _str)
	var newLen = len(_str) - 1
	var continue = strContains(_str, ".")
	var i
	
	for i = len(_str) - 1 to -0.1 step -1 loop
		if !continue then // Check inside of loop to reduce stack size
			break
		endif
		
		if _str[i] == "0" then
			newLen -= 1
		else
			if _str[i] == "." then
				newLen -= 1
			endif
			
			break
		endif
	repeat
	
	_str = _str[:newLen]
return _str

	// ----------------------------------------------------------------
	// NUMBER FUNCTIONS

/* 1 for 0 or positive, -1 for negative. */
// CORE LOADER
function getSign(_num)
	if _num >= 0 then
		_num = 1
	else
		_num = -1
	endif
return _num

	// ----------------------------------------------------------------
	// ARRAY FUNCTIONS

/* Removes item at _idx from _arr. */
// CORE LOADER
function remove(_arr, _idx)
	array newArr[len(_arr) - 1]
	var offset = 0
	
	var i
	for i = 0 to len(newArr) loop
		if i == _idx then
			offset = 1
		endif
		
		newArr[i] = _arr[i + offset]
	repeat
return newArr

// CORE LOADER
/* Inserts _elem in _arr at index _idx, pushing items at _idx and higher back by one index place. */
function insert(_arr, _elem, _idx)
	array newArr[len(_arr) + 1]
	_idx = clamp(_idx, 0, len(_arr))
	var offset = 0
	
	var i
	for i = 0 to len(newArr) loop
		if i == _idx then
			newArr[i] = _elem
			offset = -1
		else
			newArr[i] = _arr[i + offset]
		endif
	repeat
return newArr

/* Inserts _item at the end of _arr. */
// CORE LOADER
function push(_arr, _item)
	var arrBuffer = _arr
	var newArr[len(arrBuffer) + 1]
	_arr = newArr
	
	var i
	for i = 0 to len(arrBuffer) loop
		_arr[i] = arrBuffer[i]
	repeat
	
	_arr[len(arrBuffer)] = _item
return _arr

/* When considering possible matches in _arr, tries to match _item with
_arr[i][_subIdx] instad of _arr[i]. */
function findAtSubIdx(_arr, _item, _subIdx)
return findAtSubIdx(_arr, _item, _subIdx, false)

function findAtSubIdx(_arr, _item, _subIdx, _castToStr)
	var idx = -1
	
	var i
	for i = 0 to len(_arr) loop
		if _castToStr then
			_arr[i][_subIdx] = str(_arr[i][_subIdx])
		endif
		if _arr[i][_subIdx] == _item then
			idx = i
			break
		endif
	repeat
return idx

/* Explodes _elemArr into its constituent elements and inserts them into _arr. */
// CORE LOADER
function insertArray(_arr, _elemArr)
return insertArray(_arr, _elemArr, len(_arr))

function insertArray(_arr, _elemArr, _idx)
	array newArr[len(_arr) + len(_elemArr)]
	_idx = clamp(_idx, 0, len(_arr))
	var offset = 0
	
	var i
	for i = 0 to len(newArr) loop
		if i >= _idx and i < _idx + len(_elemArr) then
			newArr[i] = _elemArr[i - _idx]
			offset -= 1
		else
			newArr[i] = _arr[i + offset]
		endif
	repeat
return newArr

/* Returns true if each element in _arr1 equals each equivalent element
in _arr2. */
function arrayEquals(_arr1, _arr2)
	var eqs = true
	
	if len(_arr1) != len(_arr2) then
		eqs = false
	else
		var i
		for i = 0 to len(_arr1) loop
			if _arr1[i] != _arr2[i] then
				eqs = false
				break
			endif
		repeat
	endif
return eqs

// Splits an array into two arrays. The second array begins with the element at _idx.
function split(_arr, _idx)
	_idx = clamp(_idx, 0, len(_arr))
	array newArr1[_idx]
	array newArr2[len(_arr) - _idx]
	
	var i
	for i = 0 to len(_arr) loop
		if i < _idx then
			newArr1[i] = _arr[i]
		else
			newArr2[i - _idx] = _arr[i]
		endif
	repeat
	
	var result = [ newArr1, newArr2 ]
return result

// Discard all elements before element at _idx.
function splitEndOnly(_arr, _idx)
	_idx = clamp(_idx, 0, len(_arr))
	array newArr[len(_arr) - _idx]
	
	var i
	for i = _idx to len(_arr) loop
		newArr[i - _idx] = _arr[i]
	repeat
	
return newArr

/* Encloses _var in an array if it is not already an array. */
function encloseInArray(_var)
	if getType(_var) != "array" then
		_var = [ _var ]
	endif
return _var

/* This won't literally return type -- a string containing an int value,
for example, will be read as an int -- but it sees the general patterns 
that distinguish data types and should be robust enough for most cases. 
FUZE will throw an error if you pass it a handle. */
function getType(_var)
	var type = "string"
	str varStr = str(_var)
	int varLen = len(varStr)
	var continue = true
	
	while continue loop
		if varLen > 2 then
			if varStr[:2] == "[ ." then
				type = "struct"
				break
			endif
		endif
		
		if varLen > 1 then
			if varStr[0] == "{" then
				type = "vector"
				break
			else if varStr[:1] == "[ " then
				type = "array"
				break
			endif endif
		endif
		
		if varLen > 0 then
			// Separating steps of the condition check may help avoid stack overflow?
			var cast = float(0)
			cast = str(cast)
			var cond0 = varStr != cast
			var cond1 = int(varStr) == 0
			var cond2 = strFind(varStr, "0.") != 0
			var cond3 = strFind(varStr, "-0.") != 0
			cast = int(varStr)
			cast = str(cast)
			cast = len(cast)
			var cond4 = cast != varLen
			cast = float(varStr)
			cast = str(cast)
			cast = len(cast)
			var cond5 = cast != varLen
			
			if varStr != "0" and cond0
					and ((cond1 and cond2 and cond3)
					or (cond4 and cond5)) then
				type = "string"
				break
			else if strContains(varStr, ".") then
				type = "float"
				break
			endif endif
			type = "int"
			break
		endif
		
		continue = false
	repeat
return type

	// ----------------------------------------------------------------
	// DEBUG FUNCTIONS
	
/* Prints text array to the screen for the given duration. */
function debugPrint(_time, _text)
return debugPrint(_time, -1, _text)

function debugPrint(_time, _size, _text)
	var target = getDrawTarget()
	
	setDrawTarget(framebuffer)
	ink(white)
	
	if _size >= 0 then
		textSize(_size)
	endif
	
	if _time > 0 then
		var timer = time()
		var i
		
		while _time > 0 loop
			clear()
			
			for i = 0 to len(_text) loop
				printAt(0, i, _text[i])
			repeat
			
			printAt(twidth() - len(str(_time)), theight() - 1, _time)
			update()
			
			_time -= (time() - timer)
			timer = time()
		repeat
	else
		var btnPrompt = "Press B to continue"
		
		clear()
		
		var i
		for i = 0 to len(_text) loop
			printAt(0, i, _text[i])
		repeat
		
		printAt(twidth() - len(btnPrompt), theight() - 1, btnPrompt)
		update()
		
		var c
		
		loop
			c = controls(0)
			
			if c.b then
				break
			endif
		repeat
	endif
	
	setDrawTarget(target)
return void

// ----------------------------------------------------------------
// FILE FUNCTIONS

	// ----------------------------------------------------------------
	// FILE WRITING

/* If g_freezeFile is true, g_mapFile will remain open and will be passed
to anything requesting a file open instead of newly opening the file. Because 
the file never closes, writes won't persist on program close, and because 
g_mapFile is only opened once, the file will never be reloaded from its saved 
state during the session. The result is that file changes will persist for 
the session but will roll back when the session is terminated. */
function openFile()
	var file
	
	if g_freezeFile then
		file = g_mapFile
	else
		file = open()
	endif
return file

/* Allows a function to optionally open a file if it isn't passed one as 
an argument. */
function openFileIfNeeded(_file, _needed)
	if _needed then
		_file = openFile()
	endif
return _file

/* If a file was opened via openFileIfNeeded(), closes it. */
function closeFileIfNeeded(_file, _needed)
	if _needed then
		closeFile(_file)
	endif
return void

/* Closes file, but only if allowed by g_freezeFile. */
function closeFile(_file)
	var closed = false
	if !g_freezeFile then
		close(_file)
		closed = true
	endif
return closed

/* An end buffer stores all file data past a given index and then writes that data 
to a new index when closed. This allows us to write data of an arbitrary size in the
middle of a file without worrying about overwriting what comes after it (if larger
than the original data) or leaving garbage data (if smaller than the original data). */
function openFileEndBuffer(_file, _idx)
	var unalloIdx = getEofIdx(_file)
	
	_idx = min(_idx, unalloIdx)
	seek(_file, _idx)
return read(_file, unalloIdx - _idx)

/* Writes the file end buffer data back to the end of the file once other writes are done.  */
function closeFileEndBuffer(_file, _buffer, _idx)
	seek(_file, _idx)
	
	var lastData = len(_buffer) - 1
	if lastData > -1 then
		if lastData < len(_buffer) - 1 then
			_buffer = strSlice(_buffer, 0, lastData + 1)
		endif
		
		write(_file, _buffer)
		
		// Any data remaining in the file after the write point is garbage
		var i
		for i = _idx + lastData + 1 to len(_file) loop
			seek(_file, i)
			write(_file, chr(127))
		repeat
	/* If there's no buffer data, it means the buffer was taken from EOF, so erase
	everything from _idx on. */
	else
		var i
		for i = _idx to len(_file) loop
			seek(_file, i)
			write(_file, chr(127))
		repeat
	endif
return void

/* General-purpose file writer that automatically deals with the end buffer. */
function writeFileSegment(_file, _fileStr, _start, _end)
	var endBuf = openFileEndBuffer(_file, _end)
	seek(_file, _start)
	write(_file, _fileStr)
	closeFileEndBuffer(_file, endBuf, _start + len(_fileStr))
return void

/* There doesn't seem to be a way to delete characters, only 
overwrite them, so filesize cannot be reduced once expanded. 
As such, we just overwrite with Unicode delete chars to 
represent unallocated space. */
function clearFile(_file)
	var i
	for i = 0 to len(_file) loop
		seek(_file, i)
		write(_file, chr(127))
	repeat
return void

	// ----------------------------------------------------------------
	// FILE READING

// Template for file reads
/*
function readFileTemplate(_file)
	var sectionIdx = findFileSection(_file, "section")
	var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
	while inFileSection(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
		while inFileBlock(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
			while inFileUnit(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
				while inFileField(chunk) loop
					chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
				repeat
			repeat
		repeat
	repeat
return void
*/

/* Returns the end-of-file index or the index of the first unallocated space. */
function getEofIdx(_file)
	var eof = findFileChar(_file, chr(127))
	if eof < 0 then
		eof = len(_file)
	endif
return eof

/* A section is the highest-level file division, distinguishing between, for
example, map objects and map properties. */
// CORE LOADER
function findFileSection(_file, _section)
return findFileSection(_file, _section, 0, -1)

function findFileSection(_file, _section, _startAt, _endAt)
return findFileChunk(_file, chr(31) + _section, [ chr(31) ], _startAt, _endAt)

/* A chunk is a file section that exists between any two delimiters, which are
typically non-printing unicode characters. _endAt is non-inclusive. */
// CORE LOADER
function findFileChunk(_file, _searchStartStr, _searchEndStr, _startAt, _endAt)
	seek(_file, _startAt)
	fileStr = read(_file, len(_file) - _startAt)
	
	var startIdx = strFind(fileStr, _searchStartStr)
	var endIdx = -1
	
	if startIdx < _endAt or (_endAt < 0) then
		var i
		var newEnd
		
		for i = 0 to len(_searchEndStr) loop
			newEnd = strFind(fileStr[startIdx + 1:], _searchEndStr[i])
			
			if endIdx == -1 or newEnd < endIdx then
				endIdx = newEnd
			endif
		repeat
		
		if startIdx != -1 and endIdx == -1 then
			startIdx += _startAt
			endIdx = strFind(fileStr, chr(127)) // Find blank space in file.
			if endIdx == -1 then
				endIdx = len(fileStr)
			endif
		else if startIdx != -1 and (_endAt < 0 or endIdx < _endAt) then
			startIdx += _startAt
			endIdx += startIdx + 1 // Compensate for the search's string truncation.
		else
			endIdx = -1 // If there's no start, any end is invalid.
		endif endif
	else
		startIdx = -1
	endif
	
	var result = [
		.start = startIdx,
		.end = endIdx
	]
return result

/* Gets the index of a character within the file. Bails out if unallocated
space is encountered. */
// CORE LOADER
function findFileChar(_file, _char)
return findFileChar(_file, _char, 0)

function findFileChar(_file, _char, _startAt)
	seek(_file, _startAt)
	
	var idx = _startAt
	var charBuf = ""
	while charBuf != _char and charBuf != chr(127) loop
		seek(_file, idx)
		
		charBuf = read(_file, 1)
		if charBuf != _char then
			idx += 1
		endif
		
		if idx > len(_file) then
			idx = -1
			break
		endif
	repeat
return idx


/* Return the next file chunk as delimited by certain non-printing unicode characters 
that signify data purpose. */
// CORE LOADER
function getNextFileChunk(_file, _startIdx)
	seek(_file, _startIdx)
	
	var marker = read(_file, 1)
	var nextMarker = ""
	var nextIdx = _startIdx
	var dat = ""
	var char = ""
	var fileLen = len(_file)
	
	while nextIdx < fileLen loop
		nextIdx += 1
		seek(_file, nextIdx)
		
		char = read(_file, 1)
		if char == chr(31)
				or char == chr(30)
				or char == chr(29)
				or char == chr(28)
				or char == chr(17)
				or char == chr(127) then
			nextMarker = char
			break
		endif
		
		dat += char
	repeat
	
	var result = [
		.marker = marker,
		.idx = _startIdx,
		.nextMarker = nextMarker,
		.nextIdx = nextIdx,
		.dat = dat,
		.fileLen = len(_file)
	]
return result

/* Like getNextFileChunk(), but in the other direction. */
function getPrevFileChunk(_file, _startIdx)
	seek(_file, _startIdx)
	
	var marker = read(_file, 1)
	var prevMarker = ""
	var prevIdx = _startIdx
	var dat = ""
	var char = ""
	var fileLen = len(_file)
	
	while prevIdx > 0 loop
		prevIdx -= 1
		seek(_file, PrevIdx)
		
		char = read(_file, 1)
		if char == chr(31)
				or char == chr(30)
				or char == chr(29)
				or char == chr(28)
				or char == chr(17) then
			prevMarker = char
			break
		endif
		
		dat = char + dat
	repeat
	
	var result = [
		.marker = marker,
		.idx = _startIdx,
		.prevMarker = prevMarker,
		.prevIdx = prevIdx,
		.dat = dat,
		.fileLen = len(_file)
	]
return result

	// ----------------------------------------------------------------
	// FILE ENCODING

/* Encode section headers at various levels of the file tree. Each section header 
is identfied by a non-printing Unicode character that can't be placed with a 
standard keyboard, so user input can't create conflicts. 

The hierarchy from highest to lowest:
Section -- chr(31): Marks major chunks like maps and preferences
Version -- chr(18): Optional delimiter within a section listing the version of Celqi that saved the data
Block -- chr(17): Marks largest individual containers in a section (e.g. an object class within a map)
Unit -- chr(30): Division within a block (e.g. map objects of a type specified by block)
Field -- chr(29): The name of a varible whose value has been saved
Element -- chr(28): Part of the saved value of a variable */
function sectionStr(_str)
return chr(31) + _str

function blockStr(_str)
return chr(17) + _str

function unitStr(_str)
return chr(30) + _str

function fieldStr(_str)
return chr(29) + _str

function elemStr(_elem)
	var enc = encodeElem(_elem)
	var eStr = ""
	var i
	for i = 0 to len(enc) loop
		eStr += chr(28) + enc[i]
	repeat
return eStr

function versionStr()
	var ver = chr(18) + g_version
return ver

/* Given an input variable, returns an encoded elem string to be written
to file.

 Type designators:
"f": float
"i": int
"ia": array of ints
"3": vector3
"s": string */
function encodeElem(_dat)
	var type = getType(_dat)
	var enc
	
	loop if type == "vector" then
		var elem0 = str(_dat[0])
		strRemoveTrailingZeroes(elem0)
		var elem1 = str(_dat[1])
		strRemoveTrailingZeroes(elem1)
		var elem2 = str(_dat[2])
		strRemoveTrailingZeroes(elem2)
		if _dat[2] == 0 and _dat[3] == 0 then
			enc = [
				"2",
				elem0,
				elem1
			]
		else if _dat[3] == 0 then
			enc = [
				"3",
				elem0,
				elem1,
				elem2
			]
		else
			var elem3 = str(_dat[3])
			strRemoveTrailingZeroes(elem3)
			
			enc = [
				"4",
				elem0,
				elem1,
				elem2,
				elem3
			]
		endif endif
		break endif
	if type == "float" then
		var elem = str(_dat)
		strRemoveTrailingZeroes(elem)
		enc = [
			"f",
			elem
		]
		break endif
	if type == "array" then
		enc = [ "fa" ]
		
		var i
		for i = 0 to len(_dat) loop
			enc = push(enc, strRemoveTrailingZeroes(str(_dat[i])))
		repeat
		
		break
	else
		var typeCode
		if type == "float" then
			typeCode = "f"
		else if type == "int" then
			typeCode = "i"
		else
			typeCode = "s"
		endif endif
		
		enc = [
			typeCode,
			str(_dat)
		]
		break
	endif break repeat
return enc

	// ----------------------------------------------------------------
	// FILE DECODING

/* Reconstructs a variable's value from encoded file string. */
// CORE LOADER
function decodeElem(_e)
	var dec
	loop if _e[0] == "f" then
		dec = float(_e[1])
		break endif
	if _e[0] == "i" then
		dec = int(_e[1])
		break endif
	if _e[0] == "2" then
		dec = {0, 0}
		
		var i
		for i = 0 to 2 loop
			dec[i] = float(_e[i + 1])
		repeat
		break endif
	if _e[0] == "3" then
		dec = {0, 0, 0}
		
		var i
		for i = 0 to 3 loop
			dec[i] = float(_e[i + 1])
		repeat
		break endif
	if _e[0] == "4" then
		dec = {0, 0, 0, 0}
		
		var i
		for i = 0 to 4 loop
			dec[i] = float(_e[i + 1])
		repeat
		break endif
	if _e[0] == "fa" then
		array newFloat[len(_e) - 1]
		dec = newFloat
		
		var i
		for i = 0 to len(dec) loop
			dec[i] = float(_e[i + 1])
		repeat
		break endif
	if _e[0] == "ia" then
		array newDec[len(_e) - 1]
		dec = newDec
		
		var i
		for i = 0 to len(dec) loop
			dec[i] = int(_e[i + 1])
		repeat
		break
	else
		dec = _e[1]
		break 
	endif break repeat
return dec

/* Returns true if the given chunk is within the file. */
// CORE LOADER
function inFile(_chunk)
return _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same section. */
// CORE LOADER
function inFileSection(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same block. */			
// CORE LOADER
function inFileBlock(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(17) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same unit. */
// CORE LOADER
function inFileUnit(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(17) 				
		and _chunk.nextMarker != chr(30) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same field. */
// CORE LOADER
function inFileField(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(17) 				
		and _chunk.nextMarker != chr(30) 				
		and _chunk.nextMarker != chr(29) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

	// ----------------------------------------------------------------
	// FILE DEBUG

/* Prints all file data in human-readable form. */
function debugFile(_file)
	clear()
	printAt(0, 0, "Loading file debug view ...")
	update()
	
	var c = controls(0)
	
	textSize(15)
	var viewLine = 0
	var viewH = tHeight()
	var scrollW = textWidth("*")
	var firstChunkIdx = 0
	var lastChunkIdx = getPrevFileChunk(_file, getEofIdx(_file)).prevIdx
	var secMap = createFileOverview(_file, lastChunkIdx)
	
	var scroll
	var lineMov
	var movInc
	var i
	var chunk
	
	while !c.b loop
		ink(black)
		clear(white)
		
		c = controls(0)
		
		viewLine = 0
		scroll = round((firstChunkIdx / lastChunkIdx) * viewH)
		lineMov = 0
		
		printAt(0, scroll, "*")
		ink(black)
		drawFileOverview(secMap, scrollW)
		
		if abs(c.ry) > 0.3 or abs(c.ly) > 0.3 or c.up or c.down then
			movInc = floor(viewH / 3)
			lineMov = round(interpolate(ease_in, 0, movInc * getSign(c.ly), abs(c.ly))) 
				+ round(interpolate(ease_in, 0, 120 * getSign(c.ry), abs(c.ry))) 
				+ c.up * movInc 
				- c.down * movInc
		endif
		
		for i = 0 to abs(lineMov) loop
			if lineMov <= 0 then
				firstChunkIdx = clamp(getNextFileChunk(_file, firstChunkIdx).nextIdx,
					0, lastChunkIdx) // File
			else
				firstChunkIdx = clamp(getPrevFileChunk(_file, firstChunkIdx).prevIdx,
					0, lastChunkIdx) // File
			endif
		repeat
		
		chunk = getNextFileChunk(_file, firstChunkIdx - 1) // File
		while inFile(chunk) and viewLine <= viewH loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Section
			printDebugFileEntry(chunk.marker, chunk.dat, viewLine)
			viewLine += 1
		repeat
		
		update()
	repeat
	
	ink(white)
return void

/* Draws tickmarks next to the scrollbar in file debug view representing an overview
of the sections in the file. Longer marks are higher levels of the file tree. */
function createFileOverview(_file, _lastChunkIdx)
	array secMap[gheight()]
	var i
	for i = 0 to len(secMap) loop
		secMap[i] = ""
	repeat
	
	var chunk = getNextFileChunk(_file, -1)
	while inFile(chunk) loop
		if chunk.nextMarker != chr(28) and chunk.nextMarker != chr(29) then
			secMap[round((chunk.nextIdx / _lastChunkIdx) * gheight())] = 
				chunk.nextMarker
		endif
		
		chunk = getNextFileChunk(_file, chunk.nextIdx)
	repeat
return secMap

/* Visualizes the data from createFileOverview(). */
function drawFileOverview(_secMap, _xPos)
	var i
	for i = 0 to len(_secMap) loop
		if len(_secMap[i]) then
			var col = blue
			var lineLen = _xPos
			if _secMap[i] == chr(17) then
				lineLen *= 0.66
				col = black
			else if _secMap[i] == chr(30) then
				lineLen *= 0.33
				col = {1, 1, 1, 2} - white
			endif endif
			
			line({_xPos * 2 - lineLen, i + 1}, {_xPos * 2, i + 1}, col)
		endif
	repeat
return void

/* Diplays a line of data in the debug file reader. */
function printDebugFileEntry(_marker, _dat, _viewLine)
	ink(getFileMarkerCol(_marker))
	loop if _marker == chr(31) then
		printAt(2, _viewLine, "(section) " + _dat)
		break endif
	if _marker == chr(17) then
		printAt(4, _viewLine, "(block) " + _dat)
		break endif
	if _marker == chr(30) then
		printAt(6, _viewLine, "(unit) " + _dat)
		break endif
	if _marker == chr(29) then
		printAt(8, _viewLine, "(field) " + _dat)
		break endif
	if _marker == chr(28) then
		printAt(10, _viewLine, "(elem) " + _dat)
		break 
	endif break repeat
return void

/* Gets color coding for various file sections for the debug file reader. */
function getFileMarkerCol(_marker)
	var col = white
	loop if _marker == chr(31) then
		col = blue * 0.7
		break endif
	if _marker == chr(17) then
		col = blue * 0.8
		break endif
	if _marker == chr(30) then
		col = blue * 0.9
		break endif
	if _marker == chr(29) then
		col = blue
		break endif
	if _marker == chr(28) then
		col = black
		break
	endif break repeat
return col
