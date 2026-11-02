// Runs before the page's scripts on disguised sites: the navigator values sites check for the
// operating system. Defined on the page's own Navigator.prototype, as a real Windows Firefox has them.
"use strict";
(() => {
  const version = (navigator.userAgent.match(/rv:([\d.]+)/) || [, "128.0"])[1];
  const values = {
    platform: "Win32",
    oscpu: "Windows NT 10.0; Win64; x64",
    appVersion: "5.0 (Windows)",
    userAgent: `Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:${version}) Gecko/20100101 Firefox/${version}`,
  };
  const proto = window.wrappedJSObject.Navigator.prototype;
  for (const [name, value] of Object.entries(values)) {
    Object.defineProperty(proto, name, {
      get: exportFunction(function () { return value; }, window),
      configurable: true,
      enumerable: true,
    });
  }
})();
