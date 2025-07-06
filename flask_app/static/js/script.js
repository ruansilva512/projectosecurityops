document.addEventListener('DOMContentLoaded', function() {
    // Example: A simple console log to confirm script is loading
    console.log('Flask UI script loaded!');

    // You could add more complex JavaScript animations here,
    // like dynamic content loading, parallax effects,
    // or interactions with your backend APIs.

    // For instance, if you wanted to observe elements and add classes
    // when they enter the viewport (for lazy loading or scroll animations):
    const cards = document.querySelectorAll('.service-card');
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible'); // Add a 'visible' class
                observer.unobserve(entry.target); // Stop observing once visible
            }
        });
    }, observerOptions);

    cards.forEach(card => {
        observer.observe(card);
    });
});