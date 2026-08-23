/* ============================================================================
   bim_ui.js — Budget Impact Model, interface layer
   Rendering and event binding only. All arithmetic lives in bim_engine.js.

   Structure note: the skeleton and every <input> are built exactly once, and
   each panel returns an update() closure that mutates its outputs in place.
   A full rebuild on every input event would destroy the slider mid-drag, and
   dragging market share is the interaction this tool exists to show.
   ==========================================================================*/
(function () {
  "use strict";
  const P = window.BIM_PARAMS, E = window.BIM_ENGINE;
  const app = document.getElementById("bim-app");
  if (!app || !P || !E) return;

  const RID = P.regimens.map(r => r.id);
  const NON_VEN = RID.filter(r => !P.regimens.find(x => x.id === r).ven);
  const LABEL = Object.fromEntries(P.regimens.map(r => [r.id, r.label]));
  const IS_VEN = Object.fromEntries(P.regimens.map(r => [r.id, r.ven]));
  /* Categorical palette, fixed order, never cycled. Validated for stacked
     adjacent pairs: worst CVD deltaE 9.1, worst normal-vision deltaE 19.6.
     Three slots fall below 3:1 against the surface, so every segment large
     enough to hold one carries a direct label - identity is never colour alone. */
  const CAT = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#4a3aa7"];
  const COLOR  = Object.fromEntries(RID.map((r, i) => [r, CAT[i]]));
  const CCOLOR = CAT.slice(0, 6);
  const SHORT  = { AZA: "AZA", DE: "DEC", LDC: "LDAC", BSC: "BSC",
                   VEN_AZA: "VEN+AZA", VEN_DE: "VEN+DEC", VEN_LDC: "VEN+LDAC" };
  const SHORT_C = { drug: "Drug", administration: "Admin", adverseEvents: "AEs",
                    hospitalisation: "Hospital", monitoring: "Monitor", transfusion: "Transfusion" };
  /* on-fill ink: white on dark fills, near-black on light ones */
  function inkOn(hex) {
    const ch = i => { const c = parseInt(hex.slice(i, i + 2), 16) / 255;
                      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
    const L = 0.2126 * ch(1) + 0.7152 * ch(3) + 0.0722 * ch(5);
    return L > 0.42 ? "#141414" : "#ffffff";
  }
  const GAP = 2;   /* surface gap between stacked segments */
  const YEARS = ["y1", "y2", "y3"];

  const fmt0 = n => Math.round(n).toLocaleString("en-GB");
  const money = n => (n < 0 ? "−$" : "$") + fmt0(Math.abs(n));
  const moneyM = n => (n < 0 ? "−$" : "$") + (Math.abs(n) / 1e6).toFixed(2) + "m";
  const pmpmFmt = n => (n < 0 ? "−$" : "$") + Math.abs(n).toFixed(3);
  const pct1 = n => n.toFixed(1) + "%";

  const initial = () => ({
    perspective: "socsec",
    coveredPopulation: P.epidemiology.coveredPopulation.value,
    incidence65plus:   P.epidemiology.incidence65plus.value,
    pctUnfitIntensive: P.epidemiology.pctUnfitIntensive.value,
    pct65plus:         P.epidemiology.pct65plus.value,
    sharesWithout: Object.fromEntries(RID.map(r => [r, P.marketShare.withoutVEN[r] || 0])),
    sharesWith: Object.fromEntries(YEARS.map(y =>
      [y, Object.fromEntries(RID.map(r => [r, P.marketShare.withVEN[y][r] || 0]))]))
  });
  let S = initial();

  function el(tag, attrs, children) {
    const n = document.createElement(tag);
    if (attrs) for (const k in attrs) {
      if (k === "class") n.className = attrs[k];
      else if (k === "html") n.innerHTML = attrs[k];
      else if (k === "text") n.textContent = attrs[k];
      else n.setAttribute(k, attrs[k]);
    }
    (children || []).forEach(c => n.appendChild(c));
    return n;
  }
  const SVGNS = "http://www.w3.org/2000/svg";
  function sv(tag, attrs, text) {
    const n = document.createElementNS(SVGNS, tag);
    for (const k in (attrs || {})) n.setAttribute(k, attrs[k]);
    if (text !== undefined) n.textContent = text;
    return n;
  }
  /* Provenance chip. What a reviewer asks is which trial, which expert process,
     which price list — so the upstream source leads and the table number is a
     secondary locator for checking the replication. */
  function kindOf(sourceKey) {
    const s = P.sources[sourceKey];
    if (!s) return "published";
    if (s.type === "Assumption") return "assumption";
    if (/^Derived/.test(s.type)) return "derived";
    return "published";
  }
  function chip(prm) {
    const keys = [].concat(prm.from || []);
    const first = P.sources[keys[0]];
    const label = first ? first.short : String(prm.src || "").split("—")[0].trim();
    const extra = keys.length > 1 ? " +" + (keys.length - 1) : "";
    const tip = keys.map(k => P.sources[k] && (P.sources[k].type + ": " + P.sources[k].full
                  + (P.sources[k].ref ? "  " + P.sources[k].ref : ""))).filter(Boolean).join("\n\n")
              + (prm.src ? "\n\n" + prm.src : "");
    const n = el("span", { class: "bim-src bim-src-" + kindOf(keys[0]),
      tabindex: "0", role: "note", "data-tip": tip.trim(), "aria-label": tip.trim() });
    n.appendChild(el("span", { text: label + extra }));
    if (prm.at) n.appendChild(el("span", { class: "bim-src-at", text: prm.at }));
    return n;
  }
  function swatch(c) { return el("span", { class: "bim-swatch", style: "background:" + c }); }

  /* Hover card for the provenance chips. The native title tooltip waits about a
     second before appearing — long enough that a reader gives up — and it is
     clipped by the scrolling table wrappers. This one is instant, and lives on
     <body> so nothing can crop it. */
  const tipEl = el("div", { class: "bim-tip", role: "tooltip", "aria-hidden": "true" });
  document.body.appendChild(tipEl);
  let tipFor = null;
  function showTip(target) {
    const text = target.getAttribute("data-tip");
    if (!text) return;
    tipFor = target;
    tipEl.textContent = text;
    tipEl.classList.add("on");
    const r = target.getBoundingClientRect();
    const w = Math.min(360, window.innerWidth - 24);
    tipEl.style.width = w + "px";
    let left = Math.min(Math.max(8, r.left), window.innerWidth - w - 8);
    const below = r.bottom + 6;
    const fitsBelow = below + tipEl.offsetHeight < window.innerHeight - 8;
    tipEl.style.left = left + "px";
    tipEl.style.top = (fitsBelow ? below : r.top - tipEl.offsetHeight - 6) + "px";
  }
  function hideTip() { tipFor = null; tipEl.classList.remove("on"); }
  document.addEventListener("mouseover", e => {
    const t = e.target.closest && e.target.closest(".bim-src[data-tip]");
    if (t) showTip(t); else if (tipFor && !e.target.closest(".bim-tip")) hideTip();
  });
  document.addEventListener("focusin", e => {
    const t = e.target.closest && e.target.closest(".bim-src[data-tip]");
    if (t) showTip(t); else hideTip();
  });
  window.addEventListener("scroll", hideTip, true);
  document.addEventListener("keydown", e => { if (e.key === "Escape") hideTip(); });
  const clear = n => { while (n.firstChild) n.removeChild(n.firstChild); };

  /* current engine result, recomputed on every change */
  function compute() {
    return E.budgetImpact(P, {
      perspective: S.perspective,
      coveredPopulation: S.coveredPopulation, incidence65plus: S.incidence65plus,
      pctUnfitIntensive: S.pctUnfitIntensive, pct65plus: S.pct65plus,
      sharesWithout: S.sharesWithout, sharesWith: S.sharesWith
    });
  }

  /* ======================================================================== */
  function buildTopBar() {
    const bar = el("div", { class: "bim-topbar" });
    const left = el("div", { class: "bim-topbar-left" });
    left.appendChild(el("span", { class: "bim-topbar-label", text: "Payer perspective" }));
    const grp = el("div", { class: "bim-toggle" });
    const btns = {};
    [["socsec", "Social security"], ["private", "Private sector"]].forEach(([k, t]) => {
      const b = el("button", { type: "button", class: "bim-toggle-btn", text: t });
      b.addEventListener("click", () => { S.perspective = k; update(); });
      btns[k] = b; grp.appendChild(b);
    });
    left.appendChild(grp);
    left.appendChild(chip(P.unitCosts));
    bar.appendChild(left);

    const right = el("div", { class: "bim-topbar-right" });
    const head = el("div", { class: "bim-headline" });
    const hLab = el("span", { text: "Year-3 budget impact" });
    const hVal = el("strong", {}), hPmpm = el("em", {});
    head.appendChild(hLab); head.appendChild(hVal); head.appendChild(hPmpm);
    right.appendChild(head);
    const reset = el("button", { type: "button", class: "bim-reset", text: "Reset to base case" });
    reset.addEventListener("click", () => { S = initial(); syncInputs(); update(); });
    right.appendChild(reset);
    bar.appendChild(right);

    return { node: bar, update(res) {
      Object.keys(btns).forEach(k =>
        btns[k].className = "bim-toggle-btn" + (S.perspective === k ? " active" : ""));
      const y3 = res.years[2];
      hVal.textContent = moneyM(y3.impact.total);
      hPmpm.textContent = pmpmFmt(y3.pmpm) + " PMPM";
    } };
  }

  /* ---- panel 1: funnel --------------------------------------------------- */
  const funnelInputs = [];
  function buildFunnel() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "2 · Epidemiology funnel" }));
    w.appendChild(el("p", { class: "bim-panel-note", text:
      "From covered lives to patients eligible for treatment. Every step is an assumption a payer can challenge, so every step is exposed." }));

    const controls = el("div", { class: "bim-controls" });
    [{ key: "coveredPopulation", label: "Covered population", min: 100000, max: 5000000, step: 50000,
       fmt: fmt0, prm: P.epidemiology.coveredPopulation },
     { key: "pct65plus", label: "Members aged 65 or over", min: 5, max: 100, step: 1,
       fmt: v => v + "%", prm: P.epidemiology.pct65plus },
     { key: "incidence65plus", label: "AML incidence, aged 65+", min: 5, max: 40, step: 0.1,
       fmt: v => v.toFixed(1) + " / 100,000", prm: P.epidemiology.incidence65plus },
     { key: "pctUnfitIntensive", label: "Unfit for intensive chemotherapy", min: 20, max: 100, step: 1,
       fmt: v => v + "%", prm: P.epidemiology.pctUnfitIntensive }
    ].forEach(d => {
      const row = el("div", { class: "bim-control" });
      const lab = el("label", {});
      const val = el("span", { class: "bim-control-value", text: d.fmt(S[d.key]) });
      lab.appendChild(el("span", { text: d.label })); lab.appendChild(val);
      const input = el("input", { type: "range", min: d.min, max: d.max, step: d.step, value: S[d.key] });
      input.addEventListener("input", () => { S[d.key] = parseFloat(input.value); update(); });
      row.appendChild(lab); row.appendChild(input); row.appendChild(chip(d.prm));
      controls.appendChild(row);
      funnelInputs.push({ key: d.key, input, val, fmt: d.fmt });
    });
    w.appendChild(controls);

    const steps = el("div", { class: "bim-funnel" });
    w.appendChild(steps);
    const note = el("p", { class: "bim-callout" });
    w.appendChild(note);

    return { node: w, update(res) {
      funnelInputs.forEach(f => { f.val.textContent = f.fmt(S[f.key]); f.input.value = S[f.key]; });
      clear(steps);
      res.funnel.steps.forEach(s => {
        const row = el("div", { class: "bim-fun-row bim-fun-" + s.kind });

        /* the operator that produced this step */
        row.appendChild(el("div", { class: "bim-fun-op", text: s.op || "" }));

        /* the gauge. A share is drawn as a proportion of 100%; a rate is drawn
           against its own labelled range, because it is not a proportion of
           anything and must not be read as one. */
        const gauge = el("div", { class: "bim-fun-gauge" });
        if (s.kind === "share" || s.kind === "rate") {
          const pos = s.kind === "share"
            ? s.frac * 100
            : (s.frac - s.min) / (s.max - s.min) * 100;
          const track = el("div", { class: "bim-fun-track" });
          track.appendChild(el("div", { class: "bim-fun-fill",
            style: "width:" + Math.max(0, Math.min(100, pos)) + "%" }));
          gauge.appendChild(track);
          gauge.appendChild(el("div", { class: "bim-fun-scale", html:
            s.kind === "share"
              ? "<span>0%</span><span>100%</span>"
              : "<span>" + s.min + "</span><span>per 100,000</span><span>" + s.max + "</span>" }));
        }
        row.appendChild(gauge);

        row.appendChild(el("div", { class: "bim-fun-label" }, [
          el("span", { class: "bim-fun-name", text: s.label }),
          el("span", { class: "bim-fun-note", text: s.note })
        ]));
        row.appendChild(el("div", { class: "bim-fun-value",
          text: s.value >= 1000 ? fmt0(s.value) : s.value.toFixed(1) }));
        steps.appendChild(row);
      });
      note.innerHTML = "Target population <strong>" + res.targetPopulation.toFixed(1) +
        "</strong> patients in year 1; the publication rounds this to 129. Note what the base case " +
        "implies: the 65+ incidence rate is applied to the entire covered population, so default " +
        "membership is 100% aged 65 or over. Table 5's age-structure scenarios scale linearly from " +
        "here, which is how that reading was confirmed. The population is held constant across " +
        "all three years, exactly as in the source — no growth, no ageing trajectory, and no " +
        "carry-over of patients between budget years.";
    } };
  }

  /* ---- panel 2: market share -------------------------------------------- */
  const shareInputs = { without: {}, y1: {}, y2: {}, y3: {} };
  const shareVals   = { without: {}, y1: {}, y2: {}, y3: {} };
  const shareSums   = {};
  function buildShare() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "3 · Market share — the two worlds" }));
    w.appendChild(el("p", { class: "bim-panel-note", html:
      "A budget impact model is the world <em>with</em> the new therapy minus the world <em>without</em> it. " +
      "Without this layer there is only one world and no budget impact at all. Drag any share: the rest of " +
      "that column renormalises so it always sums to 100%." }));

    const grid = el("div", { class: "bim-share-grid" });
    const col0 = el("div", { class: "bim-share-col" });
    col0.appendChild(el("h4", { class: "bim-share-head", text: "Without venetoclax" }));
    col0.appendChild(el("p", { class: "bim-share-sub", text: "held constant across the 3-year horizon" }));
    NON_VEN.forEach(r => col0.appendChild(shareRow("without", r, v => {
      const next = E.renormalise(Object.assign({}, S.sharesWithout, { [r]: v }), r, NON_VEN);
      RID.forEach(x => S.sharesWithout[x] = IS_VEN[x] ? 0 : next[x]);
      update();
    })));
    shareSums.without = el("div", { class: "bim-share-sum" });
    col0.appendChild(shareSums.without);
    grid.appendChild(col0);

    YEARS.forEach((y, i) => {
      const col = el("div", { class: "bim-share-col" });
      col.appendChild(el("h4", { class: "bim-share-head", text: "With venetoclax — year " + (i + 1) }));
      col.appendChild(el("p", { class: "bim-share-sub", text: "manufacturer projection, Delphi-validated" }));
      RID.forEach(r => col.appendChild(shareRow(y, r, v => {
        S.sharesWith[y] = E.renormalise(Object.assign({}, S.sharesWith[y], { [r]: v }), r, RID);
        update();
      })));
      shareSums[y] = el("div", { class: "bim-share-sum" });
      col.appendChild(shareSums[y]);
      grid.appendChild(col);
    });
    w.appendChild(grid);


    const chart = el("div", { class: "bim-chart" });
    chart.appendChild(el("h4", { class: "bim-chart-title", text: "Patients treated, by regimen" }));
    chart.appendChild(el("p", { class: "bim-chart-sub", text:
      "The same target population in every column. Venetoclax regimens displace comparators, and that displacement is the budget impact." }));
    const holder = el("div", {});
    chart.appendChild(holder);
    chart.appendChild(legend(RID.map(r => [COLOR[r], LABEL[r]])));
    w.appendChild(chart);

    return { node: w, update(res) {
      const cols = [{ k: "without", shares: S.sharesWithout, n: res.years[0].targetPopulation }]
        .concat(YEARS.map((y, i) => ({ k: y, shares: S.sharesWith[y],
                                       n: res.years[i].targetPopulation })));
      cols.forEach(c => {
        Object.keys(shareInputs[c.k]).forEach(r => {
          const v = c.shares[r] || 0;
          if (document.activeElement !== shareInputs[c.k][r]) shareInputs[c.k][r].value = v;
          shareVals[c.k][r].textContent = pct1(v);
        });
        const t = RID.reduce((s, r) => s + (c.shares[r] || 0), 0);
        shareSums[c.k].textContent = "Total " + t.toFixed(1) + "%";
        shareSums[c.k].className = "bim-share-sum " + (Math.abs(t - 100) < 0.05 ? "ok" : "off");
      });
      clear(holder);
      holder.appendChild(patientChart(res, cols));
    } };
  }

  function shareRow(colKey, r, onChange) {
    const row = el("div", { class: "bim-share-row" });
    const lab = el("label", {});
    lab.appendChild(swatch(COLOR[r]));
    lab.appendChild(el("span", { class: "bim-share-name", text: LABEL[r] }));
    const val = el("span", { class: "bim-share-val", text: "0%" });
    lab.appendChild(val);
    const input = el("input", { type: "range", min: 0, max: 100, step: 0.1, value: 0 });
    input.addEventListener("input", () => onChange(parseFloat(input.value)));
    row.appendChild(lab); row.appendChild(input);
    shareInputs[colKey][r] = input; shareVals[colKey][r] = val;
    return row;
  }

  function legend(pairs) {
    const k = el("div", { class: "bim-legend" });
    pairs.forEach(([c, t]) => {
      const it = el("span", { class: "bim-legend-item" });
      if (c) it.appendChild(swatch(c));
      it.appendChild(el("span", { text: t }));
      k.appendChild(it);
    });
    return k;
  }

  function patientChart(res, cols) {
    const W = 720, H = 280, m = { t: 14, r: 12, b: 44, l: 46 };
    const svg = sv("svg", { viewBox: "0 0 " + W + " " + H, class: "bim-svg",
                            preserveAspectRatio: "xMidYMid meet" });
    const maxY = Math.max(1, ...cols.map(c => c.n));
    const pw = W - m.l - m.r, ph = H - m.t - m.b, bw = pw / cols.length * 0.56;
    [0, 0.25, 0.5, 0.75, 1].forEach(f => {
      const y = m.t + ph * (1 - f);
      svg.appendChild(sv("line", { x1: m.l, x2: W - m.r, y1: y, y2: y, class: "bim-grid" }));
      svg.appendChild(sv("text", { x: m.l - 8, y: y + 4, class: "bim-axis-label",
                                   "text-anchor": "end" }, fmt0(maxY * f)));
    });
    const names = ["Without", "With · Y1", "With · Y2", "With · Y3"];
    const varies = new Set(cols.map(c => Math.round(c.n * 10))).size > 1;
    cols.forEach((c, ci) => {
      const cx = m.l + pw / cols.length * (ci + 0.5);
      const N = c.n;
      const outside = [];
      let acc = 0;
      RID.forEach(r => {
        const v = N * (c.shares[r] || 0) / 100;
        if (v <= 0) return;
        const h = v / maxY * ph, y = m.t + ph - (acc / maxY * ph) - h;
        const drawn = Math.max(0, h - GAP);
        const rect = sv("rect", { x: cx - bw / 2, y: y, width: bw, height: drawn,
                                  fill: COLOR[r], rx: 1 });
        rect.appendChild(sv("title", {}, LABEL[r] + ": " + v.toFixed(1) + " patients (" + pct1(c.shares[r] || 0) + ")"));
        svg.appendChild(rect);
        /* a segment too short to hold its label gets one outside the bar, so a
           small arm is never left unlabelled — colour alone must not carry it */
        if (drawn >= 15) {
          svg.appendChild(sv("text", { x: cx, y: y + drawn / 2 + 4,
            "text-anchor": "middle", class: "bim-seg-label", fill: inkOn(COLOR[r]) },
            SHORT[r] + "  " + Math.round(v)));
        } else if (v > 0) {
          outside.push({ y: y + drawn / 2 + 3.5, text: SHORT[r] + " " + Math.round(v) });
        }
        acc += v;
      });
      /* stack the outside labels downwards so they never overlap */
      outside.sort((a, b) => a.y - b.y).forEach((o, i, arr) => {
        if (i && o.y - arr[i - 1].y < 11) o.y = arr[i - 1].y + 11;
        svg.appendChild(sv("line", { x1: cx + bw / 2 + 1, x2: cx + bw / 2 + 5,
          y1: o.y - 3.5, y2: o.y - 3.5, class: "bim-seg-leader" }));
        svg.appendChild(sv("text", { x: cx + bw / 2 + 8, y: o.y,
          class: "bim-seg-label bim-seg-out" }, o.text));
      });
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 18, class: "bim-axis-label",
                                   "text-anchor": "middle" }, names[ci]));
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 34, class: "bim-axis-sub",
        "text-anchor": "middle" }, (varies ? N.toFixed(1) : fmt0(N)) + " patients"));
    });
    return svg;
  }

  /* ---- panel 3: per-patient cost ---------------------------------------- */
  let costPick = "VEN_AZA";

  function buildCost() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "4 · Cost per patient per year" }));
    w.appendChild(el("p", { class: "bim-panel-note", html:
      "Six components, each a product of quantities and unit costs. " +
      "<strong>The payer switch acts here and only here:</strong> drug prices are ex-factory and " +
      "identical under both perspectives, so only the healthcare resource lines move." }));

    /* -- 3a. the efficacy inputs, and what each one drives ------------------ */
    w.appendChild(el("h4", { class: "bim-sub-title", text: "Where efficacy enters" }));
    w.appendChild(el("p", { class: "bim-panel-note", html:
      "Four parameters carry the clinical evidence into the cost, and they pull in opposite " +
      "directions. This is the whole mechanism of the budget impact: venetoclax is taken for " +
      "longer and causes more adverse events, but puts more patients into remission and keeps " +
      "more of them transfusion-independent, which takes days out of hospital and units out of " +
      "the blood bank." }));
    const effTbl = el("table", { class: "bim-table" });
    const eh = el("tr", {});
    ["Efficacy or safety input", "Drives", "Direction"].forEach(t => eh.appendChild(el("th", { text: t })));
    /* BSC is omitted: Table 1 has no best supportive care column, so every cell
       in it would be a dash. */
    const EFF_REGIMENS = P.regimens.filter(r => r.id !== "BSC");
    EFF_REGIMENS.forEach(r => eh.appendChild(el("th", { class: "num", text: SHORT[r.id] })));
    effTbl.appendChild(el("thead", {}, [eh]));
    const eb = el("tbody", {});
    const effRows = [
      ["Complete remission (CR/CRi)", "Hospitalisation", "higher → cheaper", "down",
       r => { const v = P.efficacy.completeRemission[r]; return v ? v.toFixed(1) + "%" : "—"; }],
      ["Mean duration of active treatment", "Drug acquisition · Administration · Hospitalisation", "longer → costlier", "up",
       r => { const v = P.treatmentCycles.active[r]; return v ? v.toFixed(2) : "—"; }],
      ["Transfusion independence", "Blood transfusions", "higher → cheaper", "down",
       r => { const v = P.efficacy.transfusionIndependence[r]; return v ? v.toFixed(1) + "%" : "—"; }],
      ["Febrile neutropenia incidence", "Adverse events", "higher → costlier", "up",
       r => { const v = P.aeIncidence.febrileNeutropenia[r]; return v ? v.toFixed(1) + "%" : "—"; }],
      ["Time to blood count recovery", "nothing", "reported but not used", "none",
       r => { const v = P.efficacy.bloodCountRecoveryCycles[r]; return v ? v.toFixed(2) : "—"; }]
    ];
    effRows.forEach(([name, drives, dir, arrow, get]) => {
      const tr = el("tr", { class: arrow === "none" ? "bim-row-unused" : "" });
      tr.appendChild(el("td", { text: name }));
      tr.appendChild(el("td", { class: "bim-drives", text: drives }));
      tr.appendChild(el("td", {}, [el("span", { class: "bim-dir bim-dir-" + arrow, text: dir })]));
      EFF_REGIMENS.forEach(r => tr.appendChild(el("td", { class: "num", text: get(r.id) })));
      eb.appendChild(tr);
    });
    effTbl.appendChild(eb);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [effTbl]));
    w.appendChild(el("div", { class: "bim-note-box", html:
      "<strong>Complete remission drives hospitalisation.</strong> The main paper never says how " +
      "hospital days are derived; the Delphi questionnaire does. It asks the panel for days per " +
      "cycle separately for patients who do and do not reach CR/CRi, on the assumption that no " +
      "remission means progression, and progression means admissions. That is the channel through " +
      "which the clinical result reaches the budget. Time to blood count recovery, reported in " +
      "Table 1, does no work under this reading." }));

    /* -- 3b. the summary table --------------------------------------------- */
    w.appendChild(el("h4", { class: "bim-sub-title", text: "Cost per patient, by component" }));
    const tbl = el("table", { class: "bim-table" });
    const h = el("tr", {});
    h.appendChild(el("th", { text: "Regimen" }));
    E.COMPONENTS.forEach(c => h.appendChild(el("th", { class: "num", text: E.COMPONENT_LABELS[c] })));
    h.appendChild(el("th", { class: "num", text: "Total" }));
    tbl.appendChild(el("thead", {}, [h]));
    const body = el("tbody", {});
    tbl.appendChild(body);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [tbl]));

    /* -- 3c. full derivation for one regimen -------------------------------- */
    w.appendChild(el("h4", { class: "bim-sub-title", text: "The arithmetic, in full" }));
    w.appendChild(el("p", { class: "bim-panel-note", html:
      "Pick a regimen. Every factor below is the value the model actually multiplied, generated " +
      "from the calculation itself rather than transcribed alongside it, and every one names where " +
      "it came from: <span class='bim-kind bim-kind-published'>published</span> in the source, " +
      "<span class='bim-kind bim-kind-expert'>expert</span> elicited from the Delphi panel, " +
      "<span class='bim-kind bim-kind-estimated'>estimated</span> because the source uses it but " +
      "never prints it, or <span class='bim-kind bim-kind-derived'>derived</span> by arithmetic on " +
      "the others." }));
    const derivBox = el("details", { class: "bim-details" });
    derivBox.appendChild(el("summary", { text: "Show the full arithmetic for each regimen" }));
    const picker = el("div", { class: "bim-picker" });
    const pickBtns = {};
    P.regimens.forEach(r => {
      const b = el("button", { type: "button", class: "bim-pick-btn", text: r.label });
      b.addEventListener("click", () => { costPick = r.id; update(); });
      pickBtns[r.id] = b; picker.appendChild(b);
    });
    derivBox.appendChild(picker);
    const deriv = el("div", { class: "bim-deriv" });
    derivBox.appendChild(deriv);
    w.appendChild(derivBox);

    return { node: w, update() {
      /* summary table */
      clear(body);
      RID.forEach(r => {
        const c = E.perPatientCost(P, r, S.perspective);
        const tr = el("tr", { class: IS_VEN[r] ? "bim-row-ven" : "" });
        const nm = el("td", {});
        nm.appendChild(swatch(COLOR[r]));
        nm.appendChild(el("span", { text: LABEL[r] }));
        tr.appendChild(nm);
        E.COMPONENTS.forEach(k => tr.appendChild(el("td", { class: "num", text: money(c[k]) })));
        tr.appendChild(el("td", { class: "num strong", text: money(c.total) }));
        body.appendChild(tr);
      });

      /* derivation */
      Object.keys(pickBtns).forEach(k =>
        pickBtns[k].className = "bim-pick-btn" + (k === costPick ? " active" : ""));
      clear(deriv);
      const d = E.costDetail(P, costPick, S.perspective);
      E.COMPONENTS.forEach(k => {
        const comp = d.components[k];
        const card = el("div", { class: "bim-deriv-card" });
        const head = el("div", { class: "bim-deriv-head" });
        head.appendChild(el("span", { class: "bim-deriv-name", text: E.COMPONENT_LABELS[k] }));
        head.appendChild(el("span", { class: "bim-deriv-total", text: money(comp.value) }));
        card.appendChild(head);

        if (!comp.parts.length) {
          const why = (k === "administration")
            ? "Best supportive care involves no drug administration."
            : (k === "hospitalisation")
            ? "Table 1 reports no remission rate for this regimen, so no admitted days are costed — a stated assumption that understates the comparator arm."
            : (k === "adverseEvents")
            ? "Table 1 has no adverse event column for this regimen, so the model costs none — a stated assumption that flatters the comparator."
            : "No cost arises under this component for this regimen.";
          card.appendChild(el("p", { class: "bim-deriv-none", text: why }));
        }

        comp.parts.forEach(part => {
          const block = el("div", { class: "bim-deriv-part" });
          const lab = el("div", { class: "bim-deriv-label" });
          lab.appendChild(el("span", { text: part.label }));
          lab.appendChild(el("span", { class: "bim-deriv-subtotal", text: money(part.product) }));
          block.appendChild(lab);
          const t = el("table", { class: "bim-deriv-table" });
          const tb = el("tbody", {});
          part.terms.forEach((term, i) => {
            const tr = el("tr", { class: term.efficacy ? "efficacy" : term.calibrated ? "calibrated" : "" });
            tr.appendChild(el("td", { class: "op", text: i ? "×" : "" }));
            tr.appendChild(el("td", { class: "fac", text: term.label }));
            tr.appendChild(el("td", { class: "val",
              text: term.unit === "$" ? money(term.value)
                  : term.unit === "share" ? (term.value * 100).toFixed(1) + "%"
                  : term.unit === "factor" ? term.value.toFixed(3)
                  : (Math.round(term.value * 100) / 100).toLocaleString("en-GB")
                    + (term.unit && term.unit !== "$" ? " " + term.unit : "") }));
            const prov = el("td", { class: "prov" });
            prov.appendChild(el("span", { class: "bim-kind bim-kind-" + term.kind, text: term.kind }));
            prov.appendChild(el("span", { class: "bim-prov-text",
              text: term.from + (term.at ? " · " + term.at : "") }));
            tr.appendChild(prov);
            tb.appendChild(tr);
          });
          t.appendChild(tb);
          block.appendChild(t);
          card.appendChild(block);
        });
        deriv.appendChild(card);
      });
    } };
  }

  /* ---- panel 4: budget impact -------------------------------------------- */
  function buildImpact() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "1 · Budget impact" }));
    const cards = el("div", { class: "bim-cards" });
    w.appendChild(cards);

    const tbl = el("table", { class: "bim-table" });
    const thead = el("thead", {});
    tbl.appendChild(thead);
    const body = el("tbody", {});
    tbl.appendChild(body);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [tbl]));
    w.appendChild(el("p", { class: "bim-panel-note", text:
      "Read the impact columns, not the totals. Venetoclax raises drug acquisition, administration and adverse event costs, and lowers hospitalisation and transfusion costs. Whether year 1 is a saving or a cost depends on how fast those offsets accrue — which is exactly the argument a payer will make." }));

    const chart = el("div", { class: "bim-chart" });
    chart.appendChild(el("h4", { class: "bim-chart-title", text: "Annual budget impact, by cost component" }));
    const holder = el("div", {});
    chart.appendChild(holder);
    chart.appendChild(legend(E.COMPONENTS.map((k, i) => [CCOLOR[i], E.COMPONENT_LABELS[k]])
                             .concat([[null, "— net impact, marked on each bar"]])));
    w.appendChild(chart);

    const fig = el("div", { class: "bim-chart" });
    fig.appendChild(el("h4", { class: "bim-chart-title",
      text: "The published headline figure, rebuilt beside it" }));
    fig.appendChild(el("p", { class: "bim-chart-sub", html:
      "Per-member-per-month budget impact by year and payer perspective — the only result figure in " +
      "the source. Published values are read from Table 4 divided by 1,000,000 members over 12 " +
      "months, which reproduces the figure's own labels exactly. Base-case settings, so this does " +
      "not move with the controls above." }));
    const figHolder = el("div", {});
    fig.appendChild(figHolder);
    fig.appendChild(legend([["#2a78d6", "This rebuild"], ["#eb6834", "Published"]]));
    w.appendChild(fig);


    return { node: w, update(res) {
      clear(cards);
      res.years.forEach(y => {
        const c = el("div", { class: "bim-card " + (y.impact.total < 0 ? "saving" : "impact") });
        c.appendChild(el("div", { class: "bim-card-label", text: "Year " + y.year }));
        c.appendChild(el("div", { class: "bim-card-value", text: moneyM(y.impact.total) }));
        c.appendChild(el("div", { class: "bim-card-note", text: pmpmFmt(y.pmpm) + " per member per month" }));
        cards.appendChild(c);
      });
      const cum = el("div", { class: "bim-card total" });
      cum.appendChild(el("div", { class: "bim-card-label", text: "3-year cumulative" }));
      cum.appendChild(el("div", { class: "bim-card-value", text: moneyM(res.cumulative) }));
      cum.appendChild(el("div", { class: "bim-card-note", text: "total exposure over the horizon" }));
      cards.appendChild(cum);

      clear(thead); clear(body);
      const h = el("tr", {});
      h.appendChild(el("th", { text: "Cost component" }));
      h.appendChild(el("th", { class: "num", text: "Without VEN" }));
      res.years.forEach(y => h.appendChild(el("th", { class: "num", text: "With VEN · Y" + y.year })));
      res.years.forEach(y => h.appendChild(el("th", { class: "num impact-col", text: "Impact · Y" + y.year })));
      thead.appendChild(h);
      E.COMPONENTS.concat("total").forEach(k => {
        const tr = el("tr", { class: k === "total" ? "bim-row-total" : "" });
        tr.appendChild(el("td", { text: k === "total" ? "Total" : E.COMPONENT_LABELS[k] }));
        tr.appendChild(el("td", { class: "num", text: money(res.without.components[k]) }));
        res.years.forEach(y => tr.appendChild(el("td", { class: "num", text: money(y.with.components[k]) })));
        res.years.forEach(y => {
          const v = y.impact[k];
          tr.appendChild(el("td", { class: "num impact-col " + (v < 0 ? "neg" : "pos"), text: money(v) }));
        });
        body.appendChild(tr);
      });

      clear(holder);
      holder.appendChild(impactChart(res));
      clear(figHolder);
      figHolder.appendChild(pmpmFigure());
    } };
  }

  function impactChart(res) {
    const W = 720, H = 300, m = { t: 16, r: 34, b: 46, l: 78 };
    const svg = sv("svg", { viewBox: "0 0 " + W + " " + H, class: "bim-svg",
                            preserveAspectRatio: "xMidYMid meet" });
    const pw = W - m.l - m.r, ph = H - m.t - m.b;
    let hi = 0, lo = 0;
    res.years.forEach(y => {
      let p = 0, n = 0;
      E.COMPONENTS.forEach(k => { const v = y.impact[k]; if (v > 0) p += v; else n += v; });
      hi = Math.max(hi, p); lo = Math.min(lo, n);
    });
    const span = (hi - lo) || 1, yOf = v => m.t + ph * (1 - (v - lo) / span);
    [0, 0.25, 0.5, 0.75, 1].forEach(f => {
      const v = lo + span * f, y = yOf(v);
      svg.appendChild(sv("line", { x1: m.l, x2: W - m.r, y1: y, y2: y, class: "bim-grid" }));
      svg.appendChild(sv("text", { x: m.l - 8, y: y + 4, class: "bim-axis-label",
                                   "text-anchor": "end" }, moneyM(v)));
    });
    svg.appendChild(sv("line", { x1: m.l, x2: W - m.r, y1: yOf(0), y2: yOf(0), class: "bim-zero" }));
    const bw = pw / res.years.length * 0.44;
    res.years.forEach((y, i) => {
      const cx = m.l + pw / res.years.length * (i + 0.5);
      let accP = 0, accN = 0;
      E.COMPONENTS.forEach((k, ki) => {
        const v = y.impact[k]; if (!v) return;
        const h = Math.abs(v) / span * ph;
        let yy;
        if (v > 0) { yy = yOf(accP + v); accP += v; } else { yy = yOf(accN); accN += v; }
        const top = yy + (v > 0 ? GAP : 0), drawn = Math.max(0, h - GAP);
        const rect = sv("rect", { x: cx - bw / 2, y: top, width: bw, height: drawn,
                                  fill: CCOLOR[ki], rx: 1 });
        rect.appendChild(sv("title", {}, E.COMPONENT_LABELS[k] + ": " + money(v)));
        svg.appendChild(rect);
        if (drawn >= 16) svg.appendChild(sv("text", { x: cx, y: top + drawn / 2 + 4,
          "text-anchor": "middle", class: "bim-seg-label", fill: inkOn(CCOLOR[ki]) },
          SHORT_C[k]));
      });
      /* The net is not the top of either stack — positives rise from zero and
         negatives fall from it — so it needs its own mark. A labelled rule
         reads as a level; an unlabelled dot sat over the segment text and told
         the reader nothing. */
      const ny = yOf(y.impact.total), half = bw * 0.62;
      svg.appendChild(sv("line", { x1: cx - half, x2: cx + half, y1: ny, y2: ny,
                                   class: "bim-net-line" }));
      svg.appendChild(sv("text", { x: cx + half + 7, y: ny + 4, class: "bim-net-label" },
                         "net " + moneyM(y.impact.total)));
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 18, class: "bim-axis-label",
                                   "text-anchor": "middle" }, "Year " + y.year));
    });
    return svg;
  }

  /* ---- panel 5: OWSA ------------------------------------------------------ */
  function buildOwsa() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "5 · One-way sensitivity analysis" }));
    w.appendChild(el("p", { class: "bim-panel-note", text:
      "Each parameter varied by ±25% against year-3 PMPM, following the published method (95% confidence interval where reported, otherwise ±25% — no intervals are reported). This is not decoration; it is the replication check." }));
    const holder = el("div", {});
    w.appendChild(holder);
    const note = el("div", { class: "bim-note-box" });
    w.appendChild(note);

    return { node: w, update() {
      const o = E.owsa(P, {
        perspective: S.perspective,
        coveredPopulation: S.coveredPopulation, incidence65plus: S.incidence65plus,
        pctUnfitIntensive: S.pctUnfitIntensive, pct65plus: S.pct65plus,
        sharesWithout: S.sharesWithout, sharesWith: S.sharesWith
      });
      clear(holder);
      holder.appendChild(tornado(o));
      const topClin = o.rows.find(r => !/drug cost/i.test(r.label));
      note.innerHTML =
        "<strong>Replication check against the published tornado.</strong> The source reports that the " +
        "duration of active venetoclax treatment dominates: at +25% year-3 PMPM exceeds $0.27 under the " +
        "social security perspective and $0.21 under the private perspective, and at −25% venetoclax " +
        "becomes cost-saving under both. This rebuild reproduces all three at base-case settings. " +
        "Ranking differs in one respect: drug cost edges ahead of duration here, and duration leads among " +
        "the non-price parameters (currently <em>" + (topClin ? topClin.label : "—") + "</em>). The " +
        "published figure is an image and does not list which parameters it varied; drug price is commonly " +
        "held fixed in a deterministic sensitivity analysis because it is a contracted, known quantity.";
    } };
  }

  function tornado(o) {
    const rows = o.rows, W = 720, rh = 30, m = { t: 26, r: 90, b: 34, l: 250 };
    const H = m.t + rows.length * rh + m.b;
    const svg = sv("svg", { viewBox: "0 0 " + W + " " + H, class: "bim-svg",
                            preserveAspectRatio: "xMidYMid meet" });
    const pw = W - m.l - m.r;
    let lo = o.basePMPM, hi = o.basePMPM;
    rows.forEach(r => { lo = Math.min(lo, r.low, r.high); hi = Math.max(hi, r.low, r.high); });
    const pad = (hi - lo) * 0.08 || 0.01; lo -= pad; hi += pad;
    const xOf = v => m.l + pw * (v - lo) / (hi - lo);
    [lo, (lo + hi) / 2, hi].forEach(v =>
      svg.appendChild(sv("text", { x: xOf(v), y: 14, class: "bim-axis-label",
                                   "text-anchor": "middle" }, pmpmFmt(v))));
    if (lo < 0 && hi > 0)
      svg.appendChild(sv("line", { x1: xOf(0), x2: xOf(0), y1: m.t - 6, y2: H - m.b + 4, class: "bim-grid" }));
    svg.appendChild(sv("line", { x1: xOf(o.basePMPM), x2: xOf(o.basePMPM), y1: m.t - 6,
                                 y2: H - m.b + 4, class: "bim-zero" }));
    rows.forEach((r, i) => {
      const y = m.t + i * rh, a = Math.min(r.low, r.high), b = Math.max(r.low, r.high);
      svg.appendChild(sv("text", { x: m.l - 12, y: y + rh / 2 + 4, class: "bim-tornado-label",
                                   "text-anchor": "end" }, r.label));
      const mid = Math.min(Math.max(o.basePMPM, a), b);
      const lowBar = sv("rect", { x: xOf(a), y: y + 5, width: Math.max(1, xOf(mid) - xOf(a)),
                                  height: rh - 12, fill: "#2a78d6" });
      lowBar.appendChild(sv("title", {}, r.label + " −25% → " + pmpmFmt(r.low)));
      const hiBar = sv("rect", { x: xOf(mid), y: y + 5, width: Math.max(1, xOf(b) - xOf(mid)),
                                 height: rh - 12, fill: "#eb6834" });
      hiBar.appendChild(sv("title", {}, r.label + " +25% → " + pmpmFmt(r.high)));
      svg.appendChild(lowBar); svg.appendChild(hiBar);
      svg.appendChild(sv("text", { x: xOf(b) + 8, y: y + rh / 2 + 4, class: "bim-axis-sub" },
        pmpmFmt(r.swing) + " swing"));
    });
    svg.appendChild(sv("text", { x: m.l + pw / 2, y: H - 8, class: "bim-axis-label",
                                 "text-anchor": "middle" }, "Year-3 budget impact per member per month"));
    return svg;
  }

  /* ---- panel 6: reconciliation ------------------------------------------- */
  function buildRecon() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "7 · Reconciliation against the publication" }));
    w.appendChild(el("p", { class: "bim-panel-note", html:
      "Where the rebuild lands against Table 4, at base-case settings and for the selected " +
      "perspective. <strong>Read the right-hand block, not the left.</strong> A budget impact model " +
      "reports the difference between the two worlds, so that is what has to reconcile — and a " +
      "component can be well out on level while its difference is close, because the same structural " +
      "error sits in both worlds and cancels in the subtraction. Administration is the clearest case " +
      "here: 44% low on level, within 5% on the difference." }));
    const tbl = el("table", { class: "bim-table" });
    const h1 = el("tr", {});
    h1.appendChild(el("th", { text: "" }));
    h1.appendChild(el("th", { class: "num", colspan: 3, text: "Level, without venetoclax" }));
    h1.appendChild(el("th", { class: "num impact-col", colspan: 3, text: "Difference between the two worlds, year 3" }));
    const h = el("tr", {});
    h.appendChild(el("th", { text: "" }));
    ["Rebuilt", "Published", "Δ"].forEach(t => h.appendChild(el("th", { class: "num", text: t })));
    ["Rebuilt", "Published", "Δ"].forEach(t => h.appendChild(el("th", { class: "num impact-col", text: t })));
    tbl.appendChild(el("thead", {}, [h1, h]));
    const body = el("tbody", {});
    tbl.appendChild(body);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [tbl]));



    return { node: w, update() {
      const base = E.budgetImpact(P, { perspective: S.perspective });
      const pub = P.published;
      clear(body);
      const pctCell = (ours, published, extraClass) => {
        const d = (ours - published) / Math.abs(published) * 100;
        return el("td", { class: "num " + (extraClass || "") + " " + (Math.abs(d) < 10 ? "pos" : "neg"),
                          text: (d >= 0 ? "+" : "") + d.toFixed(0) + "%" });
      };
      E.COMPONENTS.forEach(k => {
        const tr = el("tr", {});
        tr.appendChild(el("td", { text: E.COMPONENT_LABELS[k] }));
        const ol = base.without.components[k], pl = pub.withoutVEN[S.perspective][k];
        tr.appendChild(el("td", { class: "num", text: money(ol) }));
        tr.appendChild(el("td", { class: "num", text: money(pl) }));
        tr.appendChild(pctCell(ol, pl));
        const od = base.years[2].impact[k];
        const pd = pub.withVEN[S.perspective].y3[k] - pub.withoutVEN[S.perspective][k];
        tr.appendChild(el("td", { class: "num impact-col", text: money(od) }));
        tr.appendChild(el("td", { class: "num impact-col", text: money(pd) }));
        tr.appendChild(pctCell(od, pd, "impact-col"));
        body.appendChild(tr);
      });
      const tr = el("tr", { class: "bim-row-total" });
      tr.appendChild(el("td", { text: "Total" }));
      const ot = base.without.components.total, pt = pub.withoutVEN[S.perspective].total;
      tr.appendChild(el("td", { class: "num", text: money(ot) }));
      tr.appendChild(el("td", { class: "num", text: money(pt) }));
      tr.appendChild(pctCell(ot, pt));
      const oi = base.years[2].impact.total, pi = pub.budgetImpactTotal[S.perspective].y3;
      tr.appendChild(el("td", { class: "num impact-col", text: money(oi) }));
      tr.appendChild(el("td", { class: "num impact-col", text: money(pi) }));
      tr.appendChild(pctCell(oi, pi, "impact-col"));
      body.appendChild(tr);
    } };
  }

  /* Replication of the source's only result figure: PMPM by year, both
     perspectives, our value beside the published one on the same axis. */
  function pmpmFigure() {
    const groups = [{ key: "socsec", label: "Social security" },
                    { key: "private", label: "Private sector" }];
    const rows = [];
    groups.forEach(g => {
      const r = E.budgetImpact(P, { perspective: g.key });
      r.years.forEach((y, i) => rows.push({
        group: g.label, year: y.year,
        ours: y.pmpm,
        pub: P.published.budgetImpactTotal[g.key][y.key] / P.epidemiology.coveredPopulation.value / 12
      }));
    });
    const W = 720, H = 300, m = { t: 26, r: 14, b: 54, l: 62 };
    const svg = sv("svg", { viewBox: "0 0 " + W + " " + H, class: "bim-svg",
                            preserveAspectRatio: "xMidYMid meet" });
    const pw = W - m.l - m.r, ph = H - m.t - m.b;
    let lo = 0, hi = 0;
    rows.forEach(r => { lo = Math.min(lo, r.ours, r.pub); hi = Math.max(hi, r.ours, r.pub); });
    lo -= 0.02; hi += 0.03;
    const yOf = v => m.t + ph * (1 - (v - lo) / (hi - lo));

    [lo, (lo + hi) / 2, hi].concat([0]).forEach(v => {
      const y = yOf(v);
      svg.appendChild(sv("line", { x1: m.l, x2: W - m.r, y1: y, y2: y,
                                   class: v === 0 ? "bim-zero" : "bim-grid" }));
      svg.appendChild(sv("text", { x: m.l - 8, y: y + 4, class: "bim-axis-label",
                                   "text-anchor": "end" }, pmpmFmt(v)));
    });

    const slot = pw / rows.length, bw = slot * 0.3;
    rows.forEach((r, i) => {
      const cx = m.l + slot * (i + 0.5);
      [[r.ours, "#2a78d6", -1], [r.pub, "#eb6834", 1]].forEach(([v, col, side]) => {
        const x = cx + side * 2 - (side < 0 ? bw : 0);
        const y0 = yOf(0), y1 = yOf(v);
        const rect = sv("rect", { x: x, y: Math.min(y0, y1), width: bw,
                                  height: Math.max(1.5, Math.abs(y1 - y0)), fill: col, rx: 1 });
        rect.appendChild(sv("title", {}, (side < 0 ? "Rebuilt: " : "Published: ") + pmpmFmt(v)));
        svg.appendChild(rect);
        svg.appendChild(sv("text", { x: x + bw / 2, y: v >= 0 ? y1 - 5 : y1 + 12,
          class: "bim-pmpm-val", "text-anchor": "middle" }, pmpmFmt(v)));
      });
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 18, class: "bim-axis-label",
                                   "text-anchor": "middle" }, "Year " + r.year));
      if (i === 1 || i === 4) svg.appendChild(sv("text", { x: cx, y: H - m.b + 36,
        class: "bim-pmpm-group", "text-anchor": "middle" }, r.group));
    });
    svg.appendChild(sv("line", { x1: m.l + slot * 3, x2: m.l + slot * 3,
                                 y1: m.t - 8, y2: H - m.b + 40, class: "bim-grid" }));
    return svg;
  }

  /* ---- panel 7: provenance (static) --------------------------------------- */
  function buildProvenance() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "6 · Where every input comes from" }));
    w.appendChild(el("p", { class: "bim-panel-note", html:
      "The question a reviewer actually asks is not which table a number sits in — it is <em>which trial, " +
      "which expert process, which price list</em>. Each input below names its upstream source first; the " +
      "table number follows only as a locator for checking this replication against the paper. " +
      "Two assumptions remain, both listed as such; dosing schedules that the source reports " +
      "inconsistently are settled against the regulatory labels rather than guessed." }));

    const rows = [
      ["Covered population", "1,000,000 (hypothetical payer)", "studyDesign", "Table 4"],
      ["Members aged 65 or over", "100% in the base case", "rebuild", "Table 5"],
      ["AML incidence, aged 65+", "20.1 per 100,000", "seer", "Table 1"],
      ["Unfit for intensive chemotherapy", "64%", ["dombret2015", "melaOsorio2019"], "Table 1"],
      ["Age-structure scenarios", "5% to 78% aged 65+", "indec", "Table 5"],
      ["Market share, both worlds", "VEN+AZA 0 → 20.6 → 35.0 → 38.4%", ["manufacturer", "delphi"], "S1 Table"],
      ["Drug prices", "ex-factory, Sept 2020", "alfabeta", "Table 2 / S2 Table"],
      ["Best supportive care cost", "$698 per cycle", "microcosting", "S2 Table footnote"],
      ["Active treatment duration", "3.76 to 10.98 cycles", ["dombret2015", "kantarjian2012", "dinardo2020", "pollyea2018", "wei2019", "wei2020"], "Table 1"],
      ["Post-active duration", "13.04 − active cycles", "rebuild", "S2 Table"],
      ["Complete remission", "10.7% to 74.2%", ["dinardo2020", "wei2020"], "Table 1"],
      ["Time to blood count recovery", "2.04 to 6.74 cycles", ["dombret2015", "kantarjian2012"], "Table 1"],
      ["Transfusion independence", "16.7% to 59.8%", ["dinardo2020", "wei2019"], "Table 1"],
      ["Adverse event incidence", "six events, by regimen", "litReview", "Table 1"],
      ["Healthcare resource unit costs", "priced for both sectors", "iecsCosts", "Table 3"],
      ["Neutropenia unit cost", "$0 — inside hospitalisation", "iecsCosts", "Table 3"],
      ["Monitoring resource use", "per cycle and per year", "delphi", "S3 Table"],
      ["Transfusion rate of use", "3 red cell + 5 platelet units per cycle", "delphi", "S4 Table"],
      ["Exchange rate", "1 USD = 76.18 ARS, Sept 2020", "bcra", "Methods"],
      ["Sensitivity range", "±25%", "dsaMethod", "Methods"],
      ["Administration route", "AZA/LDAC subcutaneous · DEC intravenous · VEN oral", ["smpcVenclyxto", "rebuild"], "Table 4"],
      ["Dosing days per cycle", "AZA 7 · DEC 5 · LDAC 10", ["smpcVenclyxto", "smpcDacogen", "wei2020"], "SmPC / VIALE-C"],
      ["Best supportive care adverse events", "zero", "assumption", "Table 1"],
      ["Best supportive care annual drug cost", "13.04 × $698 = $9,102", "assumption", "Table 2"]
    ];
    const tbl = el("table", { class: "bim-table" });
    const h = el("tr", {});
    ["Parameter", "Value", "Upstream source", "Type", "Locator in the paper"]
      .forEach(t => h.appendChild(el("th", { text: t })));
    tbl.appendChild(el("thead", {}, [h]));
    const b = el("tbody", {});
    rows.forEach(([name, value, from, at]) => {
      const keys = [].concat(from);
      const s0 = P.sources[keys[0]];
      const tr = el("tr", { class: keys[0] === "assumption" ? "bim-row-assumption" : "" });
      tr.appendChild(el("td", { text: name }));
      tr.appendChild(el("td", { text: value }));
      tr.appendChild(el("td", {}, [chip({ from: from, src: s0 ? s0.full : "" })]));
      tr.appendChild(el("td", { class: "bim-src-type", text: s0 ? s0.type : "" }));
      tr.appendChild(el("td", { class: "bim-src-loc", text: at }));
      b.appendChild(tr);
    });
    tbl.appendChild(b);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [tbl]));

    const det = el("details", { class: "bim-details" });
    det.appendChild(el("summary", { text: "Sources in full" }));
    const list = el("div", { class: "bim-source-list" });
    const used = new Set(rows.flatMap(r => [].concat(r[2])));
    const order = ["Phase 3 trial", "Phase 1b/2 trial", "Phase 1b trial", "Observational, Argentina",
                   "Regulatory label (SmPC)",
                   "Registry / official statistics", "Census / official statistics", "Central bank",
                   "National price database", "Unit cost database", "Micro-costing",
                   "Expert elicitation", "Manufacturer projection", "Literature review",
                   "Method guidance", "Study design convention", "Derived in this rebuild", "Assumption"];
    const groups = {};
    used.forEach(k => { const s = P.sources[k]; if (!s) return;
      (groups[s.type] = groups[s.type] || []).push(s); });
    order.filter(t => groups[t]).forEach(t => {
      const g = el("div", { class: "bim-source-group" });
      g.appendChild(el("h5", { text: t }));
      groups[t].forEach(s => {
        const it = el("p", {});
        it.appendChild(el("strong", { text: s.short + (s.ref ? " " + s.ref : "") }));
        it.appendChild(el("span", { text: " — " + s.full }));
        g.appendChild(it);
      });
      list.appendChild(g);
    });
    det.appendChild(list);
    w.appendChild(det);
    return { node: w, update() {} };
  }

  /* ---- assemble ----------------------------------------------------------- */
  /* Budget impact leads. A payer-facing model answers the question first and
     shows the layers underneath it; the replication checks belong at the end. */
  const panels = [buildTopBar(), buildImpact(), buildFunnel(), buildShare(), buildCost(),
                  buildOwsa(), buildProvenance(), buildRecon()];
  const shell = el("div", { class: "bim-shell" });
  panels.forEach(p => shell.appendChild(p.node));
  app.appendChild(shell);

  function syncInputs() {
    funnelInputs.forEach(f => f.input.value = S[f.key]);
    ["without"].concat(YEARS).forEach(k => {
      const shares = k === "without" ? S.sharesWithout : S.sharesWith[k];
      Object.keys(shareInputs[k]).forEach(r => shareInputs[k][r].value = shares[r] || 0);
    });
  }
  function update() {
    const res = compute();
    panels.forEach(p => p.update(res));
  }
  syncInputs();
  update();
})();
