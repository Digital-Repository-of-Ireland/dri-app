 import $ from "jquery"

function initIngestWizard() {
  const $wizard = $('#ingestWizard')
  if (!$wizard.length || $wizard.data('wizard-initialised')) return
  $wizard.data('wizard-initialised', true)

  var btnFinish = $('<button id="#submit-wizard"></button>').text('Finish')
                                         .addClass('btn btn-info')
                                         .on('click', submitWizard);

  $('#ingestWizard').smartWizard({
    selected: 0,
    theme: 'arrows', // default, arrows, dots, progress
    transition: {
      animation: 'none', // Effect on navigation, none/fade/slide-horizontal/slide-vertical/slide-swing
    },
    autoAdjustHeight: false,
    toolbarSettings: {
      toolbarExtraButtons: [btnFinish]
    }
  });

  $("#ingestWizard").on("leaveStep", function(e, anchorObject, currentStepIndex, nextStepIndex, stepDirection) {
    if (currentStepIndex == 0 && nextStepIndex == 1) {
      if ($('#ingestWizard #collectionsSelectable').jstree('get_selected', true).length == 0) {
        alert('You must select a collection.');
        return e.preventDefault();
      }
    } else if (currentStepIndex == 1 && nextStepIndex == 2 && $('#metadataSelectableFolder').jstree('get_selected', true).length == 0) {
      alert('You must select a metadata directory.');
      return e.preventDefault();
    }
  });

  function submitWizard() {
    if ($('#ingestWizard #collectionsSelectable').jstree('get_selected', true).length == 0) {
        alert('You must select a collection.');
      $('#ingestWizard').smartWizard("goToStep", 0);
    }else if ($('#metadataSelectableFolder').jstree('get_selected', true).length == 0) {
      alert('You must select a metadata directory.');
      $('#ingestWizard').smartWizard("goToStep", 1);
    } else {
      $("#metadata_path").val($('#metadataSelectableFolder').jstree('get_selected', true)[0].data.path);
      $("#ingestWizard #collection_id").val($('#ingestWizard #collectionsSelectable').jstree('get_selected', true)[0].id);

      if ($('#assetSelectableFolder').jstree('get_selected', true).length > 0) {
        $("#asset_path").val($('#assetSelectableFolder').jstree('get_selected', true)[0].data.path);
      }

      if ($('#preservationSelectableFolder').jstree('get_selected', true).length > 0) {
        $("#preservation_path").val($('#preservationSelectableFolder').jstree('get_selected', true)[0].data.path);
      }

      $('#ingest_wizard_form').submit();
    }
  }
}

$(initIngestWizard)
document.addEventListener('turbo:load', initIngestWizard)
