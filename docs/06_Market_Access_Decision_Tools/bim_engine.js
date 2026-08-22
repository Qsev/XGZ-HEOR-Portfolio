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
    const p65   = o.pct65plus         ?? P.epidemiology.pct65plus.value;

    const aged65 = pop * (p65 / 100);
    const incident = aged65 * (inc / 100000);
    const target = incident * (unfit / 100);

    return {
      coveredPopulation: pop,
      aged65plus: aged65,
      incidentCases: incident,
      targetPopulation: target,
      steps: [
        { label: "Covered population",             value: pop,      note: "third-party payer membership" },
        { label: "Aged 65 years or over",          value: aged65,   note: p65 + "% of members" },
        { label: "Incident AML cases",             value: incident, note: inc + " per 100,000" },
        { label: "Unfit for intensive chemotherapy", value: target, note: unfit + "% of incident cases" }
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

  /* -- 3. Cost per patient per year, by component --------------------------- */
  function perPatientCost(P, regimen, perspective) {
    const U  = P.unitCosts;
    const CY = P.meta.cyclesPerYear.value;
    const active = P.treatmentCycles.active[regimen] || 0;
    const postActive = Math.max(0, CY - active);

    /* drug: active period at the regimen rate, post-active period at BSC rate */
    const perCycle = P.drugCostPerCycle[regimen].value;
    const bscRate  = P.drugCostPerCycle.BSC.value;
    const drug = (regimen === "BSC")
      ? bscRate * CY
      : perCycle * active + postActive * bscRate;

    /* monitoring: per-cycle resources run the full year; BSC is per-year only */
    const M = P.monitoringRates;
    let monitoring;
    if (regimen === "BSC") {
      monitoring = M.bloodCount.perYear.BSC    * U.bloodCount[perspective]
                 + M.chemicalPanel.perYear.BSC * U.chemicalPanel[perspective]
                 + M.bmAspiration.perYear.BSC  * U.bmAspiration[perspective]
                 + M.bmBiopsy.perYear.BSC      * U.bmBiopsy[perspective];
    } else {
      const base  = M.chemicalPanel.perCycle[regimen];
      const first = M.chemicalPanel.firstCycleExtra[regimen] ?? base;
      monitoring = M.bloodCount.perCycle[regimen] * CY * U.bloodCount[perspective]
                 + (base * CY + (first - base))   * U.chemicalPanel[perspective]
                 + M.bmAspiration.perYear[regimen] * U.bmAspiration[perspective]
                 + M.bmBiopsy.perYear[regimen]     * U.bmBiopsy[perspective];
    }

    /* adverse events: incidence x unit cost. Neutropenia is priced at zero in
       Table 3 because its management already sits inside hospitalisation.     */
    let adverseEvents = 0;
    Object.keys(P.aeIncidence).forEach(k => {
      /* iterate only keys that name an actual event, i.e. ones with a matching
         unit cost. Provenance keys (src, from, at) sit alongside the data and
         must not be walked as if they were events. */
      const unit = U["ae_" + k];
      if (!unit || typeof P.aeIncidence[k][regimen] !== "number") return;
      adverseEvents += (P.aeIncidence[k][regimen] / 100) * unit[perspective];
    });

    /* hospitalisation: neutropenic room days, driven by blood count recovery  */
    const rec = P.efficacy.bloodCountRecoveryCycles[regimen];
    const hospitalisation = rec
      ? rec * P.meta.cycleDays.value * U.neutropenicRoomDay[perspective] : 0;

    /* transfusions: applied to the share NOT achieving transfusion independence */
    const dependent = 1 - (P.efficacy.transfusionIndependence[regimen] || 0) / 100;
    const perCycleTx = P.transfusionRates.rbcPerCycle.value      * U.rbcTransfusion[perspective]
                     + P.transfusionRates.plateletPerCycle.value * U.plateletApheresis[perspective];
    const transfusion = dependent * CY * perCycleTx;

    /* administration: on active treatment days only; oral VEN is not charged  */
    const daysPerCycle = { AZA: 7, DE: 5, LDC: 10, VEN_AZA: 7, VEN_DE: 5, VEN_LDC: 10, BSC: 0 };
    const route = P.administrationRoute[regimen];
    const unit  = route === "IV" ? U.ivAdministration[perspective]
                : route === "SC" ? U.scAdministration[perspective] : 0;
    const administration = active * (daysPerCycle[regimen] || 0) * unit;

    const cost = { drug, administration, adverseEvents, hospitalisation, monitoring, transfusion };
    cost.total = COMPONENTS.reduce((s, k) => s + cost[k], 0);
    return cost;
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
    const f = funnel(P, o);
    const N = f.targetPopulation;
    const rid = ids(P);

    const without = o.sharesWithout || P.marketShare.withoutVEN;
    const withV   = o.sharesWith    || P.marketShare.withVEN;

    const base = scenarioCost(P, without, N, perspective);
    const years = ["y1", "y2", "y3"].map((y, i) => {
      const proj = scenarioCost(P, withV[y], N, perspective);
      const impact = {};
      COMPONENTS.forEach(k => impact[k] = proj.components[k] - base.components[k]);
      impact.total = proj.components.total - base.components.total;
      return {
        year: i + 1, key: y,
        without: base, with: proj, impact,
        pmpm: impact.total / f.coveredPopulation / 12
      };
    });

    return { funnel: f, perspective, targetPopulation: N, without: base, years,
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
    { id: "recovery", label: "Time to blood count recovery",
      apply: (P, f) => Object.keys(P.efficacy.bloodCountRecoveryCycles).forEach(r => {
        if (typeof P.efficacy.bloodCountRecoveryCycles[r] === "number")
          P.efficacy.bloodCountRecoveryCycles[r] *= f; }) },
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
           perPatientCost, scenarioCost, budgetImpact, owsa, DRIVERS, clone };
});
