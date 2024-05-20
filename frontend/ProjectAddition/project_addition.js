document.addEventListener('DOMContentLoaded', function() {
    const addImageBtn = document.getElementById('add-image-btn');
    const imageInput = document.getElementById('image-input');
    const projectTitleInput = document.getElementById('project-title');
    const recentProjects = document.getElementById('recent-projects');
    const imagePlaceholder = document.getElementById('image-placeholder');
    const submitBtn = document.getElementById('submit-btn');
    let selectedImageSrc = '';

    function attachAddImageBtnListener() {
        document.querySelector('.add-image-btn').addEventListener('click', function() {
            imageInput.click();
        });
    }

    attachAddImageBtnListener(); // Initial attachment

    imageInput.addEventListener('change', function() {
        const file = this.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                const img = new Image();
                img.src = e.target.result;
                img.onload = function() {
                    img.style.maxWidth = '100%';
                    img.style.maxHeight = '100%';
                    img.style.objectFit = 'contain';

                    imagePlaceholder.innerHTML = '';
                    imagePlaceholder.appendChild(img);
                    selectedImageSrc = e.target.result; // Store the image src
                };
            };
            reader.readAsDataURL(file);
        }
    });

    submitBtn.addEventListener('click', function() {
        const title = projectTitleInput.value.trim();
        if (!title) {
            alert('Please enter a project title.');
            return;
        }

        if (!selectedImageSrc) {
            alert('Please add an image.');
            return;
        }

        addProjectToGallery(title, selectedImageSrc);
        projectTitleInput.value = ''; // Clear the input field
        imagePlaceholder.innerHTML = '<button class="add-image-btn" id="add-image-btn">Add Image</button>'; // Reset image placeholder
        attachAddImageBtnListener(); // Re-attach event listener to the new button
        selectedImageSrc = ''; // Clear the selected image src
        imageInput.value = ''; // Clear the file input
    });

    function addProjectToGallery(title, imgSrc) {
        const projectItem = document.createElement('div');
        projectItem.classList.add('grid-item');

        projectItem.innerHTML = `
            <img src="${imgSrc}" alt="${title}">
            <div class="details">
                <h2 class="title">${title}</h2>
            </div>
        `;

        recentProjects.appendChild(projectItem);
    }
});
