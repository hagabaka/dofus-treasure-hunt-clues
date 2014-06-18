// Return list of coordinates as used in CSS polygon expressions
function polygon(points) {
  return 'polygon(' + points.map(function(point) {
    return point.map(function(coordinate) {
      return coordinate + 'px';
    }).join(' ');
  }).join(', ') + ')';
}

// Rectangle class
// coordinates is an object with properties top, right, bottom, left
function Rectangle(coordinates) {
  var rectangle = this;
  ['top', 'bottom', 'left', 'right'].forEach(function(property) {
    // assign properties top, right, bottom, left
    rectangle[property] = coordinates[property];
  });
}

['top', 'bottom'].forEach(function(y) {
  ['left', 'right'].forEach(function(x) {
    // define methods like topLeft(), bottomRight()
    var capitalizedX = x.replace(/^./, function(letter) {
      return letter.toUpperCase();
    });
    Rectangle.prototype[y + capitalizedX] = (function(x, y) {
      return function() {
        return [this[x], this[y]];
      };
    }(x, y));
  });
});

// Return Rectangle with coordinates relative to given point
Rectangle.prototype.relativeTo = function(point) {
  var x = point[0], y = point[1];
  return new Rectangle({
    left:   this.left   - x,
    right:  this.right  - x,
    top:    this.top    - y,
    bottom: this.bottom - y
  });
}

// Return list of coordinates as used in CSS polygon expressions
Rectangle.prototype.asPolygon = function() {
  return [this.topLeft(), this.topRight(), this.bottomRight(), this.bottomLeft()];
}

// Return intersection with other rectangle
Rectangle.prototype.intersection = function(other) {
  return new Rectangle({
    left   : Math.max(this.left  , other.left  ),
    top    : Math.max(this.top   , other.top   ),
    right  : Math.min(this.right , other.right ),
    bottom : Math.min(this.bottom, other.bottom)
  });
};

Rectangle.prototype.isValid = function() {
  return this.bottom > this.top && this.right > this.left;
};

// Return Rectangle bounding the jQuery wrapped element
Rectangle.ofElement = function(element) {
  var elementLeft = element.offset().left;
  var elementTop  = element.offset().top;
  return new Rectangle({
    left:   elementLeft,
    top:    elementTop,
    right:  elementLeft + element.outerWidth(),
    bottom: elementTop  + element.outerHeight(),
  });
}

// BlurBlocked class
// blocking is a $() wrapped element that blocks others, and
// potentiallyBlockedSelector is a jQuery selector
function BlurBlocked (blocking, potentiallyBlocked) {
  this.blocking = blocking;
  this.potentiallyBlocked = potentiallyBlocked;

  this.previouslyBlocked = $([]);
  this.blocking.css('z-index', 20);
}

(function() {
  // Update the blur clones, should be called when page scrolls, and when potentiallyBlocked
  // elements change
  BlurBlocked.prototype.update = function() {
    var potentiallyBlocked = this.potentiallyBlocked.not('.blur-clone');

    // Clean up previous blur clones
    $('svg').detach();
    this.previouslyBlocked.not(potentiallyBlocked).each(function() {
      removeBlurClone(this);
    });
    this.previouslyBlocked = $([]);

    var blurBlocked = this;
    potentiallyBlocked.each(function() {
      var element = $(this);
      var elementRectangle = Rectangle.ofElement(element);
      var blockingRectangle = Rectangle.ofElement(blurBlocked.blocking);

      blockedPart = elementRectangle.intersection(blockingRectangle);

      if(blockedPart.isValid()) {
        // The element is blocked
        blurBlocked.previouslyBlocked = blurBlocked.previouslyBlocked.add(element);

        // Create a blurred clone if this element doe not have one
        if(!this.__blurClone__) {
          this.__blurClone__ = element.clone().addClass('blur-clone').css({
            position:  'absolute',
            'z-index': 10,
          }).insertAfter(element);
        }

        // Position the blurred clone to overlap the element, and clip it to the
        // blocking element
        var cloneClip = blockingRectangle.relativeTo(elementRectangle.topLeft());
        this.__blurClone__.offset(elementRectangle)
                          .clipPath(cloneClip.asPolygon(), {svgDefId: newId()});

        // Clip the original element to everything except the blocking element
        //     5
        //    1+-----------+2
        //     |\10        |
        //     |6+-------+9|
        //     | |       | |
        //     |7+-------+8|
        //     |           |
        //    4+-----------+3
        var everything = new Rectangle({top: -5000, left: -5000, bottom: 10000, right: 10000});
        var elementClipPath = [
              everything.topLeft(), everything.topRight(), everything.bottomRight(),
              everything.bottomLeft(), everything.topLeft(), cloneClip.topLeft(),
              cloneClip.bottomLeft(), cloneClip.bottomRight(), cloneClip.topRight(),
              cloneClip.topLeft()
            ];
        element.clipPath(elementClipPath, {svgDefId: newId()});
      } else {
        removeBlurClone(this);
      }
    });
  }

  // Remove blur clones
  BlurBlocked.prototype.clear = function() {
    this.previouslyBlocked.each(function() {
      removeBlurClone(this);
    });
  }

  // Delete and detach the blurred clone
  function removeBlurClone(node) {
    if(node.__blurClone__) {
      node.__blurClone__.detach();
      delete node.__blurClone__;
      $(node).css('-webkit-clip-path', '');
    }
  }

  var id = 0;
  function newId() {
    return 'blur-blocked-clip-path-' + (id++).toString();
  }
} ());

