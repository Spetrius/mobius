"use strict";
const list = document.getElementById("list");

async function show() {
  const { sites = [] } = await browser.storage.local.get("sites");
  list.replaceChildren(...sites.map((s) => {
    const li = document.createElement("li");
    const b = document.createElement("button");
    li.textContent = s;
    b.textContent = "Remove";
    b.onclick = () => browser.storage.local.set({ sites: sites.filter((x) => x !== s) });
    li.append(b);
    return li;
  }));
  document.getElementById("empty").hidden = sites.length > 0;
}

document.getElementById("add").onsubmit = async (e) => {
  e.preventDefault();
  const input = document.getElementById("site");
  let s = input.value.trim().toLowerCase();
  try { if (s.includes("/")) s = new URL(s.includes("://") ? s : "https://" + s).hostname; } catch {}
  s = s.replace(/^www\./, "");
  if (!/^[a-z0-9.-]+\.[a-z]{2,}$/.test(s)) return;
  const { sites = [] } = await browser.storage.local.get("sites");
  if (!sites.includes(s)) await browser.storage.local.set({ sites: [...sites, s] });
  input.value = "";
};

browser.storage.onChanged.addListener(show);
show();
