#!/usr/bin/phantomjs --config=config.json

page = require('webpage').create()

phantom.injectJs('underscore.js')

log = require('system').stderr.writeLine
page.onConsoleMessage = (message) ->
  message = /^dofustreasurehuntclues: (.*)/.exec(message)?[1]
  log message if message

output = 'clues.json'

# Elements of data are in the form {clue:, image:, source: {post:, author: }}
data = []

openPage = (url) ->
  page.onLoadFinished = processPage
  log 'Opening ' + url
  page.open url

processPage = (status) ->
  unless status is 'success'
    log 'Failed to load page'
    finish 1

  log 'Processing page'
  page.injectJs 'jquery.ba-replacetext.js'

  data = data.concat page.evaluate ->
    result = []
    jQuery('div.post.entry-content').each ->
      postBlock = jQuery(this)
      textSegments = []
      postBlock.add(postBlock.find('*')).replaceText /.+/, (text) ->
        textSegments.push text
        # Clues are at most 9 words long, must start with letters, and can only contain
        # letters, whitespace, dash apostrophe, double quotes, parentheses, comma, and colon
        if text isnt 'Spoiler' and not /^\s*$/.test(text)
          "<span class='possible_clue'>#{text}</span>"
        else
          ''

      textBlocksAndImages = postBlock.find('span.possible_clue, img.bbc_img')
      textBlocksAndImages.each (index, element) ->
        if element.tagName is 'IMG'
          clue = '~ unknown clue ~'
          if index > 0
            previous = jQuery.makeArray(textBlocksAndImages)[0 .. index - 1].reverse()
            clueElement = previous.find (predecessor) -> predecessor.tagName is 'SPAN'
            if clueElement
              text = jQuery(clueElement).text().trim()
              if /^[a-zA-Z\u00C0-\u017F][-a-zA-Z\u00C0-\u017F\s'"(),:]+$/.test(text) and
                 text.split(/\s+/).length <= 9
                clue = text

          if clue is '~ unknown clue ~'
            console.log "dofustreasurehuntclues: Failed to find clue from: #{JSON.stringify(textSegments)}"

          img = jQuery(element)

          postWrap = img.closest('.post_wrap')
          image = img.attr('src')
          result.push
            clue: clue
            image: image
            source:
              post : postWrap.find('a[rel="bookmark"]').attr('href')
              author : postWrap.find('.post_username [itemprop~="name"]').text().trim()
    result

  nextPage = page.evaluate -> jQuery('a[rel="next"]').attr('href')
  if nextPage
    openPage nextPage
  else
    finish 0

finish = (status) ->
  # Fix some typos
  fixes =
    'alchemists sign': 'Alchemist sign'
    'Bomard : (not sure if anyone posted this yet)': 'Bombard'
    'Broom in Astrub': 'Broom'
    'Cenatur statue': 'Centaur statue'
    'Clam with pearl': 'Clam with a pearl'
    'Frozen Pingwin and Kani': 'Frozen Pingwin and Kanigloo'
  data.forEach (entry) ->
    if entry.clue of fixes
      entry.clue = fixes[entry.clue]

  # Normalize clues FIXME capitalize first word and proper nouns, instead of all lower case
  data.forEach (entry) ->
    entry.clue = entry.clue.toLowerCase()
    entry.clue = entry.clue.replace /\s*\(.+\)$/, ''
    entry.clue = entry.clue.replace /\s*".+"$/, ''
    entry.clue = entry.clue.replace /\s*:\s*$/, ''

  # Eliminate duplicate images, by having each image use the first known clue
  clueForImage = {}
  data.forEach (entry) ->
    if entry.clue isnt '~ unknown clue ~'
      clueForImage[entry.image] ?= entry.clue
  data.forEach (entry) ->
    entry.clue = clueForImage[entry.image] or '~ unknown clue ~'

  # Elements in OutputData are in the form {clue:, images: [image:, sources: {[post:, author:]}]}
  outputData = []
  groupedByClue = _(data).groupBy 'clue'
  for clue of groupedByClue
    images = []
    groupedByImage = _(groupedByClue[clue]).groupBy 'image'
    for image of groupedByImage
      sources = groupedByImage[image].map (element) ->
        element.source
      images.push {image: image, sources: sources}
    outputData.push {clue: clue, images: images}

  outputData = _(outputData).sortBy (entry) ->
    entry.clue.toLowerCase()
  outputString = JSON.stringify(outputData, null, ' ')
  log 'Writing to ' + output
  require('fs').write(output, outputString, 'w')
  phantom.exit status

openPage 'http://impsvillage.com/forums/topic/141320-treasure-hunting-the-guide/'

