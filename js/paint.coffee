"use strict"

class Paint
    constructor: (canvas) ->
        @canvas = $('#'+ canvas)

        @context = @canvas[0].getContext('2d')
        @context.lineJoin = 'round'
        @context.lineCap = 'round'
        @canvasOffset = @canvas.offset()
        @mouse = {x: 0, y: 0}
        @redo_list = []
        @undo_list = []

        $('#size').bind 'mousemove change', =>
            $('#sizepx').text($('#size').val())

        $("#fill").change (e) =>
            @initCanvas()

        $('button').click (e) =>
            if (e.target.id == "save")
                window.open(@canvas[0].toDataURL())
                return
            if (e.target.id == "redo")
                @redo()
                return
            if(e.target.id == "undo")
                @undo()
                return
            @selectTool(e.target.id)
        @initCanvas()

    selectTool: (tool) ->
        @tool = tool
        $('.active').removeClass('active')
        $('#'+@tool).addClass('active')
        @initCanvas()

    initCanvas: ->
        @canvas.unbind("mousemove").unbind("mouseup").unbind("mousedown").unbind("click")
        @canvas.contextmenu (e) =>
            return false
        @ev_canvas()
        if(@tool != 'text' && @tool !='picker' && @tool != 'undo' && @tool != 'redo')
            @canvas.bind 'mousedown mousemove mouseup', @ev_canvas

    ev_canvas: =>
        @context.strokeStyle = $('#color').val()
        @context.fillStyle = $('#color2').val()
        @context.lineWidth = $('#size').val()
        @offsetX = @canvasOffset.left
        @offsetY = @canvasOffset.top
        switch @tool
            when "picker"
                @picker()
            when "line"
                @line()
            when "care"
                @care()
            when "circle"
                @circle()
            when "gomme"
                @gomme()
            when "new"
                @new()
            when "text"
                @text()
            when "save"
                @save()
            else
                @pencil()

    picker: ->
        @canvas.mousedown (e) =>
            tmp = @context.getImageData(e.clientX - @offsetX, e.clientY - @offsetY, 1 ,1)
            componentToHex = (color) ->
                hex = color.toString(16)
                (if hex.length is 1 then "0" + hex else hex)
            rgbToHex = (r, g, b) ->
                "#" + componentToHex(r) + componentToHex(g) + componentToHex(b)

            if(event.which == 1)
                if(tmp.data[3] == 0)
                    $('#color').val("#ffffff")
                else
                    $('#color').val(rgbToHex(tmp.data[0], tmp.data[1], tmp.data[2]))
            else
                if(tmp.data[3] == 0)
                    $('#color2').val("#ffffff")
                else
                    $('#color2').val(rgbToHex(tmp.data[0], tmp.data[1], tmp.data[2]))

    pencil: ->
        @canvas.mousedown (e) =>
            @isDrawing = true
            @saveState()
            @context.moveTo e.clientX - @offsetX, e.clientY - @offsetY
            @context.beginPath()
            @context.arc(e.clientX - @offsetX, e.clientY - @offsetY, $('#size').val() / 100, 0, 2*Math.PI)
            @context.stroke()

        @canvas.mousemove (e) =>
            if @isDrawing
                @context.lineTo e.clientX - @offsetX, e.clientY - @offsetY
                @context.stroke()

        @canvas.mouseup () =>
            @isDrawing = false
            @initCanvas()

    line: ->
        @canvas.mousedown (e) =>
            @isDrawing = true
            @saveState()
            @mouse.x = e.clientX - @offsetX
            @mouse.y = e.clientY - @offsetY
            @tmp = @context.getImageData(0, 0, @canvas[0].width, @canvas[0].height)

        @canvas.mousemove (e) =>
            if @isDrawing
                @context.clearRect(0, 0, @canvas[0].width, @canvas[0].height)
                @context.beginPath()
                @context.putImageData(@tmp,0,0)
                @context.moveTo(@mouse.x, @mouse.y)
                @context.lineTo(e.clientX - @offsetX, e.clientY - @offsetY)
                @context.closePath()
                @context.stroke()

                @canvas.mousedown (e) =>
                    @isDrawing = false
                    @initCanvas()

                @canvas.mouseup (e) =>
                    @isDrawing = false
                    @initCanvas()

    care: ->
        @canvas.mousedown (e) =>
            @isDrawing = true
            @saveState()
            @mouse.x = e.clientX - @offsetX
            @mouse.y = e.clientY - @offsetY
            @tmp = @context.getImageData(0, 0, @canvas[0].width, @canvas[0].height)

        @canvas.mousemove (e) =>
            if @isDrawing
                x = Math.min(e.clientX - @offsetX,  @mouse.x)
                y = Math.min(e.clientY - @offsetY,  @mouse.y)
                w = Math.abs(e.clientX - @offsetX - @mouse.x)
                h = Math.abs(e.clientY - @offsetY - @mouse.y)
                @context.clearRect(0, 0, @canvas[0].width, @canvas[0].height)
                @context.putImageData(@tmp,0,0)
                @context.beginPath()
                @context.rect(x, y, w, h)
                @context.closePath()
                if ($("#fill").is(":checked"))
                    @context.fill()
                @context.stroke()

                @canvas.mousedown (e) =>
                    @isDrawing = false
                    @initCanvas()

                @canvas.mouseup (e) =>
                    @isDrawing = false
                    @initCanvas()

    circle: ->
        @canvas.mousedown (e) =>
            @isDrawing = true
            @saveState()
            @mouse.x = e.clientX - @offsetX
            @mouse.y = e.clientY - @offsetY
            @tmp = @context.getImageData(0, 0, @canvas[0].width, @canvas[0].height)

        @canvas.mousemove (e) =>
            if @isDrawing
                x2 = Math.abs(e.clientX - @offsetX)
                y2 = Math.abs(e.clientY - @offsetY)
                r = Math.sqrt(Math.pow((x2 - @mouse.x), 2) + Math.pow((y2 - @mouse.y), 2))
                @context.clearRect(0, 0, @canvas[0].width, @canvas[0].height)
                @context.putImageData(@tmp,0,0)
                @context.beginPath()
                @context.arc(@mouse.x, @mouse.y, r, 0, 2*Math.PI)
                if ($("#fill").is(":checked"))
                    @context.fill()
                @context.stroke()

                @canvas.mousedown (e) =>
                    @isDrawing = false
                    @initCanvas()

                @canvas.mouseup (e) =>
                    @isDrawing = false
                    @initCanvas()

    text: ->
        @canvas.click (e) =>
            text = prompt("Rentre ton text")
            @saveState()
            if(text != null)
                @mouse.x = e.clientX - @offsetX
                @mouse.y = e.clientY - @offsetY
                @context.font = $('#size').val() + "pt Calibri"
                @context.fillStyle = $('#color').val()
                @context.fillText(text, @mouse.x, @mouse.y)
                @initCanvas()

    gomme: ->
        @canvas.mousedown (e) =>
            @isDrawing = true
            @saveState()
            @context.moveTo e.clientX - @offsetX, e.clientY - @offsetY
            @context.beginPath()

        @canvas.mousemove (e) =>
            if @isDrawing
                @context.strokeStyle = "#FFFFFF"
                @context.lineTo e.clientX - @offsetX, e.clientY - @offsetY
                @context.stroke()

        @canvas.mouseup () =>
            @isDrawing = false
            @context.strokeStyle = $('#color').val()
            @initCanvas()

    new: ->
        @saveState()
        @context.clearRect(0, 0, @canvas[0].width, @canvas[0].height)
        @selectTool("pencil")

    saveState: (list, keep_redo) ->
        keep_redo = keep_redo or false
        @redo_list = []  unless keep_redo
        (list or @undo_list).push @canvas[0].toDataURL()

    undo: ->
        @restoreState @undo_list, @redo_list

    redo: ->
        @restoreState @redo_list, @undo_list

    restoreState: (pop, push) ->
        if pop.length
            @saveState push, true
            restore_state = pop.pop()
            img = new Image()
            img.src = restore_state
            img.onload= =>
                @context.clearRect(0, 0, @canvas[0].width, @canvas[0].height)
                @context.drawImage(img, 0, 0, @canvas[0].width, @canvas[0].height, 0, 0, @canvas[0].width, @canvas[0].height)


paint = new Paint('canvas')
