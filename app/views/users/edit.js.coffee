
# replace the body of the modal dialog box with the haml we want rendered
# $('#modal_content').html("<%= escape_javascript(render('users/edit') ) %>");
$('#modal-body').html("<%= escape_javascript(render('users/edit') ) %>");
$('#modal_popup .modal-dialog').addClass('modal-lg')
