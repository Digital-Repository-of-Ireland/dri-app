document.addEventListener('DOMContentLoaded', function() {
  var copyrightSelect = document.getElementById('copyright-select');
  var licenceFieldsetNormal = document.getElementById('licence-fieldset-normal');
  var licenceFieldsetSpecial = document.getElementById('licence-fieldset-special');

  copyrightSelect.addEventListener('change', function() {
    var selectedCopyright = copyrightSelect.value;

    if (selectedCopyright === "No Copyright") {
      licenceFieldsetNormal.style.display = 'none';
      licenceFieldsetSpecial.style.display = 'block';
    } else {
      licenceFieldsetNormal.style.display = 'block';
      licenceFieldsetSpecial.style.display = 'none';
    }
  });
});