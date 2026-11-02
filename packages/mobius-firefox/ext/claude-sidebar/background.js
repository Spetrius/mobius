// Right-click menu: hand the selection or the page to the sidebar.
"use strict";

let pending = null;   // {kind: "selection"|"page", tabId, text?}

browser.menus.create({ id: "claude-selection", title: "Ask Claude about \"%s\"", contexts: ["selection"] });
browser.menus.create({ id: "claude-page", title: "Ask Claude about this page", contexts: ["page"] });

browser.menus.onClicked.addListener((info, tab) => {
  browser.sidebarAction.open();   // first, while this still counts as a user action
  pending = info.menuItemId === "claude-selection"
    ? { kind: "selection", tabId: tab.id, text: info.selectionText }
    : { kind: "page", tabId: tab.id };
  browser.runtime.sendMessage({ type: "pending" }).catch(() => {});   // sidebar not loaded yet: it asks
});

browser.runtime.onMessage.addListener((m) => {
  if (m.type === "take-pending") { const p = pending; pending = null; return Promise.resolve(p); }
});
