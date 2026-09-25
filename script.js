// mymate interactive features
// Scroll progress, custom cursor, navigation

// DOM elements
const cursor = document.querySelector('.cursor');
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');
const scrollProgress = document.querySelector('.scroll-progress');

// Custom cursor
function updateCursor(e) {
  if (window.innerWidth > 900) { // Only on desktop
    cursor.style.left = e.clientX + 'px';
    cursor.style.top = e.clientY + 'px';
    cursor.classList.add('is-active');
  }
}

function hideCursor() {
  cursor.classList.remove('is-active');
}

// Navigation toggle
navToggle?.addEventListener('click', () => {
  navLinks?.classList.toggle('open');
  navToggle?.classList.toggle('open');
  navToggle?.setAttribute('aria-expanded', navLinks?.classList.contains('open') ? 'true' : 'false');
});

// Close navigation on outside click
document.addEventListener('click', (e) => {
  if (window.innerWidth <= 900 && 
      navLinks?.classList.contains('open') && 
      !navLinks.contains(e.target) && 
      !navToggle?.contains(e.target)) {
    navLinks.classList.remove('open');
    navToggle?.classList.remove('open');
    navToggle?.setAttribute('aria-expanded', 'false');
  }
});

// Scroll progress
window.addEventListener('scroll', () => {
  const winScroll = document.documentElement.scrollTop;
  const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
  const scrolled = (winScroll / height) * 100;
  scrollProgress.style.width = scrolled + '%';
});

// Reveal elements on scroll
function revealOnScroll() {
  const reveals = document.querySelectorAll('.reveal');
  
  reveals.forEach((element) => {
    const elementTop = element.getBoundingClientRect().top;
    const windowHeight = window.innerHeight;
    
    if (elementTop < windowHeight - 100) {
      element.classList.add('in');
    }
  });
}

// Set initial delays for staggered reveals
document.querySelectorAll('.reveal').forEach((element, index) => {
  const delay = element.dataset.delay || index * 100;
  element.style.transitionDelay = delay + 'ms';
});

// Custom cursor interaction
const interactiveElements = document.querySelectorAll('a, button, .btn, .index-row, .row, .timeline-item, .nav-links a');

interactiveElements.forEach((element) => {
  element.addEventListener('mouseenter', () => cursor?.classList.add('is-active'));
  element.addEventListener('mouseleave', () => cursor?.classList.remove('is-active'));
});

// Active navigation highlighting
window.addEventListener('scroll', () => {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links a');
  
  let current = '';
  sections.forEach((section) => {
    const sectionTop = section.offsetTop;
    const sectionHeight = section.clientHeight;
    if (window.pageYOffset >= sectionTop - 100) {
      current = section.getAttribute('id');
    }
  });
  
  navLinks.forEach((link) => {
    link.classList.remove('active');
    if (link.getAttribute('href').includes(current)) {
      link.classList.add('active');
    }
  });
});

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener('click', function (e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
});

// Initialize custom cursor and animations
function init() {
  document.body.classList.add('cursor-on');
  document.addEventListener('mousemove', updateCursor);
  document.addEventListener('mouseleave', hideCursor);
  
  // Trigger initial reveal
  revealOnScroll();
  
  // Handle window resize
  window.addEventListener('resize', () => {
    if (window.innerWidth <= 900) {
      cursor?.classList.add('mobile-hidden');
    } else {
      cursor?.classList.remove('mobile-hidden');
    }
  });
}

// Start everything when DOM is ready
document.addEventListener('DOMContentLoaded', init);

// Performance optimization - throttle scroll events
let scrollTimeout;
window.addEventListener('scroll', () => {
  window.clearTimeout(scrollTimeout);
  scrollTimeout = window.setTimeout(() => {
    revealOnScroll();
  }, 100);
});
