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
  const COLOR = { AZA: "#4a7fb5", DE: "#6b9bc9", LDC: "#93b7dc", BSC: "#c3d4e6",
                  VEN_AZA: "#b7791f", VEN_DE: "#cf9a3f", VEN_LDC: "#e0bc80" };
  const CCOLOR = ["#2f6fbd", "#4a7fb5", "#6b9bc9", "#2f8f6b", "#93b7dc", "#57a487"];
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
  function src(text) {
    const kind = /^Assumption/.test(text) ? "assumption"
               : /^Derived|^Calibrated/.test(text) ? "derived" : "published";
    return el("span", { class: "bim-src bim-src-" + kind, title: text,
                        text: text.split("—")[0].trim() });
  }
  function swatch(c) { return el("span", { class: "bim-swatch", style: "background:" + c }); }
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
    left.appendChild(src("Table 3 — IECS unit cost database, priced separately for each perspective"));
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
    w.appendChild(el("h3", { class: "bim-panel-title", text: "1 · Epidemiology funnel" }));
    w.appendChild(el("p", { class: "bim-panel-note", text:
      "From covered lives to patients eligible for treatment. Every step is an assumption a payer can challenge, so every step is exposed." }));

    const controls = el("div", { class: "bim-controls" });
    [{ key: "coveredPopulation", label: "Covered population", min: 100000, max: 5000000, step: 50000,
       fmt: fmt0, src: P.epidemiology.coveredPopulation.src },
     { key: "pct65plus", label: "Members aged 65 or over", min: 5, max: 100, step: 1,
       fmt: v => v + "%", src: P.epidemiology.pct65plus.src },
     { key: "incidence65plus", label: "AML incidence, aged 65+", min: 5, max: 40, step: 0.1,
       fmt: v => v.toFixed(1) + " / 100,000", src: P.epidemiology.incidence65plus.src },
     { key: "pctUnfitIntensive", label: "Unfit for intensive chemotherapy", min: 20, max: 100, step: 1,
       fmt: v => v + "%", src: P.epidemiology.pctUnfitIntensive.src }
    ].forEach(d => {
      const row = el("div", { class: "bim-control" });
      const lab = el("label", {});
      const val = el("span", { class: "bim-control-value", text: d.fmt(S[d.key]) });
      lab.appendChild(el("span", { text: d.label })); lab.appendChild(val);
      const input = el("input", { type: "range", min: d.min, max: d.max, step: d.step, value: S[d.key] });
      input.addEventListener("input", () => { S[d.key] = parseFloat(input.value); update(); });
      row.appendChild(lab); row.appendChild(input); row.appendChild(src(d.src));
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
      const top = res.funnel.steps[0].value;
      res.funnel.steps.forEach(s => {
        const bar = el("div", { class: "bim-funnel-step" });
        bar.appendChild(el("div", { class: "bim-funnel-fill",
          style: "width:" + Math.max(6, (s.value / top) * 100) + "%" }));
        bar.appendChild(el("div", { class: "bim-funnel-text", html:
          "<strong>" + fmt0(s.value) + "</strong><span>" + s.label + "</span><em>" + s.note + "</em>" }));
        steps.appendChild(bar);
      });
      note.innerHTML = "Target population <strong>" + res.targetPopulation.toFixed(1) +
        "</strong> patients per year; the publication rounds this to 129. Note what the base case " +
        "implies: the 65+ incidence rate is applied to the entire covered population, so default " +
        "membership is 100% aged 65 or over. Table 5's age-structure scenarios scale linearly from " +
        "here, which is how that reading was confirmed.";
    } };
  }

  /* ---- panel 2: market share -------------------------------------------- */
  const shareInputs = { without: {}, y1: {}, y2: {}, y3: {} };
  const shareVals   = { without: {}, y1: {}, y2: {}, y3: {} };
  const shareSums   = {};
  function buildShare() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "2 · Market share — the two worlds" }));
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

    w.appendChild(el("div", { class: "bim-note-box", html:
      "<strong>A contradiction in the published supplement, and how it was settled.</strong> " +
      "S1 Table gives venetoclax + decitabine 14.5% and venetoclax + LDAC 9.6%. S7 Table gives those same " +
      "two regimens 12 and 19 patients — the opposite assignment. Reconciling each against the drug costs " +
      "in Table 4 settles it: S7's assignment reproduces published drug spend to within 0.35–1.3%, S1's is " +
      "out by 3.7–5.2%. The two rows of S1 Table appear to be transposed, and this model follows S7." }));

    const chart = el("div", { class: "bim-chart" });
    chart.appendChild(el("h4", { class: "bim-chart-title", text: "Patients treated, by regimen" }));
    chart.appendChild(el("p", { class: "bim-chart-sub", text:
      "The same target population in every column. Venetoclax regimens displace comparators, and that displacement is the budget impact." }));
    const holder = el("div", {});
    chart.appendChild(holder);
    chart.appendChild(legend(RID.map(r => [COLOR[r], LABEL[r]])));
    w.appendChild(chart);

    return { node: w, update(res) {
      const cols = [{ k: "without", shares: S.sharesWithout }]
        .concat(YEARS.map(y => ({ k: y, shares: S.sharesWith[y] })));
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
    const W = 720, H = 260, m = { t: 14, r: 12, b: 44, l: 46 };
    const svg = sv("svg", { viewBox: "0 0 " + W + " " + H, class: "bim-svg",
                            preserveAspectRatio: "xMidYMid meet" });
    const N = res.targetPopulation, maxY = Math.max(1, N);
    const pw = W - m.l - m.r, ph = H - m.t - m.b, bw = pw / cols.length * 0.56;
    [0, 0.25, 0.5, 0.75, 1].forEach(f => {
      const y = m.t + ph * (1 - f);
      svg.appendChild(sv("line", { x1: m.l, x2: W - m.r, y1: y, y2: y, class: "bim-grid" }));
      svg.appendChild(sv("text", { x: m.l - 8, y: y + 4, class: "bim-axis-label",
                                   "text-anchor": "end" }, fmt0(maxY * f)));
    });
    const names = ["Without", "With · Y1", "With · Y2", "With · Y3"];
    cols.forEach((c, ci) => {
      const cx = m.l + pw / cols.length * (ci + 0.5);
      let acc = 0;
      RID.forEach(r => {
        const v = N * (c.shares[r] || 0) / 100;
        if (v <= 0) return;
        const h = v / maxY * ph, y = m.t + ph - (acc / maxY * ph) - h;
        const rect = sv("rect", { x: cx - bw / 2, y: y, width: bw, height: Math.max(0, h), fill: COLOR[r] });
        rect.appendChild(sv("title", {}, LABEL[r] + ": " + v.toFixed(1) + " patients (" + pct1(c.shares[r] || 0) + ")"));
        svg.appendChild(rect); acc += v;
      });
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 18, class: "bim-axis-label",
                                   "text-anchor": "middle" }, names[ci]));
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 34, class: "bim-axis-sub",
                                   "text-anchor": "middle" }, fmt0(N) + " patients"));
    });
    return svg;
  }

  /* ---- panel 3: per-patient cost ---------------------------------------- */
  function buildCost() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "3 · Cost per patient per year" }));
    w.appendChild(el("p", { class: "bim-panel-note", html:
      "Six components, built bottom-up from published quantities and unit costs. " +
      "<strong>The payer switch acts here and only here:</strong> drug prices are ex-factory and identical " +
      "under both perspectives, so only the healthcare resource lines move when you switch." }));

    const tbl = el("table", { class: "bim-table" });
    const h = el("tr", {});
    h.appendChild(el("th", { text: "Regimen" }));
    E.COMPONENTS.forEach(c => h.appendChild(el("th", { class: "num", text: E.COMPONENT_LABELS[c] })));
    h.appendChild(el("th", { class: "num", text: "Total" }));
    tbl.appendChild(el("thead", {}, [h]));
    const body = el("tbody", {});
    tbl.appendChild(body);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [tbl]));

    const det = el("details", { class: "bim-details" });
    det.appendChild(el("summary", { text: "How each component is built" }));
    const g = el("div", { class: "bim-build-grid" });
    [["Drug acquisition", "cost per cycle × active cycles + (13.04 − active cycles) × $698",
      "S2 Table. Deliberately not a frozen annual total: treatment duration is the leading sensitivity driver in the source, and it can only move the result if drug cost is a function of it. Rebuilds every published annual total to within 0.09%."],
     ["Administration", "active cycles × administration days per cycle × IV or SC unit cost",
      "Table 3. Venetoclax is oral and carries no administration cost."],
     ["Adverse events", "Σ (event incidence × unit cost)",
      "Table 1 × Table 3. Neutropenia is priced at $0 in Table 3 because its management already sits inside hospitalisation — charging it again would double-count."],
     ["Hospitalisation", "time to blood count recovery × 28 days × neutropenic room cost per day",
      "Table 1 × Table 3."],
     ["Monitoring", "resource use per cycle × 13.04 cycles × unit cost, plus annual marrow procedures",
      "S3 Table × Table 3. Venetoclax regimens take extra chemistry panels in cycle 1 for tumour lysis monitoring."],
     ["Blood transfusions", "(1 − transfusion independence) × 13.04 cycles × (3 red cell + 5 platelet units)",
      "Table 1 × S4 Table × Table 3."]
    ].forEach(([t, f, n]) => {
      const it = el("div", { class: "bim-build-item" });
      it.appendChild(el("h5", { text: t }));
      it.appendChild(el("code", { text: f }));
      it.appendChild(el("p", { text: n }));
      g.appendChild(it);
    });
    det.appendChild(g);
    w.appendChild(det);

    return { node: w, update() {
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
    } };
  }

  /* ---- panel 4: budget impact -------------------------------------------- */
  function buildImpact() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "4 · Budget impact" }));
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
                             .concat([[null, "● net impact"]])));
    w.appendChild(chart);

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
    } };
  }

  function impactChart(res) {
    const W = 720, H = 300, m = { t: 16, r: 12, b: 46, l: 78 };
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
        const rect = sv("rect", { x: cx - bw / 2, y: yy, width: bw, height: Math.max(0, h), fill: CCOLOR[ki] });
        rect.appendChild(sv("title", {}, E.COMPONENT_LABELS[k] + ": " + money(v)));
        svg.appendChild(rect);
      });
      svg.appendChild(sv("circle", { cx: cx, cy: yOf(y.impact.total), r: 5, class: "bim-net-dot" }));
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 18, class: "bim-axis-label",
                                   "text-anchor": "middle" }, "Year " + y.year));
      svg.appendChild(sv("text", { x: cx, y: H - m.b + 34, class: "bim-axis-sub",
                                   "text-anchor": "middle" }, "net " + moneyM(y.impact.total)));
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
                                  height: rh - 12, fill: "#2f8f6b", opacity: 0.85 });
      lowBar.appendChild(sv("title", {}, r.label + " −25% → " + pmpmFmt(r.low)));
      const hiBar = sv("rect", { x: xOf(mid), y: y + 5, width: Math.max(1, xOf(b) - xOf(mid)),
                                 height: rh - 12, fill: "#b7791f", opacity: 0.85 });
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
    w.appendChild(el("h3", { class: "bim-panel-title", text: "6 · Reconciliation against the publication" }));
    w.appendChild(el("p", { class: "bim-panel-note", text:
      "Nothing here is calibrated to make the numbers agree. This panel reports where the rebuild lands against Table 4 and where it does not, at base-case settings and for the selected perspective." }));
    const tbl = el("table", { class: "bim-table" });
    const h = el("tr", {});
    ["", "Rebuilt", "Published", "Difference"].forEach(t =>
      h.appendChild(el("th", { class: t ? "num" : "", text: t })));
    tbl.appendChild(el("thead", {}, [h]));
    const body = el("tbody", {});
    tbl.appendChild(body);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [tbl]));
    w.appendChild(el("div", { class: "bim-note-box", html:
      "<strong>What reconciles, and what does not.</strong> Drug acquisition and adverse events rebuild to " +
      "within 0.5%, because those are fully specified in the source. Administration and hospitalisation do " +
      "not, and the reason is in the publication itself: administration in later cycles is costed at a daily " +
      "hospital stay whose unit cost is never reported, and the neutropenic room day count has no published " +
      "driver. Scaling those components up to force agreement was tested and rejected. The coefficients fit " +
      "on the without-venetoclax mix, but hospitalisation and transfusions are precisely where venetoclax " +
      "generates its offsets, so correcting the levels inflates the difference and the year-3 impact " +
      "collapses by more than 40%. In a budget impact model only the difference between the two worlds is " +
      "the answer, and a level correction is not a difference correction. The rebuild is therefore left " +
      "uncalibrated and the residual is shown rather than removed." }));

    return { node: w, update() {
      const base = E.budgetImpact(P, { perspective: S.perspective });
      const pub = P.published;
      clear(body);
      const row = (label, ours, published, cls) => {
        const tr = el("tr", { class: cls || "" });
        tr.appendChild(el("td", { text: label }));
        tr.appendChild(el("td", { class: "num", text: money(ours) }));
        tr.appendChild(el("td", { class: "num", text: money(published) }));
        const d = (ours - published) / Math.abs(published) * 100;
        tr.appendChild(el("td", { class: "num " + (Math.abs(d) < 10 ? "pos" : "neg"),
                                  text: (d >= 0 ? "+" : "") + d.toFixed(1) + "%" }));
        body.appendChild(tr);
      };
      E.COMPONENTS.forEach(k => row("Without VEN · " + E.COMPONENT_LABELS[k],
        base.without.components[k], pub.withoutVEN[S.perspective][k]));
      base.years.forEach(y => row("Budget impact · year " + y.year,
        y.impact.total, pub.budgetImpactTotal[S.perspective][y.key], "bim-row-total"));
    } };
  }

  /* ---- panel 7: provenance (static) --------------------------------------- */
  function buildProvenance() {
    const w = el("section", { class: "bim-panel" });
    w.appendChild(el("h3", { class: "bim-panel-title", text: "7 · Parameter provenance" }));
    w.appendChild(el("p", { class: "bim-panel-note", text:
      "Every input carries a source tag: a table number in the publication, an arithmetic derivation from one, or an explicit assumption. There are three assumptions and they are listed as such." }));
    const rows = [
      ["Covered population", "1,000,000", "Table 4"],
      ["AML incidence, aged 65+", "20.1 per 100,000", "Table 1"],
      ["Unfit for intensive chemotherapy", "64%", "Table 1"],
      ["Members aged 65 or over", "100% in the base case", "Derived — implied by the funnel; confirmed against Table 5"],
      ["Market share, without venetoclax", "AZA 58.5 · DE 11.5 · LDC 11.4 · BSC 18.6", "S1 Table"],
      ["Market share, with venetoclax", "VEN+AZA 20.6 → 35.0 → 38.4", "S1 Table, transposition corrected against S7 Table"],
      ["Drug cost per cycle", "AZA $14,966 · VEN+AZA $16,827 · BSC $698", "S2 Table"],
      ["Active treatment duration", "3.76 to 10.98 cycles", "Table 1"],
      ["Post-active duration", "13.04 − active cycles", "Derived — matches S2 Table to 0.01 cycles"],
      ["Healthcare resource unit costs", "priced for both perspectives", "Table 3"],
      ["Monitoring resource use", "per cycle and per year", "S3 Table"],
      ["Transfusion rate", "3 red cell + 5 platelet units per cycle", "S4 Table"],
      ["Adverse event incidence", "six events, by regimen", "Table 1"],
      ["Neutropenia unit cost", "$0 under both perspectives", "Table 3 — already inside hospitalisation"],
      ["Sensitivity range", "±25%", "Methods — 95% CI where reported, otherwise ±25%"],
      ["Administration route", "AZA/LDC subcutaneous · DE intravenous · VEN oral", "Assumption — licensed routes; the source states only the costing rule"],
      ["Best supportive care adverse events", "zero", "Assumption — Table 1 has no BSC column"],
      ["Best supportive care annual drug cost", "13.04 × $698 = $9,102", "Assumption — no BSC row in Table 2; 6.1% below the figure implied by Table 4"]
    ];
    const tbl = el("table", { class: "bim-table" });
    const h = el("tr", {});
    ["Parameter", "Value", "Source"].forEach(t => h.appendChild(el("th", { text: t })));
    tbl.appendChild(el("thead", {}, [h]));
    const b = el("tbody", {});
    rows.forEach(([a, c, d]) => {
      const tr = el("tr", { class: /^Assumption/.test(d) ? "bim-row-assumption" : "" });
      tr.appendChild(el("td", { text: a }));
      tr.appendChild(el("td", { text: c }));
      tr.appendChild(el("td", {}, [src(d)]));
      b.appendChild(tr);
    });
    tbl.appendChild(b);
    w.appendChild(el("div", { class: "bim-table-wrap" }, [tbl]));
    return { node: w, update() {} };
  }

  /* ---- assemble ----------------------------------------------------------- */
  const panels = [buildTopBar(), buildFunnel(), buildShare(), buildCost(),
                  buildImpact(), buildOwsa(), buildRecon(), buildProvenance()];
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
