let solution
let cntSolution = 0

function myRound(x, p) {
  const mult = Math.pow(10, p)
  return Math.round(mult * x) / mult
}

function downloadCoord(s) {
  const csvContent = "data:text/csv;charset=utf-8," + s.all_solutions[cntSolution].positions.map(e => e.map(f => myRound(f, 2)).join(",")).join("\n")
  const encodedUri = encodeURI(csvContent)
  window.open(encodedUri)
}

function clearRoom(ctx, w, h) {
  ctx.clearRect(0, 0, w, h)
  ctx.fillStyle = "#fff"
  ctx.fillRect(0, 0, w, h)
}

function drawRoomAndTeacherSpace(ctx, w, h, scale, salax, salay) {
  // Draw room
  ctx.strokeStyle = "black"
  ctx.lineWidth = "1"
  ctx.strokeRect(0, 0, w, h)

  ctx.strokeStyle = "red"
  ctx.lineWidth   = "3"
  ctx.strokeRect(2, h + 2 - salay * scale, salax * scale, salay * scale - 4)

  // Draw teacher space
  ctx.strokeStyle = "red"
  ctx.lineWidth = "1"
  ctx.font = "15px Arial"
  tw = ctx.measureText("P")
  ctx.strokeText("P", w - (50 + tw.width) / 2.0, h - (salay * scale) / 2 + 10)
  ctx.strokeRect(w - 50 + 5, 1, 50 - 5 - 2, h - 2)
}

function drawChair(ctx, cw, ch, scale, px, py) {
  // The chair: 2/3 of ch and 1/4 of cw
  ctx.fillRect(px - (cw / 8) * scale, py - (ch / 3) * scale, cw * scale / 4, (2 * ch)  * scale / 3)
  ctx.strokeRect(px - (cw / 8) * scale, py - (ch / 3) * scale, cw * scale / 4, (2 * ch)  * scale / 3)

  // The table: ch and 3/4 of cw
  ctx.fillRect(px + (ch / 8) * scale, py - (ch / 2) * scale, cw * 3 * scale / 4, ch * scale)
  ctx.strokeRect(px + (ch / 8) * scale, py - (ch / 2) * scale, cw * 3 * scale / 4, ch * scale)
}

/*
Draw solution `s` at position `cntSolution + move` if this value is
within the available number of solutions. The solution object `s`
has to be obtained by the optimization packing strategy.
*/

function drawOptSolution(s, move) {
  if (!s) return
  
  cnt = cntSolution + move

  if (cnt < 0) {
    $("#prevSolution").prop('disabled', true)
    return
  }

  if (cnt >= s.all_solutions.length) {
    $("#nextSolution").prop('disabled', true)
    return
  }

  $("#prevSolution").prop('disabled', false)
  $("#nextSolution").prop('disabled', false)

  if(cnt === 0) $("#prevSolution").prop('disabled', true)
  if(cnt === s.all_solutions.length-1) $("#nextSolution").prop('disabled', true)

  cntSolution += move

  const canvas = document.getElementById("map")
  __actuallyDrawOptSolution(canvas, s)

  // Hidden canvas for printing
  const hiddenCanvas = document.getElementById("map-hidden")
  __actuallyDrawOptSolution(hiddenCanvas, s)
}

function download_pdf(filename){
  printJS({
      printable: 'map-hidden',
      type: 'html',
      style: "#map-hidden {display: block;margin: 0 auto;}"//transform: scale(2.0)margin-top:20%;}"
  })
}

/* Internal function to draw the optimization solution in the
* canvas. */
function __actuallyDrawOptSolution(mycanvas, s) {
  const ctx = mycanvas.getContext("2d")
  
  const w = mycanvas.width*1
  const h = mycanvas.height*1
  
  const salax =  parseFloat($('#txtLarguraSala').val())
  const salay = parseFloat($('#txtComprimentoSala').val())
  const cw = parseFloat($('#txtLarguraCarteira').val())
  const ch = parseFloat($('#txtComprimentoCarteira').val())
  
  const scale = Math.min((w - 50) / salax, (h) / salay)

  clearRoom(ctx, w, h)
  drawRoomAndTeacherSpace(ctx, w, h, scale, salax, salay)
  
  currSol = s.all_solutions[cntSolution]

  const radius = currSol.min_distance / 2.0
  const fontSize = Math.max(10, parseInt(radius * scale / 2.0))
  
  for (let i = 0; i < currSol.positions.length; i++) {
    const x = currSol.positions[i][0] * scale
    const y = h - currSol.positions[i][1] * scale
    
    ctx.globalAlpha = 0.8
    ctx.strokeStyle = "black"
    ctx.lineWidth   = "1"
    // Do not paint the chairs
    ctx.fillStyle = "white"

    drawChair(ctx, cw, ch, scale, x, y)

    ctx.globalAlpha = 0.7
    ctx.fillStyle = "brown"
    ctx.font = fontSize + "px Arial"
    tw = ctx.measureText(i + 1)

    if (y - (ch * scale) / 2 < fontSize) ctx.fillText(i + 1, x, y + (ch * scale) / 2)
    else ctx.fillText(i + 1, x, y - (ch * scale) / 2)
    
    ctx.globalAlpha = 1.0
  }

  // Draw origin
  ctx.globalAlpha = 0.7
  ctx.strokeStyle = "red"
  ctx.font = "10px Arial"
  ctx.strokeText("Origem", 2, h - 5)
  ctx.globalAlpha = 1.0
}

function drawRowSol(s) {
  if (!s) return

  const visibleCanvas = document.getElementById("map")
  __actuallyDrawRowSolution(visibleCanvas, s)

  const hiddenCanvas = document.getElementById("map-hidden")
  __actuallyDrawRowSolution(hiddenCanvas, s)  
}

function __actuallyDrawRowSolution(mycanvas, s) {

  const ctx = mycanvas.getContext("2d")

  const w = mycanvas.width
  const h = mycanvas.height
  
  const rW = parseFloat($('#txtLarguraSala').val())
  const rH = parseFloat($('#txtComprimentoSala').val())
  const cW = parseFloat($('#txtLarguraCarteira').val())
  const cH = parseFloat($('#txtComprimentoCarteira').val())
  const cR = solution.rowSpace
  const cC = solution.chairSpace

  clearRoom(ctx, w, h)

  const scale = Math.min((w - 50) / rW, (h) / rH)
  drawRoomAndTeacherSpace(ctx, w, h, scale, rW, rH)

  ctx.strokeStyle = "black"
  ctx.lineWidth   = "1"
  ctx.fillStyle   = "#BB8888"

  let py = h - rH * scale + cH * scale / 2

  for (let i = 0; i < solution.rows; i++) {
    let px = cW * scale / 4
    
    for (let j = 0; j < solution.chairs; j++) {
      ctx.fillStyle = "black"
      ctx.globalAlpha = 0.5
      if (solution.A[i][j] == 1) {
        ctx.fillStyle = "white"
        ctx.globalAlpha = 0.8
      }

      drawChair(ctx, cW, cH, scale, px, py)
      px += (cW + cC) * scale
    }

    py += (cH + cR) * scale
  }
}

function prepareResultsSection() {
  solution = null
  $("#result").empty()
  $("#result").append('<div id="summary" class="col-sm-12 col-lg-6 mt-4 mb-4"></div>')
  $("#sectionSeparator").show()
  $("#sectionResults").show()
  $("#result").append('<img src="assets/img/loading.gif" id="loading"></img>')
}

function drawFixedLayout(result) {
  $("div#summary"). append(`
    <h2 class="margin-left-adjust">Resultados</h2>
    <h4 class="mt-1 margin-left-adjust">Fileiras: ${result.rows}</h4>
    <h4 class="mt-1 margin-left-adjust">Cadeiras: ${result.chairs}</h4>
    <h4 class="mt-1 margin-left-adjust">Número de estudantes: ${result.students}</h4>
  `)
  $("div#summary").append("<button class='btn btn-confirm mt-4 margin-left-adjust' id='download' onclick='download_pdf()'>Baixar PDF</button>")
  $("#result").append(`
    <div class="col-sm-12 col-lg-6 mt-4 mb-4">
    <canvas id="map"
       width="${60 + parseFloat($(txtLarguraSala).val()) * Math.min((300 - 50) / parseFloat($(txtLarguraSala).val()), (300) / parseFloat($(txtComprimentoSala).val()))}"
       height="${parseFloat($(txtComprimentoSala).val()) * Math.min((300 - 50) / parseFloat($(txtLarguraSala).val()), (300) / parseFloat($(txtComprimentoSala).val()))}">
    Por favor, use um navegador que suporte HTML5.</canvas></div>
  `)

  $("#mapHiddenPlacement").append(`
      <canvas hidden id="map-hidden"
         width="${60 + parseFloat($(txtLarguraSala).val()) * Math.min((500 - 50) / parseFloat($(txtLarguraSala).val()), (500) / parseFloat($(txtComprimentoSala).val()))}"
         height="${parseFloat($(txtComprimentoSala).val()) * Math.min((500 - 50) / parseFloat($(txtLarguraSala).val()), (500) / parseFloat($(txtComprimentoSala).val()))}">
        Por favor, use um navegador que suporte HTML5.
      </canvas>
  `)

  solution = result // Sets the solution to the global variable
  drawRowSol(solution) // Draw the solution to canvas
}

function drawFreeLayout(result) {
  $("div#summary"). append(`
    <h2 class="margin-left-adjust">Resultados</h2>
    <h4 class="mt-1 margin-left-adjust">Soluções encontradas: ${result["solutions"]}</h4>
    <h4 class="mt-1 margin-left-adjust">Distância ideal calculada: ${myRound(result["min_distance"], 2)}</h4>
    <h4 class="mt-1 margin-left-adjust">Número de carteiras: ${result["number_items"]}</h4>
  `)
  $("div#summary").append("<button class='btn btn-confirm mt-4 margin-left-adjust' id='download' onclick='download_pdf()'>Baixar PDF</button>")

  $("#result").append('<div id="freeLayoutImage" class="col-sm-12 col-lg-6 mt-4 mb-4"></div>')
  $("#freeLayoutImage").append(`
    <div class="row">
      <button id="prevSolution" class="btn btn-confirm" style="border-radius: 5px 0px 0px 5px" onclick="drawOptSolution(solution, -1)">&lt;</button>
      <canvas id="map"
         width="${60 + parseFloat($(txtLarguraSala).val()) * Math.min((300 - 50) / parseFloat($(txtLarguraSala).val()), (300) / parseFloat($(txtComprimentoSala).val()))}"
         height="${parseFloat($(txtComprimentoSala).val()) * Math.min((300 - 50) / parseFloat($(txtLarguraSala).val()), (300) / parseFloat($(txtComprimentoSala).val()))}">
        Por favor, use um navegador que suporte HTML5.
      </canvas>
      <button id="nextSolution" class="btn btn-confirm" style="border-radius: 0px 5px 5px 0px" onclick="drawOptSolution(solution, +1)">&gt;</button>
    </div>`
  )
  $("#freeLayoutImage").append(`
    <div class="row mt-2">
      <button class="btn btn-confirm" onclick="downloadCoord(solution)">Baixar Coordenadas (CSV)</button>
    </div>
  `)

  $("#mapHiddenPlacement").append(`
      <canvas hidden id="map-hidden"
         width="${60 + parseFloat($(txtLarguraSala).val()) * Math.min((500 - 50) / parseFloat($(txtLarguraSala).val()), (500) / parseFloat($(txtComprimentoSala).val()))}"
         height="${parseFloat($(txtComprimentoSala).val()) * Math.min((500 - 50) / parseFloat($(txtLarguraSala).val()), (500) / parseFloat($(txtComprimentoSala).val()))}">
        Por favor, use um navegador que suporte HTML5.
      </canvas>
  `)
    
  solution = result
  cntSolution = 0
  drawOptSolution(solution, 0)
}

function errorHandler() {
  $("#loading").remove()
  $("#result").append(`
    <div class="alert alert-danger alert-dismissible fade show margin-left-adjust">
      Erro! Verifique as informações inseridas. Caso ocorra novamente, envie um email para <b>salaplanejada@unifesp.br</b>.
      <button type="button" class="close" data-dismiss="alert">
        &times;
      </button>
    </div>`
  )
}

$(document).ready(function() {
  function checkUsuarioForm() {
    return  $('#txtNome').val() !== '' &&
            $('#txtInstituicao').val() !== '' &&
            $('#txtEmail').val() !== ''
  }

  $('#txtNome,#txtInstituicao,#txtEmail').keyup(function(e) {
    if(checkUsuarioForm()) $('#btnUsuarioSubmit').prop('disabled', false)
    else $('#btnUsuarioSubmit').prop('disabled', true)
  })

  function checkCalcularForm() {
    return  $('#txtLarguraSala').val() !== '' &&
            $('#txtComprimentoSala').val() !== '' &&
            $('#txtLarguraCarteira').val() !== '' &&
            $('#txtComprimentoCarteira').val() !== '' &&
            $('#txtDistanciaMinima').val() !== ''
  }

  function checkCalcularFormExtra() {
    const selectedModo = parseInt($('#selectModo').val())

    if(selectedModo) { // Modo livre
      return  ($('#radioInserir').is(':checked') && $('#txtQuantidadeCarteirasRadio').val() !== '') || 
              $('#radioMaxima').is(':checked')
    }
    // Modo fixo
    return  $('#txtQuantidadeFileiras').val() !== '' &&
            $('#txtQuantidadeCarteirasFileira').val() !== ''
  }

  function enableCalcularButton() {
    if(checkCalcularForm() && checkCalcularFormExtra()) $('#btnCalcularSubmit').prop('disabled', false)
    else $('#btnCalcularSubmit').prop('disabled', true)
  }

  $('#txtLarguraSala,#txtComprimentoSala,#txtLarguraCarteira,#txtComprimentoCarteira,#txtQuantidadeFileiras,#txtQuantidadeCarteirasFileira,#txtDistanciaMinima,#txtQuantidadeCarteirasRadio').keyup(function(e) {
    enableCalcularButton()
  })

  $('#frmUsuario').submit(function(e) {
    e.preventDefault()
    
    $('#firstPage').hide()
    $('#secondPage').show()

    // $('#firstPage').show()
    // $('#secondPage').show()
    // var url = form.attr('action')
    
    // $.ajax({
    //   type: "POST",
    //   url: url,
    //   data: form.serialize(),
    //   success: function(data) {
    //       alert(data)
    //   }
    // })
  })

  $('#selectModo').change(function() {
    const podeMoverCadeiras = parseInt($(this).val())

    if(podeMoverCadeiras) { // Modo livre
      $('#modoFixo').hide()
      $('#modoLivre').show()

      $('#txtQuantidadeFileiras,#txtQuantidadeCarteirasFileira').val('')
    } else { // Modo Fixo
      $('#modoLivre').hide()
      $('#modoFixo').show()

      $('#txtDistanciaMinima,#txtQuantidadeCarteirasRadio').val('')
      $('#radioInserir,#radioMaxima').prop("checked", false)
    }

    enableCalcularButton()
  })

  $('.radio-carteiras').change(function(e) {
    e.preventDefault()
    
    const value = $(this).val()

    if(value == '2') {
      $('#radioInserir').prop("checked", false)
      $('#radioMaxima').prop("checked", true)
    } else {
      $('#radioInserir').prop("checked", true)
      $('#radioMaxima').prop("checked", false)
    }

    enableCalcularButton()
  })

  $("#frmCalcular").submit(function(e) {
    e.preventDefault()

    prepareResultsSection()
    
    const selectedModo = parseInt($('#selectModo').val())

    if(selectedModo) { // Modo livre
      const selectedRadio = $("input[name=radio-options]:checked").val()
      const data = {
        1: $("#txtLarguraSala").val(),
        2: $("#txtComprimentoSala").val(),
        3: $("#txtLarguraCarteira").val(),
        4: $("#txtComprimentoCarteira").val(),
        5: $("#txtDistanciaMinima").val(),
        6: "100",
        7: "0",
        8: selectedRadio,
      }
      if (selectedRadio == "1") data[9] = $("#txtQuantidadeCarteirasRadio").val()

      // Better way to do this?
      const wantRows = $("#checkDesejaFileiras:checked").length > 0
      if (wantRows) {
        if (selectedRadio == "1") data[8] = "3"
        else data[8] = "4"
      }

      $.ajax({
        url: "http://200.144.93.70/a/optimize",
        type: "GET",
        data,
        crossDomain: true,
        dataType: 'jsonp',
        // set the request header authorization to the bearer token that is generated
        success: function(result) {
          $("#loading").remove()

          if(result["found_solution"]) drawFreeLayout(result)
          else $("div#summary").append('<center><h1 class="mb-0">Resultados</h1>Não foi possível encontrar uma solução com os dados informados: o problema é muito grande ou não há solução. Caso seu problema seja complexo, entre em contato com <b>salaplanejada@unifesp.br</b></center>')
        },
        error: errorHandler
      })
    } else { // Modo fixo
      const data = {
        1: $("#txtLarguraSala").val(),
        2: $("#txtComprimentoSala").val(),
        3: $("#txtLarguraCarteira").val(),
        4: $("#txtComprimentoCarteira").val(),
        5: $("#txtQuantidadeFileiras").val(),
        6: $("#txtQuantidadeCarteirasFileira").val(),
        7: $("#txtDistanciaMinima").val(),
      }
      
      $.ajax({
        url: "http://200.144.93.70/a/rows",
        type: "GET",
        data,
        crossDomain: true,
        dataType: 'jsonp',
        // set the request header authorization to the bearer token that is generated
        success: function(result) {
          $("#loading").remove()

          if (result.status) drawFixedLayout(result)
          else $("div#summary").append('<center><h1 class="mb-0">Resultados</h1><h3 class="mb-0">Não há solução ótima</h3></center>')
        },
        error: errorHandler
      })
    }
  })
})
