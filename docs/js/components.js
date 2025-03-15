/**
 * Enhanced component system for AshTrail GitHub Pages
 */

class ComponentLoader {
    constructor() {
        this.componentsCache = {};
        this.loadedComponents = new Set();
        this.componentsPath = '/Users/soupycampbell/Documents/smoke_log/docs/components/';
    }

    /**
     * Initializes the component loader
     */
    init() {
        document.addEventListener('DOMContentLoaded', () => {
            this.loadAllComponents();
        });
    }

    /**
     * Load all components in the document
     */
    loadAllComponents() {
        // Process components with data-component attribute
        const componentElements = document.querySelectorAll('[data-component]');
        
        componentElements.forEach(element => {
            const componentName = element.getAttribute('data-component');
            this.loadComponent(componentName, element);
        });

        // Process components with data-component-url attribute (for custom HTML files)
        const customComponentElements = document.querySelectorAll('[data-component-url]');
        
        customComponentElements.forEach(element => {
            const componentUrl = element.getAttribute('data-component-url');
            this.loadComponentFromUrl(componentUrl, element);
        });
    }

    /**
     * Load a predefined component by name
     * @param {string} name - Component name
     * @param {Element} targetElement - Element to replace with component
     */
    loadComponent(name, targetElement) {
        const components = {
            header: `
                <header class="site-header fade-in">
                    <div class="container d-flex justify-content-between align-items-center">
                        <h1>AshTrail</h1>
                        <nav>
                            <ul class="d-flex">
                                <li class="stagger-item"><a href="index.html" class="link-animated">Privacy Policy</a></li>
                                <li class="stagger-item"><a href="support.html" class="link-animated">Support</a></li>
                                <li class="stagger-item"><a href="terms_conditions.html" class="link-animated">Terms</a></li>
                            </ul>
                        </nav>
                    </div>
                </header>
            `,
            footer: `
                <footer class="site-footer">
                    <div class="container">
                        <div class="d-flex justify-content-between align-items-center">
                            <p>&copy; 2025 AshTrail LLC. All rights reserved.</p>
                            <div class="footer-links">
                                <a href="index.html" class="link-animated">Privacy</a> | 
                                <a href="support.html" class="link-animated">Support</a> | 
                                <a href="terms_conditions.html" class="link-animated">Terms</a>
                            </div>
                        </div>
                    </div>
                </footer>
            `,
            loading: `
                <div class="loading-container text-center py-5">
                    <div class="loading mx-auto"></div>
                    <p class="mt-3">Loading...</p>
                </div>
            `
        };
        
        if (components[name]) {
            targetElement.outerHTML = components[name];
            this.loadedComponents.add(name);
            this.triggerComponentLoadedEvent(name);
        } else {
            console.error(`Component "${name}" not found`);
            targetElement.outerHTML = `<div class="error-message">Component "${name}" not found</div>`;
        }
    }

    /**
     * Load a component from a custom URL
     * @param {string} url - URL to load the component from
     * @param {Element} targetElement - Element to replace with component
     */
    loadComponentFromUrl(url, targetElement) {
        // Show loading indicator
        targetElement.innerHTML = `
            <div class="loading-container text-center py-3">
                <div class="loading mx-auto"></div>
            </div>
        `;

        // Check if component is already cached
        if (this.componentsCache[url]) {
            targetElement.outerHTML = this.componentsCache[url];
            return;
        }

        // Fetch the component
        fetch(url)
            .then(response => {
                if (!response.ok) {
                    throw new Error(`Failed to load component from ${url}`);
                }
                return response.text();
            })
            .then(html => {
                // Cache the component
                this.componentsCache[url] = html;
                
                // Replace the target element
                targetElement.outerHTML = html;
                
                // Trigger component loaded event
                this.triggerComponentLoadedEvent(url);
            })
            .catch(error => {
                console.error(error);
                targetElement.outerHTML = `
                    <div class="error-message p-3 bg-danger text-white rounded">
                        Failed to load component: ${error.message}
                    </div>
                `;
            });
    }

    /**
     * Trigger a custom event when a component is loaded
     * @param {string} componentName - Name of the loaded component
     */
    triggerComponentLoadedEvent(componentName) {
        const event = new CustomEvent('componentLoaded', {
            detail: {
                componentName: componentName,
                timestamp: new Date()
            }
        });
        document.dispatchEvent(event);
    }
}

// Initialize the component loader
const componentLoader = new ComponentLoader();
componentLoader.init();

// Add animation observers for scroll-based animations
document.addEventListener('DOMContentLoaded', () => {
    const animatedElements = document.querySelectorAll('.animate-on-scroll');
    
    if (animatedElements.length > 0 && 'IntersectionObserver' in window) {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animated');
                    observer.unobserve(entry.target);
                }
            });
        }, { threshold: 0.1 });
        
        animatedElements.forEach(element => {
            observer.observe(element);
        });
    } else {
        // Fallback for browsers that don't support IntersectionObserver
        animatedElements.forEach(element => {
            element.classList.add('animated');
        });
    }
});
