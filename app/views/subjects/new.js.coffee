
# replace the body of the modal dialog box with the haml we want rendered
$('#modal-body').html("<%= escape_javascript(render('subjects/create') ) %>");
###################################
# bind events for new content
