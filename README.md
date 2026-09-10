# Katae's Reshade Effects
Designed for use with raw Reshade in FFXIV, this is a small compilation of effects, some as experiments, some as effects I couldn't find, and thus made my own.

The effects have not been tested outside of FFXIV and thus I provide no immediate support outside of that game.

# Installation
Download the repository as a .zip, then install the ``shaders`` and ``presets`` in their respective folders for your Reshade/Gshade installation.

##

##

# Presets

## Katae_ObraDinn
A small compilation of effects to attempt to emulate the visuals of Obra Dinn. In reality, I may have made it look more like a 1-bit stylistic.

## Katae_Retro3D
An experiment of attempting to create a sort of old-school look via a mix of an edge-aware pixelizer, an outline, and a color "de-detailing".

##

##

# Shader Effects
You can find these effects in the Home section of Reshade

## K_BasicOutline
Simple outline shader with a depth-aware calibration. 

## K_DitheredQuads
Precursor to the Obra Dinn effect, which attempts to dither a quad based on the total brightness, then select "the most important pixel" per quad to display.

## K_ApproximateAlbedo
A shader that effectively forces the colors to be a vector length of 1. Potentially useful for a future effect.

## K_NeoPixelizer
An edge-aware pixelizer that attempts to emulate old-school texture sampling, while preserving the edges of objects. Severely experimental, and likely needs fine-tuning for each specific shot.

## K_Paintbrush
Paintbrush based on compute shaders. By default, hold X to draw, V to wipe. You can customize which keys are used from the hexcodes in the preprocessor.

## K_ProfilePicCrop
Overlays a square and a circle cutoff so you can align a picture intended for use in profiles, like Discord, or others.

## K_RetroColors
Reduces the color depth per-component. By default, the shader attempts to emulate a near-8-bit color scheme.

## K_Obra
Dithers the screen in a 1-bit color depth.

## K_Debug
A debugging shader/visualizer for me to test my common functions (from within KataeFuncs.fxh)

##

##

# Disclaimer

No artificial intelligence (AI) was used in the making of these effects, only biological stupidity. 

Any fault is potentially caused by using Reshade's integrated editor to develop the effects, instead of a proper external editor.

I am terrible at READMEs