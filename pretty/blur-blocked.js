var blurBlocked = (function() {
  var my = {}

  var blocking;
  var potentiallyBlockedSelector;
  var previouslyBlocked;

  // _blocking is a $() wrapped element that blocks others, and
  // _potentiallyBlockedSelector is a jQuery selector
  my.initialize = function(_blocking, _potentiallyBlockedSelector) {
    blocking = _blocking;
    blocking.css('z-index', 20);
    previouslyBlocked = $([]);
    potentiallyBlockedSelector = _potentiallyBlockedSelector;
  }

  // Update the blur clones, should be called when page scrolls, and when potentiallyBlocked
  // elements change
  my.update = function() {

    var potentiallyBlocked = $(potentiallyBlockedSelector).not('.blur-clone');

    // Clean up previous blur clones
    previouslyBlocked.not(potentiallyBlocked).each(function() {
      removeBlurClone(this);
    });
    previouslyBlocked = $([]);

    potentiallyBlocked.each(function() {
      var element = $(this);
      var elementBox = box(element);
      var blockingBox = box(blocking);

      blockedBox = {
        left:   Math.max(blockingBox.left  , elementBox.left  ),
        top:    Math.max(blockingBox.top   , elementBox.top   ),
        right:  Math.min(blockingBox.right , elementBox.right ),
        bottom: Math.min(blockingBox.bottom, elementBox.bottom),
      };

      if(blockedBox.bottom > blockedBox.top && blockedBox.right > blockedBox.left) {
        // The element is blocked
        previouslyBlocked = previouslyBlocked.add(element);

        // Create a blurred clone if this element doe not have one
        if(!this.__blurClone__) {
          this.__blurClone__ = element.clone().addClass('blur-clone').css({
            position:  'absolute',
            'z-index': 10,
          }).insertAfter(element);
        }

        // Position the blurred clone to overlap the element, and clip it to the
        // blocking element
        var clipBox = {
          top:    Math.max(blockingBox.top    - elementBox.top,  -1),
          left:   Math.max(blockingBox.left   - elementBox.left, -1),
          bottom: Math.max(blockingBox.bottom - elementBox.top ,  1),
          right:  Math.max(blockingBox.right  - elementBox.left,  1),
        };
        var clipPx = boxWithPx(clipBox);
        this.__blurClone__.offset(elementBox).css('-webkit-clip-path', boxToPolygon(clipPx));

        /*      1---------------2
         *      |               |
         *      10-+-------9    |
         * y -> 5--6       |    |
         *      |  |       |    |
         *      |  7-------8    |
         *      4---------------3
         *
         *
         *
         */
        var elementPx = boxWithPx({
          left:   -1,
          top:    -1,
          right:  element.outerWidth()  + 1,
          bottom: element.outerHeight() + 1,
        });
        var y = (clipBox.top - 1).toString() + 'px';
        var right = (elementBox.right + 1).toString() + 'px';
        var elementPolygon =  polygon(
          [elementPx.left,  elementPx.top   ],
          [elementPx.right, elementPx.top   ],
          [elementPx.right, elementPx.bottom],
          [elementPx.left,  elementPx.bottom],
          [elementPx.left,  y               ],
          [clipPx.left,     y               ],
          [clipPx.left,     clipPx.bottom   ],
          [clipPx.right,    clipPx.bottom   ],
          [clipPx.right,    clipPx.top      ],
          [elementPx.left,  clipPx.top      ]
        );
        console.log(elementPolygon);
        element.css('-webkit-clip-path', elementPolygon);
      } else {
        removeBlurClone(this);
      }
    });
  }

  // Remove blur clones
  my.clear = function() {
    previouslyBlocked.each(function() {
      removeBlurClone(this);
    });
  }

  // Return object containing the left, top, right and bottom coordinates
  function box(element) {
    var elementLeft = element.offset().left;
    var elementTop  = element.offset().top;
    return  {
      left:   elementLeft,
      top:    elementTop,
      right:  elementLeft + element.outerWidth(),
      bottom: elementTop  + element.outerHeight(),
    };
  }

  // Append 'px' to all properties
  function boxWithPx(regularBox) {
    newBox = {}
    for(coordinate in regularBox) {
      newBox[coordinate] = regularBox[coordinate] + 'px';
    }
    return newBox;
  }

  // Return list of coordinates as used in CSS polygon expressions
  function boxToPolygon(_box) {
    return polygon([_box.left , _box.top   ],
                   [_box.right, _box.top   ],
                   [_box.right, _box.bottom],
                   [_box.left , _box.bottom]);
  }

  // Return list of coordinates as used in CSS polygon expressions
  function polygon() {
    var points = $.makeArray(arguments);
    return 'polygon(' + points.map(function(point) {
      return point.join(' ');
    }).join(', ') + ')';
  }
  // Delete and detach the blurred clone
  function removeBlurClone(node) {
    if(node.__blurClone__) {
      node.__blurClone__.detach();
      delete node.__blurClone__;
      $(node).css('-webkit-clip-path', '');
    }
  }

  return my;
} ());

