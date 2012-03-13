//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.geom.Point;

import flump.SwfTexture;
import flump.xfl.XflKeyframe;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

import com.threerings.util.Comparators;

public class Packer
{
    public const atlases :Vector.<Atlas> = new Vector.<Atlas>();

    public function Packer (target :DeviceType, authored :DeviceType, lib :XflLibrary) {
        _target = target;
        _lib = lib;
        var scale :Number = target.resWidth / authored.resWidth;
        for each (var tex :XflTexture in _lib.textures) {
            _unpacked.push(SwfTexture.fromTexture(_lib.swf, tex, scale));
        }
        for each (var movie :XflMovie in _lib.movies) {
            if (!movie.flipbook) continue;
            for each (var kf :XflKeyframe in movie.layers[0].keyframes) {
                _unpacked.push(SwfTexture.fromFlipbook(lib.swf, movie, kf.index, scale));
            }
        }
        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));
        while (_unpacked.length > 0) pack();
    }

    public function get targetDevice () :DeviceType {
        return _target;
    }

    protected function pack () :void {
        const tex :SwfTexture = _unpacked[0];
        if (tex.w > MAX_SIZE || tex.h > MAX_SIZE) throw new Error("Too large to fit in an atlas");
        for each (var atlas :Atlas in atlases) {
            // TODO(bruno): Support rotated textures?
            if (atlas.place(tex)) {
                _unpacked.shift();
                return;
            }
        }

        // It didn't fit in any existing atlas, add another one
        var size :Point = findOptimalSize();
        atlases.push(new Atlas(_lib.location + "/atlas" + atlases.length, _target, size.x, size.y));
        pack();
    }

    // Estimate the optimal size for the next atlas
    protected function findOptimalSize () :Point {
        var area :int = 0;
        var maxW :int = 0;
        var maxH :int = 0;
        for each (var tex :SwfTexture in _unpacked) {
            var w :int = tex.w + 2*Atlas.PADDING;
            var h :int = tex.h + 2*Atlas.PADDING;
            area += w*h;
            maxW = Math.max(maxW, w);
            maxH = Math.max(maxH, h);
        }

        var size :Point = new Point(nextPowerOfTwo(maxW), nextPowerOfTwo(maxH));

        // Double the area until it's big enough
        while (size.x*size.y < area) {
            if (size.x < size.y) {
                size.x *= 2;
            } else {
                size.y *= 2;
            }
        }

        size.x = Math.min(size.x, MAX_SIZE);
        size.y = Math.min(size.y, MAX_SIZE);

        return size;
    }

    protected static function nextPowerOfTwo (n :int) :int
    {
        var p :int = 1;
        while (p < n) {
            p *= 2;
        }
        return p;
    }

    protected var _unpacked :Vector.<SwfTexture> = new Vector.<SwfTexture>();

    protected var _target :DeviceType;
    protected var _lib :XflLibrary;

    // Maximum width or height of a texture atlas
    private static const MAX_SIZE :int = 1024;
}
}
