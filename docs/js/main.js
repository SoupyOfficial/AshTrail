/**
 * Main JavaScript for AshTrail GitHub Pages
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all features
    initThemeToggle();
    initAccessibility();
    initLazyLoading();
    
    // Listen for component load events
    document.addEventListener('componentLoaded', function(event) {
        console.log('Component loaded:', event.detail.componentName);
        
        // Initialize features on newly loaded components
        initAccessibility();
    });
});

/**
 * Initialize theme toggle functionality
 */
function initThemeToggle() {
    const themeToggleBtn = document.getElementById('theme-toggle');
    if (!themeToggleBtn) return;

    // Check for saved user preference or respect system preference
    const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)');
    const savedTheme = localStorage.getItem('theme');
    
    if (savedTheme === 'light' || (!savedTheme && !prefersDarkScheme.matches)) {
        document.body.classList.add('light-theme');
        updateThemeToggleIcon('dark');
    } else {
        updateThemeToggleIcon('light');
    }

    // Toggle theme on button click
    themeToggleBtn.addEventListener('click', function() {
        if (document.body.classList.contains('light-theme')) {
            document.body.classList.remove('light-theme');
            localStorage.setItem('theme', 'dark');
            updateThemeToggleIcon('light');
        } else {
            document.body.classList.add('light-theme');
            localStorage.setItem('theme', 'light');
            updateThemeToggleIcon('dark');
        }
    });

    // Listen for system preference changes
    prefersDarkScheme.addEventListener('change', e => {
        if (!localStorage.getItem('theme')) {
            if (e.matches) {
                document.body.classList.remove('light-theme');
                updateThemeToggleIcon('light');
            } else {
                document.body.classList.add('light-theme');
                updateThemeToggleIcon('dark');
            }
        }
    });
}

/**
 * Update theme toggle button icon
 * @param {string} newIcon - Which icon to show ('light' or 'dark')
 */
function updateThemeToggleIcon(newIcon) {
    const themeToggleBtn = document.getElementById('theme-toggle');
    if (!themeToggleBtn) return;

    if (newIcon === 'light') {
        themeToggleBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.25a.75.75 0 01.75.75v2.25a.75.75 0 01-1.5 0V3a.75.75 0 01.75-.75zM7.5 12a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM18.894 6.166a.75.75 0 00-1.06-1.06l-1.591 1.59a.75.75 0 101.06 1.061l1.591-1.59zM21.75 12a.75.75 0 01-.75.75h-2.25a.75.75 0 010-1.5H21a.75.75 0 01.75.75zM17.834 18.894a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 10-1.061 1.06l1.59 1.591zM12 18a.75.75 0 01.75.75V21a.75.75 0 01-1.5 0v-2.25A.75.75 0 0112 18zM7.758 17.303a.75.75 0 00-1.061-1.06l-1.591 1.59a.75.75 0 001.06 1.061l1.591-1.59zM6 12a.75.75 0 01-.75.75H3a.75.75 0 010-1.5h2.25A.75.75 0 016 12zM6.697 7.757a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 00-1.061 1.06l1.59 1.591z"/></svg>';
        themeToggleBtn.setAttribute('aria-label', 'Switch to light mode');
    } else {
        themeToggleBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path fill-rule="evenodd" d="M9.528 1.718a.75.75 0 01.162.819A8.97 8.97 0 009 6a9 9 0 009 9 8.97 8.97 0 003.463-.69.75.75 0 01.981.98 10.503 10.503 0 01-9.694 6.46c-5.799 0-10.5-4.701-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 01.818.162z" clip-rule="evenodd"/></svg>';
        themeToggleBtn.setAttribute('aria-label', 'Switch to dark mode');
    }
}

/**
 * Initialize accessibility improvements
 */
function initAccessibility() {
    // Add appropriate ARIA labels to any unlabeled elements
    document.querySelectorAll('a, button').forEach(el => {
        if (!el.getAttribute('aria-label') && !el.textContent.trim()) {
            const nextEl = el.nextElementSibling;
            if (nextEl && nextEl.tagName === 'SPAN') {
                el.setAttribute('aria-label', nextEl.textContent);
            }
        }
    });

    // Make sure all interactive elements are keyboard navigable
    document.querySelectorAll('[role="button"], [data-clickable]').forEach(el => {
        if (!el.getAttribute('tabindex')) {
            el.setAttribute('tabindex', '0');
        }

        // Add keyboard event listeners for elements that should be clickable
        el.addEventListener('keydown', function(event) {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                el.click();
            }
        });
    });
}

/**
 * Initialize lazy loading for images and other resources
 */
function initLazyLoading() {
    if ('IntersectionObserver' in window) {
        const imgObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    const src = img.getAttribute('data-src');
                    
                    if (src) {
                        img.src = src;
                        img.removeAttribute('data-src');
                    }
                    
                    observer.unobserve(img);
                }
            });
        });

        // Observe all images with data-src attribute
        document.querySelectorAll('img[data-src]').forEach(img => {
            imgObserver.observe(img);
        });
    } else {
        // Fallback for browsers that don't support Intersection Observer
        document.querySelectorAll('img[data-src]').forEach(img => {
            const src = img.getAttribute('data-src');
            if (src) {
                img.src = src;
                img.removeAttribute('data-src');
            }
        });
    }
}
