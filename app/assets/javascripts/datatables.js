//= require datatables/jquery.dataTables

//optional add '=' enable
// require datatables/extensions/AutoFill/dataTables.autoFill
// require datatables/extensions/Buttons/dataTables.buttons
// require datatables/extensions/Buttons/buttons.html5
// require datatables/extensions/Buttons/buttons.print
// require datatables/extensions/Buttons/buttons.colVis
// require datatables/extensions/Buttons/buttons.flash
// require datatables/extensions/ColReorder/dataTables.colReorder
// require datatables/extensions/FixedColumns/dataTables.fixedColumns
// require datatables/extensions/FixedHeader/dataTables.fixedHeader
// require datatables/extensions/KeyTable/dataTables.keyTable
// require datatables/extensions/Responsive/dataTables.responsive
// require datatables/extensions/RowReorder/dataTables.rowReorder
// require datatables/extensions/Scroller/dataTables.scroller
// require datatables/extensions/Select/dataTables.select

$(document).ready(function() {
    $('#datatable_activity').DataTable( {
        "processing": true,
        "serverSide": true,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_activity').data('source'),
        columnDefs: [
          { targets: [0, 4], orderable: true },
          { targets: '_all', orderable: false }
        ]
    } );
} );

$(document).ready(function() {
    $('#datatable_fixity').DataTable( {
        "processing": true,
        "serverSide": true,
        "searching": false,
        "bInfo" : false,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_fixity').data('source'),
        columnDefs: [
          { "render": function ( data, type, row ) {
                        if (data == 'passed') {
                          return "<i class=\"fa fa-check-circle-o fa-2x text-success\" >" + "(" + row[5] + " of " + row[4] + " checked)</i>"
                        } else if (data == 'failed') {
                          return "<i class=\"fa fa-times fa-2x text-danger\" >" + "(" + row[5] + " of " + row[4] + " checked)</i>"
                        } else {
                          return "<i class=\"fa fa-exclamation-circle fa-2x text-warning\" ></i>"
                        }
            },
            "targets": 2
          },
          { "render": function ( data, type, row ) {
            return "<a rel=\"nofollow\" data-method=\"put\" href=\"" + data + "\">"
              + "<i class=\"fa fa-arrow-circle-right fa-2x text-success\"></i></a>"
            },
            "targets": 3
          },
          { targets: '_all', orderable: false }
        ]
    } );
} );

$(document).ready(function() {
    $('#datatable_user_activity').DataTable( {
        "processing": true,
        "serverSide": true,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_user_activity').data('source'),
        columnDefs: [
          { targets: [0, 1, 3], orderable: true },
          { targets: '_all', orderable: false }
        ]
    } );
} );

$(document).ready(function() {
    var table = $('#datatable_my_collections').DataTable( {
        "processing": true,
        "serverSide": true,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_my_collections').data('source'),
        "searching": false,
        columnDefs: [
          { targets: '_all', orderable: true },
          { targets: '_all', searchable: false }
        ]
    } );

} );

$(document).ready(function() {
    var table = $('#datatable_show_collection').DataTable( {
        "processing": true,
        "serverSide": true,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_show_collection').data('source'),
        "searching": false,
        columnDefs: [
          { targets: '_all', orderable: true },
          { targets: '_all', searchable: false }
        ]
    } );

} );