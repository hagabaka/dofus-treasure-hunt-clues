// Highlighting HTML Access Keys by Christian Schmidt
// This code may be freely used, copied, modified, distributed etc.

// Iterates through all elements that support the ACCESSKEY attribute.
function highlightAccessKeys() {
    //don't do anything in old browsers
    if (!document.getElementsByTagName) return;

    var labels = document.getElementsByTagName('LABEL');
    for (var i = 0; i < labels.length; i++) {
        var control = document.getElementById(labels[i].htmlFor);
        if (control && control.accessKey) {
            highlightAccessKey(labels[i], control.accessKey);
        } else if (labels[i].accessKey) {
            highlightAccessKey(labels[i], labels[i].accessKey);
        }
    }

    var tagNames = new Array('A', 'BUTTON', 'LEGEND');
    for (var j = 0; j < tagNames.length; j++) {
        var elements = document.getElementsByTagName(tagNames[j]);
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].accessKey) {
                highlightAccessKey(elements[i], elements[i].accessKey);
            }
        }
    }
}

// Highlights the specified character in the specified element
function highlightAccessKey(e, accessKey) {
    if (e.hasChildNodes()) {
        var childNode, txt;
        
        //find the first text node that contains the access character
        for (var i = 0; i < e.childNodes.length; i++) {
            txt = e.childNodes[i].nodeValue;
            if (e.childNodes[i].nodeType == 3 &&
                txt.toLowerCase().indexOf(accessKey.toLowerCase()) != -1) {
            
                childNode = e.childNodes[i];
                break;
            }
        }
        
        if (!childNode) {
            //access character was not found
            return;
        }

        var pos = txt.toLowerCase().indexOf(accessKey.toLowerCase());
        var span = document.createElement('SPAN');
        var spanText = document.createTextNode(txt.substr(pos, 1));
        span.className = 'accesskey';
        span.appendChild(spanText);

        //the text before the access key
        var text1 = document.createTextNode(txt.substr(0, pos));
        //the text after the access key
        var text2 = document.createTextNode(txt.substr(pos + 1));
        
        if (text1.length > 0) e.insertBefore(text1, childNode);
        e.insertBefore(span, childNode);
        if (text2.length > 0) e.insertBefore(text2, childNode);

        e.removeChild(childNode);
    }
}
