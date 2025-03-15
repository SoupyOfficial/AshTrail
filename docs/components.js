/**
 * Simple component system for AshTrail GitHub Pages
 */

document.addEventListener('DOMContentLoaded', function() {
    // Load components marked with data-component attribute
    const componentElements = document.querySelectorAll('[data-component]');
    
    componentElements.forEach(element => {
        const componentName = element.getAttribute('data-component');
        loadComponent(componentName, element);
    });
});

/**
 * Load a component by name
 * @param {string} name - Component name
 * @param {Element} targetElement - Element to replace with component
 */
function loadComponent(name, targetElement) {
    const components = {
        header: `
            <header>
                <div class="container">
                    <h1>AshTrail</h1>
                    <nav>
                        <ul>
                            <li><a href="index.html">Privacy Policy</a></li>
                            <li><a href="support.html">Support</a></li>
                        </ul>
                    </nav>
                </div>
            </header>
        `,
        footer: `
            <footer>
                <div class="container">
                    <p>&copy; 2025 AshTrail LLC. All rights reserved.</p>
                </div>
            </footer>
        `
    };
    
    if (components[name]) {
        targetElement.outerHTML = components[name];
    } else {
        console.error(`Component "${name}" not found`);
    }
}
