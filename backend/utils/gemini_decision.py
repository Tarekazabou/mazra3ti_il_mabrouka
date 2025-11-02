"""
GEMINI LLM DECISION LAYER (Stage 2)
Takes XGBoost predictions + weather forecast → Final irrigation decision
Uses Google Gemini API for reasoning with weather context
"""

import os
import json
import google.generativeai as genai
from typing import Dict, List, Tuple
import joblib
import pandas as pd
import numpy as np
import time
from datetime import datetime


class GeminiIrrigationDecision:
    """
    Stage 2 decision maker using Gemini LLM
    Refines XGBoost predictions with weather forecasting intelligence
    """
    
    def __init__(self, api_key: str = None):
        """
        Initialize Gemini API
        
        Args:
            api_key: Google Gemini API key (if None, reads from GEMINI_API_KEY env var)
        """
        if api_key is None:
            api_key = os.getenv('GEMINI_API_KEY')
            if not api_key:
                raise ValueError("API key required. Set GEMINI_API_KEY environment variable or pass api_key parameter.")
        
        genai.configure(api_key=api_key)
        # Use gemini-2.0-flash - the stable available model
        self.model = genai.GenerativeModel('gemini-2.0-flash')
        
        # Rate limiting
        self.last_api_call = 0
        self.min_delay_seconds = 2  # Wait at least 2 seconds between calls
        
        # Load XGBoost models (from backend/models/)
        print("📦 Loading XGBoost models...")
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        models_dir = os.path.join(base_dir, 'models')
        
        self.model_should_water = joblib.load(os.path.join(models_dir, 'model_should_water.pkl'))
        self.model_duration = joblib.load(os.path.join(models_dir, 'model_duration.pkl'))
        self.model_intensity = joblib.load(os.path.join(models_dir, 'model_intensity.pkl'))
        self.duration_features = joblib.load(os.path.join(models_dir, 'duration_features.pkl'))
        
        # Load metadata
        metadata_path = os.path.join(base_dir, 'models_metadata.json')
        if os.path.exists(metadata_path):
            with open(metadata_path, 'r') as f:
                self.metadata = json.load(f)
        else:
            # Fallback metadata if file doesn't exist
            self.metadata = {'model_version': '1.0', 'training_date': 'unknown'}
        
        print("✅ Models loaded successfully!")
    
    def get_system_prompt(self) -> str:
        """
        Returns the system prompt for Gemini LLM
        This prompt controls the LLM's behavior and output format
        """
        return """You are an expert agricultural irrigation advisor AI specialized in precision irrigation for Tunisia's Mediterranean climate.

## YOUR ROLE
You receive:
1. **XGBoost Model Predictions** (Stage 1): Initial irrigation decision based on current sensor data and plant characteristics
2. **24-Hour Weather Forecast**: Hour-by-hour rain probability and precipitation amounts

Your task is to **refine** the XGBoost decision by considering weather forecasting to optimize water usage and plant health.

## PRIMARY GOALS (IN ORDER)
1. **Plant Health & Productivity** - Maintain optimal moisture for maximum yield
2. **Water Conservation** - Save water when possible WITHOUT compromising health
3. **Prevent Damage** - Avoid waterlogging and drought stress

**IMPORTANT**: The optimal moisture range is designed for MAXIMUM PRODUCTIVITY, not just survival. 
Plants at optimal moisture produce better yields, tastier fruit, and healthier growth.

## DECISION RULES

### When to OVERRIDE XGBoost "WATER" → "DO NOT WATER":
1. **Heavy rain expected very soon** (next 3-4 hours):
   - Rain probability > 80% AND expected precipitation > 15mm
   - Current moisture is not critically low (> 35%)
   - Rain timing allows plant to wait safely
   
2. **Guaranteed heavy rainfall** (next 6 hours):
   - Rain probability > 75% AND expected precipitation > 12mm
   - Current soil moisture > 40%
   - Watering would risk waterlogging

3. **Multiple rain events creating saturation risk**:
   - Total expected rainfall > 20mm in next 12 hours
   - Current moisture already > 50%
   - Clear waterlogging risk

**BE CAUTIOUS**: Rain forecasts are not 100% accurate. If current moisture is below optimal, 
prefer watering unless rain is VERY certain and VERY soon.

### When to OVERRIDE XGBoost "DO NOT WATER" → "WATER":
1. **Moisture below optimal range**:
   - Even with rain forecast, if moisture < optimal minimum
   - Rain is uncertain (< 60% probability) or delayed (> 8 hours)
   - Plant health requires immediate attention

2. **Critical moisture levels**:
   - Moisture < 30% regardless of rain forecast
   - Plant survival at risk
   - Rain forecast unreliable or too far away

3. **Productivity optimization**:
   - Moisture at low end of optimal range
   - Critical growth stage (flowering, fruiting)
   - No significant rain expected (< 5mm total)

### When to ADJUST DURATION:
1. **Reduce duration** if:
   - Moderate rain expected (5-10mm) in next 8 hours → reduce by 15-25%
   - Current moisture > 50% and light rain coming → reduce by 10-20%
   
2. **Increase duration** if:
   - Moisture well below optimal and no rain for 24+ hours → increase by 10-20%
   - High evapotranspiration conditions (hot, dry, windy) → increase by 10-15%
   - Deep-rooted plants with high water needs → maintain or increase

### When to ADJUST INTENSITY:
1. **Reduce intensity** if:
   - Soil compaction is high → prevent runoff
   - Steep slope → prevent erosion
   - Recent rain made soil soft → gentle watering
   
2. **Increase intensity** if:
   - Sandy soil with good drainage
   - Flat terrain
   - Need faster application due to timing constraints

## CRITICAL CONSTRAINTS
- Duration must be between 5-90 minutes (IF watering)
- Intensity must be between 20-100 percent (IF watering)
- **IMPORTANT**: If should_water is false, duration_minutes MUST be 0 and intensity_percent MUST be 0
- **IMPORTANT**: If should_water is true, duration_minutes MUST be 5-90 and intensity_percent MUST be 20-100
- ALWAYS provide reasoning for any override or significant adjustment
- Balance water conservation with plant health - **prioritize health when uncertain**
- Consider Tunisia's water scarcity BUT not at expense of crop productivity

## DECISION PHILOSOPHY
- **Optimal moisture = Maximum yield and quality** (not just survival)
- **Under-watering** → Reduced yields, poor fruit quality, stunted growth
- **Proper irrigation** → Healthy plants, good harvest, farmer income
- Rain forecasts are helpful but uncertain - don't risk plant health on uncertain rain
- When in doubt, **water for productivity** rather than risk under-irrigation

## OUTPUT FORMAT (STRICT JSON)
You must respond with ONLY valid JSON, no markdown formatting, no explanations outside JSON:

{
  "final_decision": {
    "should_water": <boolean>,
    "duration_minutes": <integer: 0 if should_water=false, 5-90 if should_water=true>,
    "intensity_percent": <integer: 0 if should_water=false, 20-100 if should_water=true>
  },
  "reasoning": {
    "xgboost_recommendation": "<summary of XGBoost prediction>",
    "weather_analysis": "<key weather insights from forecast>",
    "decision_rationale": "<why you made this final decision>",
    "adjustments_made": "<any changes from XGBoost prediction and why>",
    "confidence_level": "<high|medium|low>"
  },
  "water_savings": {
    "modified_from_xgboost": <boolean>,
    "estimated_water_saved_liters": <integer, 0 if no change or if watering>,
    "conservation_note": "<brief note on water conservation>"
  }
}

**CRITICAL**: When should_water is false, you MUST set duration_minutes=0 and intensity_percent=0. Do not provide watering parameters when not watering!

## RESPONSE REQUIREMENTS
1. **Always output valid JSON** - no markdown code blocks, no extra text
2. **Be concise** - reasoning should be 1-2 sentences per field
3. **Be decisive** - provide clear recommendations
4. **Prioritize productivity** - optimal moisture yields best crops
5. **Consider sustainability** - but not at cost of farmer's livelihood
6. **When uncertain about rain** - favor watering to ensure plant health

Remember: Farmers depend on good yields for their income. Under-watering costs more (in lost production) 
than moderate water use. Your goal is to make the smartest irrigation decision that ensures HEALTHY, 
PRODUCTIVE plants while being reasonably efficient with water."""

    def create_duration_features(self, data: Dict) -> pd.DataFrame:
        """
        Create enhanced features for duration model prediction
        Must match the feature engineering in training script
        
        Args:
            data: Dictionary with sensor and plant data
            
        Returns:
            DataFrame with all required features for duration model
        """
        # Start with base features
        X = pd.DataFrame([data])
        
        # Feature engineering (same as training)
        X['moisture_deficit'] = 100 - X['soil_moisture']
        X['water_stress'] = X['moisture_deficit'] * X['water_requirement_level']
        X['et_factor'] = (X['current_temperature'] / 25) * (1 + (100 - X['current_humidity']) / 100)
        X['root_moisture_need'] = X['root_depth_cm'] * X['moisture_deficit']
        X['watering_urgency'] = X['minutes_since_last_watering'] / 1440
        
        # Soil retention mapping
        soil_retention_map = {1: 0.5, 2: 1.0, 3: 1.5}
        X['soil_retention'] = X['soil_type_encoded'].map(soil_retention_map)
        
        X['drought_stress'] = X['drought_tolerance'] * X['moisture_deficit']
        X['optimal_time'] = ((X['hour_of_day'] >= 6) & (X['hour_of_day'] <= 10) | 
                            (X['hour_of_day'] >= 17) & (X['hour_of_day'] <= 21)).astype(int)
        
        # Seasonal demand
        season_demand = {1: 1.1, 2: 1.5, 3: 1.2, 4: 0.8}
        X['seasonal_demand'] = X['season'].map(season_demand)
        
        X['infiltration_factor'] = 100 - X['soil_compaction']
        X['runoff_risk'] = X['slope_degrees'] / 20
        
        # Return only the columns needed for duration model
        return X[self.duration_features]
    
    def get_xgboost_predictions(self, sensor_data: Dict) -> Dict:
        """
        Get predictions from all 3 XGBoost models
        
        Args:
            sensor_data: Dictionary containing all required features
            
        Returns:
            Dictionary with predictions from all models
        """
        # Prepare base features
        base_features = [
            'soil_moisture', 'current_temperature', 'current_humidity',
            'minutes_since_last_watering', 'water_requirement_level',
            'root_depth_cm', 'drought_tolerance', 'soil_type_encoded',
            'soil_compaction', 'slope_degrees', 'hour_of_day',
            'day_of_year', 'season'
        ]
        
        X_base = pd.DataFrame([sensor_data])[base_features]
        
        # Model 1: Should water (classification)
        should_water_pred = self.model_should_water.predict(X_base)[0]
        should_water_proba = self.model_should_water.predict_proba(X_base)[0][1]
        
        # Model 2 & 3: Only predict if should water
        if should_water_pred == 1:
            # Duration (enhanced features)
            X_duration = self.create_duration_features(sensor_data)
            duration_pred = self.model_duration.predict(X_duration)[0]
            duration_pred = int(np.clip(duration_pred, 5, 90))
            
            # Intensity (base features)
            intensity_pred = self.model_intensity.predict(X_base)[0]
            intensity_pred = int(np.clip(intensity_pred, 20, 100))
        else:
            duration_pred = 0
            intensity_pred = 0
        
        return {
            'should_water': bool(should_water_pred),
            'should_water_confidence': float(should_water_proba),
            'duration_minutes': duration_pred,
            'intensity_percent': intensity_pred
        }
    
    def format_weather_summary(self, 
                               rain_probability_24h: List[float], 
                               precipitation_mm_24h: List[float]) -> str:
        """
        Create human-readable weather summary for LLM
        
        Args:
            rain_probability_24h: List of 24 hourly rain probabilities (0-100)
            precipitation_mm_24h: List of 24 hourly precipitation amounts (mm)
            
        Returns:
            Formatted weather summary string
        """
        if len(rain_probability_24h) != 24 or len(precipitation_mm_24h) != 24:
            raise ValueError("Weather forecast must contain exactly 24 hourly values")
        
        # Summary statistics
        max_prob = max(rain_probability_24h)
        total_precip = sum(precipitation_mm_24h)
        high_prob_hours = sum(1 for p in rain_probability_24h if p > 60)
        
        # Find significant rain events
        rain_events = []
        for hour, (prob, precip) in enumerate(zip(rain_probability_24h, precipitation_mm_24h)):
            if prob > 40 and precip > 2:
                rain_events.append(f"Hour {hour}: {prob:.0f}% probability, {precip:.1f}mm")
        
        summary = f"""24-Hour Weather Forecast Summary:
- Maximum rain probability: {max_prob:.0f}%
- Total expected precipitation: {total_precip:.1f}mm
- Hours with >60% rain probability: {high_prob_hours}
- Significant rain events: {len(rain_events)}

Hourly Details (showing hours with >30% rain probability):"""
        
        for hour, (prob, precip) in enumerate(zip(rain_probability_24h, precipitation_mm_24h)):
            if prob > 30:
                summary += f"\n  • Hour {hour:2d}: {prob:5.1f}% chance, {precip:4.1f}mm expected"
        
        if not any(p > 30 for p in rain_probability_24h):
            summary += "\n  • No significant rain expected in next 24 hours"
        
        return summary
    
    def decide(self, 
               sensor_data: Dict,
               rain_probability_24h: List[float],
               precipitation_mm_24h: List[float]) -> Dict:
        """
        Make final irrigation decision using Gemini LLM
        
        Args:
            sensor_data: Dictionary with all sensor readings and plant features
            rain_probability_24h: List of 24 hourly rain probabilities (0-100)
            precipitation_mm_24h: List of 24 hourly precipitation amounts (mm)
            
        Returns:
            Dictionary with final decision and reasoning
        """
        print("\n" + "="*70)
        print("🧠 GEMINI LLM DECISION PROCESS")
        print("="*70)
        
        # Stage 1: XGBoost predictions
        print("\n📊 Stage 1: XGBoost Models")
        xgboost_pred = self.get_xgboost_predictions(sensor_data)
        print(f"   Should Water: {xgboost_pred['should_water']} (confidence: {xgboost_pred['should_water_confidence']:.2%})")
        print(f"   Duration: {xgboost_pred['duration_minutes']} minutes")
        print(f"   Intensity: {xgboost_pred['intensity_percent']}%")
        
        # Weather summary
        print("\n🌦️  Weather Forecast Analysis")
        weather_summary = self.format_weather_summary(rain_probability_24h, precipitation_mm_24h)
        print(weather_summary)
        
        # Prepare prompt for Gemini
        user_prompt = f"""## STAGE 1: XGBoost Model Predictions

**Should Water:** {xgboost_pred['should_water']}
**Confidence:** {xgboost_pred['should_water_confidence']:.1%}
**Recommended Duration:** {xgboost_pred['duration_minutes']} minutes
**Recommended Intensity:** {xgboost_pred['intensity_percent']}%

## Current Conditions

**Soil & Plant:**
- Soil Moisture: {sensor_data['soil_moisture']:.1f}%
- Temperature: {sensor_data['current_temperature']:.1f}°C
- Humidity: {sensor_data['current_humidity']:.1f}%
- Minutes Since Last Watering: {sensor_data['minutes_since_last_watering']}
- Water Requirement Level: {sensor_data['water_requirement_level']}
- Root Depth: {sensor_data['root_depth_cm']}cm
- Drought Tolerance: {sensor_data['drought_tolerance']}
- Soil Type: {sensor_data.get('soil_type', 'unknown')} (encoded: {sensor_data['soil_type_encoded']})
- Soil Compaction: {sensor_data['soil_compaction']:.1f}%
- Slope: {sensor_data['slope_degrees']:.1f}°

## {weather_summary}

## YOUR TASK

Analyze the XGBoost recommendation and weather forecast. Make your final irrigation decision considering:
1. Is rain expected that could replace or supplement irrigation?
2. Should duration/intensity be adjusted based on weather?
3. Will this decision conserve water while maintaining plant health?

Respond with ONLY valid JSON following the specified format."""

        # Call Gemini API
        print("\n🤖 Stage 2: Gemini LLM Reasoning...")
        
        # Rate limiting - wait if needed
        time_since_last_call = time.time() - self.last_api_call
        if time_since_last_call < self.min_delay_seconds:
            wait_time = self.min_delay_seconds - time_since_last_call
            print(f"   ⏳ Rate limiting: waiting {wait_time:.1f}s...")
            time.sleep(wait_time)
        
        try:
            self.last_api_call = time.time()
            
            response = self.model.generate_content(
                [self.get_system_prompt(), user_prompt],
                generation_config=genai.types.GenerationConfig(
                    temperature=0.3,  # Low temperature for consistent decisions
                    top_p=0.8,
                    top_k=40,
                    max_output_tokens=1024,
                )
            )
            
            # Parse JSON response
            response_text = response.text.strip()
            
            # Remove markdown code blocks if present
            if response_text.startswith('```json'):
                response_text = response_text.split('```json')[1].split('```')[0].strip()
            elif response_text.startswith('```'):
                response_text = response_text.split('```')[1].split('```')[0].strip()
            
            final_decision = json.loads(response_text)
            
            # Validate decision
            self._validate_decision(final_decision)
            
            # Add metadata
            final_decision['metadata'] = {
                'xgboost_prediction': xgboost_pred,
                'weather_total_precip_24h': sum(precipitation_mm_24h),
                'weather_max_rain_prob': max(rain_probability_24h),
                'model_version': self.metadata['model_version'],
                'timestamp': pd.Timestamp.now().isoformat()
            }
            
            print("\n✅ Final Decision Generated!")
            print(f"   Water: {final_decision['final_decision']['should_water']}")
            print(f"   Duration: {final_decision['final_decision']['duration_minutes']} min")
            print(f"   Intensity: {final_decision['final_decision']['intensity_percent']}%")
            print(f"   Confidence: {final_decision['reasoning']['confidence_level']}")
            
            return final_decision
            
        except Exception as e:
            error_msg = str(e)
            
            # Check if it's a rate limit error
            if "429" in error_msg or "Quota exceeded" in error_msg or "RATE_LIMIT" in error_msg:
                print(f"\n⚠️  API Rate Limit Exceeded!")
                print(f"   The free Gemini API has limited requests per minute.")
                print(f"   Falling back to XGBoost-only decision...\n")
                
                # Return XGBoost decision with fallback note
                return self._create_fallback_decision(xgboost_pred, sensor_data, 
                                                     rain_probability_24h, precipitation_mm_24h,
                                                     "API rate limit exceeded")
            
            elif "JSON" in error_msg or "parse" in error_msg:
                print(f"❌ Error: Failed to parse LLM response as JSON")
                try:
                    print(f"   Response preview: {response_text[:200]}...")
                except:
                    pass
                raise Exception(f"Invalid JSON from LLM: {e}")
            
            else:
                print(f"❌ Error in Gemini API call: {e}")
                print(f"   Falling back to XGBoost-only decision...\n")
                return self._create_fallback_decision(xgboost_pred, sensor_data,
                                                     rain_probability_24h, precipitation_mm_24h,
                                                     str(e))
    
    def _validate_decision(self, decision: Dict):
        """Validate the LLM decision meets all constraints"""
        required_keys = ['final_decision', 'reasoning', 'water_savings']
        for key in required_keys:
            if key not in decision:
                raise ValueError(f"Missing required key in LLM response: {key}")
        
        fd = decision['final_decision']
        
        # Type checks
        if not isinstance(fd['should_water'], bool):
            raise ValueError("should_water must be boolean")
        
        # Critical rule: If not watering, duration and intensity MUST be 0
        if not fd['should_water']:
            if fd['duration_minutes'] != 0:
                print(f"   ⚠️  Correcting: should_water=false but duration={fd['duration_minutes']}, setting to 0")
                fd['duration_minutes'] = 0
            if fd['intensity_percent'] != 0:
                print(f"   ⚠️  Correcting: should_water=false but intensity={fd['intensity_percent']}, setting to 0")
                fd['intensity_percent'] = 0
        
        # If watering, validate ranges
        if fd['should_water']:
            if not (5 <= fd['duration_minutes'] <= 90):
                raise ValueError(f"duration_minutes must be 5-90 when watering, got {fd['duration_minutes']}")
            
            if not (20 <= fd['intensity_percent'] <= 100):
                raise ValueError(f"intensity_percent must be 20-100 when watering, got {fd['intensity_percent']}")
        
        print("   ✓ Decision validation passed")
    
    def _create_fallback_decision(self, xgboost_pred: Dict, sensor_data: Dict,
                                  rain_probability_24h: List[float],
                                  precipitation_mm_24h: List[float],
                                  error_reason: str) -> Dict:
        """
        Create a fallback decision using XGBoost only when LLM fails
        Applies simple weather-based rules
        
        Args:
            xgboost_pred: XGBoost model predictions
            sensor_data: Sensor readings
            rain_probability_24h: Rain probability forecast
            precipitation_mm_24h: Precipitation forecast
            error_reason: Why we're falling back
            
        Returns:
            Decision in same format as LLM decision
        """
        print("🔄 Creating rule-based fallback decision...")
        
        # Start with XGBoost recommendation
        should_water = xgboost_pred['should_water']
        duration = xgboost_pred['duration_minutes']
        intensity = xgboost_pred['intensity_percent']
        
        # Simple weather-based adjustments
        total_rain_24h = sum(precipitation_mm_24h)
        max_rain_prob = max(rain_probability_24h)
        heavy_rain_soon = any(p > 70 and precipitation_mm_24h[i] > 8 
                              for i, p in enumerate(rain_probability_24h[:6]))
        
        adjustments = []
        
        # Rule 1: Don't water if heavy rain coming soon
        if should_water and heavy_rain_soon:
            should_water = False
            adjustments.append("Cancelled watering due to heavy rain expected within 6 hours")
        
        # Rule 2: Reduce duration if moderate rain expected
        elif should_water and total_rain_24h > 10 and max_rain_prob > 50:
            reduction = 0.25  # 25% reduction
            duration = int(duration * (1 - reduction))
            duration = max(5, duration)  # At least 5 minutes
            adjustments.append(f"Reduced duration by 25% due to {total_rain_24h:.1f}mm rain expected")
        
        # Rule 3: Check critical moisture override
        if not should_water and sensor_data['soil_moisture'] < 25:
            # Even with rain, if critically dry, water anyway
            if max_rain_prob < 80 or total_rain_24h < 15:
                should_water = True
                duration = max(duration, 20)
                intensity = max(intensity, 50)
                adjustments.append("Override: Critical soil moisture requires immediate watering")
        
        # Create decision structure
        fallback_decision = {
            "final_decision": {
                "should_water": should_water,
                "duration_minutes": duration if should_water else 0,
                "intensity_percent": intensity if should_water else 0
            },
            "reasoning": {
                "xgboost_recommendation": f"XGBoost: {'Water' if xgboost_pred['should_water'] else 'No water'} "
                                        f"({xgboost_pred['duration_minutes']}min, {xgboost_pred['intensity_percent']}%)",
                "weather_analysis": f"24h forecast: {total_rain_24h:.1f}mm total, {max_rain_prob:.0f}% max probability",
                "decision_rationale": " | ".join(adjustments) if adjustments else "Using XGBoost recommendation as-is",
                "adjustments_made": " | ".join(adjustments) if adjustments else "None",
                "confidence_level": "medium",
                "fallback_mode": True,
                "fallback_reason": error_reason
            },
            "water_savings": {
                "modified_from_xgboost": len(adjustments) > 0,
                "estimated_water_saved_liters": 0,
                "conservation_note": "Fallback mode: Simple rule-based adjustments"
            },
            "metadata": {
                "xgboost_prediction": xgboost_pred,
                "weather_total_precip_24h": total_rain_24h,
                "weather_max_rain_prob": max_rain_prob,
                "model_version": self.metadata['model_version'],
                "timestamp": pd.Timestamp.now().isoformat(),
                "fallback_mode": True
            }
        }
        
        print(f"   ✓ Fallback decision: {'Water' if should_water else 'Skip'} "
              f"({duration}min, {intensity}%)")
        
        return fallback_decision


def main():
    """Example usage"""
    print("="*70)
    print("GEMINI IRRIGATION DECISION SYSTEM - EXAMPLE")
    print("="*70)
    
    # Initialize (requires GEMINI_API_KEY environment variable)
    # To set: export GEMINI_API_KEY="your-api-key-here" (Linux/Mac)
    #         set GEMINI_API_KEY=your-api-key-here (Windows CMD)
    try:
        decision_maker = GeminiIrrigationDecision()
    except ValueError as e:
        print(f"\n❌ {e}")
        print("\nPlease set your Gemini API key:")
        print("   Windows CMD: set GEMINI_API_KEY=your-api-key")
        print("   PowerShell:  $env:GEMINI_API_KEY='your-api-key'")
        print("   Linux/Mac:   export GEMINI_API_KEY='your-api-key'")
        return
    
    # Example sensor data
    sensor_data = {
        'soil_moisture': 35.5,
        'current_temperature': 28.3,
        'current_humidity': 45.2,
        'minutes_since_last_watering': 720,  # 12 hours
        'water_requirement_level': 3,
        'root_depth_cm': 50,
        'drought_tolerance': 2,
        'soil_type_encoded': 2,  # loam
        'soil_type': 'loam',
        'soil_compaction': 55.0,
        'slope_degrees': 3.5,
        'hour_of_day': 18,  # 6 PM
        'day_of_year': 180,
        'season': 2  # summer
    }
    
    # Example weather forecast
    # Scenario: Light rain expected in 6-8 hours
    rain_probability_24h = [
        10, 15, 10, 5, 10, 15,    # Hours 0-5: low probability
        45, 60, 75, 70, 50, 30,   # Hours 6-11: rain event
        20, 15, 10, 10, 5, 5,     # Hours 12-17: clearing
        5, 10, 5, 5, 10, 10       # Hours 18-23: dry
    ]
    
    precipitation_mm_24h = [
        0, 0, 0, 0, 0, 0.5,
        2, 4, 6, 5, 3, 1.5,
        0.5, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0
    ]
    
    # Make decision
    final_decision = decision_maker.decide(
        sensor_data,
        rain_probability_24h,
        precipitation_mm_24h
    )
    
    # Display results
    print("\n" + "="*70)
    print("📋 FINAL DECISION DETAILS")
    print("="*70)
    print(json.dumps(final_decision, indent=2))
    
    print("\n" + "="*70)
    print("✅ DECISION READY FOR MICROCONTROLLER")
    print("="*70)
    print(f"Water: {final_decision['final_decision']['should_water']}")
    print(f"Duration: {final_decision['final_decision']['duration_minutes']} minutes")
    print(f"Intensity: {final_decision['final_decision']['intensity_percent']}%")


if __name__ == "__main__":
    main()
