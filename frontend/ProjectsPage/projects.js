document.addEventListener('DOMContentLoaded', function () {
    showProjects('italy');
});

function showProjects(location) {
    const projectsList = document.getElementById('projects-list');
    projectsList.innerHTML = ''; // Clear the current projects

    const projects = {
        italy: [
            {
                img: 'path/to/photo1.jpg',
                date: '2023-05-19',
                location: 'Venice, Italy',
                title: 'Beautiful Venice'
            },
            {
                img: 'path/to/photo2.jpg',
                date: '2023-05-20',
                location: 'Florence, Italy',
                title: 'Charming Florence'
            }
        ],
        australia: [
            {
                img: 'path/to/photo3.jpg',
                date: '2023-06-15',
                location: 'Sydney, Australia',
                title: 'Sydney Opera House'
            },
            {
                img: 'path/to/photo4.jpg',
                date: '2023-06-16',
                location: 'Melbourne, Australia',
                title: 'Melbourne Cityscape'
            }
        ],
        india: [
            {
                img: 'path/to/photo5.jpg',
                date: '2023-07-10',
                location: 'Agra, India',
                title: 'Taj Mahal'
            },
            {
                img: 'path/to/photo6.jpg',
                date: '2023-07-11',
                location: 'Jaipur, India',
                title: 'Pink City Jaipur'
            }
        ],
        brazil: [
            {
                img: 'path/to/photo7.jpg',
                date: '2023-08-05',
                location: 'Rio de Janeiro, Brazil',
                title: 'Rio Carnival'
            },
            {
                img: 'path/to/photo8.jpg',
                date: '2023-08-06',
                location: 'Sao Paulo, Brazil',
                title: 'Sao Paulo Skyline'
            }
        ]
    };

    projects[location].forEach(project => {
        const projectItem = document.createElement('div');
        projectItem.classList.add('grid-item');
        
        projectItem.innerHTML = `
            <img src="${project.img}" alt="${project.title}">
            <div class="details">
                <p class="date">${project.date}</p>
                <p class="location">${project.location}</p>
                <h2 class="title">${project.title}</h2>
            </div>
        `;
        
        projectsList.appendChild(projectItem);
    });

    // Update active button
    document.querySelectorAll('.filter-buttons button').forEach(button => {
        button.classList.remove('active');
    });
    document.querySelector(`.filter-buttons button[onclick="showProjects('${location}')"]`).classList.add('active');
}
