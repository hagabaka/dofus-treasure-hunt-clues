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

        clipBox = cssBox({
          top:    blockingBox.top    - elementBox.top,
                  left:   blockingBox.left   - elementBox.left,
                  bottom: blockingBox.bottom - elementBox.top ,
                  right:  blockingBox.right  - elementBox.left,
        });

        // Create a blurred clone if this element doe not have one
        if(!this.__blurClone__) {
          this.__blurClone__ = element.clone().addClass('blur-clone').css({
            position:  'absolute',
            'z-index': 10,
          }).insertAfter(element);
        }

        // Position the blurred clone to overlap the element, and clip it to the
        // blocking element
        this.__blurClone__.offset(elementBox).css('clip',
            'rect(' + clipBox.top    + ', ' + clipBox.right + ', ' +
                      clipBox.bottom + ', ' + clipBox.left  + ')');

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
  function cssBox(regularBox) {
    newBox = {}
    for(coordinate in regularBox) {
      newBox[coordinate] = regularBox[coordinate] + 'px';
    }
    return newBox;
  }

  // Delete and detach the blurred clone
  function removeBlurClone(node) {
    if(node.__blurClone__) {
      node.__blurClone__.detach();
      delete node.__blurClone__;
    }
  }

  return my;
} ());

