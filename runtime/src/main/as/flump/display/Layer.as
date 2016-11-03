//
// Flump - Copyright 2013 Flump Authors

package flump.display {

import flash.geom.Rectangle;
import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import starling.display.Canvas;
import starling.display.DisplayObject;
import starling.display.Quad;
import starling.display.Sprite;
import starling.filters.ColorMatrixFilter;
import starling.geom.Polygon;




/**
 * A logical wrapper around the DisplayObject(s) residing on the timeline of a single layer of a
 * Movie. Responsible for efficiently managing the creation and display of the DisplayObjects for
 * this layer on each frame.
 */
internal class Layer
{
    public function Layer (movie :Movie, src :LayerMold, library :Library, flipbook :Boolean) {
        _movie = movie;
        _keyframes = src.keyframes;
        _name = src.name;
		_mask = src.mask;

        const lastKf :KeyframeMold = _keyframes[_keyframes.length - 1];
        _numFrames = lastKf.index + lastKf.duration;

        var lastItem :String = null;
        for (var ii :int = 0; ii < _keyframes.length && lastItem == null; ii++) {
            lastItem = _keyframes[ii].ref;
        }

        if (!flipbook && lastItem == null) {
            // The layer is empty.
            _currentDisplay = new Sprite();
            movie.addChild(_currentDisplay);
            _numDisplays = 1;

        } else {
            // Create the display objects for each keyframe.
            // If multiple consecutive keyframes refer to the same library item,
            // we reuse that item across those frames.
            _displays = new Vector.<DisplayObject>(_keyframes.length, true);
            for (ii = 0; ii < _keyframes.length; ++ii) {
                var kf :KeyframeMold = _keyframes[ii];
                var display :DisplayObject = null;
                if (ii > 0 && _keyframes[ii - 1].ref == kf.ref) {
                    // Reuse previous frame's DisplayObject
                    display = _displays[ii - 1];
                } else {
                    // Create a new DisplayObject
                    _numDisplays++;
                    if (kf.ref == null) {
                        display = new Sprite();
                    } else {
                        display = library.createDisplayObject(kf.ref);
						var childMovie :Movie = (display as Movie);
                        if (childMovie != null) {
                            childMovie.setParentMovie(movie);
                        }
                    }
                }

                _displays[ii] = display;
                display.visible = false;
                movie.addChild(display);
            }

            _currentDisplay = _displays[0];
            _currentDisplay.visible = true;
        }

        _currentDisplay.name = _name;
    }

    public function get numDisplays () :int {
        return _numDisplays;
    }

    /** See Movie.removeChildAt */
    public function replaceCurrentDisplay (disp :DisplayObject) :void {
        _currentDisplay = disp;
        for (var ii :int = 0; ii < _displays.length; ++ii) {
            if (_displays[ii] == _currentDisplay) {
                _displays[ii] = disp;
            }
        }
        _currentDisplay = disp;
    }

    /** This Layer's name */
    public function get name () :String {
        return _name;
    }
	
    public function drawFrame (frame :int) :void {
        if (_displays == null || _disabled) {
            // We have nothing to display.
            return;

        } else if (frame >= _numFrames) {
            // We've overshot our final frame. Hide the display.
            _currentDisplay.visible = false;
            _keyframeIdx = _keyframes.length - 1;
            return;
        }

        // Update our keyframeIdx.
        // If our new frame appears before our previous keyframe in the timeline, we
        // reset our keyframeIdx to 0.
        if (_keyframes[_keyframeIdx].index > frame) {
            _keyframeIdx = 0;
        }
        // Next, we iterate keyframes, starting at keyframeIdx, until we find the keyframe
        // that contains our new frame.
        while (_keyframeIdx < _keyframes.length - 1 && _keyframes[_keyframeIdx + 1].index <= frame) {
            _keyframeIdx++;
        }

        // Swap in the proper DisplayObject for this keyframe.
        const disp :DisplayObject = _displays[_keyframeIdx];
        if (_currentDisplay != disp) {
            _currentDisplay.name = null;
            _currentDisplay.visible = false;
            // If we're swapping in a Movie, reset its timeline.
            if (disp is Movie) {
                Movie(disp).addedToLayer();
            }
            _currentDisplay = disp;
            _currentDisplay.name = _name;
        }

        const kf :KeyframeMold = _keyframes[_keyframeIdx];
        const layer :DisplayObject = _currentDisplay;
		
		if (_mask != null && layer.parent.getChildByName(_mask)!=null) {
			var lRect:Rectangle = _movie.getChildByName(_mask).bounds;
			_movie.removeChild(layer.parent.getChildByName(_mask));
			var mask:Quad = new Quad(lRect.width, lRect.height);
			mask.x = lRect.x;
			mask.y = lRect.y;
			_movie.addChild(mask);
			layer.mask = mask;
		}
		
		var lFilter:ColorMatrixFilter = new ColorMatrixFilter();
		var lColor:Object={};
		var lQ:Number;
		var lMultiplier:Number;
		
		
        if (_keyframeIdx == _keyframes.length - 1 || kf.index == frame || !kf.tweened) {
            layer.x = kf.x;
            layer.y = kf.y;
            layer.scaleX = kf.scaleX;
            layer.scaleY = kf.scaleY;
            layer.skewX = kf.skewX;
            layer.skewY = kf.skewY;
            layer.alpha = kf.alpha;
			
			if (kf.tint != null) {
				lMultiplier=kf.tint[0];
				lColor = getTint(parseInt(kf.tint[1].substr(1), 16));
				lQ = 1 - lMultiplier;
				
				lFilter.concatValues(
					lQ+lColor.r*lMultiplier, lColor.r*lMultiplier, lColor.r*lMultiplier, 0, 0,
					lColor.g*lMultiplier, lQ+lColor.g*lMultiplier, lColor.g*lMultiplier, 0, 0,
					lColor.b*lMultiplier, lColor.b*lMultiplier, lQ+lColor.b*lMultiplier, 0, 0,
					0, 0, 0, 1, 0);
				layer.filter = lFilter;
			}
			
        } else {
            var interped :Number = (frame - kf.index) / kf.duration;
            var ease :Number = kf.ease;
            if (ease != 0) {
                var t :Number;
                if (ease < 0) {
                    // Ease in
                    var inv :Number = 1 - interped;
                    t = 1 - inv * inv;
                    ease = -ease;
                } else {
                    // Ease out
                    t = interped * interped;
                }
                interped = ease * t + (1 - ease) * interped;
            }
            const nextKf :KeyframeMold = _keyframes[_keyframeIdx + 1];
            layer.x = kf.x + (nextKf.x - kf.x) * interped;
            layer.y = kf.y + (nextKf.y - kf.y) * interped;
            layer.scaleX = kf.scaleX + (nextKf.scaleX - kf.scaleX) * interped;
            layer.scaleY = kf.scaleY + (nextKf.scaleY - kf.scaleY) * interped;
            layer.skewX = kf.skewX + (nextKf.skewX - kf.skewX) * interped;
            layer.skewY = kf.skewY + (nextKf.skewY - kf.skewY) * interped;
            layer.alpha = kf.alpha + (nextKf.alpha - kf.alpha) * interped;	
			
			//TODO: eviter de réappliquer le filtre si ca n'a pas bougé
			if (kf.tint!=null || nextKf.tint!=null) {
				var lCurrent:Array = kf.tint == null ? [0, "#000000"] : kf.tint;
				var lNext:Array = nextKf.tint == null ? [0,"#000000"] : nextKf.tint;
				
				var lMultA:Number, lMultB:Number;
				var lA:Object, lB:Object;
				
				lA = getTint(parseInt(lCurrent[1].substr(1), 16));
				lMultA = lCurrent[0];
				
				lMultB = lNext[0];
			
				if (lCurrent[1] != lNext[1]) {
					lB = getTint(parseInt(lNext[1].substr(1), 16));
					lColor.r = lA.r + (lB.r - lA.r) * interped;
					lColor.g = lA.g + (lB.g - lA.g) * interped;
					lColor.b = lA.b + (lB.b - lA.b) * interped;
				} else lColor = lA;
				
				lMultiplier = lMultA +( lMultB - lMultA) * interped;
				lQ = 1 - lMultiplier;
				
				if (lMultiplier > 0) {
					lFilter.concatValues(
						lQ+lColor.r*lMultiplier, lColor.r*lMultiplier, lColor.r*lMultiplier, 0, 0,
						lColor.g*lMultiplier, lQ+lColor.g*lMultiplier, lColor.g*lMultiplier, 0, 0,
						lColor.b*lMultiplier, lColor.b*lMultiplier, lQ+lColor.b*lMultiplier, 0, 0,
						0, 0, 0, 1, 0);
					layer.filter = lFilter;
				}
				else layer.filter = null;
			}
			
        }
        layer.pivotX = kf.pivotX;
        layer.pivotY = kf.pivotY;
        layer.visible = kf.visible;
		
    }

    /** Expands the given bounds to include the bounds of this Layer's current display object. */
    internal function expandBounds (targetSpace :DisplayObject, resultRect :Rectangle) :Rectangle {
        // if no objects on this frame, do not change bounds
        if (_keyframes[_keyframeIdx].ref == null) {
            return resultRect;
        }

        // if no rect was incoming, the resulting bounds is exactly the bounds of the display
        if (resultRect.isEmpty()) {
            return _currentDisplay.getBounds(targetSpace, resultRect);
        }

        // otherwise expand bounds by current display's bounds, if it has any
        var layerRect :Rectangle = _currentDisplay.getBounds(targetSpace);
        if (layerRect.left < resultRect.left) resultRect.left = layerRect.left;
        if (layerRect.right > resultRect.right) resultRect.right = layerRect.right;
        if (layerRect.top < resultRect.top) resultRect.top = layerRect.top;
        if (layerRect.bottom > resultRect.bottom) resultRect.bottom = layerRect.bottom;

        return resultRect;
    }
	
	protected function getTint(pColor:int):Object {
		return {
			r: ((pColor >> 16) & 0xFF) /255,
			g: ((pColor >> 8) & 0xFF) /255,
			b: (pColor & 0xFF) /255
				};
	}
	

    protected var _movie :Movie; // our parent Movie
    protected var _name :String;
    protected var _keyframes :Vector.<KeyframeMold>;
    protected var _numFrames :int;
    // Stores this layer's DisplayObjects indexed by keyframe.
    protected var _displays :Vector.<DisplayObject>;
    // The index of the last keyframe drawn in drawFrame.
    protected var _keyframeIdx :int;

    // The current DisplayObject being rendered for this layer
    internal var _currentDisplay :DisplayObject;
    // If true, the Layer is not being updated by its parent movie. (Managed by Movie)
    internal var _disabled :Boolean;
    // The number of DisplayObjects we're managing
    protected var _numDisplays :int;
	
	protected var _mask:String;
}
}
