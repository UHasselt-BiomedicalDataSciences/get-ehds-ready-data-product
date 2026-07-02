// Turns pandoc/citeproc in-text citations into hover/tap pop-ups.
//
// citeproc renders each citation as:
//   <span class="citation" data-cites="key1 key2"><a href="#ref-key1">[1]</a>...</span>
// and the full bibliography (hidden via CSS) into:
//   <div id="refs">...<div id="ref-key1" class="csl-entry">...</div>...</div>
//
// Each citation gets a `.cite-tooltip` populated with the matching
// bibliography entries. The tooltips are appended to <body> — not nested in
// the citation — because several containers (.card, .split, .canvas-grid)
// use overflow:hidden for their rounded-corner styling and would clip a
// nested pop-up. Visibility and position are managed here: on open, the
// pop-up is placed above the citation in page coordinates, clamped to the
// viewport, flipped below the citation when there is no room above, and
// --arrow-x keeps the arrow anchored on the citation mark.
(function () {
  "use strict";

  var MARGIN = 12; // minimum gap to the viewport edges
  var GAP = 10;    // gap between the citation and the pop-up

  function buildTooltip(keys) {
    var tooltip = document.createElement("div");
    tooltip.className = "cite-tooltip";
    tooltip.setAttribute("role", "tooltip");

    var found = false;
    keys.forEach(function (key) {
      var entry = document.getElementById("ref-" + key);
      if (!entry) return;
      found = true;
      tooltip.appendChild(entry.cloneNode(true));
    });

    return found ? tooltip : null;
  }

  function hide(tooltip) {
    tooltip.classList.remove("is-visible");
  }

  function hideAll(except) {
    document.querySelectorAll(".cite-tooltip.is-visible").forEach(function (tooltip) {
      if (tooltip !== except) tooltip.classList.remove("is-visible");
    });
  }

  function show(citation, tooltip) {
    hideAll(tooltip);

    var rect = citation.getBoundingClientRect();
    var width = tooltip.offsetWidth;
    var height = tooltip.offsetHeight;
    var scrollX = window.scrollX;
    var scrollY = window.scrollY;
    var viewportWidth = document.documentElement.clientWidth;

    var centerX = scrollX + rect.left + rect.width / 2;
    var left = centerX - width / 2;
    left = Math.min(left, scrollX + viewportWidth - MARGIN - width);
    left = Math.max(left, scrollX + MARGIN);

    var below = rect.top - height - GAP < MARGIN;
    var top = below ? scrollY + rect.bottom + GAP : scrollY + rect.top - height - GAP;

    // Keep the arrow over the citation, but never in the rounded corners.
    var arrowX = Math.max(14, Math.min(centerX - left, width - 14));

    tooltip.style.left = left + "px";
    tooltip.style.top = top + "px";
    tooltip.style.setProperty("--arrow-x", arrowX + "px");
    tooltip.classList.toggle("is-below", below);
    tooltip.classList.add("is-visible");
  }

  function enhance(citation, index) {
    var keys = (citation.getAttribute("data-cites") || "").trim().split(/\s+/).filter(Boolean);
    if (!keys.length) return;

    var tooltip = buildTooltip(keys);
    if (!tooltip) return;

    var wrap = document.createElement("span");
    wrap.className = "cite-wrap";

    citation.parentNode.insertBefore(wrap, citation);
    wrap.appendChild(citation);

    tooltip.id = "cite-tooltip-" + index;
    document.body.appendChild(tooltip);

    // A short close delay lets the pointer cross the gap between the
    // citation and the pop-up without the pop-up disappearing.
    var closeTimer = null;
    function scheduleHide() {
      closeTimer = window.setTimeout(function () { hide(tooltip); }, 150);
    }
    function cancelHide() {
      if (closeTimer) {
        window.clearTimeout(closeTimer);
        closeTimer = null;
      }
    }

    wrap.addEventListener("mouseenter", function () {
      cancelHide();
      show(citation, tooltip);
    });
    wrap.addEventListener("mouseleave", scheduleHide);
    tooltip.addEventListener("mouseenter", cancelHide);
    tooltip.addEventListener("mouseleave", scheduleHide);

    var link = citation.querySelector("a");
    if (link) {
      link.setAttribute("aria-describedby", tooltip.id);
      link.addEventListener("focus", function () {
        cancelHide();
        show(citation, tooltip);
      });
      link.addEventListener("blur", scheduleHide);
      link.addEventListener("click", function (event) {
        event.preventDefault();
        cancelHide();
        if (tooltip.classList.contains("is-visible")) {
          hide(tooltip);
        } else {
          show(citation, tooltip);
        }
      });
    }
  }

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll(".citation[data-cites]").forEach(enhance);

    document.addEventListener("click", function (event) {
      if (!event.target.closest(".cite-wrap") && !event.target.closest(".cite-tooltip")) {
        hideAll();
      }
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") hideAll();
    });

    // Positions are computed per open; on resize they may be stale, so close.
    window.addEventListener("resize", function () { hideAll(); });
  });
})();
