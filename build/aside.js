function refreshAsides() {
  document.querySelectorAll("aside").forEach(function (aside) {
    // If the asides are inline, clear their position.
    window.console.log(window.innerWidth);
    if (window.innerWidth < 1088) {
      aside.style.top = "auto";
      return;
    }

    // Find the span the aside should be anchored next to.
    const name = aside.getAttribute("name");
    if (name == null) {
      window.console.log("No name for aside:");
      window.console.log(aside);
      return;
    }

    const span = document.querySelector("span[name='" + name + "']");
    if (span == null) {
      window.console.log("No span for aside '" + name + "'");
      return;
    }

    // Vertically position the aside next to the span it annotates.
    if (aside.classList.contains("bottom")) {
      aside.style.top = (span.offsetTop - aside.offsetHeight + 24) + "px";
    } else {
      aside.style.top = (span.offsetTop) + "px";
    }
  });
}

if (document.readyState !== "loading") {
  refreshAsides();
} else {
  document.addEventListener("DOMContentLoaded", refreshAsides);
}

// On the off chance the browser supports the new font loader API, use it.
if (document.fontloader) {
  document.fontloader.notifyWhenFontsReady(refreshAsides);
}

window.addEventListener('resize', refreshAsides, true);

// Lame. Just do another refresh after a bit when the font is *probably*
// loaded to hack around the fact that the metrics changed.
window.setTimeout(refreshAsides, 200);
