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
  # Do not load ads, videos etc
  page.onResourceRequested = (requestData, request) ->
    unless /impsvillage|jquery/.test(requestData.url)
      request.abort()

  log 'Opening ' + url
  page.open url

processPage = (status) ->
  unless status is 'success'
    log 'Failed to load page'
    finish 1

  log 'Processing page'
  page.injectJs 'jquery.ba-replacetext.js'
  page.injectJs 'sugar-date.js'

  data = data.concat page.evaluate ->
    result = []
    jQuery('div.post.entry-content').each ->
      postBlock = jQuery(this)

      textSegments = []
      postBlock.add(postBlock.find('*')).replaceText /.+/, (text) ->
        textSegments.push text
        if text isnt 'Spoiler' and not /^\s*$/.test(text)
          "<span class='possible_clue'>#{text}</span>"
        else
          ''

      textBlocksAndImages = postBlock.find('span.possible_clue, img.bbc_img')
      textBlocksAndImages.each (index, element) ->
        if element.tagName is 'IMG'
          clue = null
          if index > 0
            previous = jQuery.makeArray(textBlocksAndImages)[0 .. index - 1].reverse()
            clueElement = previous.find (predecessor) -> predecessor.tagName is 'SPAN'
            if clueElement
              text = jQuery(clueElement).text().trim()
              # Clues are at most 9 words long, must start with letters, and can only contain
              # letters, whitespace, dash apostrophe, double quotes, parentheses, comma, and
              # colon. An entire clue wrapped by '~ ... ~' is also accepted.
              letter = 'a-zA-Z\u00C0-\u017F'
              phrase = ///[ #{letter} ] [ - #{letter} \s ' " ( ) , : ]+///.source
              if ///
                  ^ ~ \s+ #{phrase} \s+ ~ $ |
                  ^     " #{phrase} "     $ |
                  ^       #{phrase}       $
                 ///.test(text) and text.split(/\s+/).length <= 9
                clue = text

          # unless clue
          #   console.log "dofustreasurehuntclues: Failed to find clue from: #{JSON.stringify(textSegments)}"

          img = jQuery(element)

          postWrap = img.closest('.post_wrap')
          editDateString =
            postBlock.find('.edit strong').text().replace(/^Edited by [^,]+, (.+)\.$/, '$1')
          postDateString = postWrap.find('[itemprop="commentTime"]').text()
          lastUpdated = Date.create (editDateString or postDateString).replace(' - ', ' ')
          console.log "dofustreasurehuntclues: #{JSON.stringify [editDateString, postDateString, editDateString or postDateString]}" unless lastUpdated.valueOf()
          image = img.attr('src')
          post = postWrap.find('a[rel="bookmark"]').attr('href')
          author = postWrap.find('.post_username [itemprop~="name"]').text().trim()
          result.push {clue, image, source: {post, author, lastUpdated}}
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
    entry.clue = entry.clue.replace /^"(.+)"$/, '$1'
    entry.clue = entry.clue.replace /\s*\(.+\)$/, ''
    entry.clue = entry.clue.replace /\s*".+"$/, ''
    entry.clue = entry.clue.replace /\s*:\s*$/, ''

  # Eliminate duplicate images, by having each image use the latest updated known clue
  clueForImage = {}
  data.forEach (entry) ->
    {clue, image, source: {lastUpdated}} = entry
    if clue and
       (image not of clueForImage or lastUpdated > clueForImage[image].lastUpdated)
      clueForImage[image] = {lastUpdated, clue}

  data.forEach (entry) ->
    entry.clue = clueForImage[entry.image]?.clue or '~ unknown clue ~'

  # Elements in OutputData are in the form {clue:, images: [image:, sources: {[post:, author:]}]}
  outputData = []
  groupedByClue = _(data).groupBy 'clue'
  for clue of groupedByClue
    images = []
    groupedByImage = _(groupedByClue[clue]).groupBy 'image'
    for image of groupedByImage
      sources = groupedByImage[image].map (element) ->
        element.source
      sources = _(sources).sortBy 'lastUpdated'
      images.push {image, sources}
    outputData.push {clue, images}

  outputData = _(outputData).sortBy (entry) ->
    entry.clue.toLowerCase()
  outputString = JSON.stringify(outputData, null, ' ')
  log 'Writing to ' + output
  require('fs').write(output, outputString, 'w')
  phantom.exit status

openPage 'http://impsvillage.com/forums/topic/141320-treasure-hunting-the-guide/'

