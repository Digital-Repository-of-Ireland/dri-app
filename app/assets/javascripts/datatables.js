//= require jquery.dataTables

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
        "stateSave": true,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_activity').data('source'),
        columnDefs: [
          { targets: [0, 4], orderable: true },
          { targets: '_all', orderable: false }
        ]
    } );
    $('#datatable_fixity').DataTable( {
        "processing": true,
        "serverSide": true,
        "searching": false,
        "stateSave": true,
        "bInfo" : false,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_fixity').data('source'),
        columnDefs: [
          { "render": function ( data, type, row ) {
                        if (data == 'passed') {
                          return "<i class=\"fa fa-check-circle-o text-success\" >" + "(" + row[5] + " of " + row[4] + " checked)</i>"
                        } else if (data == 'failed') {
                          return "<i class=\"fa fa-times text-danger\" >" + "(" + row[5] + " of " + row[4] + " checked, " + row[6] + " failures)</i>"
                        } else {
                          return "<i class=\"fa fa-exclamation-circle text-warning\" ></i>"
                        }
            },
            "targets": 2
          },
          { "render": function ( data, type, row ) {
            return "<a rel=\"nofollow\" data-method=\"put\" href=\"" + data + "\">"
              + "<i class=\"fa fa-arrow-circle-right text-success\"></i></a>"
            },
            "targets": 3
          },
          { targets: '_all', orderable: false }
        ]
    } );
    $('#datatable_stats').DataTable( {
        "processing": true,
        "serverSide": true,
        "searching": false,
        "stateSave": true,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_stats').data('source'),
        columnDefs: [
          { targets: '_all', orderable: false },
        ]
    } );
    $('#datatable_user_activity').DataTable( {
        "processing": true,
        "serverSide": true,
        "stateSave": true,
        "order": [[ 0, "desc" ]],
        "ajax": $('#datatable_user_activity').data('source'),
        columnDefs: [
          { targets: [0, 1, 3], orderable: true },
          { targets: '_all', orderable: false }
        ]
    } );
    var datatableUsers = $('#datatable_users').DataTable( {
        "processing": true,
        "serverSide": true,
        "stateSave": true,
        "order": [[ 5, "desc" ]],
        "ajax": {
          "url": $('#datatable_users').data('source'),
          "data": function(d) {
            d.filter = $('#datatable_users_filter').val();
            d.approver = $('#datatable_users_approvers').val();
          }
        },
        columnDefs: [
          { targets: [0], visible: false, searchable: false },
          { targets: [1, 3, 4, 5], orderable: true },
          { "render": function ( data, type, row ) {
            return "<a rel=\"nofollow\" data-method=\"get\" href=\"" + data + "\">"
              + "<i class=\"fa fa-edit fa-2x text-success\"></i></a>"
            },
            "targets": 8
          },
          { "render": function ( data, type, row ) {
            if(data == true) {
               return "<i class=\"fa fa-check-circle-o fa-2x text-success\"></i>"
            } else {
               return "<i class=\"fa fa-times fa-2x text-danger\"></i>"
            }
            },
            "targets": 7
          },
          { targets: '_all', orderable: false }
        ]
    } );
    $('#datatable_users_filter').change( function() {
        if ($(this).val() != 'cm') {
            $('#approvers_select').hide();
        } else {
            $('#approvers_select').show();
        }
        datatableUsers.draw();
    } );
    $('#datatable_users_approvers').change( function() {
        datatableUsers.draw();
    } );


    var datatableCmUsers = $('#datatable_cm_users').DataTable( {
        "processing": true,
        "serverSide": true,
        "stateSave": true,
        "order": [[ 1, "asc" ]],
        "ajax": {
          "url": $('#datatable_cm_users').data('source'),
          "data": function(d) {
            d.filter = 'manage';
          }
        },
        columnDefs: [
          { targets: [0, 6, 7, 8], "visible": false, searchable: false },
          { targets: [1, 3, 4, 5], orderable: true },
          { targets: '_all', orderable: false },
        ]
    } );
    $('#datatable_cm_users tbody').on('click','tr', function() {
      var currentRowData = datatableCmUsers.row(this).data();
      location.href = "manage_users/" + currentRowData[0];
    });

    $('#datatable_my_collections').DataTable( {
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
    $('#datatable_show_collection').DataTable( {
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
