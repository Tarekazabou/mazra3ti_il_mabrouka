// WiEmpower Smart Irrigation System - Simulation
// Hybrid AI Decision System: XGBoost + Gemini

// System Configuration
const CONFIG = {
  aiDecisionInterval: 8000, // 8 seconds for faster demo
  sensorUpdateInterval: 1500, // 1.5 seconds
  numberOfAreas: 4,
  areas: [
    {
      id: 1,
      name: "Tomatoes",
      plant: "🍅",
      moistureOptimal: [60, 75],
      waterNeed: 3,
    },
    {
      id: 2,
      name: "Peppers",
      plant: "🌶️",
      moistureOptimal: [55, 70],
      waterNeed: 2,
    },
    {
      id: 3,
      name: "Wheat",
      plant: "🌾",
      moistureOptimal: [40, 60],
      waterNeed: 2,
    },
    {
      id: 4,
      name: "Olives",
      plant: "🫒",
      moistureOptimal: [35, 55],
      waterNeed: 1,
    },
  ],
};

// Global State
let state = {
  aiMode: true,
  areas: [],
  weather: {
    temperature: 25,
    humidity: 60,
    rainProbability: 20,
    expectedRain: 0,
  },
  statistics: {
    totalDecisions: 0,
    waterSaved: 0,
    activeValves: 0,
  },
  nextDecisionTime: 0,
  timerInterval: null,
};

// Initialize System
function init() {
  console.log("🌱 Initializing WiEmpower Simulation...");

  // Initialize areas with more varied initial moisture levels
  CONFIG.areas.forEach((areaConfig) => {
    state.areas.push({
      id: areaConfig.id,
      name: areaConfig.name,
      plant: areaConfig.plant,
      moistureOptimal: areaConfig.moistureOptimal,
      waterNeed: areaConfig.waterNeed,
      soilMoisture: Math.floor(Math.random() * 40) + 25, // 25-65% - more varied
      temperature: 24 + Math.random() * 10, // 24-34°C
      valveOpen: false,
      isWatering: false,
      wateringDuration: 0,
      wateringIntensity: 0,
      lastWateredMinutes: Math.floor(Math.random() * 1440),
      minutesSinceLastWatering: Math.floor(Math.random() * 1440),
    });
  });

  // Start update loops
  updateClock();
  setInterval(updateClock, 1000);

  updateSensorData();
  setInterval(updateSensorData, CONFIG.sensorUpdateInterval);

  updateWeather();
  setInterval(updateWeather, 30000); // Update weather every 30 seconds

  // Start AI decision cycle immediately
  addLog("info", "🚀 System starting... First AI decision in 2 seconds!");
  setTimeout(() => {
    aiDecisionCycle();
    setInterval(aiDecisionCycle, CONFIG.aiDecisionInterval);
  }, 2000); // First decision after 2 seconds

  // Countdown to next decision
  state.nextDecisionTime = 2; // Start countdown from 2 seconds
  console.log("🔧 Setting up timer, initial value:", state.nextDecisionTime);

  // Update immediately
  updateNextDecisionTimer();

  // Then start the interval
  if (state.timerInterval) {
    clearInterval(state.timerInterval); // Clear any existing interval
  }
  state.timerInterval = setInterval(() => {
    updateNextDecisionTimer();
    console.log("⏱️ Timer tick:", state.nextDecisionTime);
  }, 1000);

  // Setup event listeners
  document
    .getElementById("aiModeToggle")
    .addEventListener("change", function () {
      state.aiMode = this.checked;
      document.getElementById("modeLabel").textContent = state.aiMode
        ? "AI Mode: ON"
        : "AI Mode: OFF (Manual)";
      document.getElementById("modeLabel").style.color = state.aiMode
        ? "#4CAF50"
        : "#FF9800";

      addLog(
        "system",
        `${state.aiMode ? "🤖 AI Mode Enabled" : "👤 Manual Mode Enabled"}`
      );

      // Enable/disable manual controls
      updateManualControlButtons();
    });

  console.log("✅ System initialized successfully!");
  updateDisplay();
}

// Update Clock
function updateClock() {
  const now = new Date();
  const timeString = now.toLocaleTimeString("en-US", { hour12: false });
  document.getElementById("currentTime").textContent = timeString;
}

// Update Sensor Data (Simulate sensor readings)
function updateSensorData() {
  state.areas.forEach((area) => {
    // Simulate sensor data changes
    if (!area.isWatering) {
      // Moisture decreases over time (balanced evaporation)
      const evaporationRate = 0.05 + Math.random() * 0.08; // 0.05-0.13% per update (reduced)
      area.soilMoisture = Math.max(15, area.soilMoisture - evaporationRate);
      area.minutesSinceLastWatering += CONFIG.sensorUpdateInterval / 60000;
    } else {
      // Moisture increases when watering (much better absorption)
      const absorptionRate = (area.wateringIntensity / 100) * 1.8; // Significantly improved absorption
      area.soilMoisture = Math.min(95, area.soilMoisture + absorptionRate);
    }

    // Temperature fluctuation
    area.temperature = 24 + Math.random() * 10 + (area.isWatering ? -2 : 0);
  });

  updateDisplay();
}

// Update Weather (Simulate weather changes)
function updateWeather() {
  // Generate random weather scenario
  const scenarios = [
    { temp: 28, humidity: 40, rainProb: 10, rain: 0 },
    { temp: 32, humidity: 35, rainProb: 5, rain: 0 },
    { temp: 26, humidity: 65, rainProb: 45, rain: 3 },
    { temp: 24, humidity: 70, rainProb: 75, rain: 8 },
    { temp: 30, humidity: 50, rainProb: 30, rain: 1 },
  ];

  const scenario = scenarios[Math.floor(Math.random() * scenarios.length)];
  state.weather = scenario;

  document.getElementById("weatherTemp").textContent = scenario.temp;
  document.getElementById("weatherHumidity").textContent = scenario.humidity;
  document.getElementById("rainProb").textContent = scenario.rainProb;
  document.getElementById("expectedRain").textContent = scenario.rain;
}

// AI Decision Cycle (Every 30 seconds in demo)
async function aiDecisionCycle() {
  if (!state.aiMode) {
    addLog("info", "⏸️ AI decision skipped - Manual mode active");
    return;
  }

  addLog("ai", "🧠 AI Decision Cycle Started...", "Analyzing all farm areas");

  // Process each area
  for (const area of state.areas) {
    // Skip if currently watering
    if (area.isWatering) {
      addLog(
        "info",
        `⏩ Area ${area.id} (${area.name}) - Currently watering, skipping decision`
      );
      continue;
    }

    // Simulate AI decision process
    await new Promise((resolve) => setTimeout(resolve, 500)); // Small delay for visual effect

    const decision = makeAIDecision(area);

    // Execute decision
    if (decision.shouldWater) {
      startWatering(area.id, decision.duration, decision.intensity, true);

      addLog(
        "water",
        `💧 Area ${area.id} (${area.name}) - Water for ${decision.duration} min at ${decision.intensity}%`,
        `XGBoost: Water | Gemini: Confirmed | Reason: ${decision.reason}`
      );
    } else {
      addLog(
        "skip",
        `🚫 Area ${area.id} (${area.name}) - No watering needed`,
        `XGBoost: ${decision.xgboostSaid} | Gemini: ${decision.geminiSaid} | Reason: ${decision.reason}`
      );
    }

    state.statistics.totalDecisions++;

    if (decision.waterSaved > 0) {
      state.statistics.waterSaved += decision.waterSaved;
    }
  }

  // Reset timer
  state.nextDecisionTime = CONFIG.aiDecisionInterval / 1000;

  updateDisplay();
  updateStatistics();
}

// AI Decision Logic (Simplified simulation of XGBoost + Gemini)
function makeAIDecision(area) {
  const decision = {
    shouldWater: false,
    duration: 0,
    intensity: 0,
    xgboostSaid: "No",
    geminiSaid: "No",
    reason: "",
    waterSaved: 0,
  };

  // Stage 1: XGBoost Decision (based on sensor data and plant needs)
  const moistureDeficit = 100 - area.soilMoisture;
  const isLowMoisture = area.soilMoisture < area.moistureOptimal[0];
  const isCriticallyLow = area.soilMoisture < 30;
  const timeSinceLastWater = area.minutesSinceLastWatering;

  // XGBoost logic (improved with better durations)
  let xgboostWater = false;
  let xgboostDuration = 0;
  let xgboostIntensity = 0;

  if (isCriticallyLow) {
    xgboostWater = true;
    xgboostDuration = 40 + Math.floor(Math.random() * 20); // 40-60 minutes
    xgboostIntensity = 80 + Math.floor(Math.random() * 15); // 80-95%
    decision.xgboostSaid = "Water (Critical)";
  } else if (area.soilMoisture < area.moistureOptimal[0] - 5) {
    // Well below optimal
    xgboostWater = true;
    xgboostDuration = 30 + Math.floor(Math.random() * 15); // 30-45 minutes
    xgboostIntensity = 65 + Math.floor(Math.random() * 20); // 65-85%
    decision.xgboostSaid = "Water (Low)";
  } else if (isLowMoisture && timeSinceLastWater > 480) {
    // Slightly below optimal + time passed
    xgboostWater = true;
    xgboostDuration = 20 + Math.floor(Math.random() * 15); // 20-35 minutes
    xgboostIntensity = 55 + Math.floor(Math.random() * 20); // 55-75%
    decision.xgboostSaid = "Water (Preventive)";
  } else {
    decision.xgboostSaid = "No Water";
  }

  // Stage 2: Gemini Refinement (considers weather forecast)
  const heavyRainSoon =
    state.weather.rainProbability > 70 && state.weather.expectedRain > 8;
  const moderateRain =
    state.weather.rainProbability > 50 && state.weather.expectedRain > 3;
  const noRain = state.weather.rainProbability < 30;

  // Gemini decision logic
  if (xgboostWater) {
    // XGBoost said water, Gemini checks weather
    if (heavyRainSoon && !isCriticallyLow) {
      // Override: Don't water
      decision.shouldWater = false;
      decision.geminiSaid = "Override: Cancel";
      decision.reason = `Heavy rain (${state.weather.expectedRain}mm) expected soon - water conservation`;
      decision.waterSaved = Math.floor(
        (xgboostDuration * xgboostIntensity) / 10
      ); // Estimate water saved
    } else if (moderateRain && area.soilMoisture > 40) {
      // Adjust: Reduce watering
      decision.shouldWater = true;
      decision.duration = Math.floor(xgboostDuration * 0.7);
      decision.intensity = Math.floor(xgboostIntensity * 0.8);
      decision.geminiSaid = "Adjusted (30% reduction)";
      decision.reason = `Moderate rain expected - reduced duration to conserve water`;
      decision.waterSaved = Math.floor(
        ((xgboostDuration - decision.duration) * xgboostIntensity) / 10
      );
    } else {
      // Confirm: Water as recommended
      decision.shouldWater = true;
      decision.duration = xgboostDuration;
      decision.intensity = xgboostIntensity;
      decision.geminiSaid = "Confirmed";
      decision.reason = `Soil moisture ${area.soilMoisture.toFixed(
        1
      )}% below optimal (${area.moistureOptimal[0]}-${
        area.moistureOptimal[1]
      }%)`;
    }
  } else {
    // XGBoost said don't water
    if (isLowMoisture && noRain && timeSinceLastWater > 720) {
      // Override: Water anyway
      decision.shouldWater = true;
      decision.duration = 15 + Math.floor(Math.random() * 10);
      decision.intensity = 40 + Math.floor(Math.random() * 20);
      decision.geminiSaid = "Override: Water";
      decision.reason =
        "No rain forecast, moisture declining - preventive watering for plant health";
    } else {
      // Confirm: Don't water
      decision.shouldWater = false;
      decision.geminiSaid = "Confirmed";
      decision.reason = `Moisture adequate (${area.soilMoisture.toFixed(
        1
      )}%) for now`;
    }
  }

  return decision;
}

// Start Watering
function startWatering(areaId, duration, intensity, isAI = false) {
  const area = state.areas.find((a) => a.id === areaId);
  if (!area) return;

  area.isWatering = true;
  area.valveOpen = true;
  area.wateringDuration = duration;
  area.wateringIntensity = intensity;

  // Update visual
  updateValveVisual(areaId, true);

  // Stop watering after duration (200ms per "minute" for visible moisture increase)
  const simulatedDuration = duration * 200; // 200ms per "minute" = 40min watering lasts 8 seconds
  setTimeout(() => {
    stopWatering(areaId);
    addLog("info", `✅ Area ${area.id} (${area.name}) - Watering complete`);
  }, simulatedDuration);

  if (!isAI) {
    addLog(
      "manual",
      `👤 Manual Control - Area ${areaId} (${area.name}) valve opened`
    );
  }

  updateDisplay();
  updateStatistics();
}

// Stop Watering
function stopWatering(areaId) {
  const area = state.areas.find((a) => a.id === areaId);
  if (!area) return;

  area.isWatering = false;
  area.valveOpen = false;
  area.lastWateredMinutes = 0;
  area.minutesSinceLastWatering = 0;

  // Update visual
  updateValveVisual(areaId, false);

  updateDisplay();
  updateStatistics();
}

// Manual Control
function manualControl(areaId, open) {
  if (state.aiMode) {
    showNotification("⚠️ Disable AI mode to use manual controls", "warning");
    return;
  }

  const area = state.areas.find((a) => a.id === areaId);
  if (!area) return;

  if (open) {
    if (area.isWatering) {
      showNotification(`Area ${areaId} is already watering`, "info");
      return;
    }
    // Manual watering for 30 "seconds" at 70% intensity (faster for demo)
    startWatering(areaId, 30, 70, false);
    showNotification(`✅ Valve ${areaId} opened manually`, "success");
  } else {
    if (!area.isWatering) {
      showNotification(`Area ${areaId} valve is already closed`, "info");
      return;
    }
    stopWatering(areaId);
    addLog(
      "manual",
      `👤 Manual Control - Area ${areaId} (${area.name}) valve closed`
    );
    showNotification(`✅ Valve ${areaId} closed manually`, "success");
  }
}

// Update Display
function updateDisplay() {
  state.areas.forEach((area) => {
    // Update sensor readings
    document.getElementById(`moisture${area.id}`).textContent =
      area.soilMoisture.toFixed(1);
    document.getElementById(`temp${area.id}`).textContent =
      area.temperature.toFixed(1);

    // Update valve status
    const valveStatus = area.valveOpen ? "OPEN 🟢" : "CLOSED 🔴";
    document.getElementById(`valveStatus${area.id}`).textContent = valveStatus;

    // Update last watered
    const lastWaterText =
      area.minutesSinceLastWatering < 60
        ? `${Math.floor(area.minutesSinceLastWatering)} min ago`
        : `${Math.floor(area.minutesSinceLastWatering / 60)} hrs ago`;
    document.getElementById(`lastWater${area.id}`).textContent = lastWaterText;

    // Update AI decision display
    if (area.isWatering) {
      document.getElementById(
        `aiDecision${area.id}`
      ).textContent = `⚡ Watering: ${area.wateringDuration}s @ ${area.wateringIntensity}%`;
    } else {
      document.getElementById(`aiDecision${area.id}`).textContent =
        area.soilMoisture < area.moistureOptimal[0]
          ? "⚠️ Low moisture detected"
          : "✅ Optimal conditions";
    }
  });

  // Update phone UI
  updatePhoneUI();
}

// Update Phone UI with live data
function updatePhoneUI() {
  // Calculate overall farm health
  const avgMoisture =
    state.areas.reduce((sum, area) => sum + area.soilMoisture, 0) /
    state.areas.length;
  const criticalCount = state.areas.filter(
    (area) => area.soilMoisture < 30
  ).length;
  const warningCount = state.areas.filter(
    (area) =>
      area.soilMoisture >= 30 && area.soilMoisture < area.moistureOptimal[0]
  ).length;

  // Update status card
  const statusCard = document.getElementById("phoneStatusCard");
  const statusIcon = document.getElementById("phoneStatusIcon");
  const statusTitle = document.getElementById("phoneStatusTitle");
  const statusSubtitle = document.getElementById("phoneStatusSubtitle");

  if (statusCard && statusIcon && statusTitle && statusSubtitle) {
    if (criticalCount > 0) {
      statusCard.className = "status-card critical";
      statusIcon.textContent = "⚠️";
      statusTitle.textContent = "يحتاج إلى عناية";
      statusSubtitle.textContent = `${criticalCount} منطقة تحتاج إلى ري فوري`;
    } else if (warningCount > 0) {
      statusCard.className = "status-card warning";
      statusIcon.textContent = "⚡";
      statusTitle.textContent = "تحت المراقبة";
      statusSubtitle.textContent = `${warningCount} منطقة تحتاج إلى مراقبة`;
    } else {
      statusCard.className = "status-card";
      statusIcon.textContent = "✅";
      statusTitle.textContent = "كل شيء رائع!";
      statusSubtitle.textContent = "المزرعة في حالة ممتازة";
    }
  }

  // Update farm statistics
  const avgTemp =
    state.areas.reduce((sum, area) => sum + area.temperature, 0) /
    state.areas.length;
  const activeValves = state.areas.filter((area) => area.valveOpen).length;

  const phoneTempElement = document.getElementById("phoneTemp");
  const phoneValvesElement = document.getElementById("phoneValves");

  if (phoneTempElement) phoneTempElement.textContent = `${avgTemp.toFixed(1)}°`;
  if (phoneValvesElement) phoneValvesElement.textContent = activeValves;

  // Update individual vegetation cards
  state.areas.forEach((area) => {
    const moistureElement = document.getElementById(`phoneM${area.id}`);
    const statusElement = document.getElementById(`phoneS${area.id}`);
    const vegStatusIcon = document.getElementById(`phoneVegStatus${area.id}`);

    if (moistureElement) {
      moistureElement.textContent = `${area.soilMoisture.toFixed(1)}%`;

      // Update color based on moisture level
      if (area.soilMoisture < 30) {
        moistureElement.className = "status-text-critical";
      } else if (area.soilMoisture < area.moistureOptimal[0]) {
        moistureElement.className = "status-text-warning";
      } else {
        moistureElement.className = "status-text-good";
      }
    }

    if (statusElement) {
      if (area.valveOpen) {
        statusElement.textContent = "جاري الري";
        statusElement.className = "status-text-good";
      } else if (area.soilMoisture < 30) {
        statusElement.textContent = "يحتاج ري";
        statusElement.className = "status-text-critical";
      } else if (area.soilMoisture < area.moistureOptimal[0]) {
        statusElement.textContent = "مراقبة";
        statusElement.className = "status-text-warning";
      } else {
        statusElement.textContent = "ممتاز";
        statusElement.className = "status-text-good";
      }
    }

    if (vegStatusIcon) {
      if (area.soilMoisture < 30) {
        vegStatusIcon.textContent = "⚠️";
        vegStatusIcon.className = "veg-status status-critical";
      } else if (area.soilMoisture < area.moistureOptimal[0]) {
        vegStatusIcon.textContent = "⚡";
        vegStatusIcon.className = "veg-status status-warning";
      } else {
        vegStatusIcon.textContent = "✅";
        vegStatusIcon.className = "veg-status status-good";
      }
    }
  });
}

// Update Valve Visual
function updateValveVisual(areaId, isOpen) {
  const valve = document.getElementById(`valve${areaId}`);
  const pipe = document.querySelectorAll(".pipe")[areaId - 1];
  const farmArea = document.getElementById(`area${areaId}`);

  if (isOpen) {
    valve.classList.add("open");
    pipe.classList.add("flowing");
    farmArea.classList.add("watering");
  } else {
    valve.classList.remove("open");
    pipe.classList.remove("flowing");
    farmArea.classList.remove("watering");
  }
}

// Update Statistics
function updateStatistics() {
  const activeValves = state.areas.filter((a) => a.valveOpen).length;
  state.statistics.activeValves = activeValves;

  document.getElementById("totalDecisions").textContent =
    state.statistics.totalDecisions;
  document.getElementById("activeValves").textContent = `${activeValves}/4`;
  document.getElementById("waterSaved").textContent =
    state.statistics.waterSaved;
}

// Update Next Decision Timer
function updateNextDecisionTimer() {
  if (state.nextDecisionTime > 0) {
    state.nextDecisionTime--;
  }

  const minutes = Math.floor(state.nextDecisionTime / 60);
  const seconds = state.nextDecisionTime % 60;
  const timerElement = document.getElementById("nextDecision");

  if (timerElement) {
    const displayText = `${String(minutes).padStart(2, "0")}:${String(
      seconds
    ).padStart(2, "0")}`;
    timerElement.textContent = displayText;
    // Log first few updates
    if (state.nextDecisionTime >= 0 && state.nextDecisionTime <= 3) {
      console.log("⏱️ Timer display updated to:", displayText);
    }
  } else {
    console.warn("⚠️ Timer element not found!");
  }
}

// Update Manual Control Buttons
function updateManualControlButtons() {
  for (let i = 1; i <= CONFIG.numberOfAreas; i++) {
    document.getElementById(`open${i}`).disabled = state.aiMode;
    document.getElementById(`close${i}`).disabled = state.aiMode;
  }
}

// Add Log Entry
function addLog(type, message, detail = "") {
  const logContainer = document.getElementById("decisionLog");

  // Safety check - element might not exist yet
  if (!logContainer) {
    console.log(`[${type}] ${message}`, detail || "");
    return;
  }

  const timestamp = new Date().toLocaleTimeString("en-US", { hour12: false });

  const logEntry = document.createElement("div");
  logEntry.className = `log-entry ${type}`;

  const timeSpan = document.createElement("span");
  timeSpan.className = "log-time";
  timeSpan.textContent = timestamp;

  const messageSpan = document.createElement("span");
  messageSpan.className = "log-message";
  messageSpan.textContent = message;

  logEntry.appendChild(timeSpan);
  logEntry.appendChild(messageSpan);

  if (detail) {
    const detailSpan = document.createElement("span");
    detailSpan.className = "log-detail";
    detailSpan.textContent = detail;
    logEntry.appendChild(detailSpan);
  }

  // Insert at top
  if (
    logContainer.firstChild &&
    logContainer.firstChild.classList &&
    logContainer.firstChild.classList.contains("log-entry")
  ) {
    logContainer.insertBefore(logEntry, logContainer.firstChild);
  } else {
    logContainer.appendChild(logEntry);
  }

  // Keep only last 50 entries
  while (logContainer.children.length > 50) {
    logContainer.removeChild(logContainer.lastChild);
  }
}

// Show Notification
function showNotification(message, type = "info") {
  const notification = document.createElement("div");
  notification.className = `notification ${type}`;
  notification.textContent = message;

  document.body.appendChild(notification);

  setTimeout(() => {
    notification.style.animation = "slideInRight 0.5s ease reverse";
    setTimeout(() => {
      document.body.removeChild(notification);
    }, 500);
  }, 3000);
}

// Format Time
function formatTime(minutes) {
  if (minutes < 60) {
    return `${Math.floor(minutes)} min`;
  } else {
    const hours = Math.floor(minutes / 60);
    const mins = Math.floor(minutes % 60);
    return `${hours}h ${mins}m`;
  }
}

// Toggle AI Mode
function toggleAIMode() {
  const aiModeToggle = document.getElementById("aiModeToggle");
  const aiModeLabel = document.getElementById("aiModeLabel");
  const aiModeDesc = document.getElementById("aiModeDesc");

  state.aiMode = aiModeToggle.checked;

  if (state.aiMode) {
    // AI Mode ON
    aiModeLabel.textContent = "التحكم الذكي (AI)";
    aiModeDesc.textContent = "الذكاء الاصطناعي يدير الري تلقائياً";

    // Hide all manual controls
    for (let i = 1; i <= 4; i++) {
      const controls = document.getElementById(`manualControls${i}`);
      if (controls) controls.style.display = "none";
    }

    addLog("AI", "🤖 تم تفعيل وضع التحكم الذكي", "success");
    showNotification(
      "AI Mode Enabled - Automated irrigation active",
      "success"
    );
  } else {
    // Manual Mode ON
    aiModeLabel.textContent = "التحكم اليدوي";
    aiModeDesc.textContent = "يمكنك التحكم بالصمامات يدوياً";

    // Show all manual controls
    for (let i = 1; i <= 4; i++) {
      const controls = document.getElementById(`manualControls${i}`);
      if (controls) controls.style.display = "flex";
    }

    // Close all valves when switching to manual
    state.areas.forEach((area) => {
      if (area.valveOpen) {
        closeValve(area.id);
      }
    });

    addLog("Manual", "👤 تم تفعيل وضع التحكم اليدوي", "warning");
    showNotification("Manual Mode Enabled - You control the valves", "warning");
  }
}

// Manual Valve Control
function manualValveControl(areaId, openValve) {
  if (state.aiMode) {
    showNotification(
      "Please disable AI mode first to use manual controls",
      "error"
    );
    return;
  }

  const area = state.areas.find((a) => a.id === areaId);
  if (!area) return;

  if (openValve) {
    // Open valve manually
    if (area.valveOpen) {
      showNotification(`Valve ${areaId} is already open`, "info");
      return;
    }

    // Open the valve
    area.valveOpen = true;
    area.isWatering = true;
    area.wateringStartTime = Date.now();

    updateValveVisual(areaId, true);
    addLog(`Manual-${areaId}`, `💧 فتح صمام ${area.name} يدوياً`, "info");
    showNotification(`Valve ${areaId} (${area.name}) opened manually`, "info");

    // Start a watering cycle (30 seconds = 30 minutes in simulation)
    area.manualWateringTimeout = setTimeout(() => {
      closeValve(areaId);
      showNotification(`Valve ${areaId} auto-closed after 30 min`, "info");
    }, 30000); // 30 seconds
  } else {
    // Close valve manually
    closeValve(areaId);
    addLog(`Manual-${areaId}`, `🚫 إغلاق صمام ${area.name} يدوياً`, "warning");
    showNotification(
      `Valve ${areaId} (${area.name}) closed manually`,
      "warning"
    );
  }

  updateDisplay();
}

// Close Valve Helper
function closeValve(areaId) {
  const area = state.areas.find((a) => a.id === areaId);
  if (!area) return;

  // Clear any manual timeout
  if (area.manualWateringTimeout) {
    clearTimeout(area.manualWateringTimeout);
    area.manualWateringTimeout = null;
  }

  // Close the valve
  area.valveOpen = false;
  area.isWatering = false;

  if (area.wateringStartTime) {
    const duration = (Date.now() - area.wateringStartTime) / 1000;
    const minutesWatered = Math.floor(duration / 60);
    area.minutesSinceLastWatering = 0;
    area.wateringStartTime = null;
  }

  updateValveVisual(areaId, false);
}

// Start Simulation (called when button is clicked)
function startSimulation() {
  console.log("🚀 Starting WiEmpower Simulation...");

  // Hide the overlay
  const overlay = document.getElementById("startOverlay");
  overlay.classList.add("hidden");

  // Remove overlay after animation
  setTimeout(() => {
    overlay.style.display = "none";
  }, 500);

  // Initialize the simulation
  init();

  // Verify timer is working
  console.log("⏱️ Timer initialized to:", state.nextDecisionTime, "seconds");
  console.log(
    "⏱️ Timer element exists:",
    document.getElementById("nextDecision") !== null
  );

  // Show success message
  setTimeout(() => {
    showNotification(
      "✅ Simulation started! First AI decision in 3 seconds",
      "success"
    );
  }, 1000);
}

// Initialize on load - just setup the start button
window.addEventListener("DOMContentLoaded", () => {
  console.log("🌱 WiEmpower Simulation Ready");

  // Setup start button
  const startButton = document.getElementById("startButton");
  if (startButton) {
    startButton.addEventListener("click", startSimulation);
  }

  // Update clock even before starting
  updateClock();
  setInterval(updateClock, 1000);
});

// Export for debugging
window.simulationState = state;
window.simulationConfig = CONFIG;

console.log("🌱 WiEmpower Simulation Script Loaded");
console.log("💡 Access state via: window.simulationState");
console.log("⚙️ Access config via: window.simulationConfig");
