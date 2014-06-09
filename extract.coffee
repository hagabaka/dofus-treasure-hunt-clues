#!/usr/bin/env phantomjs

page = require('webpage').create()
log = require('system').stderr.writeLine
output = 'clues.json'
data = {}

openPage = (url) ->
  page.onLoadFinished = processPage
  log 'Opening ' + url
  page.open url

finish = ->
  log 'Writing to ' + output
  require('fs').write(output, JSON.stringify(data), 'w')
  phantom.exit()

processPage = (status) ->
  unless status is 'success'
    log 'Failed to load page'
    finish()

  newData = page.evaluate ->
    result = {}
    jQuery('div.post.entry-content span[rel="lightbox"] > img.bbc_img').each ->
      img = jQuery(this)
      parentParagraph = img.closest('p')
      unless parentParagraph.length
        parentParagraph = img.parent()
      clueElement = parentParagraph.prevAll().find('strong, u').first()
      clue = clueElement.text().trim().toLowerCase()
      if !clue.length
        clue = '** unknown clue **'
      url = img.attr('src')
      if clue of result
        result[clue].push(url)
      else
        result[clue] = [url]
    result

  for clue of newData
    if clue of data
      data[clue] = data[clue].concat newData[clue]
    else
      data[clue] = newData[clue]

  nextPage = page.evaluate -> jQuery('a[rel="next"]').attr('href')
  if nextPage
    openPage nextPage
  else
    finish()

openPage 'http://impsvillage.com/forums/topic/141320-treasure-hunting-the-guide/'

