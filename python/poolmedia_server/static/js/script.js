
function prepareResultsSection() {
  solution = null
  $("#result").empty()
  $("#result").append('<div id="summary" class="col-sm-12 col-lg-6 mt-4 mb-4"></div>')
  $("#sectionSeparator").show()
  $("#sectionResults").show()
  $("#result").append('<div id="loading" class="loader"></div>')
}

function displaySolution(result) {

  const nSols = result["solutions"].length
  maxLen = 0
  const solMatrix = []
  for (i in result["solutions"]) {
    const s = result["solutions"][i]
    console.log(s)
    maxLen = Math.max(maxLen, (s["sequence"]).length)
    solMatrix.push(s["sequence"])
  }
  
  $("div#summary"). append(`
    <h2 class="margin-left-adjust">Results</h2>
    <h4 class="mt-1 margin-left-adjust">Optimal cost: ${result["optimalCost"]}</h4>
    <h4 class="mt-1 margin-left-adjust">Failures by lack of memory: ${result["memFailures"]}</h4>
    <h4 class="mt-1 margin-left-adjust">Number of strategies: ${result["solutions"].length}</h4>
    <h4 class="mt-1 margin-left-adjust">Strategies:</h4>
  `)

  t = `<table class="table table-hover table-striped">
       <thead> <tr>`

  for (i=1; i<=maxLen; i++)
    t += '<th> Stage ' + i + '</th>'
  t += '</tr> </thead> <tbody>'
  for (i=0; i<solMatrix.length; i++) {
    t += '<tr>'
    for (j=0; j<maxLen; j++) {
      if (solMatrix[i][j]) t += '<td>' + solMatrix[i][j] + '</td>'
    }
    t += '</tr>'
  }
  t += '</table>'
  $("div#summary").append(t)

}

function errorHandler() {
  $("#loading").remove()
  $("#result").append(`
    <div class="alert alert-danger alert-dismissible fade show margin-left-adjust">
      Server error! Please contact XXXX@XXX. 
      <button type="button" class="close" data-dismiss="alert">
        &times;
      </button>
    </div>`
  )
}

$(document).ready(function() {

  function checkCalcularForm() {
    return  $('#minindinf').val() !== '' &&
            $('#maxindinf').val() !== '' &&
            $('#numbstrat').val() !== '' &&
            $('#maxm1size').val() !== '' &&
            $('#maxnstage').val() !== ''
  }

  function enableCalcularButton() {
    if(checkCalcularForm()) $('#btnCalcularSubmit').prop('disabled', false)
    else $('#btnCalcularSubmit').prop('disabled', true)
  }

  $('#minindinf,#maxindinf,#numbstrat,#maxm1size,#maxnstage').keyup(function(e) {
    enableCalcularButton()
  })

  // Check the form in case the page has been reloaded
  enableCalcularButton()
  
  $("#frmCalcular").submit(function(e) {
    e.preventDefault()

    prepareResultsSection()
    
    const data = {
      minindinf: $("#minindinf").val(),
      maxindinf: $("#maxindinf").val(),
      numbstrat: $("#numbstrat").val(),
      maxm1size: $("#maxm1size").val(),
      maxnstage: $("#maxnstage").val()
    }

    // Ajax call
    $.ajax({
      url: "http://localhost:5000/poolmedia",
      type: "GET",
      data,
      crossDomain: true,
      dataType: 'jsonp',
      // set the request header authorization to the bearer token that is generated
      success: function(result) {
        $("#loading").remove()
        
        if(result["foundSolution"]) displaySolution(result)
        else $("div#summary").append(`
          <center><h1 class="mb-0">Results</h1>
            ${result["message"]}
          </center>
        `)
      },
      error: errorHandler
    })
  })
})
