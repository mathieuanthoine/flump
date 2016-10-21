# Flump+

Flump+ is a fork that adds new features above the Flump original exporter.
We hope that these features will be embeded in original Flump project.

## The new features of Flump+ are
### Support of mask layers
- Only Sprites can be masks
- Only one masked layer is possible

### Support of tint on Sprites and MovieClips
- Apply a tint on a MovieClip or Sprite in Flash/Animate and get the tint applied at runtime

### Storage of custom Data in the Json description file
- Store Flash/Animate persistent Data on instances
- At runtime get these data with the MovieClip/Sprite getCustomData and Movie getLayerCustomData methods

You can install [persistent data panel](https://github.com/mathieuanthoine/AnimateCCPersistentDataTools) in Flash/Animate to easily manage persistent data. 

### Storage of the base Class
- create a base class file that inherits from Sprite or MovieClip (see the TextSprite example below)
- add code in it if you want these instances to have a particular behaviour at compilation
- the base class of the Sprites or MovieClip instances is stored in the Json description only if they are different than Sprite or MovieClip
- At runtime, get the base class name with the MovieClip/Sprite getBaseClass method
- At runtime, create custom behaviour on the base class if you want

### Flipbook class
- create a base class file named Flipbook

        package {
			import flash.display.MovieClip;
			public class Flipbook extends MovieClip {}
        }
		
- set the base class of a Symbol to the Flipbook class
- Now your Symbol is a Flipbook (no need to name the first layer)
	
## At the moment
- only [pixi-flump-runtime](https://github.com/jackwlee01/pixi-flump-runtime) supports Flump+ features.
- Tint and mask are not visibles in the Flump+ preview (only in a project using pixi-flump-runtime)

## Examples of new features usage
### Support of Dynamic TextField
- Create a base Class named TextSprite, for example:

        package {
        	import flash.display.Sprite;
        	import flash.text.TextField;
        	import flash.utils.getQualifiedClassName;
        	public class TextSprite extends Sprite {
        		public function TextSprite() {
        			super();
        			for (var i:int = numChildren - 1; i >= 0; i--) {
        				if (getQualifiedClassName(getChildAt(i)) == "flash.text::TextField") removeChildAt(i);
        			}
        			if (numChildren==0) {
        				graphics.lineTo(1, 1);
        				graphics.lineStyle(1, 0, 0);
        			}
        		}
        	}
        }


- Set the base class of Sprite symbols that only contain a TextField to the TextSprite class
- Store the description of the TextFields in the custom Data
- At compile time, the TextSprite class will remove the TextField to avoid its integration in the atlas
- At runtime, using data from custom Data storage allows to build a dynamic TextField like in the FLA

### Support of filters
- Store the filters data in the instance persistent data
- At runtime, get the filter data with getLayerCustomData and apply a similar filter

# Flump

Flump reads specially-constructed `.fla` and `.xfl` files saved by Flash and extracts animations and
textures to allow them to be recreated in the GPU. Animations created in Flump's style will use far
less texture memory per frame of animation than an equivalent flipbook animation, allowing for more
expressive animations on mobile platforms. Runtimes have been written for [Starling], [Sparrow],
[Flambe], [PlayN], and [StageXL].

[Starling]: https://github.com/threerings/flump/tree/master/runtime
[Sparrow]: https://github.com/threerings/betwixt
[Flambe]: https://github.com/aduros/flambe
[PlayN]: https://github.com/threerings/tripleplay
[StageXL]: http://www.stagexl.org/index.html

# Creating a movie for Flump

1. [Install the latest version of Adobe AIR](http://get.adobe.com/air/).
1. [Install the Flump AIR app](https://github.com/threerings/flump/releases/latest).
2. Create a `.fla` in Flash CS 5, 5.5, or 6.
3. Create a new item in the library and draw a shape in its canvas.
4. Right-click on the item, select its properties, tick the **Export for ActionScript** and
   **Export in frame 1** checkboxes and change its base class to `flash.display.Sprite`.
5. Create a second item in the library, and drag the first into it.
6. Add additional frames in the second item, and create a classic tween moving the first item around
   in those frames.
6. Set the **Export for ActionScript** and **Export in frame 1** properties for the second item. Leave its base class as `flash.display.MovieClip`.
7. Save the file and publish it as a swf.
8. Open the Flump app and change its import directory to the directory containing the `.fla` and
   `.swf` files. The `.fla` file should appear in the list of source files.
9. Select the `.fla` file and click 'Preview'. The tween you created in step 6 should start playing
   back in a preview window.

# Details of Flump's conversion

This walks through Flump's process when it exports a single .fla/.swf file combo.

### Texture creation

For each item in the document's library that is exported for ActionScript and extends
`flash.display.Sprite`, Flump creates a texture. To do so, it instantiates the library's exported
symbol from the `.swf` file and renders it to a bitmap.

All of the created bitmaps for a Flash document are packed into texture atlases, and xml is
generated to map between a texture's symbol and its location in the bitmap.

### Animation creation

For each item in the document's library that extends `flash.display.MovieClip` and isn't a flipbook
(explained below), Flump creates an animation. It checks that for all layers and keyframes, each
used symbol is either a texture, an animation, or a flipbook. Flump animations can only be
constructed from the flump types.

### Flipbook creation

For animations that only contain a few frames, a flipbook may be more appropriate. To create one,
add a new item to the library and name the first layer in the created item `flipbook`. When
exporting, flump will create a bitmap for each keyframe in the flipbook layer. In playback, flump
will display those bitmaps at the same timing.

### Compatibility

Flump works with Flash CS 5 and later

# Precompiled binaries

[Get them here](https://github.com/threerings/flump/releases/latest)

# Building

You will need these dependencies to build Flump:

* [Flex SDK 4.6](http://www.adobe.com/devnet/flex/flex-sdk-download.html).

* [AIR SDK](https://www.adobe.com/devnet/air/air-sdk-download.html). 

* [AIR SDK with Flex Support](https://www.adobe.com/devnet/air/air-sdk-download.html) You'll also need to download the version of the AIR SDK that comes *without* the new compiler (links near the bottom of that page) and [follow the instructions here to overlay it on the Flex SDK](http://helpx.adobe.com/x-productkb/multi/how-overlay-air-sdk-flex-sdk.html)

* [Ant](http://ant.apache.org/)

1. Build the flump runtime

        flump/runtime$ ant -Dairsdk.dir=/path/to/air maven-deploy

2. Build the flump exporter

        flump/exporter$ ant -Dflexsdk.dir=/path/to/flex swf
        
3. Build the flump demo

        flump/demo ant -Dairsdk.dir=/path/to/air

4. To get AIR to report errors, run Flump with the AIR debugger (adl):

        flump/exporter$ /path/to/air/bin/adl etc/airdesc.xml dist
        
# Runtimes

A list of known Flump runtime implementations for different languages and frameworks:

* [Flump (Starling/AS3)](https://github.com/tconkling/flump) (the reference runtime, contained here)
* [Flambe (Haxe)](https://github.com/aduros/flambe)
* [pixi-flump-runtime (Haxe/PixiJs)](https://github.com/jackwlee01/pixi-flump-runtime)
* [StageXL_Flump](https://github.com/bp74/StageXL_Flump) (Dart / HTML5 / WebGL / Canvas)
* [Betwixt (Sparrow/Objective-C)](https://github.com/threerings/betwixt) (no longer maintained)
* [pixi-flump](https://github.com/mientjan/pixi-flump) (Javascript/PixiJs)
* [Lump (LÖVE2D)](https://github.com/sixFingers/lump) (Lua)
