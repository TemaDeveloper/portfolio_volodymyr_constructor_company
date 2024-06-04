document.getElementById('generate-link-btn').addEventListener('click', function() {
    // Generate the link here
    document.getElementById('generated-link').innerText = 'http://example.com/generated-link';
});

function navigateToAddProject() {
    window.location.href = '../ProjectAddition/addition.html';
}

function navigateToUpdateProject() {
    window.location.href = '../ProjectUpdate/update_project.html';
}
