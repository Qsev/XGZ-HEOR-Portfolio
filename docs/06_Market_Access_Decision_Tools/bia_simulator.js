(() => {
  const app = document.getElementById("bia-app");
  if (!app) return;
  app.className = "bia-shell";
  app.innerHTML = `  <div class="bia-grid">

    <main>
      <section class="bia-results-grid" aria-label="Headline results">
        <div class="bia-card">
          <div class="bia-card-label">Eligible patients</div>
          <div class="bia-card-value" id="eligible-card"></div>
          <div class="bia-card-note">final funnel estimate</div>
        </div>
        <div class="bia-card">
          <div class="bia-card-label">Year 1 treated patients</div>
          <div class="bia-card-value" id="treated-card"></div>
          <div class="bia-card-note">eligible x Year 1 uptake</div>
        </div>
        <div class="bia-card">
          <div class="bia-card-label">Net annual price</div>
          <div class="bia-card-value" id="net-price-card"></div>
          <div class="bia-card-note">after PAS discount</div>
        </div>
        <div class="bia-card">
          <div class="bia-card-label">Year 1 net budget impact</div>
          <div class="bia-card-value" id="year1-card"></div>
          <div class="bia-card-note">incremental annual impact</div>
        </div>
        <div class="bia-card">
          <div class="bia-card-label">3-year cumulative impact</div>
          <div class="bia-card-value" id="cum3-card"></div>
          <div class="bia-card-note">NHS standard planning horizon</div>
        </div>
        <div class="bia-card">
          <div class="bia-card-label">5-year cumulative impact</div>
          <div class="bia-card-value" id="cum-card"></div>
          <div class="bia-card-note">sum across Years 1-5</div>
        </div>
      </section>

      <details class="bia-panel bia-calculation-panel" aria-label="Headline calculation notes">
        <summary class="bia-calculation-summary">
          <span>
            <span class="bia-chart-title">How the Headline Numbers Are Calculated</span>
            <span class="bia-chart-subtitle">These notes translate the headline cards back into the model arithmetic.</span>
          </span>
        </summary>
        <div class="bia-calculation-grid">
          <div class="bia-calculation-item">
            <h4>Eligible patients</h4>
            <p id="calc-eligible"></p>
          </div>
          <div class="bia-calculation-item">
            <h4>Net annual price</h4>
            <p id="calc-net-price"></p>
          </div>
          <div class="bia-calculation-item">
            <h4>Year 1 net budget impact</h4>
            <p id="calc-y1-impact"></p>
          </div>
          <div class="bia-calculation-item">
            <h4>3-year cumulative impact</h4>
            <p id="calc-cum3"></p>
          </div>
          <div class="bia-calculation-item">
            <h4>5-year cumulative impact</h4>
            <p id="calc-cumulative"></p>
          </div>
        </div>
      </details>

      <section class="bia-panel bia-scenario-panel" aria-label="Scenario presets">
        <div class="bia-scenario-header">
          <div>
            <div class="bia-scenario-title">Scenario Layer: How Market Access Assumptions Change the Story</div>
            <p class="bia-scenario-copy">Each scenario represents a plausible payer-facing discussion, not just a shortcut for moving sliders. Use the buttons to see which business assumption changes and how the budget impact moves compared with the Base Case.</p>
          </div>
        </div>
        <div class="bia-scenario-buttons" id="scenario-buttons"></div>
        <p class="bia-scenario-detail" id="scenario-detail"></p>
        <div class="bia-scenario-learning">
          <div class="bia-scenario-box">
            <h4>What this scenario is testing</h4>
            <p id="scenario-use-case"></p>
            <h4>Assumptions changed</h4>
            <ul id="scenario-assumptions"></ul>
          </div>
          <div class="bia-scenario-box">
            <h4>Compared with Base Case</h4>
            <div class="bia-delta-grid">
              <div class="bia-delta-card">
                <div class="bia-delta-label">Year 1 net budget impact</div>
                <div class="bia-delta-value" id="scenario-delta-y1"></div>
              </div>
              <div class="bia-delta-card">
                <div class="bia-delta-label">5-year cumulative impact</div>
                <div class="bia-delta-value" id="scenario-delta-cum"></div>
              </div>
            </div>
            <p class="bia-delta-note" id="scenario-delta-note"></p>
          </div>
        </div>
      </section>

      <aside class="bia-panel bia-inputs">
        <div class="bia-inputs-header">
          <span class="bia-section-title" style="margin:0;">Adjust Assumptions</span>
          <button id="reset-btn" class="bia-reset-btn" type="button">Reset to defaults</button>
        </div>
        <div class="bia-input-group-grid">
          <div>
            <div class="bia-section-title">Population Funnel</div>
            <div class="bia-control">
              <label for="incident">Annual incident population <span class="bia-value" data-display="incident"></span></label>
              <input id="incident" data-input="incident" type="range" min="1000" max="20000" step="100" value="8000">
            </div>
            <div class="bia-control">
              <label for="diagnosis">Diagnosis rate <span class="bia-value" data-display="diagnosis"></span></label>
              <input id="diagnosis" data-input="diagnosis" type="range" min="50" max="100" step="1" value="90">
            </div>
            <div class="bia-control">
              <label for="biomarker">Biomarker prevalence <span class="bia-value" data-display="biomarker"></span></label>
              <input id="biomarker" data-input="biomarker" type="range" min="5" max="80" step="1" value="30">
            </div>
            <div class="bia-control">
              <label for="line">Treatment-line eligibility <span class="bia-value" data-display="line"></span></label>
              <input id="line" data-input="line" type="range" min="10" max="90" step="1" value="45">
            </div>
            <div class="bia-control">
              <label for="suitability">Clinical suitability <span class="bia-value" data-display="suitability"></span></label>
              <input id="suitability" data-input="suitability" type="range" min="40" max="100" step="1" value="80">
            </div>
          </div>

          <div>
            <div class="bia-section-title">Annual Uptake</div>
            <div class="bia-control">
              <label for="uptake1">Year 1 uptake <span class="bia-value" data-display="uptake1"></span></label>
              <input id="uptake1" data-input="uptake1" type="range" min="0" max="100" step="1" value="10">
            </div>
            <div class="bia-control">
              <label for="uptake2">Year 2 uptake <span class="bia-value" data-display="uptake2"></span></label>
              <input id="uptake2" data-input="uptake2" type="range" min="0" max="100" step="1" value="20">
            </div>
            <div class="bia-control">
              <label for="uptake3">Year 3 uptake <span class="bia-value" data-display="uptake3"></span></label>
              <input id="uptake3" data-input="uptake3" type="range" min="0" max="100" step="1" value="30">
            </div>
            <div class="bia-control">
              <label for="uptake4">Year 4 uptake <span class="bia-value" data-display="uptake4"></span></label>
              <input id="uptake4" data-input="uptake4" type="range" min="0" max="100" step="1" value="40">
            </div>
            <div class="bia-control">
              <label for="uptake5">Year 5 uptake <span class="bia-value" data-display="uptake5"></span></label>
              <input id="uptake5" data-input="uptake5" type="range" min="0" max="100" step="1" value="45">
            </div>
          </div>

          <div>
            <div class="bia-section-title">Costs and Offsets</div>
            <div class="bia-control">
              <label for="listPrice">Annual list price <span class="bia-value" data-display="listPrice"></span></label>
              <input id="listPrice" data-input="listPrice" type="range" min="10000" max="150000" step="1000" value="75000">
            </div>
            <div class="bia-control">
              <label for="discount">PAS discount <span class="bia-value" data-display="discount"></span></label>
              <input id="discount" data-input="discount" type="range" min="0" max="60" step="1" value="20">
            </div>
            <div class="bia-control">
              <label for="duration">Mean treatment duration <span class="bia-value" data-display="duration"></span></label>
              <input id="duration" data-input="duration" type="range" min="0.1" max="1.5" step="0.05" value="0.75">
            </div>
            <div class="bia-control">
              <label for="admin">Administration cost <span class="bia-value" data-display="admin"></span></label>
              <input id="admin" data-input="admin" type="range" min="0" max="15000" step="250" value="2500">
            </div>
            <div class="bia-control">
              <label for="monitoring">Monitoring cost <span class="bia-value" data-display="monitoring"></span></label>
              <input id="monitoring" data-input="monitoring" type="range" min="0" max="10000" step="250" value="1500">
            </div>
            <div class="bia-control">
              <label for="ae">Adverse event cost <span class="bia-value" data-display="ae"></span></label>
              <input id="ae" data-input="ae" type="range" min="0" max="20000" step="250" value="2000">
            </div>
            <div class="bia-control">
              <label for="comparator">Comparator annual cost <span class="bia-value" data-display="comparator"></span></label>
              <input id="comparator" data-input="comparator" type="range" min="0" max="100000" step="1000" value="25000">
            </div>
            <div class="bia-control">
              <label for="displacement">Comparator displacement <span class="bia-value" data-display="displacement"></span></label>
              <input id="displacement" data-input="displacement" type="range" min="0" max="100" step="1" value="80">
            </div>
          </div>
        </div>
      </aside>


      <section class="bia-panel">
        <div class="bia-chart-title">Year-by-Year Results</div>
        <div class="bia-table-wrap">
          <table class="bia-table">
            <thead>
              <tr>
                <th>Year</th>
                <th>Uptake</th>
                <th>Treated patients</th>
                <th>Drug B cost</th>
                <th>Other costs</th>
                <th>Displaced comparator</th>
                <th>Net budget impact</th>
                <th>Cumulative impact</th>
              </tr>
            </thead>
            <tbody id="results-body"></tbody>
          </table>
        </div>
      </section>

      <section class="bia-chart-grid">
        <div class="bia-panel">
          <div class="bia-chart-title">Population Funnel</div>
          <div class="bia-chart-subtitle">From incident population to clinically suitable eligible patients.</div>
          <svg class="bia-svg" id="funnel-chart" viewBox="0 0 640 260" role="img" aria-label="Population funnel chart"></svg>
        </div>
        <div class="bia-panel">
          <div class="bia-chart-title">Uptake Curve</div>
          <div class="bia-chart-subtitle">Annual proportion of eligible patients expected to receive Drug B.</div>
          <svg class="bia-svg" id="uptake-chart" viewBox="0 0 640 260" role="img" aria-label="Uptake curve chart"></svg>
        </div>
        <div class="bia-panel">
          <div class="bia-chart-title">Annual Net Budget Impact</div>
          <div class="bia-chart-subtitle">Incremental budget impact after comparator displacement.</div>
          <svg class="bia-svg" id="annual-chart" viewBox="0 0 640 260" role="img" aria-label="Annual net budget impact chart"></svg>
        </div>
        <div class="bia-panel">
          <div class="bia-chart-title">Cumulative Budget Impact</div>
          <div class="bia-chart-subtitle">Running total across the 5-year model horizon.</div>
          <svg class="bia-svg" id="cumulative-chart" viewBox="0 0 640 260" role="img" aria-label="Cumulative budget impact chart"></svg>
        </div>
      </section>

      <section class="bia-panel" aria-label="One-way sensitivity analysis">
        <div class="bia-chart-title">One-Way Sensitivity: Key Budget Impact Drivers</div>
        <div class="bia-chart-subtitle">Each driver is varied one at a time while all other current assumptions are held constant. The output is the 5-year cumulative budget impact range.</div>
        <div class="bia-sensitivity-layout">
          <div>
            <svg class="bia-svg" id="tornado-chart" viewBox="0 0 700 360" role="img" aria-label="One-way sensitivity tornado chart"></svg>
            <p class="bia-sensitivity-summary" id="sensitivity-summary"></p>
          </div>
          <div class="bia-table-wrap">
            <table class="bia-table">
              <thead>
                <tr>
                  <th>Driver</th>
                  <th>Low</th>
                  <th>High</th>
                  <th>Range</th>
                </tr>
              </thead>
              <tbody id="sensitivity-body"></tbody>
            </table>
          </div>
        </div>
      </section>
    </main>
  </div>

  `;

  const ids = [
    "incident", "diagnosis", "biomarker", "line", "suitability",
    "uptake1", "uptake2", "uptake3", "uptake4", "uptake5",
    "listPrice", "discount", "duration", "admin", "monitoring",
    "ae", "comparator", "displacement"
  ];

  const percentIds = new Set([
    "diagnosis", "biomarker", "line", "suitability",
    "uptake1", "uptake2", "uptake3", "uptake4", "uptake5",
    "discount", "displacement"
  ]);
  const gbpIds = new Set(["listPrice", "admin", "monitoring", "ae", "comparator"]);

  const fmtInt = new Intl.NumberFormat("en-GB", { maximumFractionDigits: 0 });
  const fmtOne = new Intl.NumberFormat("en-GB", { maximumFractionDigits: 1 });
  const fmtDuration = new Intl.NumberFormat("en-GB", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
  const fmtCurrency = new Intl.NumberFormat("en-GB", {
    style: "currency",
    currency: "GBP",
    maximumFractionDigits: 0
  });

  const baseValues = {
    incident: 8000,
    diagnosis: 90,
    biomarker: 30,
    line: 45,
    suitability: 80,
    uptake1: 10,
    uptake2: 20,
    uptake3: 30,
    uptake4: 40,
    uptake5: 45,
    listPrice: 75000,
    discount: 20,
    duration: 0.75,
    admin: 2500,
    monitoring: 1500,
    ae: 2000,
    comparator: 25000,
    displacement: 80
  };

  const scenarios = [
    {
      id: "base",
      label: "Base Case",
      description: "The reference scenario: moderate uptake, 20% PAS discount, and 0.75-year mean treatment duration.",
      useCase: "This is the anchor scenario. In a real project, the base case is the version that stakeholders use as the main reference point before testing uncertainty or alternative access strategies.",
      values: {},
      assumptions: ["Reference assumptions for all inputs."]
    },
    {
      id: "high-uptake",
      label: "Rapid Adoption",
      description: "Tests a faster launch curve where eligible patients switch to Drug B more quickly than in the base case.",
      useCase: "This reflects a strong clinical pull or successful formulary implementation. It is commercially attractive, but it can create an early affordability challenge for the payer.",
      values: { uptake1: 20, uptake2: 35, uptake3: 50, uptake4: 60, uptake5: 65 },
      assumptions: ["Year 1 uptake increases from 10% to 20%.", "Year 5 uptake increases from 45% to 65%.", "Price, duration, and eligible population stay unchanged."]
    },
    {
      id: "low-uptake",
      label: "Phased Adoption",
      description: "Tests slower uptake, as if local systems adopt the therapy gradually or apply access management.",
      useCase: "This is relevant when a payer wants to manage near-term budget pressure through phased rollout, pathway restrictions, or slower implementation.",
      values: { uptake1: 5, uptake2: 10, uptake3: 18, uptake4: 25, uptake5: 30 },
      assumptions: ["Year 1 uptake decreases from 10% to 5%.", "Year 5 uptake decreases from 45% to 30%.", "Other assumptions stay unchanged."]
    },
    {
      id: "higher-population",
      label: "Expanded Eligible Population",
      description: "Tests what happens if the eligible population is larger than expected.",
      useCase: "This reflects a common payer challenge: whether epidemiology, biomarker prevalence, treatment-line eligibility, or clinical suitability assumptions underestimate patient volume.",
      values: { incident: 9500, biomarker: 35, line: 50, suitability: 85 },
      assumptions: ["Incident population increases from 8,000 to 9,500.", "Biomarker prevalence increases from 30% to 35%.", "Treatment-line eligibility increases from 45% to 50%.", "Clinical suitability increases from 80% to 85%."]
    },
    {
      id: "pas-discount",
      label: "Deeper PAS Discount",
      description: "Tests whether a deeper net price adjustment could reduce affordability pressure.",
      useCase: "This is the commercial access question behind a PAS scenario: how much budget pressure is reduced if the net price is lower, and whether the remaining impact is still material.",
      values: { discount: 40 },
      assumptions: ["PAS discount increases from 20% to 40%.", "Eligible population, uptake, duration, and comparator displacement stay unchanged."]
    },
    {
      id: "shorter-duration",
      label: "Shorter Treatment Duration",
      description: "Tests what happens if patients remain on treatment for a shorter average duration.",
      useCase: "Treatment duration is often a major budget driver. A shorter duration reduces Drug B acquisition costs, but it also reduces the comparator cost offset in this simplified model.",
      values: { duration: 0.5 },
      assumptions: ["Mean treatment duration decreases from 0.75 years to 0.50 years.", "All uptake, population, price, and comparator assumptions stay unchanged."]
    }
  ];

  let activeScenarioId = "base";

  const setInputValue = (id, value) => {
    const input = app.querySelector(`[data-input="${id}"]`);
    if (input) input.value = value;
  };

  const applyScenario = (scenarioId) => {
    const scenario = scenarios.find((item) => item.id === scenarioId) || scenarios[0];
    activeScenarioId = scenario.id;
    const values = { ...baseValues, ...scenario.values };
    Object.entries(values).forEach(([id, value]) => setInputValue(id, value));
    updateScenarioUI();
    update();
  };

  const updateScenarioUI = () => {
    app.querySelectorAll("[data-scenario]").forEach((button) => {
      button.classList.toggle("active", button.dataset.scenario === activeScenarioId);
    });
    const scenario = scenarios.find((item) => item.id === activeScenarioId) || scenarios[0];
    const detail = app.querySelector("#scenario-detail");
    if (detail) detail.textContent = scenario.description;
    const useCase = app.querySelector("#scenario-use-case");
    if (useCase) useCase.textContent = scenario.useCase;
    const assumptionList = app.querySelector("#scenario-assumptions");
    if (assumptionList) {
      assumptionList.innerHTML = "";
      scenario.assumptions.forEach((assumption) => {
        const item = document.createElement("li");
        item.textContent = assumption;
        assumptionList.appendChild(item);
      });
    }
  };

  const renderScenarioButtons = () => {
    const container = app.querySelector("#scenario-buttons");
    if (!container) return;
    container.innerHTML = "";
    scenarios.forEach((scenario) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "bia-scenario-button";
      button.dataset.scenario = scenario.id;
      button.textContent = scenario.label;
      button.addEventListener("click", () => applyScenario(scenario.id));
      container.appendChild(button);
    });
    updateScenarioUI();
  };

  const getInputs = () => {
    const raw = {};
    ids.forEach((id) => {
      raw[id] = Number(app.querySelector(`[data-input="${id}"]`).value);
    });

    return valuesToInputs(raw);
  };

  const calculate = (p) => {
    const diagnosed = p.incident * p.diagnosis;
    const biomarkerPositive = diagnosed * p.biomarker;
    const lineEligible = biomarkerPositive * p.line;
    const eligible = lineEligible * p.suitability;
    const netPrice = p.listPrice * (1 - p.discount);

    let cumulative = 0;
    const years = p.uptake.map((uptake, index) => {
      const treated = eligible * uptake;
      const drugCost = treated * netPrice * p.duration;
      const otherCosts = treated * (p.admin + p.monitoring + p.ae);
      const displaced = treated * p.comparator * p.displacement * p.duration;
      const netImpact = drugCost + otherCosts - displaced;
      cumulative += netImpact;

      return {
        year: index + 1,
        uptake,
        treated,
        drugCost,
        otherCosts,
        displaced,
        netImpact,
        cumulative
      };
    });

    return {
      funnel: [
        { label: "Incident population", value: p.incident },
        { label: "Diagnosed", value: diagnosed },
        { label: "Biomarker-positive", value: biomarkerPositive },
        { label: "Line eligible", value: lineEligible },
        { label: "Clinically suitable", value: eligible }
      ],
      eligible,
      netPrice,
      years
    };
  };

  const cumulativeImpact = (rawValues) => {
    const result = calculate(valuesToInputs(rawValues));
    return result.years[result.years.length - 1].cumulative;
  };

  const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

  const scaleUptake = (raw, factor) => {
    const next = { ...raw };
    ["uptake1", "uptake2", "uptake3", "uptake4", "uptake5"].forEach((id) => {
      next[id] = clamp(raw[id] * factor, 0, 100);
    });
    return next;
  };

  const sensitivityDrivers = [
    {
      label: "Eligible population",
      lowNote: "-20%",
      highNote: "+20%",
      low: (raw) => ({ ...raw, incident: raw.incident * 0.8 }),
      high: (raw) => ({ ...raw, incident: raw.incident * 1.2 }),
      interpretation: "patient volume and epidemiology assumptions"
    },
    {
      label: "Uptake curve",
      lowNote: "-20%",
      highNote: "+20%",
      low: (raw) => scaleUptake(raw, 0.8),
      high: (raw) => scaleUptake(raw, 1.2),
      interpretation: "adoption speed and pathway implementation"
    },
    {
      label: "Net price",
      lowNote: "-20%",
      highNote: "+20%",
      low: (raw) => ({ ...raw, listPrice: raw.listPrice * 0.8 }),
      high: (raw) => ({ ...raw, listPrice: raw.listPrice * 1.2 }),
      interpretation: "price, discount, and commercial access agreement"
    },
    {
      label: "Treatment duration",
      lowNote: "-20%",
      highNote: "+20%",
      low: (raw) => ({ ...raw, duration: clamp(raw.duration * 0.8, 0.1, 1.5) }),
      high: (raw) => ({ ...raw, duration: clamp(raw.duration * 1.2, 0.1, 1.5) }),
      interpretation: "how long patients remain on therapy"
    },
    {
      label: "Comparator annual cost",
      lowNote: "-20%",
      highNote: "+20%",
      low: (raw) => ({ ...raw, comparator: raw.comparator * 0.8 }),
      high: (raw) => ({ ...raw, comparator: raw.comparator * 1.2 }),
      interpretation: "size of displaced comparator cost offsets"
    },
    {
      label: "Comparator displacement",
      lowNote: "-20 pp",
      highNote: "+20 pp",
      low: (raw) => ({ ...raw, displacement: clamp(raw.displacement - 20, 0, 100) }),
      high: (raw) => ({ ...raw, displacement: clamp(raw.displacement + 20, 0, 100) }),
      interpretation: "whether Drug B actually replaces existing comparator use"
    }
  ];

  const getSensitivityRows = (raw) => {
    const base = cumulativeImpact(raw);
    return sensitivityDrivers
      .map((driver) => {
        const lowImpact = cumulativeImpact(driver.low(raw));
        const highImpact = cumulativeImpact(driver.high(raw));
        const minImpact = Math.min(lowImpact, highImpact);
        const maxImpact = Math.max(lowImpact, highImpact);
        return {
          ...driver,
          base,
          lowImpact,
          highImpact,
          minImpact,
          maxImpact,
          range: maxImpact - minImpact
        };
      })
      .sort((a, b) => b.range - a.range);
  };

  const formatDisplay = (id, value) => {
    if (percentIds.has(id)) return `${value}%`;
    if (gbpIds.has(id)) return fmtCurrency.format(value);
    if (id === "duration") return `${fmtDuration.format(value)} years`;
    return fmtInt.format(value);
  };

  const formatMillions = (value) => {
    const sign = value < 0 ? "-" : "";
    return `${sign}£${(Math.abs(value) / 1_000_000).toFixed(2)}m`;
  };

  const formatDelta = (value) => {
    if (Math.abs(value) < 1) return "No change";
    const sign = value > 0 ? "+" : "-";
    return `${sign}£${(Math.abs(value) / 1_000_000).toFixed(2)}m`;
  };

  const valuesToInputs = (raw) => ({
    raw,
    incident: raw.incident,
    diagnosis: raw.diagnosis / 100,
    biomarker: raw.biomarker / 100,
    line: raw.line / 100,
    suitability: raw.suitability / 100,
    uptake: [raw.uptake1, raw.uptake2, raw.uptake3, raw.uptake4, raw.uptake5].map((v) => v / 100),
    listPrice: raw.listPrice,
    discount: raw.discount / 100,
    duration: raw.duration,
    admin: raw.admin,
    monitoring: raw.monitoring,
    ae: raw.ae,
    comparator: raw.comparator,
    displacement: raw.displacement / 100
  });

  const clearSvg = (svg) => {
    while (svg.firstChild) svg.removeChild(svg.firstChild);
  };

  const add = (svg, tag, attrs = {}, text = "") => {
    const el = document.createElementNS("http://www.w3.org/2000/svg", tag);
    Object.entries(attrs).forEach(([key, value]) => el.setAttribute(key, value));
    if (text) el.textContent = text;
    svg.appendChild(el);
    return el;
  };

  const drawAxes = (svg, width, height, margin) => {
    add(svg, "line", {
      x1: margin.left, y1: height - margin.bottom,
      x2: width - margin.right, y2: height - margin.bottom,
      stroke: "#b9c2cf", "stroke-width": 1
    });
    add(svg, "line", {
      x1: margin.left, y1: margin.top,
      x2: margin.left, y2: height - margin.bottom,
      stroke: "#b9c2cf", "stroke-width": 1
    });
  };

  const niceTicks = (dataMax, count = 5) => {
    if (dataMax <= 0) return [0];
    const rawStep = dataMax / count;
    const mag = Math.pow(10, Math.floor(Math.log10(rawStep)));
    const niceStep = [1, 2, 2.5, 5, 10].find((f) => f * mag >= rawStep) * mag;
    const n = Math.ceil(dataMax / niceStep);
    return Array.from({ length: n + 1 }, (_, i) => i * niceStep);
  };

  const fmtAxisM = (v) => v === 0 ? "£0" : `£${(v / 1e6).toFixed(0)}m`;

  const drawYAxis = (svg, ticks, tickMax, width, height, margin, fmt) => {
    const chartH = height - margin.top - margin.bottom;
    ticks.forEach((tick) => {
      const yPos = height - margin.bottom - (tick / tickMax) * chartH;
      add(svg, "line", { x1: margin.left, y1: yPos, x2: width - margin.right, y2: yPos, stroke: "#eaeef2", "stroke-width": 1 });
      add(svg, "text", { x: margin.left - 6, y: yPos + 4, "font-size": 11, fill: "#8fa0b4", "text-anchor": "end" }, fmt(tick));
    });
  };

  const drawFunnel = (data) => {
    const svg = app.querySelector("#funnel-chart");
    clearSvg(svg);
    const svgW = 640;
    const rowH = 30;
    const step = 52;
    const topPad = 16;
    const height = topPad + (data.length - 1) * step + rowH + 16;
    svg.setAttribute("viewBox", `0 0 ${svgW} ${height}`);

    const labelRight = 196;
    const barStart = 204;
    const barMaxW = 300;
    const numX = barStart + barMaxW + 10;
    const max = data[0].value || 1;

    data.forEach((d, i) => {
      const y = topPad + i * step;
      const w = Math.max(12, (d.value / max) * barMaxW);

      if (i > 0) {
        const pct = Math.round((d.value / data[i - 1].value) * 100);
        add(svg, "text", {
          x: barStart, y: y - 5,
          "font-size": 11, fill: "#8fa0b4"
        }, `↓ ${pct}%`);
      }

      add(svg, "rect", {
        x: barStart, y, width: w, height: rowH, rx: 4,
        fill: i === data.length - 1 ? "#2f8f6b" : "#2f6fbd",
        opacity: 1 - i * 0.07
      });

      add(svg, "text", {
        x: labelRight, y: y + 20,
        "font-size": 13, fill: "#172033", "text-anchor": "end"
      }, d.label);

      add(svg, "text", {
        x: numX, y: y + 20,
        "font-size": 12, fill: "#5f6b7a"
      }, fmtInt.format(d.value));
    });
  };

  const drawUptake = (years) => {
    const svg = app.querySelector("#uptake-chart");
    clearSvg(svg);
    const width = 640;
    const height = 260;
    const margin = { top: 24, right: 28, bottom: 42, left: 54 };
    const chartH = height - margin.top - margin.bottom;
    const dataMaxPct = Math.max(1, ...years.map((d) => d.uptake * 100));
    const ticks = niceTicks(dataMaxPct);
    const tickMax = ticks[ticks.length - 1];
    drawYAxis(svg, ticks, tickMax, width, height, margin, (v) => `${v}%`);
    drawAxes(svg, width, height, margin);
    const x = (i) => margin.left + (i / 4) * (width - margin.left - margin.right);
    const y = (v) => height - margin.bottom - (v * 100 / tickMax) * chartH;
    const points = years.map((d, i) => `${x(i)},${y(d.uptake)}`).join(" ");
    add(svg, "polyline", { points, fill: "none", stroke: "#2f6fbd", "stroke-width": 4, "stroke-linejoin": "round" });
    years.forEach((d, i) => {
      add(svg, "circle", { cx: x(i), cy: y(d.uptake), r: 5, fill: "#2f6fbd" });
      add(svg, "text", { x: x(i), y: height - 14, "font-size": 12, fill: "#5f6b7a", "text-anchor": "middle" }, `Y${d.year}`);
      add(svg, "text", { x: x(i), y: y(d.uptake) - 10, "font-size": 12, fill: "#172033", "text-anchor": "middle" }, `${Math.round(d.uptake * 100)}%`);
    });
  };

  const drawBars = (years) => {
    const svg = app.querySelector("#annual-chart");
    clearSvg(svg);
    const width = 640;
    const height = 260;
    const margin = { top: 24, right: 28, bottom: 42, left: 68 };
    const chartH = height - margin.top - margin.bottom;
    const chartW = width - margin.left - margin.right;
    const dataMax = Math.max(1, ...years.map((d) => Math.abs(d.netImpact)));
    const ticks = niceTicks(dataMax);
    const tickMax = ticks[ticks.length - 1];
    drawYAxis(svg, ticks, tickMax, width, height, margin, fmtAxisM);
    drawAxes(svg, width, height, margin);
    const barW = chartW / years.length * 0.58;
    years.forEach((d, i) => {
      const x = margin.left + i * (chartW / years.length) + (chartW / years.length - barW) / 2;
      const barH = Math.abs(d.netImpact) / tickMax * chartH;
      const y = height - margin.bottom - barH;
      add(svg, "rect", { x, y, width: barW, height: barH, rx: 5, fill: d.netImpact >= 0 ? "#b24b4b" : "#2f8f6b" });
      add(svg, "text", { x: x + barW / 2, y: y - 8, "font-size": 12, fill: "#172033", "text-anchor": "middle" }, formatMillions(d.netImpact));
      add(svg, "text", { x: x + barW / 2, y: height - 14, "font-size": 12, fill: "#5f6b7a", "text-anchor": "middle" }, `Y${d.year}`);
    });
  };

  const drawCumulative = (years) => {
    const svg = app.querySelector("#cumulative-chart");
    clearSvg(svg);
    const width = 640;
    const height = 260;
    const margin = { top: 24, right: 28, bottom: 42, left: 68 };
    const chartH = height - margin.top - margin.bottom;
    const chartW = width - margin.left - margin.right;
    const dataMax = Math.max(1, ...years.map((d) => Math.abs(d.cumulative)));
    const ticks = niceTicks(dataMax);
    const tickMax = ticks[ticks.length - 1];
    drawYAxis(svg, ticks, tickMax, width, height, margin, fmtAxisM);
    drawAxes(svg, width, height, margin);
    const x = (i) => margin.left + (i / 4) * chartW;
    const y = (v) => height - margin.bottom - (v / tickMax) * chartH;
    const points = years.map((d, i) => `${x(i)},${y(d.cumulative)}`).join(" ");
    add(svg, "polyline", { points, fill: "none", stroke: "#b7791f", "stroke-width": 4, "stroke-linejoin": "round" });
    years.forEach((d, i) => {
      add(svg, "circle", { cx: x(i), cy: y(d.cumulative), r: 5, fill: "#b7791f" });
      add(svg, "text", { x: x(i), y: height - 14, "font-size": 12, fill: "#5f6b7a", "text-anchor": "middle" }, `Y${d.year}`);
      add(svg, "text", { x: x(i), y: y(d.cumulative) - 10, "font-size": 12, fill: "#172033", "text-anchor": "middle" }, formatMillions(d.cumulative));
    });
  };

  const drawTornado = (rows) => {
    const svg = app.querySelector("#tornado-chart");
    clearSvg(svg);
    const width = 700;
    const margin = { top: 28, right: 80, bottom: 32, left: 190 };
    const rowH = 42;
    const lastContentBottom = margin.top + (rows.length - 1) * rowH + 24;
    const height = lastContentBottom + margin.bottom;
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
    const chartW = width - margin.left - margin.right;
    const base = rows[0]?.base || 0;
    const min = Math.min(...rows.map((row) => row.minImpact), base);
    const max = Math.max(...rows.map((row) => row.maxImpact), base);
    const span = Math.max(1, max - min);
    const x = (value) => margin.left + ((value - min) / span) * chartW;
    const baseX = x(base);

    add(svg, "line", {
      x1: baseX,
      y1: margin.top - 8,
      x2: baseX,
      y2: lastContentBottom,
      stroke: "#172033",
      "stroke-width": 1.4,
      "stroke-dasharray": "4 4"
    });
    add(svg, "text", {
      x: baseX,
      y: 18,
      "font-size": 12,
      fill: "#172033",
      "text-anchor": "middle"
    }, `Base ${formatMillions(base)}`);

    rows.forEach((row, i) => {
      const y = margin.top + i * rowH + 14;
      const lowX = x(row.lowImpact);
      const highX = x(row.highImpact);
      const left = Math.min(lowX, highX);
      const right = Math.max(lowX, highX);
      add(svg, "text", {
        x: 12,
        y: y + 6,
        "font-size": 13,
        fill: "#172033"
      }, row.label);
      add(svg, "rect", {
        x: left,
        y: y - 10,
        width: Math.max(2, right - left),
        height: 20,
        rx: 4,
        fill: "#2f6fbd",
        opacity: 0.82
      });
      add(svg, "text", {
        x: left - 8,
        y: y + 5,
        "font-size": 11,
        fill: "#5f6b7a",
        "text-anchor": "end"
      }, formatMillions(row.minImpact));
      add(svg, "text", {
        x: right + 8,
        y: y + 5,
        "font-size": 11,
        fill: "#5f6b7a"
      }, formatMillions(row.maxImpact));
    });
  };

  const updateTable = (years) => {
    const body = app.querySelector("#results-body");
    body.innerHTML = "";
    years.forEach((d) => {
      const row = document.createElement("tr");
      const cells = [
        `Year ${d.year}`,
        `${Math.round(d.uptake * 100)}%`,
        fmtOne.format(d.treated),
        formatMillions(d.drugCost),
        formatMillions(d.otherCosts),
        formatMillions(d.displaced),
        formatMillions(d.netImpact),
        formatMillions(d.cumulative)
      ];
      cells.forEach((value) => {
        const cell = document.createElement("td");
        cell.textContent = value;
        row.appendChild(cell);
      });
      body.appendChild(row);
    });
  };

  const updateSensitivity = (raw) => {
    const rows = getSensitivityRows(raw);
    drawTornado(rows);

    const body = app.querySelector("#sensitivity-body");
    if (body) {
      body.innerHTML = "";
      rows.forEach((row) => {
        const tr = document.createElement("tr");
        [
          `${row.label} (${row.lowNote}/${row.highNote})`,
          formatMillions(row.minImpact),
          formatMillions(row.maxImpact),
          formatMillions(row.range)
        ].forEach((value) => {
          const td = document.createElement("td");
          td.textContent = value;
          tr.appendChild(td);
        });
        body.appendChild(tr);
      });
    }

    const summary = app.querySelector("#sensitivity-summary");
    const top = rows[0];
    if (summary && top) {
      summary.textContent =
        `Largest driver: ${top.label}. In this one-way sensitivity check, ${top.interpretation} creates the widest 5-year cumulative impact range (${formatMillions(top.range)}). This is the assumption a payer or commissioner would most likely scrutinise first.`;
    }
  };

  const updateCalculationNotes = (p, result) => {
    const y1 = result.years[0];
    const cum3 = result.years[2].cumulative;
    const cumulative = result.years[result.years.length - 1].cumulative;
    const eligibleEl = app.querySelector("#calc-eligible");
    const netPriceEl = app.querySelector("#calc-net-price");
    const y1El = app.querySelector("#calc-y1-impact");
    const cum3El = app.querySelector("#calc-cum3");
    const cumulativeEl = app.querySelector("#calc-cumulative");

    if (eligibleEl) {
      eligibleEl.innerHTML =
        `<strong>${fmtInt.format(result.eligible)}</strong> = ${fmtInt.format(p.incident)} incident patients x ` +
        `${Math.round(p.diagnosis * 100)}% diagnosed x ${Math.round(p.biomarker * 100)}% biomarker-positive x ` +
        `${Math.round(p.line * 100)}% treatment-line eligible x ${Math.round(p.suitability * 100)}% clinically suitable.`;
    }

    if (netPriceEl) {
      netPriceEl.innerHTML =
        `<strong>${fmtCurrency.format(result.netPrice)}</strong> = ${fmtCurrency.format(p.listPrice)} list price x ` +
        `(1 - ${Math.round(p.discount * 100)}% PAS discount). This is the net annual price after discount, not list price multiplied by the discount itself.`;
    }

    if (y1El) {
      y1El.innerHTML =
        `<strong>${formatMillions(y1.netImpact)}</strong> = ${formatMillions(y1.drugCost)} Drug B cost + ` +
        `${formatMillions(y1.otherCosts)} administration/monitoring/adverse event costs - ` +
        `${formatMillions(y1.displaced)} displaced comparator cost.`;
    }

    if (cum3El) {
      cum3El.innerHTML =
        `<strong>${formatMillions(cum3)}</strong> = sum of Years 1, 2, and 3 net budget impacts. ` +
        `NHS commissioning planning cycles typically use a 3-year horizon, making this the standard short-term affordability checkpoint in a formulary submission.`;
    }

    if (cumulativeEl) {
      cumulativeEl.innerHTML =
        `<strong>${formatMillions(cumulative)}</strong> = sum of annual net budget impacts across Years 1-5. ` +
        `It accumulates the yearly values shown in the Year-by-Year Results table.`;
    }
  };

  const updateScenarioComparison = (result) => {
    const baseResult = calculate(valuesToInputs({ ...baseValues }));
    const currentY1 = result.years[0].netImpact;
    const currentCum = result.years[result.years.length - 1].cumulative;
    const baseY1 = baseResult.years[0].netImpact;
    const baseCum = baseResult.years[baseResult.years.length - 1].cumulative;
    const deltaY1 = currentY1 - baseY1;
    const deltaCum = currentCum - baseCum;

    const y1El = app.querySelector("#scenario-delta-y1");
    const cumEl = app.querySelector("#scenario-delta-cum");
    const noteEl = app.querySelector("#scenario-delta-note");
    if (y1El) y1El.textContent = formatDelta(deltaY1);
    if (cumEl) cumEl.textContent = formatDelta(deltaCum);

    if (!noteEl) return;
    if (activeScenarioId === "base") {
      noteEl.textContent = "This is the reference scenario, so the comparison values show no change.";
    } else if (deltaCum > 0) {
      noteEl.textContent = "Positive values mean this scenario increases affordability pressure compared with the Base Case.";
    } else if (deltaCum < 0) {
      noteEl.textContent = "Negative values mean this scenario reduces affordability pressure compared with the Base Case.";
    } else {
      noteEl.textContent = "This scenario has no material impact on cumulative budget impact compared with the Base Case.";
    }
  };

  const update = () => {
    const p = getInputs();
    const result = calculate(p);

    Object.entries(p.raw).forEach(([id, value]) => {
      const el = app.querySelector(`[data-display="${id}"]`);
      if (el) el.textContent = formatDisplay(id, value);
    });

    app.querySelector("#eligible-card").textContent = fmtInt.format(result.eligible);
    app.querySelector("#treated-card").textContent = fmtOne.format(result.years[0].treated);
    app.querySelector("#net-price-card").textContent = fmtCurrency.format(result.netPrice);
    app.querySelector("#year1-card").textContent = formatMillions(result.years[0].netImpact);
    app.querySelector("#cum3-card").textContent = formatMillions(result.years[2].cumulative);
    app.querySelector("#cum-card").textContent = formatMillions(result.years[4].cumulative);

    drawFunnel(result.funnel);
    drawUptake(result.years);
    drawBars(result.years);
    drawCumulative(result.years);
    updateTable(result.years);
    updateCalculationNotes(p, result);
    updateSensitivity(p.raw);
    updateScenarioComparison(result);
  };

  ids.forEach((id) => {
    app.querySelector(`[data-input="${id}"]`).addEventListener("input", update);
  });

  app.querySelector("#reset-btn").addEventListener("click", () => {
    ids.forEach((id) => setInputValue(id, baseValues[id]));
    activeScenarioId = "base";
    updateScenarioUI();
    update();
  });

  renderScenarioButtons();
  update();
})();
