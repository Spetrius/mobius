// Sites listed here get a Windows User-Agent header (here) and Windows navigator values
// (disguise.js, run before the page's own scripts). Everything else keeps reporting Linux.
"use strict";

const version = (navigator.userAgent.match(/rv:([\d.]+)/) || [, "128.0"])[1];
const WINDOWS_UA = `Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:${version}) Gecko/20100101 Firefox/${version}`;

let sites = [];          // hostnames, without "www."; subdomains count too
let registered = null;   // the content script registration for those sites

const siteOf = (url) => {
  try {
    const u = new URL(url);
    if (!/^https?:$/.test(u.protocol)) return null;
    return u.hostname.replace(/^www\./, "");
  } catch { return null; }
};
const covered = (url) => {
  const h = siteOf(url);
  return !!h && sites.some((s) => h === s || h.endsWith("." + s));
};

async function apply() {
  if (registered) { await registered.unregister(); registered = null; }
  if (sites.length) {
    registered = await browser.contentScripts.register({
      matches: sites.flatMap((s) => [`*://${s}/*`, `*://*.${s}/*`]),
      js: [{ file: "disguise.js" }],
      runAt: "document_start",
      allFrames: true,
    });
  }
  const tabs = await browser.tabs.query({});
  for (const t of tabs) badge(t);
}

function badge(tab) {
  if (!tab || tab.id === undefined) return;
  const on = covered(tab.url || "");
  browser.browserAction.setBadgeText({ tabId: tab.id, text: on ? "WIN" : "" });
  browser.browserAction.setTitle({
    tabId: tab.id,
    title: `Windows disguise: ${on ? "ON" : "off"} for this site (click to switch)`,
  });
}

async function load() {
  ({ sites = [] } = await browser.storage.local.get("sites"));
  await apply();
}

// The header, for the page itself and everything it loads
browser.webRequest.onBeforeSendHeaders.addListener(
  (d) => {
    if (![d.url, d.documentUrl, d.originUrl].some((u) => u && covered(u))) return {};
    for (const h of d.requestHeaders) {
      if (h.name.toLowerCase() === "user-agent") h.value = WINDOWS_UA;
    }
    return { requestHeaders: d.requestHeaders };
  },
  { urls: ["<all_urls>"] },
  ["blocking", "requestHeaders"],
);

// Toolbar button: turn the disguise on or off for the current site, then reload it
browser.browserAction.onClicked.addListener(async (tab) => {
  const host = siteOf(tab.url || "");
  if (!host) return;
  const match = sites.find((s) => host === s || host.endsWith("." + s));
  sites = match ? sites.filter((s) => s !== match) : [...sites, host];
  await browser.storage.local.set({ sites });
  browser.tabs.reload(tab.id, { bypassCache: true });
});

browser.storage.onChanged.addListener((c) => { if (c.sites) load(); });
browser.tabs.onUpdated.addListener((id, info, tab) => { if (info.url || info.status) badge(tab); });
load();
