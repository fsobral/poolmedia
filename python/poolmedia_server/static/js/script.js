
function prepareResultsSection() {
  solution = null
  $("#result").empty()
  $("#result").append('<div id="summary" class="col-sm-12 col-lg-6 mt-4 mb-4"></div>')
  $("#sectionSeparator").show()
  $("#sectionResults").show()
  $("#result").append('<div id="loading" class="loader"></div>')
}

function displaySolution(result) {

  const solutions = result["solutions"]
  const nSols = solutions.length
  maxLen = 0

  for (i in solutions) {
    const s = result["solutions"][i]
    maxLen = Math.max(maxLen, (s["sequence"]).length)
  }
  
  $("div#summary"). append(`
    <h2 class="margin-left-adjust">Results</h2>
    <h4 class="mt-1 margin-left-adjust">Optimal cost: ${result["optimalCost"]}</h4>
    <h4 class="mt-1 margin-left-adjust">Failures by lack of memory: ${result["memFailures"]}</h4>
    <h4 class="mt-1 margin-left-adjust">Number of strategies: ${nSols}</h4>
    <h4 class="mt-1 margin-left-adjust">Strategies:</h4>
  `)

  hasSimulations = result["simulations"] ? true:false

  // Add table with the number of best strategies found
  
  t = `<table class="ml-2 table table-hover">
       <thead> <tr>`

  for (i=1; i<=maxLen; i++)
    t += '<th> Stage ' + i + '</th>'
  t += '<th> Cost </th> <th></th> </tr> </thead> <tbody>'
  for (i=0; i<solutions.length; i++) {
    t += '<tr>'
    s = solutions[i]
    for (j=0; j<s.nStages; j++) t += '<td>' + s["sequence"][j] + '</td>'
    for (j=s.nStages; j<maxLen; j++) t += '<td></td>'
    t += '<td>' + s["cost"] + '</td> <td>'
    
    t += hasSimulations ? `<button type="button" class="btn btn-success" data-toggle="modal" data-target="#modalSim${i}">Simulate!</button>`:''
    t += '</td></tr>'
  }
  t += '</table>'

  $("div#summary").append(t)


  // Add modal elements with the results of the simulations
  
  if (hasSimulations) {
    
    const simulations = result["simulations"]

    for (i=0; i<simulations.length; i++) {
      t = `<div class="modal" id="modalSim${i}">
             <div class="modal-dialog">
               <div class="modal-content">
                 <div class="modal-body">
                   <p>
                     <button type="button" class="close" data-dismiss="modal">&times;</button>
                   </p>      
                   <table class="ml-2 table table-hover">
                   <thead> <tr>
                     <th> Stage </th>
                     <th> Pool size </th>
                     <th> Pools necessary </th>
                     <th> Time </th>
                     <th> Overflow </th>
                     <th> Total time </th>
                   </tr> </thead>`

      s = simulations[i]['s']

      t += '<tbody>'
      
      for (j=0; j<s.length; j++) {
        t += `<tr> <td> ${j+1} </td>`
        for (k=0; k<5; k++) t += '<td>' + s[j][k] + '</td>'
        t += '</tr>'
      }

      t += '</tbody>'
      t += '</table>'
      t += '</div></div></div></div>'

      $("div#summary").append(t)
      
    }
  }
    
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

  // Hide/show simulation form
  if ($("#wantsimul").prop('checked')) $("#simulations").show()
  $("#wantsimul").on("change", function() {
    if (this.checked) $("#simulations").show()
    else $("#simulations").hide()
  })
    
  function checkCalcularForm() {
    return  $('#minindinf').val() !== '' &&
      $('#maxindinf').val() !== '' &&
      $('#numbstrat').val() !== '' &&
      $('#maxm1size').val() !== '' &&
      $('#maxnstage').val() !== '' &&
      ( !($('#wantsimul').prop('checked')) ||
        ( $('#populsize').val() !== '' &&
          $('#parapools').val() !== '' )
      )
      
  }

  function enableCalcularButton() {
    if(checkCalcularForm()) $('#btnCalcularSubmit').prop('disabled', false)
    else $('#btnCalcularSubmit').prop('disabled', true)
  }

  $('#minindinf,#maxindinf,#numbstrat,#maxm1size,#maxnstage,#wantsimul,#populsize,#parapools').on("change blur",function(e) {
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
      maxnstage: $("#maxnstage").val(),
      wantsimul: ($("#wantsimul").prop('checked') ? 1:0),
      populsize: $("#populsize").val(),
      parapools: $("#parapools").val()
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
