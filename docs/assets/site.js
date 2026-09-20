(function () {
  'use strict';
  var root = document.documentElement;
  root.classList.add('js');

  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Sticky nav gets a hairline once the page scrolls.
  var nav = document.querySelector('.nav');
  function onScroll() { nav.classList.toggle('scrolled', window.scrollY > 8); }
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  var year = document.getElementById('year');
  if (year) year.textContent = new Date().getFullYear();

  // Reveal-on-scroll. Content stays visible if IntersectionObserver is unavailable.
  var reveals = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window && !reduce) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });
    reveals.forEach(function (el) { io.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add('in'); });
  }

  // Workflow stepper: click a step to jump to it; otherwise it auto-advances
  // when a step's progress bar finishes (CSS animation -> animationend).
  var flow = document.querySelector('[data-flow]');
  if (!flow) return;
  var steps = Array.prototype.slice.call(flow.querySelectorAll('.step'));
  var imgs = Array.prototype.slice.call(flow.querySelectorAll('[data-step-img]'));
  var manual = false;

  function activate(i) {
    steps.forEach(function (s, j) {
      var on = j === i;
      s.classList.toggle('is-active', on);
      s.setAttribute('aria-pressed', on ? 'true' : 'false');
      s.classList.remove('auto');
      if (on && !manual && !reduce) {
        void s.offsetWidth; // restart the CSS animation
        s.classList.add('auto');
      }
    });
    imgs.forEach(function (im, j) { im.classList.toggle('is-active', j === i); });
  }

  steps.forEach(function (s, i) {
    s.addEventListener('click', function () { manual = true; activate(i); });
  });

  flow.addEventListener('animationend', function (e) {
    if (!e.target.classList.contains('step__bar')) return;
    var cur = steps.findIndex(function (s) { return s.classList.contains('is-active'); });
    activate((cur + 1) % steps.length);
  });

  // Only run the timer while the stepper is on screen and not hovered.
  flow.classList.add('paused');
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { flow.classList.toggle('paused', !e.isIntersecting); });
    }, { threshold: 0.35 }).observe(flow);
  } else {
    flow.classList.remove('paused');
  }
  flow.addEventListener('mouseenter', function () { flow.classList.add('paused'); });
  flow.addEventListener('mouseleave', function () { flow.classList.remove('paused'); });

  activate(0);
})();
