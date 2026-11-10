function removeSplashFromWeb() {
  document.getElementById("splash")?.remove();
  document.getElementById("splash-branding")?.remove();
  document.body.style.background = "transparent";
}

//the version under the splash, from the version.json written by `flutter build web`
//(this file loads in <head>: wait for the body before looking for the element)
document.addEventListener("DOMContentLoaded", () =>
  fetch("version.json")
    .then((r) => r.json())
    .then((v) => {
      const el = document.getElementById("splash-version");
      if (el && v.version) el.textContent = "v" + v.version;
    })
    .catch(() => {})
);
