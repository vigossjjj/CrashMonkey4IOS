MonkeyResult = ->
  that = {}
  options = null

  that.configure = (opts) ->
    options = opts
    options.image_size_rate = opts.image_size_rate || 1
    that

  that.draw = ->
    ir = options.image_size_rate
    for log, i in options.log_list
      do (log, i) ->
        text_div = $('#'+options.text_prefix+'-'+i)
        text_div.html(log.message + "<hr>"+log.timestamp)
        img = new Image()
        img.addEventListener "load", ->
          element = $('#'+options.view_prefix+'-'+i)
          canvas = element[0]
          canvas.width = img.width * ir
          canvas.height = img.height * ir
          context = canvas.getContext('2d')
          context.scale(1,1)
          context.clearRect(0,0,canvas.width, canvas.height)
          context.drawImage(img, 0, 0, canvas.width, canvas.height)
          target = DrawTarget(canvas: canvas, context: context, image_size_rate: ir, index: i)
          eval(log.message)
        img.src = log.screen_image + '.png'

  return that

DrawTarget = (opts) ->
  that = {}
  options = opts
  canvas = options.canvas
  context = options.context
  ir = options.image_size_rate
  context.strokeStyle = "#f00"
  context.lineWidth = 2
  arc_radius = 20

  that.tapWithOptions = (p1, info) ->
    console.log(opts.index, p1, info)
    pos_to_number(p1)

    tc = 1*info.touchCount
    for num in [0..(tc-1)]
      o = x: (context.lineWidth + 2)*(num - (tc-1)/2), y: 0
      draw_arc({x: (p1.x*ir + o.x)/ir, y: (p1.y*ir + o.y)/ir}, r: 0.1)

    for num in [0..(1*info.tapCount-1)]
      draw_arc(p1, r: (arc_radius*ir + (1+context.lineWidth)*num)/ir)

  that.pinchCloseFromToForDuration = (p1, p2, info) ->
    pos_to_number(p) for p in [p1, p2]
    draw_arc(p1)
    draw_arc(p2)
    #
    center = x: (p1.x+p2.x)/2, y: (p1.y+p2.y)/2
    draw_arrow(p1, center)
    draw_arrow(p2, center)

  that.pinchOpenFromToForDuration = (p1, p2, info) ->
    pos_to_number(p) for p in [p1, p2]
    draw_arc(p1)
    draw_arc(p2)
    #
    center = x: (p1.x+p2.x)/2, y: (p1.y+p2.y)/2
    draw_arrow(center, p1)
    draw_arrow(center, p2)

  that.dragFromToForDuration = (p1, p2, info) ->
    pos_to_number(p) for p in [p1, p2]
    console.log(opts.index, p1, p2, info)
    draw_arc(p1)
    draw_arc(p2)
    draw_arrow(p1, p2)

  that.flickFromTo = (p1, p2, info) ->
    pos_to_number(p) for p in [p1, p2]
    console.log(opts.index, p1, p2, info)
    draw_arc(p1)
    draw_arrow(p1, p2)

  that.lockForDuration = (duration) ->
    draw_text("Lock Screen #{Math.floor(duration * 100)/100} Secs.")

  that.deactivateAppForDuration = (duration) ->
    draw_text("Deactivate #{Math.floor(duration * 100)/100} Secs.")

  that.setDeviceOrientation = (orientation) ->
    draw_text("Orientation to #{orientation_name(orientation)}")

  that.shake = ->
    draw_text("Shake!")

  that.clickVolumeUp = ->
    draw_text("clickVolumeUp!")

  that.clickVolumeDown = ->
    draw_text("clickVolumeDown!")

  draw_text = (text, opts={}) ->
    context.font = "10px 'ＭＳ Ｐゴシック'"
    context.lineWidth = 1
    context.strokeStyle = "green"
    context.beginPath()
    context.fillRect(canvas.width*0.1, 20, canvas.width*0.8, 40)
    context.stroke()
    context.strokeText(text, canvas.width*0.13, 42)


  orientation_name = (orientation) ->
    # http://www.testmachine.ch/javadoc/constant-values.html#ch.sukha.testmachine.client.IosDebuggingInterface.UIA_DEVICE_ORIENTATION_FACEDOWN
    switch 1 * orientation
      when 0 then "UNKNOWN"
      when 1 then "PORTRAIT"
      when 2 then "PORTRAIT_UPSIDEDOWN"
      when 3 then "LANDSCAPELEFT"
      when 4 then "LANDSCAPERIGHT"
      when 5 then "FACEUP"
      when 6 then "FACEDOWN"
      else "UNDEF"

  pos_to_number = (p) ->
    p.x = 1 * p.x
    p.y = 1 * p.y
    p

  draw_arc = (p, opts={}) ->
    radius = opts.r || arc_radius
    context.beginPath()
    context.arc(p.x * ir, p.y * ir, radius * ir, 0, Math.PI*2)
    context.stroke()

  draw_arrow = (p1, p2, opts={}) ->
    vx = p2.x - p1.x
    vy = p2.y - p1.y
    v = Math.sqrt(vx*vx + vy*vy)
    ux = vx/v
    uy = vy/v
    opts.w ||= 8
    opts.h ||= 12
    opts.h2 ||= 5
    lp = {x: p2.x - uy * opts.w - ux * opts.h, y: p2.y + ux * opts.w - uy * opts.h}
    rp = {x: p2.x + uy * opts.w - ux * opts.h, y: p2.y - ux * opts.w - uy * opts.h}
    mp = {x: p2.x - ux * opts.h2, y: p2.y - uy * opts.h2}
    context.beginPath()
    context.moveTo(p1.x * ir, p1.y * ir)
    context.lineTo(mp.x * ir, mp.y * ir)
    context.lineTo(lp.x * ir, lp.y * ir)
    context.lineTo(p2.x * ir, p2.y * ir)
    context.lineTo(rp.x * ir, rp.y * ir)
    context.lineTo(mp.x * ir, mp.y * ir)
    context.stroke()

  return that

window.MonkeyResult = MonkeyResult

