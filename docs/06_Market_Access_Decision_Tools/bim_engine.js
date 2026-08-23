/* ============================================================================
   bim_engine.js — Budget Impact Model, calculation engine
   ----------------------------------------------------------------------------
   Pure functions. No DOM, no globals written, no parameters hard-coded.
   Every function takes the parameter object as its first argument, so the
   sensitivity analysis can perturb a copy without touching the base case.

   Structure mirrors the source publication:
     funnel -> market share -> per-patient cost -> two scenarios -> difference
   ==========================================================================*/

(function (root, factory) {
  if (typeof module !== "undefined" && module.exports) module.exports = factory();
  else root.BIM_ENGINE = factory();
})(typeof self !== "undefined" ? self : this, function () {

  const COMPONENTS = ["drug", "administration", "adverseEvents",
                      "hospitalisation", "monitoring", "transfusion"];

  const COMPONENT_LABELS = {
    drug            : "Drug acquisition",
    administration  : "Administration",
    adverseEvents   : "Adverse events",
    hospitalisation : "Hospitalisation",
    monitoring      : "Monitoring",
    transfusion     : "Blood transfusions"
  };

  const clone = (o) => JSON.parse(JSON.stringify(o));
  const ids   = (P) => P.regimens.map(r => r.id);

  /* -- 1. Epidemiology funnel ---------------------------------------------- */
  function funnel(P, o) {
    o = o || {};
    const pop   = o.coveredPopulation ?? P.epidemiology.coveredPopulation.value;
    const inc   = o.incidence65plus   ?? P.epidemiology.incidence65plus.value;
    const unfit = o.pctUnfitIntensive ?? P.epidemiology.pctUnfitIntensive.value;
    const p65   = o.pct65plus ?? P.epidemiology.pct65plus.value;

    const aged65 = pop * (p65 / 100);
    const incident = aged65 * (inc / 100000);
    const target = incident * (unfit / 100);

    return {
      coveredPopulation: pop,
      pct65plus: p65,
      aged65plus: aged65,
      incidentCases: incident,
      targetPopulation: target,
      /* Each step is tagged by the KIND of quantity that produces it. Two of
         these filters are proportions and one is an incidence rate; drawing all
         three as one bar length was the original defect — a funnel spanning
         five orders of magnitude cannot be read on a single linear scale. */
      steps: [
        { kind: "start", label: "Covered population", value: pop,
          note: "third-party payer membership" },
        { kind: "share", label: "Aged 65 years or over", value: aged65,
          op: "x " + p65 + "%", frac: p65 / 100, min: 5, max: 100,
          note: "share of members" },
        { kind: "rate",  label: "Incident AML cases", value: incident,
          op: "x " + inc + " per 100,000", frac: inc, min: 5, max: 40,
          note: "annual incidence in the 65+ population" },
        { kind: "share", label: "Unfit for intensive chemotherapy", value: target,
          op: "x " + unfit + "%", frac: unfit / 100, min: 20, max: 100,
          note: "share of incident cases" }
      ]
    };
  }

  /* -- 2. Market share ------------------------------------------------------
     Renormalise so the year always sums to 100%. When one regimen is dragged,
     the remainder is redistributed in proportion to its current split.        */
  function renormalise(shares, movedKey, regimenIds) {
    const out = {};
    regimenIds.forEach(r => out[r] = Math.max(0, shares[r] || 0));
    if (!movedKey) {
      const t = regimenIds.reduce((s, r) => s + out[r], 0);
      if (t <= 0) return out;
      regimenIds.forEach(r => out[r] = out[r] / t * 100);
      return out;
    }
    const moved = Math.min(100, out[movedKey]);
    const others = regimenIds.filter(r => r !== movedKey);
    const restNow = others.reduce((s, r) => s + out[r], 0);
    const restTarget = 100 - moved;
    if (restNow <= 0) {
      // nothing left to scale: spread the remainder evenly, never divide by zero
      others.forEach(r => out[r] = restTarget / others.length);
    } else {
      others.forEach(r => out[r] = out[r] / restNow * restTarget);
    }
    out[movedKey] = moved;
    return out;
  }

  function patients(P, shares, targetN) {
    const out = {};
    ids(P).forEach(r => out[r] = targetN * (shares[r] || 0) / 100);
    return out;
  }

  /* -- 3. Cost per patient per year, by component --------------------------
     costDetail returns the arithmetic itself — every factor, labelled, with the
     efficacy inputs flagged. perPatientCost is derived from it rather than
     computed separately, so what the interface displays IS what the model
     evaluated. Two implementations would drift, and a model whose shown working
     does not match its own result is worse than one that shows nothing.

     Where efficacy enters is the point of this structure. Four parameters do
     the work, and they pull in opposite directions:
       active treatment duration   -> drug, administration        (longer = costlier)
       time to blood count recovery -> hospitalisation            (faster = cheaper)
       transfusion independence     -> transfusions               (higher = cheaper)
       adverse event incidence      -> adverse events             (higher = costlier)
     Complete remission is reported by the source but does no work anywhere in
     the model: cost responds to how long treatment runs and how much hospital
     and blood product a patient needs, not to whether remission was achieved. */
  /* Provenance kinds carried by every factor:
       published  — a value printed in the source publication
       expert     — elicited from the modified Delphi panel
       estimated  — not published anywhere; fitted to the published totals
       derived    — arithmetic on the above                                   */
  const SRC = {
    price:    { kind: "published", from: "Alfa Beta national price list, Sept 2020", at: "S2 Table" },
    trial:    { kind: "published", from: "Pivotal trial for this regimen",           at: "Table 1" },
    safety:   { kind: "published", from: "Pivotal trial safety data",                at: "Table 1" },
    iecs:     { kind: "published", from: "IECS unit cost database",                  at: "Table 3" },
    label:    { kind: "published", from: "Regulatory label / pivotal trial protocol", at: "SmPC" },
    micro:    { kind: "published", from: "Micro-costing by local clinical experts",  at: "S2 footnote" },
    delphiMon:{ kind: "expert",    from: "Modified Delphi panel, six onco-haematologists", at: "S3 Table" },
    delphiTx: { kind: "expert",    from: "Local expert, validated by the Delphi panel",    at: "S4 Table" },
    delphiHosp:{kind: "expert",    from: "Delphi questionnaire — structure and this value", at: "S5 File" },
    estHosp:  { kind: "estimated", from: "Panel's answer never published; fitted to the published hospitalisation totals", at: "S5 File" },
    estTx:    { kind: "estimated", from: "Fitted to the published transfusion totals",      at: "Methods" },
    year:     { kind: "derived",   from: "365 days / 28-day cycle",                          at: "" },
    postAct:  { kind: "derived",   from: "Cycles in the year minus active cycles",           at: "" },
    laterAct: { kind: "derived",   from: "Active cycles minus the first two",                at: "" },
    txCycles: { kind: "derived",   from: "Year minus the period of transfusion independence", at: "" }
  };
  const T = (label, value, unit, key, extra) =>
    Object.assign({ label, value, unit }, SRC[key], extra || {});

  function costDetail(P, regimen, perspective) {
    const U  = P.unitCosts;
    const CY = P.meta.cyclesPerYear.value;
    const active = P.treatmentCycles.active[regimen] || 0;
    const postActive = Math.max(0, CY - active);
    const bscRate = P.drugCostPerCycle.BSC.value;
    const c = {};

    /* drug acquisition */
    c.drug = regimen === "BSC"
      ? { parts: [{ label: "Best supportive care, whole year", terms: [
            T("BSC cost per cycle", bscRate, "$", "micro"),
            T("Cycles per year", CY, "cycles", "year")] }] }
      : { parts: [
          { label: "Active treatment", terms: [
            T("Drug cost per cycle", P.drugCostPerCycle[regimen].value, "$", "price"),
            T("Mean duration of active treatment", active, "cycles", "trial", { efficacy: true })] },
          { label: "Post-active period, on best supportive care", terms: [
            T("Remaining cycles in the year", postActive, "cycles", "postAct", { efficacy: true }),
            T("BSC cost per cycle", bscRate, "$", "micro")] }] };

    /* administration — venetoclax is oral and carries none */
    const daysPerCycle = Object.fromEntries(Object.entries(P.administrationDaysPerCycle)
      .map(([k, v]) => [k, v.value]));
    const route = P.administrationRoute[regimen];
    const admUnit = route === "IV" ? U.ivAdministration[perspective]
                  : route === "SC" ? U.scAdministration[perspective] : 0;
    c.administration = { parts: (active && daysPerCycle[regimen]) ? [
      { label: route + " administration", terms: [
        T("Mean duration of active treatment", active, "cycles", "trial", { efficacy: true }),
        T("Administration days per cycle", daysPerCycle[regimen], "days", "label"),
        T(route + " administration cost", admUnit, "$", "iecs")] }] : [] };

    /* adverse events — one line per event */
    c.adverseEvents = { parts: Object.keys(P.aeIncidence).filter(k =>
        U["ae_" + k] && typeof P.aeIncidence[k][regimen] === "number" && P.aeIncidence[k][regimen] > 0)
      .map(k => ({ label: k.replace(/([A-Z])/g, " $1").toLowerCase(), terms: [
        T("Incidence", P.aeIncidence[k][regimen] / 100, "share", "safety", { efficacy: true }),
        T("Cost per event", U["ae_" + k][perspective], "$", "iecs")] })) };

    /* hospitalisation — remission status is the switch */
    const HD = P.hospitalisationDays;
    const cr = (P.efficacy.completeRemission[regimen] || 0) / 100;
    const firstCycles = Math.min(2, active);
    const laterActive = Math.max(0, active - 2);
    const room = U.neutropenicRoomDay[perspective];
    c.hospitalisation = { parts: [] };
    if (firstCycles > 0) c.hospitalisation.parts.push(
      { label: "Cycles 1 and 2 — every patient is admitted for treatment", terms: [
        T("Cycles", firstCycles, "cycles", "delphiHosp"),
        T("Days per cycle", HD.firstTwoCycles.value, "days", "estHosp", { calibrated: true }),
        T("Neutropenic room per day", room, "$", "iecs")] });
    if (laterActive > 0) {
      c.hospitalisation.parts.push(
        { label: "Later active cycles — patients in remission", terms: [
          T("Achieving complete remission", cr, "share", "trial", { efficacy: true }),
          T("Cycles", laterActive, "cycles", "laterAct", { efficacy: true }),
          T("Days per cycle", HD.activeRemission.value, "days", "delphiHosp"),
          T("Neutropenic room per day", room, "$", "iecs")] },
        { label: "Later active cycles — patients progressing", terms: [
          T("Not achieving remission", 1 - cr, "share", "trial", { efficacy: true }),
          T("Cycles", laterActive, "cycles", "laterAct", { efficacy: true }),
          T("Days per cycle", HD.activeNoRemission.value, "days", "estHosp", { calibrated: true }),
          T("Neutropenic room per day", room, "$", "iecs")] });
    }
    if (postActive > 0) c.hospitalisation.parts.push(
      { label: "Post-active period, on best supportive care", terms: [
        T("Cycles", postActive, "cycles", "postAct", { efficacy: true }),
        T("Days per cycle", HD.postActive.value, "days", "estHosp", { calibrated: true }),
        T("Neutropenic room per day", room, "$", "iecs")] });

    /* monitoring */
    const M = P.monitoringRates;
    c.monitoring = { parts: [] };
    if (regimen === "BSC") {
      c.monitoring.parts = [
        { label: "Blood count", terms: [
          T("Per year", M.bloodCount.perYear.BSC, "tests", "delphiMon"),
          T("Unit cost", U.bloodCount[perspective], "$", "iecs")] },
        { label: "Chemistry panel", terms: [
          T("Per year", M.chemicalPanel.perYear.BSC, "panels", "delphiMon"),
          T("Unit cost", U.chemicalPanel[perspective], "$", "iecs")] },
        { label: "Marrow aspiration", terms: [
          T("Per year", M.bmAspiration.perYear.BSC, "procedures", "delphiMon"),
          T("Unit cost", U.bmAspiration[perspective], "$", "iecs")] },
        { label: "Marrow biopsy", terms: [
          T("Per year", M.bmBiopsy.perYear.BSC, "procedures", "delphiMon"),
          T("Unit cost", U.bmBiopsy[perspective], "$", "iecs")] }];
    } else {
      const base = M.chemicalPanel.perCycle[regimen];
      const first = M.chemicalPanel.firstCycleExtra[regimen] ?? base;
      c.monitoring.parts = [
        { label: "Blood count", terms: [
          T("Per cycle", M.bloodCount.perCycle[regimen], "tests", "delphiMon"),
          T("Cycles per year", CY, "cycles", "year"),
          T("Unit cost", U.bloodCount[perspective], "$", "iecs")] },
        { label: "Chemistry panel, routine", terms: [
          T("Per cycle", base, "panels", "delphiMon"),
          T("Cycles per year", CY, "cycles", "year"),
          T("Unit cost", U.chemicalPanel[perspective], "$", "iecs")] }];
      if (first !== base) c.monitoring.parts.push(
        { label: "Chemistry panel, extra in cycle 1 for tumour lysis monitoring", terms: [
          T("Additional panels", first - base, "panels", "delphiMon"),
          T("Unit cost", U.chemicalPanel[perspective], "$", "iecs")] });
      c.monitoring.parts.push(
        { label: "Marrow aspiration", terms: [
          T("Per year", M.bmAspiration.perYear[regimen], "procedures", "delphiMon"),
          T("Unit cost", U.bmAspiration[perspective], "$", "iecs")] },
        { label: "Marrow biopsy", terms: [
          T("Per year", M.bmBiopsy.perYear[regimen], "procedures", "delphiMon"),
          T("Unit cost", U.bmBiopsy[perspective], "$", "iecs")] });
    }

    /* transfusions */
    const TR = P.transfusionRates;
    const indep = (P.efficacy.transfusionIndependence[regimen] || 0) / 100;
    const cyclesNeeding = Math.max(0, CY - indep * TR.independenceCycles.value);
    c.transfusion = { parts: [
      { label: "Red cells", terms: [
        T("Cycles requiring transfusion", cyclesNeeding, "cycles", "txCycles", { efficacy: true }),
        T("Units per cycle", TR.rbcPerCycle.value, "units", "delphiTx"),
        T("Rate-of-use calibration", TR.useFactor.value, "factor", "estTx", { calibrated: true }),
        T("Unit cost", U.rbcTransfusion[perspective], "$", "iecs")] },
      { label: "Platelets by apheresis", terms: [
        T("Cycles requiring transfusion", cyclesNeeding, "cycles", "txCycles", { efficacy: true }),
        T("Units per cycle", TR.plateletPerCycle.value, "units", "delphiTx"),
        T("Rate-of-use calibration", TR.useFactor.value, "factor", "estTx", { calibrated: true }),
        T("Unit cost", U.plateletApheresis[perspective], "$", "iecs")] }] };

    let total = 0;
    COMPONENTS.forEach(k => {
      c[k].parts.forEach(p => { p.product = p.terms.reduce((a, t) => a * t.value, 1); });
      c[k].value = c[k].parts.reduce((a, p) => a + p.product, 0);
      total += c[k].value;
    });
    return { regimen, perspective, components: c, total,
             activeCycles: active, postActiveCycles: postActive };
  }

  function perPatientCost(P, regimen, perspective) {
    const d = costDetail(P, regimen, perspective);
    const out = {};
    COMPONENTS.forEach(k => out[k] = d.components[k].value);
    out.total = d.total;
    return out;
  }

  /* -- 4. Whole-scenario cost ------------------------------------------------ */
  function scenarioCost(P, shares, targetN, perspective) {
    const n = patients(P, shares, targetN);
    const out = {}; COMPONENTS.forEach(k => out[k] = 0);
    const byRegimen = {};
    ids(P).forEach(r => {
      const c = perPatientCost(P, r, perspective);
      byRegimen[r] = { patients: n[r], perPatient: c, total: n[r] * c.total };
      COMPONENTS.forEach(k => out[k] += n[r] * c[k]);
    });
    out.total = COMPONENTS.reduce((s, k) => s + out[k], 0);
    return { components: out, byRegimen, patients: n };
  }

  /* -- 5. Budget impact: the two worlds, subtracted -------------------------- */
  function budgetImpact(P, o) {
    o = o || {};
    const perspective = o.perspective || "socsec";
    const without = o.sharesWithout || P.marketShare.withoutVEN;
    const withV   = o.sharesWith    || P.marketShare.withVEN;

    /* Both worlds are evaluated on the same population, so nothing about the
       population can leak into the difference and be read as budget impact. */
    const years = ["y1", "y2", "y3"].map((y, i) => {
      const fy = funnel(P, o);
      const Ny = fy.targetPopulation;
      const base = scenarioCost(P, without, Ny, perspective);
      const proj = scenarioCost(P, withV[y], Ny, perspective);
      const impact = {};
      COMPONENTS.forEach(k => impact[k] = proj.components[k] - base.components[k]);
      impact.total = proj.components.total - base.components.total;
      return {
        year: i + 1, key: y, funnel: fy, targetPopulation: Ny,
        without: base, with: proj, impact,
        pmpm: impact.total / fy.coveredPopulation / 12
      };
    });

    const f = years[0].funnel;
    return { funnel: f, perspective, targetPopulation: years[0].targetPopulation,
             without: years[0].without, years,
             cumulative: years.reduce((s, y) => s + y.impact.total, 0) };
  }

  /* -- 6. One-way sensitivity analysis ---------------------------------------
     Range follows the publication: 95% CI where reported, otherwise +/-25%.
     No CIs are reported, so +/-25% applies throughout.
     Outcome is year-3 PMPM, matching the published tornado.                   */
  const DRIVERS = [
    { id: "duration_ven", label: "Duration of active treatment, VEN combinations",
      apply: (P, f) => ["VEN_AZA", "VEN_DE", "VEN_LDC"].forEach(r => {
        P.treatmentCycles.active[r] = Math.min(P.meta.cyclesPerYear.value,
                                               P.treatmentCycles.active[r] * f); }) },
    { id: "duration_comp", label: "Duration of active treatment, comparators",
      apply: (P, f) => ["AZA", "DE", "LDC"].forEach(r => {
        P.treatmentCycles.active[r] = Math.min(P.meta.cyclesPerYear.value,
                                               P.treatmentCycles.active[r] * f); }) },
    { id: "price_ven", label: "Venetoclax combination drug cost",
      apply: (P, f) => ["VEN_AZA", "VEN_DE", "VEN_LDC"].forEach(r => {
        P.drugCostPerCycle[r].value *= f; }) },
    { id: "price_comp", label: "Comparator drug cost",
      apply: (P, f) => ["AZA", "DE", "LDC"].forEach(r => {
        P.drugCostPerCycle[r].value *= f; }) },
    { id: "uptake", label: "Venetoclax market share, year 3",
      apply: (P, f) => {
        const rid = P.regimens.map(r => r.id);
        const s = P.marketShare.withVEN.y3;
        ["VEN_AZA", "VEN_DE", "VEN_LDC"].forEach(r => s[r] = s[r] * f);
        const t = rid.reduce((a, r) => a + (s[r] || 0), 0);
        rid.forEach(r => s[r] = (s[r] || 0) / t * 100); } },
    { id: "incidence", label: "AML incidence rate",
      apply: (P, f) => { P.epidemiology.incidence65plus.value *= f; } },
    { id: "unfit", label: "Share unfit for intensive chemotherapy",
      apply: (P, f) => { P.epidemiology.pctUnfitIntensive.value =
                         Math.min(100, P.epidemiology.pctUnfitIntensive.value * f); } },
    { id: "hosp", label: "Neutropenic room cost per day",
      apply: (P, f) => { P.unitCosts.neutropenicRoomDay.socsec  *= f;
                         P.unitCosts.neutropenicRoomDay.private *= f; } },
    { id: "remission", label: "Complete remission rate",
      apply: (P, f) => Object.keys(P.efficacy.completeRemission).forEach(r => {
        if (typeof P.efficacy.completeRemission[r] === "number")
          P.efficacy.completeRemission[r] = Math.min(100, P.efficacy.completeRemission[r] * f); }) },
    { id: "hospdays", label: "Hospital days when not in remission",
      apply: (P, f) => { P.hospitalisationDays.activeNoRemission.value *= f;
                         P.hospitalisationDays.postActive.value *= f; } },
    { id: "txindep", label: "Transfusion independence",
      apply: (P, f) => Object.keys(P.efficacy.transfusionIndependence).forEach(r => {
        if (typeof P.efficacy.transfusionIndependence[r] === "number")
          P.efficacy.transfusionIndependence[r] = Math.min(100,
            P.efficacy.transfusionIndependence[r] * f); }) }
  ];

  function owsa(P, o) {
    o = o || {};
    const pct = (o.range ?? P.sensitivity.range.value) / 100;
    const baseResult = budgetImpact(P, o);
    const basePMPM = baseResult.years[2].pmpm;

    const rows = DRIVERS.map(d => {
      const run = (f) => {
        const Q = clone(P);
        d.apply(Q, f);
        const opts = Object.assign({}, o);
        // OWSA perturbs the parameter set, so drop any UI share overrides that
        // would otherwise mask the perturbation of market share.
        if (d.id === "uptake") { delete opts.sharesWith; }
        return budgetImpact(Q, opts).years[2].pmpm;
      };
      const low = run(1 - pct), high = run(1 + pct);
      return { id: d.id, label: d.label, low, high, base: basePMPM,
               swing: Math.abs(high - low) };
    });
    rows.sort((a, b) => b.swing - a.swing);
    return { basePMPM, range: pct * 100, rows };
  }

  return { COMPONENTS, COMPONENT_LABELS, funnel, renormalise, patients,
           perPatientCost, costDetail, scenarioCost, budgetImpact, owsa, DRIVERS, clone };
});
