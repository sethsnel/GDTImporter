<%
  /**
   * wizard refresh flow action
   *
   * When a page (/ partial) is rendered, any DOM event handlers need to be
   * (re-)attached. The af:ajaxButton, af:ajaxSubmitJs and af:redirect tags
   * supports calling a JavaScript after the page has been rendered by passing
   * the 'afterSuccess' argument.
   *
   * Example:     af:redirect afterSuccess="onPage();"
   *              af:redirect afterSuccess="console.log('redirecting...');"
   *
   * Generally one would expect this code to add jQuery event handlers to
   * DOM objects in the rendered page (/ partial).
   *
   * @author Jeroen Wesbeek
   * @since 20101206
   *
   * Revision information:
   * $Rev: 1555 $
   * $Author: t.w.abma@umcutrecht.nl $
   * $Date: 2011-02-24 11:15:00 +0100 (Thu, 24 Feb 2011) $
   */
%>
<script type="text/javascript">
  var oldImportfile = '';
  var checkEverySeconds = 2;

  var dataTable;

  // Initially called when starting the import wizard
  function onPage() {
    onStudyWizardPage();
    // GENERAL

    $('#simplewizardform').submit(function() {
      if ($('#file').val() == "") {
        alert("Please choose your Excel file to import.");
        return false
      } else
      if ($('#entity').val() == "") {
        $('#datatemplate').addClass("validationfail");
        return false
      } else {
        $('#simplewizardform').submit();
      }

      return false;
    });

    $('#attachSamplesDiv').hide();
    $('#attachEventsDiv').hide();

    // Create listener which is checking whether a (new) file has been uploaded
    oldImportfile = $("#importfile").val();

    setInterval(function() {


      // A file was uploaded and a next page call was issued which failed?
      if ($("#importfile").val().length > "existing*".length && $("#pageOneRefresh").val() == "true") {
        updateDatamatrixPreview()
        // Reset the refresh page value
        $("#pageOneRefresh").val("")
      }

      if (($("#importfile").val() != oldImportfile) || $("#pageOneRefresh").val() == "true") {
        // Reset the refresh page value
        $("#pageOneRefresh").val("")

        $('#datamatrixpreview').html('<table cellpadding="0" cellspacing="0" border="0" class="display" id="datamatrix"></table>');

        $.ajax({
          type: "POST",
          data: "importfile=" + $("#importfile").val() + "&sheetIndex=" + $("#sheetIndex").val() ,
          url: "getDatamatrixAsJSON",
          success: function(msg) {

            var jsonDatamatrix = eval(msg);

            // Update sheet selector by first clearing it and appending the sheets user can choose from
            $("select[name='sheetIndex']").find('option').remove().end()

            for (i = 0; i < jsonDatamatrix.numberOfSheets; i++) {
              $("select[name='sheetIndex']").append(new Option(i + 1, i));
            }

            dataTable = $('#datamatrix').dataTable({
              "sScrollX": "100%",
              "bScrollCollapse": true,
              "bSort" : false,
              "bPaginate": false,
              "aaData": jsonDatamatrix.aaData,
              "aoColumns": jsonDatamatrix.aoColumns
            });
          }
        });

        // Update the original
        oldImportfile = $("#importfile").val()

      }
    }, checkEverySeconds * 1000);

    // attach event to apply fuzzy matching
    $('#fuzzymatchselect').click(function() {
      $("#fuzzymatching").val("true")
      refreshFlow()
    });

    // open load box
    $('#loadpropertiesbutton').click(function() {
      $("#loadmapping").toggle("scale")
    });

    // mapping has been chosen and OK button pressed? refresh the flow page
    $('#loadmappingok').click(function() {
      if ($("#loadimportmapping_id").val()) refreshFlow()
    });

    // open delete box
    $('#deletepropertiesbutton').click(function() {
      $("#deletemapping").toggle("scale")
    });

    // mapping has been chosen and OK button pressed? refresh the flow page
    $('#deletemappingok').click(function() {
      if ($("#deleteimportmapping_id").val()) refreshFlow()
    });

    // open save box
    $('#savepropertiesbutton').click(function() {
      $("#savemapping").toggle("scale")

      if ($("#mappingname").val()) refreshFlow();
    });

    // mapping given a name and OK button pressed? Then refresh the flow
    $('#savemappingok').click(function() {
      if ($("#mappingname").val()) refreshFlow();
    });

    // Disable Enter key
    function stopRKey(evt) {
      var evt = (evt) ? evt : ((event) ? event : null);
      var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
      if ((evt.keyCode == 13) && (node.type == "text")) {
        return false;
      }
    }

    document.onkeypress = stopRKey;


    // attach function to clear button to reset all selects to "don't import"
    $('#clearselect').click(function() {
      $("#currentmapping").html("Current import mapping: none")

      // for each select field on the page
      $("select").each(function() {
        // set its value to its first option
        $(this).val($('option:first', this).val());
      });
    });

    // attach change event function to prevent duplicate selection of properties
    $('select[name^="columnproperty.index."]').each(function() {
      $(this).bind('change', function(e) {
        var selection = $(this)

        $('select[name^="columnproperty.index."] option:selected').each(function() {
          var selector = $(this)

          if (selection.attr('id') != selector.parent().attr('id') && (selection.val() != "dontimport"))
            if ($(this).val() == selection.val()) {
              selection.val($('option:first', selection).val());

              alert("Property is already set for an other column, please choose a different property.")
              return false
            }
        });
      });
    });
  }

  /**
   * Update one select based on another select
   *
   * @author
   * @see  http://www.grails.org/Tag+-+remoteFunction
   * @param   string  select (form) name
   * @param   string  JSON data
   * @param   boolean keep the first option
   * @param   int  selected option
   * @param   string  if null, show this as option instead
   * @void
   */
  function updateSelect(name, data, keepFirstOption, selected, presentNullAsThis) {
    var rselect = $('#' + name).get(0)
    var items = data

    var selectedEntity = $('#entity :selected').text();

    $('#parentEntityField').show();
    $('#attachSamplesDiv').hide();
    $('#attachEventsDiv').hide();
    switch (selectedEntity) {
      case 'Study':
              $('#parentEntityField').hide();
              break;
      case 'Sample':
              $('#attachSamplesDiv').show();
              break
      case 'Event':
              $('#attachEventsDiv').show();
              break
    }

    $('select[name=template_id]').attr('entity', $('#' + 'entity').val());

    if (items) {

      // remove old options
      var start = (keepFirstOption) ? 0 : -1;
      var i = rselect.length

      while (i > start) {
        rselect.remove(i)
        i--
      }

      // add new options
      $.each(items, function() {
        var i = rselect.options.length

        rselect.options[i] = new Option(
                (presentNullAsThis && this.name == null) ? presentNullAsThis : this.name,
                this.id
                );
        if (this.id == selected) rselect.options[i].selected = true
      });
    }

    // handle template selects
    new SelectAddMore().init({
      rel      : 'template',
      url      : baseUrl + '/templateEditor',
      vars    : 'entity', // can be a comma separated list of variable names to pass on
      label   : 'add / modify ...',
      style   : 'modify',
      onClose : function(scope) {
        refreshFlow()
      }
    });
  }

  /**
   * This function will update the datamatrix preview, based on the sheet index supplied
   */
  function updateDatamatrixPreview() {

    $.ajax({
      type: "POST",
      data: "importfile=" + $("#importfile").val() + "&sheetIndex=" + $("#sheetIndex").val() ,
      url: "getDatamatrixAsJSON",
      success: function(msg) {

        var jsonDatamatrix = eval(msg);
        var sheetIndex = $("#sheetIndex").val()

        // Update sheet selector by first clearing it and appending the sheets user can choose from
        $("select[name='sheetIndex']").find('option').remove().end()

        for (i = 0; i < jsonDatamatrix.numberOfSheets; i++) {
          $("select[name='sheetIndex']").append(new Option(i + 1, i));
        }

        // Set selected sheet
        $("#sheetIndex").val(sheetIndex).attr('selected', true);

        dataTable.fnDestroy();

        $('#datamatrixpreview').html('<table cellpadding="0" cellspacing="0" border="0" class="display" id="datamatrix"></table>');

        dataTable = $('#datamatrix').dataTable({
          "sScrollX": "100%",
          "bScrollCollapse": true,
          "bRetrieve": false,
          "bDestroy": true,
          "bPaginate": false,
          "bSort" : false,
          "aaData": jsonDatamatrix.aaData,
          "aoColumns": jsonDatamatrix.aoColumns
        });
      }
    });

  }


</script>