#!/usr/bin/phantomjs --config=config.json

page = require('webpage').create()
phantom.injectJs('underscore.js')

log = require('system').stderr.writeLine

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

  data = data.concat page.evaluate ->
    result = []
    jQuery('div.post.entry-content span[rel="lightbox"] > img.bbc_img').each ->
      img = jQuery(this)
      parentParagraph = img.closest('p')
      unless parentParagraph.length
        parentParagraph = img.parent()
      clueElement = parentParagraph.prevAll().find('strong, u').first()
      unless clueElement.length
        clueElement = parentParagraph.prevAll().filter('strong, u').first()
      clue = clueElement.text().trim()
      if !clue.length
        clue = '~ unknown clue ~'
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

