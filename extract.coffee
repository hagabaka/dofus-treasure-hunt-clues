#!/usr/bin/phantomjs --config=config.json

page = require('webpage').create()

phantom.injectJs('underscore.js')

log = require('system').stderr.writeLine
page.onConsoleMessage = log

output = 'clues.json'

# Elements of data are in the form {clue:, image:, source: {post:, author: }}
data = []

openPage = (url) ->
  page.onLoadFinished = processPage
  log 'Opening ' + url
  page.open url

finish = ->
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

  outputData = _(outputData).sortBy 'clue'
  outputString = JSON.stringify(outputData, null, ' ')
  log 'Writing to ' + output
  require('fs').write(output, outputString, 'w')
  phantom.exit()

processPage = (status) ->
  unless status is 'success'
    log 'Failed to load page'
    finish()

  log 'Processing page'
  page.injectJs 'jquery.ba-replacetext.js'

  data = data.concat page.evaluate ->
    result = []
    jQuery('div.post.entry-content').each ->
      postBlock = jQuery(this)
      textSegments = []
      postBlock.add(postBlock.find('*')).replaceText /.+/, (text) ->
        textSegments.push text
        # Clues must contain letters, and can only contain letters, whitespace, dash, apostrophe,
        # parentheses, and colon
        if /[a-zA-Z]/.test(text) and /^[-a-zA-Z():\s']+$/.test(text)
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
              clue = jQuery(clueElement).text().trim()
          if clue is '~ unknown clue ~'
            console.log "Failed to find clue from: #{JSON.stringify(textSegments)}"

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
    finish()

openPage 'http://impsvillage.com/forums/topic/141320-treasure-hunting-the-guide/'

