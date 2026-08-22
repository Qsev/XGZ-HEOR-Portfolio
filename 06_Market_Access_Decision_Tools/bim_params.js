/* ============================================================================
   bim_params.js — Budget Impact Model, parameter set
   ----------------------------------------------------------------------------
   SINGLE SOURCE OF TRUTH. No calculation logic lives in this file.

   Every value carries a `src` tag. Permitted values only:
     "Table 1".."Table 5"   main text of the source publication
     "S1 Table".."S7 Table" supplementary material
     "Derived — <formula>"  arithmetic on the above
     "Calibrated — <what>"  fitted so the base case reproduces published output
     "Assumption — <basis>" not in the publication; our own choice, stated

   SOURCE PUBLICATION (CC-BY, reuse permitted with attribution):
     Palacios A, Espinola N, Gonzalez JM, Rojas-Roque C, Rivas MM, Kanevski D,
     Morisset P, Augustovski F, Pichon-Riviere A, Bardach A.
     Budget impact analysis of venetoclax for the management of acute myeloid
     leukemia from the perspective of the social security and the private
     sector in Argentina. PLoS One. 2024;19(1):e0295798.
     doi:10.1371/journal.pone.0295798

   This is a METHODS DEMONSTRATION. It is not a client deliverable and not a
   validated reimbursement model.
   ==========================================================================*/

const BIM_PARAMS = {

  meta: {
    citation : "Palacios A, et al. PLoS One. 2024;19(1):e0295798",
    doi      : "10.1371/journal.pone.0295798",
    licence  : "CC-BY 4.0",
    currency : "USD",
    costYear : 2020,
    fxNote   : { value: 76.18, unit: "ARS per USD, September 2020", src: "Methods — direct medical costs" },
    inflation: { applied: false, src: "Methods — inflation deliberately excluded (Argentine high-inflation context)" },
    horizonYears: { value: 3, src: "Methods" },
    cycleDays   : { value: 28, src: "Methods" },
    cyclesPerYear: { value: 13.04, src: "Derived — 365 / 28; corroborated by S2 (active + post-active cycles sum to 13.04 for every regimen)" }
  },

  /* -- 1. Epidemiology funnel --------------------------------------------- */
  epidemiology: {
    coveredPopulation: { value: 1000000, src: "Table 4 — third-party payer with 1,000,000 covered lives" },
    incidence65plus  : { value: 20.1, unit: "cases per 100,000 aged 65+", src: "Table 1 (National Cancer Institute 2014)" },
    pctUnfitIntensive: { value: 64, unit: "%", src: "Table 1 (Dombret 2015; Mela-Osorio 2019)" },
    pct65plus        : { value: 100, unit: "%",
                         src: "Derived — base case applies the 65+ incidence to the whole covered population, i.e. implicitly 100% aged 65+. Confirmed: Table 5 PMPM scales linearly with this share (78% x base 0.136 = 0.106 vs published 0.105)." },
    pyramidScenarios : { value: [5, 10, 15, 20, 78], unit: "% aged 65+", src: "Table 5 / Methods — scenario analysis" },
    targetPopulation : { value: 129, unit: "patients per year",
                         src: "Derived — 1,000,000 x 20.1/100,000 x 64% = 129; matches S7 Table total" }
  },

  /* -- 2. Regimens --------------------------------------------------------- */
  regimens: [
    { id: "AZA",     label: "Azacitidine",                  ven: false },
    { id: "DE",      label: "Decitabine",                   ven: false },
    { id: "LDC",     label: "Low-dose cytarabine",          ven: false },
    { id: "BSC",     label: "Best supportive care",         ven: false },
    { id: "VEN_AZA", label: "Venetoclax + azacitidine",     ven: true  },
    { id: "VEN_DE",  label: "Venetoclax + decitabine",      ven: true  },
    { id: "VEN_LDC", label: "Venetoclax + low-dose cytarabine", ven: true }
  ],

  /* -- 3. Market share — the two worlds ------------------------------------
     ⚠ PUBLISHED INCONSISTENCY, RESOLVED.
     S1 Table assigns 14.5/14.3/14.6% to VEN+DE and 9.6% to VEN+LDC.
     S7 Table assigns 12 patients to VEN+DE and 19 to VEN+LDC — the opposite.
     Arbitrated against Table 4 drug costs: S7's assignment reproduces the
     published drug spend to within 0.35-1.3%; S1's is out by 3.7-5.2%.
     We therefore use S7's assignment (VEN+DE = 9.6%, VEN+LDC = 14.5/14.3/14.6%).
     The two VEN+DE / VEN+LDC rows of S1 Table appear to be transposed.        */
  marketShare: {
    withoutVEN: { // constant across all three years
      AZA: 58.5, DE: 11.5, LDC: 11.4, BSC: 18.6,
      VEN_AZA: 0, VEN_DE: 0, VEN_LDC: 0,
      src: "S1 Table — 'Before entry' column; held constant over the 3-year horizon"
    },
    withVEN: {
      y1: { AZA: 22.2, DE: 10.1, LDC: 8.2, BSC: 14.8, VEN_AZA: 20.6, VEN_DE: 9.6,  VEN_LDC: 14.5 },
      y2: { AZA: 14.1, DE:  7.6, LDC: 6.1, BSC: 13.3, VEN_AZA: 35.0, VEN_DE: 9.6,  VEN_LDC: 14.3 },
      y3: { AZA: 12.5, DE:  5.8, LDC: 5.8, BSC: 13.3, VEN_AZA: 38.4, VEN_DE: 9.6,  VEN_LDC: 14.6 },
      src: "S1 Table, with VEN+DE / VEN+LDC transposition corrected against S7 Table and Table 4"
    },
    provenanceNote: "Market shares are AbbVie Argentina projections, validated by a modified Delphi panel of six onco-haematologists (Methods). They are projections, not observed market data."
  },

  /* -- 4. Drug acquisition cost --------------------------------------------
     Built bottom-up, NOT taken as a frozen annual total. This matters: the
     publication's top sensitivity driver is treatment duration, which can only
     move the result if drug cost is a function of duration.

       drug cost per patient-year
         = costPerCycle x activeCycles                    (active period)
         + (cyclesPerYear - activeCycles) x bscCostPerCycle  (post-active period)

     Reproduces every S2 Table annual total to within 0.09%.                  */
  drugCostPerCycle: {
    AZA:     { value: 14966, src: "S2 Table — column F, drug cost per patient per cycle" },
    DE:      { value:  6253, src: "S2 Table — column F" },
    LDC:     { value:    56, src: "S2 Table — column F" },
    VEN_AZA: { value: 16827, src: "S2 Table — derived from column H / column G (weighted over initiation, post-initiation and subsequent cycles)" },
    VEN_DE:  { value:  8116, src: "S2 Table — derived from column H / column G" },
    VEN_LDC: { value:  2383, src: "S2 Table — derived from column H / column G" },
    BSC:     { value:   698, src: "S2 Table footnote — BSC costed at $698 per cycle by micro-costing" },
    note: "Ex-factory prices, identical under both payer perspectives. Only healthcare resource unit costs differ by perspective."
  },

  /* -- 5. Treatment duration ------------------------------------------------
     Post-active duration is DERIVED, not read off S2: every regimen's active
     plus post-active cycles sum to 13.04 (= 365/28), i.e. patients are followed
     for a full year and time off active treatment is costed at the BSC rate.
     Derived post-active durations match S2 Table to within 0.01 cycles.      */
  treatmentCycles: {
    active: { AZA: 8.80, DE: 6.90, LDC: 3.76, VEN_AZA: 10.98, VEN_DE: 10.94, VEN_LDC: 7.06, BSC: 0,
              src: "Table 1 — mean duration of active treatment, 28-day cycles" },
    postActiveRule: { src: "Derived — cyclesPerYear (13.04) minus active cycles, costed at the BSC rate of $698/cycle. Validated against S2 Table: 2.07/6.14/9.28/2.07/2.11/5.99 published vs 2.06/6.14/9.28/2.06/2.10/5.98 derived." }
  },

  /* -- 5b. Published annual drug totals — VALIDATION ONLY, not model inputs -- */
  drugCostPerPatientYear_published: {
    AZA: 134662, DE: 47430, LDC: 6682, VEN_AZA: 186207, VEN_DE: 90262, VEN_LDC: 20999,
    BSC: null,
    src: "Table 2 / S2 Table. BSC has no published row; bottom-up gives 13.04 x $698 = $9,102, which is 6.1% below the $9,694 implied by Table 4's without-VEN drug total. Residual logged in the reconciliation panel, not patched."
  },

  /* -- 6. Efficacy parameters that drive cost ------------------------------- */
  efficacy: {
    completeRemission: { AZA: 27.8, DE: 25.62, LDC: 10.7, VEN_AZA: 66.4, VEN_DE: 74.2, VEN_LDC: 48, BSC: 0,
                         unit: "%", src: "Table 1 — CR or CR with incomplete recovery. (Table 1's unit label reads 'in days'; the values are percentages — an evident typographical error in the source.)" },
    bloodCountRecoveryCycles: { AZA: 2.89, DE: 6.74, LDC: 5.80, VEN_AZA: 2.04, VEN_DE: 2.98, VEN_LDC: 2.20, BSC: null,
                         src: "Table 1 — mean time to blood count recovery, 28-day cycles. Drives neutropenic-room days." },
    transfusionIndependence: { AZA: 38.5, DE: 30.0, LDC: 16.7, VEN_AZA: 59.8, VEN_DE: 52.0, VEN_LDC: 41.0, BSC: 0,
                         unit: "%", src: "Table 1 — patients achieving platelet or RBC transfusion independence for 56 days" }
  },

  /* -- 7. Adverse event incidence ------------------------------------------- */
  aeIncidence: { // %
    neutropenia:        { AZA: 26.3, DE: 32.0, LDC: 20.0, VEN_AZA: 42.0, VEN_DE: 38.0, VEN_LDC: 46.0, BSC: 0 },
    febrileNeutropenia: { AZA: 28.0, DE: 32.0, LDC: 25.0, VEN_AZA: 42.0, VEN_DE: 65.0, VEN_LDC: 32.0, BSC: 0 },
    thrombocytopenia:   { AZA: 23.7, DE: 40.0, LDC: 35.0, VEN_AZA: 45.0, VEN_DE: 45.0, VEN_LDC: 45.0, BSC: 0 },
    anaemia:            { AZA: 15.7, DE: 34.0, LDC: 27.0, VEN_AZA: 26.0, VEN_DE: 15.0, VEN_LDC: 25.0, BSC: 0 },
    hypokalaemia:       { AZA:  5.1, DE: 11.0, LDC:  9.0, VEN_AZA: 11.0, VEN_DE: 16.0, VEN_LDC: 28.0, BSC: 0 },
    pneumonia:          { AZA: 19.1, DE: 21.0, LDC: 19.1, VEN_AZA: 20.0, VEN_DE: 32.0, VEN_LDC: 20.0, BSC: 0 },
    src: "Table 1 — safety parameters. BSC set to zero: Table 1 has no BSC column (Assumption)."
  },

  /* -- 8. Unit costs by payer perspective ----------------------------------
     THE PERSPECTIVE SWITCH ACTS HERE AND ONLY HERE. Drug prices do not move. */
  unitCosts: {
    ivAdministration:   { socsec:  183, private:  206, src: "Table 3" },
    scAdministration:   { socsec:    3, private:    3, src: "Table 3 — costed as a home nursing visit" },
    bloodCount:         { socsec:    2, private:    2, src: "Table 3 (haemogram)" },
    chemicalPanel:      { socsec:   29, private:   34, src: "Table 3" },
    bmAspiration:       { socsec:  109, private:  114, src: "Table 3" },
    bmBiopsy:           { socsec:  150, private:  164, src: "Table 3" },
    neutropenicRoomDay: { socsec:  226, private:  381, src: "Table 3 — hospitalisation in neutropenic room" },
    rbcTransfusion:     { socsec:  121, private:  140, src: "Table 3" },
    plateletApheresis:  { socsec:  278, private:  379, src: "Table 3" },
    ae_neutropenia:        { socsec:    0, private:    0, src: "Table 3 — zero by design: neutropenia management is already inside the hospitalisation cost. Counting it again would double-count." },
    ae_febrileNeutropenia: { socsec: 2529, private: 2773, src: "Table 3" },
    ae_thrombocytopenia:   { socsec:  290, private:  396, src: "Table 3" },
    ae_anaemia:            { socsec:  105, private:  133, src: "Table 3" },
    ae_hypokalaemia:       { socsec:   60, private:   60, src: "Table 3" },
    ae_pneumonia:          { socsec: 1843, private: 2035, src: "Table 3" },
    src: "Table 3 — IECS Unit Cost Database"
  },

  /* -- 9. Monitoring resource use ------------------------------------------- */
  monitoringRates: {
    bloodCount:    { perCycle: { AZA: 2.84, DE: 2.84, LDC: 2.84, VEN_AZA: 2.84, VEN_DE: 2.84, VEN_LDC: 2.84 },
                     perYear:  { BSC: 4 }, src: "S3 Table" },
    chemicalPanel: { perCycle: { AZA: 2.33, DE: 2.33, LDC: 2.33, VEN_AZA: 2.33, VEN_DE: 2.33, VEN_LDC: 2.33 },
                     firstCycleExtra: { VEN_AZA: 4, VEN_DE: 4, VEN_LDC: 5 },
                     perYear:  { BSC: 1 },
                     src: "S3 Table — VEN regimens take 4 (5 for VEN+LDC) panels in cycle 1 for tumour lysis monitoring, then 2.33" },
    bmAspiration:  { perYear: { AZA: 2, DE: 2, LDC: 2, VEN_AZA: 2, VEN_DE: 2, VEN_LDC: 2, BSC: 1 }, src: "S3 Table" },
    bmBiopsy:      { perYear: { AZA: 1, DE: 1, LDC: 1, VEN_AZA: 1, VEN_DE: 1, VEN_LDC: 1, BSC: 0.5 }, src: "S3 Table" }
  },

  /* -- 10. Transfusion resource use ------------------------------------------ */
  transfusionRates: {
    rbcPerCycle:      { value: 3, src: "S4 Table" },
    plateletPerCycle: { value: 5, src: "S4 Table" },
    note: "Applied to the share of patients NOT achieving transfusion independence (Table 1)."
  },

  /* -- 11. Administration route ---------------------------------------------- */
  administrationRoute: {
    AZA: "SC", DE: "IV", LDC: "SC", BSC: "none",
    VEN_AZA: "SC", VEN_DE: "IV", VEN_LDC: "SC",
    src: "Assumption — from the licensed routes (azacitidine and LDAC subcutaneous, decitabine intravenous, venetoclax oral). The publication states only that IV therapy is hospitalised for the first two cycles and that SC is costed as a home nursing visit."
  },

  /* -- 12. Sensitivity analysis ---------------------------------------------- */
  sensitivity: {
    range: { value: 25, unit: "%",
             src: "Methods — DSA varied parameters by their 95% CI, or by +/-25% where no CI was available. We apply +/-25% throughout, since no CIs are reported in the tables." },
    outcome: { value: "Year-3 PMPM", src: "Fig 3 — the published tornado is on year-3 PMPM budget impact" },
    publishedTopDriver: { value: "Mean duration of active treatment, VEN combinations",
             src: "Results/Discussion — at -25% VEN becomes cost-saving; at +25% year-3 PMPM exceeds $0.27 (social security) and $0.21 (private)" }
  },

  /* -- 13. Published results — VALIDATION TARGETS, not model inputs ---------- */
  published: {
    src: "Table 4 / Table 5 / Discussion",
    budgetImpactTotal: {
      socsec:  { y1:  -452078, y2: 1182455, y3: 1629818 },
      private: { y1:  -740814, y2:  720377, y3: 1120977 }
    },
    pmpm: {
      socsec:  { y1: -0.038, y3: 0.136 },
      private: { y1: -0.062, y3: 0.096 },
      note: "Discussion reports private year-1 saving as $0.059 in one sentence and $0.062 in another; Table 4 implies -0.0617."
    },
    withoutVEN: {
      socsec:  { drug: 11143997, administration: 193294, adverseEvents: 122748, hospitalisation: 5287818, monitoring: 163806, transfusion: 2685672, total: 19597335 },
      private: { drug: 11143997, administration: 231543, adverseEvents: 137453, hospitalisation: 8916164, monitoring: 187833, transfusion: 3538762, total: 24155752 }
    },
    withVEN: {
      socsec: {
        y1: { drug: 11046855, administration: 253177, adverseEvents: 158589, hospitalisation: 4853804, monitoring: 168199, transfusion: 2664634, total: 19145257 },
        y2: { drug: 12920459, administration: 266046, adverseEvents: 168570, hospitalisation: 4601535, monitoring: 169250, transfusion: 2653930, total: 20779790 },
        y3: { drug: 13432047, administration: 270833, adverseEvents: 170594, hospitalisation: 4533200, monitoring: 169347, transfusion: 2651133, total: 21227154 }
      },
      private: {
        y1: { drug: 11046855, administration: 303362, adverseEvents: 177804, hospitalisation: 8184341, monitoring: 192388, transfusion: 3510187, total: 23414938 },
        y2: { drug: 12920459, administration: 318735, adverseEvents: 189049, hospitalisation: 7758974, monitoring: 193288, transfusion: 3495625, total: 24876129 },
        y3: { drug: 13432047, administration: 324461, adverseEvents: 191324, hospitalisation: 7643749, monitoring: 193333, transfusion: 3491816, total: 25276730 }
      }
    },
    pmpmByPyramid: {
      src: "Table 5 — year 3",
      socsec:  { 5: 0.007, 10: 0.014, 15: 0.020, 20: 0.027, 78: 0.105 },
      private: { 5: 0.005, 10: 0.009, 15: 0.014, 20: 0.019, 78: 0.073 }
    }
  }
};

if (typeof module !== "undefined" && module.exports) { module.exports = BIM_PARAMS; }
if (typeof window !== "undefined") { window.BIM_PARAMS = BIM_PARAMS; }
