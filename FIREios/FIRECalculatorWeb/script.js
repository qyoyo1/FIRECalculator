const CURRENCIES = ["USD", "CHF", "EUR", "RMB"];

const FX_TO_USD = {
  USD: 1.0,
  CHF: 1.12,
  EUR: 1.09,
  RMB: 0.14,
};

const SCENARIOS = [
  {
    name: "Conservative",
    description: "Lower growth assumptions focused on stability and downside protection.",
    growth: { cash: 0.015, equity: 0.05, realEstate: 0.03, pension: 0.02 },
  },
  {
    name: "Base",
    description: "Balanced assumptions representing a moderate long-term outcome.",
    growth: { cash: 0.025, equity: 0.07, realEstate: 0.045, pension: 0.03 },
  },
  {
    name: "Aggressive",
    description: "Higher growth assumptions with greater risk and volatility.",
    growth: { cash: 0.035, equity: 0.09, realEstate: 0.06, pension: 0.04 },
  },
];

const state = {
  currentAge: 34,
  fireAge: 40,
  assets: [
    { key: "cash", label: "Cash", amount: 8000, currency: "CHF" },
    { key: "equity", label: "Equity", amount: 316000, currency: "CHF" },
    { key: "realEstate", label: "Real Estate", amount: 0, currency: "CHF" },
    { key: "pension", label: "Pension", amount: 173000, currency: "CHF" },
  ],
  expectedIncomeInputs: {
    expectedAnnualIncome: { amount: 300000, currency: "CHF", sign: 1, label: "Expected annual income" },
    realEstateIncome: { amount: 0, currency: "CHF", sign: 1, label: "Real estate income" },
    rentExpenses: { amount: 24000, currency: "CHF", sign: -1, label: "Rent expenses" },
    sharedExpenses: { amount: 36000, currency: "CHF", sign: -1, label: "Shared expenses" },
  },
};

const currentAgeInput = document.getElementById("currentAge");
const fireAgeInput = document.getElementById("fireAge");
const assetInputsContainer = document.getElementById("assetInputs");
const validationContainer = document.getElementById("validation");
const portfolioByCurrency = document.getElementById("portfolioByCurrency");
const portfolioUsdTotal = document.getElementById("portfolioUsdTotal");
const portfolioFxInfo = document.getElementById("portfolioFxInfo");
const scenarioResults = document.getElementById("scenarioResults");
const expectedIncomeByCurrency = document.getElementById("expectedIncomeByCurrency");
const expectedIncomeUsdTotal = document.getElementById("expectedIncomeUsdTotal");
const expectedIncomeFxInfo = document.getElementById("expectedIncomeFxInfo");
const expectedIncomeAmountInput = document.getElementById("expectedIncomeAmount");
const expectedIncomeCurrencySelect = document.getElementById("expectedIncomeCurrency");
const realEstateIncomeAmountInput = document.getElementById("realEstateIncomeAmount");
const realEstateIncomeCurrencySelect = document.getElementById("realEstateIncomeCurrency");
const rentExpensesAmountInput = document.getElementById("rentExpensesAmount");
const rentExpensesCurrencySelect = document.getElementById("rentExpensesCurrency");
const sharedExpensesAmountInput = document.getElementById("sharedExpensesAmount");
const sharedExpensesCurrencySelect = document.getElementById("sharedExpensesCurrency");

function formatCurrency(amount, code) {
  if (code === "USD") {
    return (
      "$" +
      amount.toLocaleString("en-US", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      })
    );
  }
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: code,
    maximumFractionDigits: 2,
  })
    .format(amount)
    .replace(/US\$/g, "$");
}

function formatPercent(value) {
  return `${(value * 100).toFixed(2)}%`;
}

function sanitizeDecimal(rawValue) {
  const sanitized = rawValue.replace(/[^\d.]/g, "");
  const parts = sanitized.split(".");
  if (parts.length <= 1) return sanitized;
  return `${parts[0]}.${parts.slice(1).join("")}`;
}

function createCurrencyIconLabel() {
  const icon = document.createElement("span");
  icon.className = "currency-icon-label";
  icon.setAttribute("aria-label", "Currency");
  icon.setAttribute("title", "Currency");
  return icon;
}

function renderAssetInputs() {
  assetInputsContainer.innerHTML = "";

  state.assets.forEach((asset, index) => {
    const row = document.createElement("div");
    row.className = "asset-row";

    const title = document.createElement("div");
    title.className = "asset-name";
    title.textContent = asset.label;

    const amountLabel = document.createElement("label");
    amountLabel.textContent = "Amount";
    const amountInput = document.createElement("input");
    amountInput.type = "text";
    amountInput.inputMode = "decimal";
    amountInput.value = String(asset.amount);
    amountInput.addEventListener("input", (event) => {
      const value = sanitizeDecimal(event.target.value);
      event.target.value = value;
      state.assets[index].amount = value === "" ? 0 : Number(value);
      render();
    });
    amountLabel.appendChild(amountInput);

    const currencyLabel = document.createElement("label");
    currencyLabel.appendChild(createCurrencyIconLabel());
    const select = document.createElement("select");
    CURRENCIES.forEach((currency) => {
      const option = document.createElement("option");
      option.value = currency;
      option.textContent = currency;
      if (currency === asset.currency) option.selected = true;
      select.appendChild(option);
    });
    select.addEventListener("change", (event) => {
      state.assets[index].currency = event.target.value;
      render();
    });
    currencyLabel.appendChild(select);

    const inputsWrap = document.createElement("div");
    inputsWrap.className = "asset-inputs";
    inputsWrap.appendChild(currencyLabel);
    inputsWrap.appendChild(amountLabel);

    row.appendChild(title);
    row.appendChild(inputsWrap);
    assetInputsContainer.appendChild(row);
  });
}

function getValidationErrors() {
  const errors = [];
  if (!Number.isInteger(state.currentAge) || state.currentAge < 0) {
    errors.push("Current age must be a valid non-negative integer.");
  }
  if (!Number.isInteger(state.fireAge) || state.fireAge < 0) {
    errors.push("FIRE age must be a valid non-negative integer.");
  }
  if (state.fireAge < state.currentAge) {
    errors.push("FIRE age must be greater than or equal to current age.");
  }
  state.assets.forEach((asset) => {
    if (!Number.isFinite(asset.amount) || asset.amount < 0) {
      errors.push(`${asset.label} must be a valid non-negative number.`);
    }
  });
  Object.values(state.expectedIncomeInputs).forEach((item) => {
    if (!Number.isFinite(item.amount) || item.amount < 0) {
      errors.push(`${item.label} must be a valid non-negative number.`);
    }
  });
  return errors;
}

function calculatePortfolioSummary() {
  const byCurrency = { USD: 0, CHF: 0, EUR: 0, RMB: 0 };
  let totalUsd = 0;

  state.assets.forEach((asset) => {
    byCurrency[asset.currency] += asset.amount;
    totalUsd += asset.amount * FX_TO_USD[asset.currency];
  });

  return { byCurrency, totalUsd };
}

function calculateExpectedIncomeSummary() {
  const byCurrency = { USD: 0, CHF: 0, EUR: 0, RMB: 0 };
  let totalUsd = 0;

  Object.values(state.expectedIncomeInputs).forEach((item) => {
    const signedAmount = item.amount * item.sign;
    byCurrency[item.currency] += signedAmount;
    totalUsd += signedAmount * FX_TO_USD[item.currency];
  });

  return { byCurrency, totalUsd };
}

function calculateScenarios() {
  const yearsToFire = Math.max(state.fireAge - state.currentAge, 0);
  const netAnnualIncomeUSD = calculateExpectedIncomeSummary().totalUsd;
  const futureYearsTotalIncomeUSD = netAnnualIncomeUSD * yearsToFire;

  return SCENARIOS.map((scenario) => {
    let projectedAssetsUSD = 0;
    const growthRatesSummary = state.assets
      .map((asset) => `${asset.label}: ${formatPercent(scenario.growth[asset.key] ?? 0)}`)
      .join(", ");

    state.assets.forEach((asset) => {
      const growthRate = scenario.growth[asset.key] ?? 0;
      const projected = asset.amount * Math.pow(1 + growthRate, yearsToFire);
      projectedAssetsUSD += projected * FX_TO_USD[asset.currency];
    });
    const fireTotalUSD = projectedAssetsUSD + futureYearsTotalIncomeUSD;
    const annualIncomeUSDFromFire = fireTotalUSD * 0.03;
    const monthlyIncomeUSDFromFire = annualIncomeUSDFromFire / 12;

    return {
      name: scenario.name,
      calculationDetail: [
        `Growth rates -> ${growthRatesSummary}`,
      ].join("\n"),
      projectedAssetsUSD,
      futureYearsTotalIncomeUSD,
      fireTotalUSD,
      annualIncomeUSD: annualIncomeUSDFromFire,
      monthlyIncomeUSD: monthlyIncomeUSDFromFire,
    };
  });
}

function renderValidation(errors) {
  validationContainer.innerHTML = "";
  if (errors.length === 0) return;

  const ul = document.createElement("ul");
  errors.forEach((error) => {
    const li = document.createElement("li");
    li.textContent = error;
    ul.appendChild(li);
  });
  validationContainer.appendChild(ul);
}

function renderPortfolioSummary(summary) {
  portfolioByCurrency.innerHTML = "";
  CURRENCIES.forEach((currency) => {
    const row = document.createElement("div");
    row.className = "summary-row";
    row.innerHTML = `<span>${currency}</span><strong>${formatCurrency(summary.byCurrency[currency], currency)}</strong>`;
    portfolioByCurrency.appendChild(row);
  });
  portfolioUsdTotal.textContent = formatCurrency(summary.totalUsd, "USD");
}

function renderExpectedIncomeSummary(summary) {
  expectedIncomeByCurrency.innerHTML = "";
  CURRENCIES.forEach((currency) => {
    const row = document.createElement("div");
    row.className = "summary-row";
    row.innerHTML = `<span>${currency}</span><strong>${formatCurrency(summary.byCurrency[currency], currency)}</strong>`;
    expectedIncomeByCurrency.appendChild(row);
  });
  expectedIncomeUsdTotal.textContent = formatCurrency(summary.totalUsd, "USD");
}

function renderFxInfo() {
  const fxText = `FX to USD: 1 USD=${FX_TO_USD.USD.toFixed(2)}, 1 CHF=${FX_TO_USD.CHF.toFixed(2)}, 1 EUR=${FX_TO_USD.EUR.toFixed(2)}, 1 RMB=${FX_TO_USD.RMB.toFixed(2)}`;
  portfolioFxInfo.textContent = fxText;
  expectedIncomeFxInfo.textContent = fxText;
}

function renderScenarios(scenarios) {
  scenarioResults.innerHTML = "";
  scenarios.forEach((scenario) => {
    const card = document.createElement("article");
    card.className = "scenario-card";
    card.innerHTML = `
      <h3>${scenario.name}</h3>
      <p class="scenario-description">${scenario.calculationDetail}</p>
      <div class="row"><span>Projected Assets (USD)</span><strong>${formatCurrency(scenario.projectedAssetsUSD, "USD")}</strong></div>
      <div class="row"><span>FIRE Total (USD)</span><strong>${formatCurrency(scenario.fireTotalUSD, "USD")}</strong></div>
      <div class="row"><span>Annual Income (3%)</span><strong>${formatCurrency(scenario.annualIncomeUSD, "USD")}</strong></div>
      <div class="row"><span>Monthly Income</span><strong>${formatCurrency(scenario.monthlyIncomeUSD, "USD")}</strong></div>
    `;
    scenarioResults.appendChild(card);
  });
}

function render() {
  const errors = getValidationErrors();
  renderValidation(errors);

  const summary = calculatePortfolioSummary();
  renderPortfolioSummary(summary);
  const incomeSummary = calculateExpectedIncomeSummary();
  renderExpectedIncomeSummary(incomeSummary);
  renderFxInfo();

  if (errors.length === 0) {
    renderScenarios(calculateScenarios());
  } else {
    scenarioResults.innerHTML = "<p>Fix validation issues to calculate scenarios.</p>";
  }
}

function setupAges() {
  currentAgeInput.value = String(state.currentAge);
  fireAgeInput.value = String(state.fireAge);

  currentAgeInput.addEventListener("input", (event) => {
    const numericText = event.target.value.replace(/[^\d]/g, "");
    event.target.value = numericText;
    state.currentAge = numericText === "" ? 0 : Number(numericText);
    render();
  });

  fireAgeInput.addEventListener("input", (event) => {
    const numericText = event.target.value.replace(/[^\d]/g, "");
    event.target.value = numericText;
    state.fireAge = numericText === "" ? 0 : Number(numericText);
    render();
  });
}

function setupExpectedIncome() {
  const bindIncomeInput = (amountInput, currencySelect, key) => {
    amountInput.value = String(state.expectedIncomeInputs[key].amount);
    currencySelect.value = state.expectedIncomeInputs[key].currency;

    amountInput.addEventListener("input", (event) => {
      const value = sanitizeDecimal(event.target.value);
      event.target.value = value;
      state.expectedIncomeInputs[key].amount = value === "" ? 0 : Number(value);
      render();
    });

    currencySelect.addEventListener("change", (event) => {
      state.expectedIncomeInputs[key].currency = event.target.value;
      render();
    });
  };

  bindIncomeInput(expectedIncomeAmountInput, expectedIncomeCurrencySelect, "expectedAnnualIncome");
  bindIncomeInput(realEstateIncomeAmountInput, realEstateIncomeCurrencySelect, "realEstateIncome");
  bindIncomeInput(rentExpensesAmountInput, rentExpensesCurrencySelect, "rentExpenses");
  bindIncomeInput(sharedExpensesAmountInput, sharedExpensesCurrencySelect, "sharedExpenses");
}

setupAges();
setupExpectedIncome();
renderAssetInputs();
render();
