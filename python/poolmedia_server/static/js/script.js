
function prepareResultsSection() {
  solution = null
  $("#result").empty()
  $("#result").append('<div id="summary" class="col-sm-12 col-lg-6 mt-4 mb-4"></div>')
  $("#sectionSeparator").show()
  $("#sectionResults").show()
  $("#result").append('<div id="loading" class="loader"></div>')
}

function displaySolution(result) {
  $("div#summary"). append(`
    <h2 class="margin-left-adjust">Results</h2>
    <h4 class="mt-1 margin-left-adjust">Soluções encontradas: ${result["solutions"]}</h4>
    <h4 class="mt-1 margin-left-adjust">Distância ideal calculada: ${myRound(result["min_distance"], 2)}</h4>
    <h4 class="mt-1 margin-left-adjust">Número de carteiras: ${result["number_items"]}</h4>
  `)
}

function errorHandler() {
  $("#loading").remove()
  $("#result").append(`
    <div class="alert alert-danger alert-dismissible fade show margin-left-adjust">
      Error! 
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
        
        if(result["found_solution"]) displaySolution(result)
        else $("div#summary").append(`
          <center><h1 class="mb-0">Results</h1>
            We were unable to find a solution to the requested problem. If the problem is
            too large, please contact XXXX@XXX.XX.
          </center>
        `)
      },
      error: errorHandler
    })
  })
})
