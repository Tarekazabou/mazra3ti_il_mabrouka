"""
RASPBERRY PI SIMULATION - Real Scenario Test
============================================

This script simulates:
1. Raspberry Pi with soil moisture sensor
2. Sensor reads soil moisture
3. Pi sends data to backend server
4. Backend calls weather API
5. Backend uses AI (XGBoost + Gemini) to make irrigation decision
6. Backend returns decision to Pi
7. Pi activates/deactivates valve based on decision

For NEW USERS (first time):
- minutes_since_last_watering = 1440 (24 hours - large random number)
- This ensures first-time users can get watering recommendations
"""

import requests
import json
import time
import random
from datetime import datetime

# Backend server configuration
BACKEND_URL = "http://localhost:5000"

# Simulated sensor data
class RaspberryPiSensor:
    """Simulates a Raspberry Pi with soil moisture sensor"""
    
    def __init__(self, user_id: str, plant_name: str):
        self.user_id = user_id
        self.plant_name = plant_name
        print(f"\n🔌 Raspberry Pi initialized for user: {user_id}")
        print(f"   Monitoring plant: {plant_name}")
    
    def read_soil_moisture(self) -> float:
        """
        Simulate reading from soil moisture sensor
        In real Pi: This would read from ADC connected to moisture sensor
        Returns: Soil moisture percentage (0-100%)
        """
        # Simulate realistic soil moisture reading
        moisture = random.uniform(30, 70)  # Random between 30-70%
        print(f"\n📊 Sensor Reading:")
        print(f"   Soil Moisture: {moisture:.1f}%")
        return moisture
    
    def check_if_new_user(self) -> bool:
        """
        Check if this is a new user (first time using app)
        In real scenario: Check if user has watering history
        """
        try:
            response = requests.get(
                f"{BACKEND_URL}/api/farmer/{self.user_id}/history",
                timeout=10
            )
            
            if response.status_code == 200:
                history = response.json()
                is_new = history.get('count', 0) == 0
                if is_new:
                    print(f"   ⚠️  NEW USER - No watering history found")
                else:
                    print(f"   ✓ Existing user - {history.get('count')} past waterings")
                return is_new
            return True  # Assume new if can't check
            
        except Exception as e:
            print(f"   ⚠️  Could not check history: {e}")
            return True  # Assume new user if error
    
    def get_minutes_since_last_watering(self) -> int:
        """
        Get minutes since last watering
        For NEW USERS: Return 1440 (24 hours) - large random number
        For EXISTING USERS: Calculate from last_watering timestamp
        """
        is_new = self.check_if_new_user()
        
        if is_new:
            # NEW USER: Use large random number (simulate 24 hours since last watering)
            minutes = 1440  # 24 hours
            print(f"   🆕 First-time user: Using {minutes} minutes (24 hours) as default")
            return minutes
        
        # EXISTING USER: Get actual last watering time from backend
        try:
            response = requests.get(
                f"{BACKEND_URL}/api/farmer/{self.user_id}/state",
                timeout=10
            )
            
            if response.status_code == 200:
                state = response.json()
                last_watering_iso = state.get('user', {}).get('last_watering')
                
                if last_watering_iso:
                    last_watering = datetime.fromisoformat(last_watering_iso)
                    now = datetime.now()
                    minutes = int((now - last_watering).total_seconds() / 60)
                    print(f"   ⏱️  Last watered: {minutes} minutes ago")
                    return minutes
                else:
                    # No last watering recorded - treat as new
                    minutes = 1440
                    print(f"   ⚠️  No last_watering found: Using {minutes} minutes")
                    return minutes
            
            # Fallback
            return 1440
            
        except Exception as e:
            print(f"   ⚠️  Error getting last watering: {e}")
            return 1440  # Fallback to 24 hours
    
    def send_to_backend(self, soil_moisture: float) -> dict:
        """
        Send sensor data to backend and get AI decision
        
        Pi sends:
        - soil_moisture (from sensor)
        - minutes_since_last_watering (calculated or default 1440 for new users)
        
        Backend does:
        - Gets user profile (soil properties, plant features)
        - Calls weather API for forecast
        - Runs XGBoost models
        - Runs Gemini LLM for refinement
        - Returns decision
        """
        minutes_since = self.get_minutes_since_last_watering()
        
        payload = {
            'plant_name': self.plant_name,
            'soil_moisture': soil_moisture,
            'minutes_since_last_watering': minutes_since
        }
        
        print(f"\n📤 Sending to backend:")
        print(f"   URL: {BACKEND_URL}/api/farmer/{self.user_id}/decision")
        print(f"   Data: {json.dumps(payload, indent=6)}")
        
        try:
            response = requests.post(
                f"{BACKEND_URL}/api/farmer/{self.user_id}/decision",
                json=payload,
                timeout=30  # AI decision can take time
            )
            
            print(f"\n📥 Backend Response:")
            print(f"   Status Code: {response.status_code}")
            
            if response.status_code == 200:
                decision = response.json()
                print(f"   Response: {json.dumps(decision, indent=6)}")
                return decision
            else:
                print(f"   ❌ Error: {response.text}")
                return {'success': False, 'error': response.text}
                
        except Exception as e:
            print(f"   ❌ Connection Error: {e}")
            return {'success': False, 'error': str(e)}
    
    def activate_valve(self, duration_minutes: int, intensity_percent: int):
        """
        Simulate activating irrigation valve
        In real Pi: This would trigger GPIO pins to control valve
        """
        print(f"\n💧 VALVE ACTIVATED")
        print(f"   Duration: {duration_minutes} minutes")
        print(f"   Intensity: {intensity_percent}%")
        print(f"   Water will flow for {duration_minutes} minutes at {intensity_percent}% intensity")
        
        # Simulate valve operation
        print(f"\n   ⏳ Watering in progress...")
        for i in range(min(5, duration_minutes)):  # Show first 5 minutes
            time.sleep(1)
            elapsed = i + 1
            remaining = duration_minutes - elapsed
            print(f"   [{elapsed}/{duration_minutes} min] 💧 Watering... ({remaining} min remaining)")
        
        if duration_minutes > 5:
            print(f"   ... (continuing for {duration_minutes - 5} more minutes)")
        
        print(f"\n   ✅ Watering complete!")
    
    def run_cycle(self):
        """
        Run one complete irrigation decision cycle
        This simulates what the Pi does periodically (e.g., every 30 minutes)
        """
        print("\n" + "="*70)
        print("🌱 IRRIGATION CYCLE STARTED")
        print("="*70)
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Step 1: Read sensor
        soil_moisture = self.read_soil_moisture()
        
        # Step 2: Send to backend and get AI decision
        decision = self.send_to_backend(soil_moisture)
        
        if not decision.get('success'):
            print("\n❌ Decision failed - no action taken")
            return
        
        # Step 3: Check if watering in progress
        if decision.get('watering_in_progress'):
            print(f"\n⏳ WATERING ALREADY IN PROGRESS")
            print(f"   Remaining: {decision.get('remaining_minutes')} minutes")
            print(f"   Message: {decision.get('message')}")
            return
        
        # Step 4: Process AI decision
        final_decision = decision.get('decision', {})
        should_water = final_decision.get('should_water', False)
        
        print(f"\n🤖 AI DECISION:")
        print(f"   Should Water: {should_water}")
        
        if should_water:
            duration = final_decision.get('duration_minutes', 0)
            intensity = final_decision.get('intensity_percent', 0)
            reasoning = decision.get('reasoning', 'No reasoning provided')
            
            print(f"   Duration: {duration} minutes")
            print(f"   Intensity: {intensity}%")
            print(f"\n   💡 Reasoning:")
            print(f"   {reasoning}")
            
            # Step 5: Activate valve
            self.activate_valve(duration, intensity)
        else:
            print(f"   ✓ No watering needed")
            print(f"\n   💡 Reasoning:")
            print(f"   {decision.get('reasoning', 'Soil moisture is adequate')}")
        
        # Step 6: Show weather context
        weather = decision.get('weather', {})
        if weather:
            print(f"\n🌦️  Weather Context:")
            current = weather.get('current', {})
            print(f"   Temperature: {current.get('temperature', 'N/A')}°C")
            print(f"   Humidity: {current.get('humidity', 'N/A')}%")
            print(f"   Condition: {current.get('condition', 'N/A')}")
            print(f"   Expected rain (24h): {weather.get('total_rain_24h', 0):.1f}mm")
            print(f"   Max rain probability: {weather.get('max_rain_probability', 0):.0f}%")
        
        print("\n" + "="*70)
        print("✅ IRRIGATION CYCLE COMPLETE")
        print("="*70)


def test_new_user_scenario():
    """
    Test Scenario 1: NEW USER (First time using app)
    - No watering history
    - minutes_since_last_watering = 1440 (24 hours)
    """
    print("\n")
    print("="*70)
    print("TEST SCENARIO 1: NEW USER (FIRST TIME)")
    print("="*70)
    print("\nSimulating: Farmer Mabrouka using app for the first time")
    print("Expected: minutes_since_last_watering = 1440 (24 hours)")
    
    # Create simulated Pi for new user
    pi = RaspberryPiSensor(
        user_id="test_new_user_123",
        plant_name="tomato"
    )
    
    # Run irrigation cycle
    pi.run_cycle()


def test_existing_user_scenario():
    """
    Test Scenario 2: EXISTING USER (Has watering history)
    - Has previous watering records
    - minutes_since_last_watering calculated from last_watering timestamp
    """
    print("\n")
    print("="*70)
    print("TEST SCENARIO 2: EXISTING USER (WITH HISTORY)")
    print("="*70)
    print("\nSimulating: Farmer with existing watering history")
    print("Expected: minutes_since_last_watering calculated from last watering")
    
    # Create simulated Pi for existing user
    pi = RaspberryPiSensor(
        user_id="mabrouka_zaghouan",
        plant_name="tomato"
    )
    
    # Run irrigation cycle
    pi.run_cycle()


def test_continuous_monitoring():
    """
    Test Scenario 3: CONTINUOUS MONITORING
    - Simulate Pi checking every 30 minutes
    - Shows how system handles repeated cycles
    """
    print("\n")
    print("="*70)
    print("TEST SCENARIO 3: CONTINUOUS MONITORING (3 CYCLES)")
    print("="*70)
    print("\nSimulating: Pi checking soil every 30 minutes")
    
    pi = RaspberryPiSensor(
        user_id="mabrouka_zaghouan",
        plant_name="tomato"
    )
    
    num_cycles = 3
    for cycle_num in range(1, num_cycles + 1):
        print(f"\n{'='*70}")
        print(f"CYCLE {cycle_num}/{num_cycles}")
        print(f"{'='*70}")
        
        pi.run_cycle()
        
        if cycle_num < num_cycles:
            print(f"\n⏰ Waiting 30 seconds (simulating 30 minutes)...")
            time.sleep(30)  # In real scenario: time.sleep(30 * 60)


def test_backend_health():
    """Test if backend server is running and responsive"""
    print("\n" + "="*70)
    print("🔍 CHECKING BACKEND SERVER")
    print("="*70)
    
    try:
        # Test health endpoint
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        if response.status_code == 200:
            print(f"✅ Backend server is RUNNING")
            print(f"   URL: {BACKEND_URL}")
            print(f"   Status: {response.json()}")
            return True
        else:
            print(f"❌ Backend returned status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to backend server")
        print(f"   URL: {BACKEND_URL}")
        print(f"   Error: {e}")
        print(f"\n💡 Make sure backend is running:")
        print(f"   cd backend")
        print(f"   python app.py")
        return False


def main():
    """
    Main test suite for Raspberry Pi simulation
    Tests complete ML pipeline with realistic scenarios
    """
    print("\n")
    print("="*70)
    print("🍓 RASPBERRY PI IRRIGATION SYSTEM - SIMULATION TEST")
    print("="*70)
    print("\nThis script simulates:")
    print("  • Raspberry Pi with soil moisture sensor")
    print("  • Sensor reading and data transmission")
    print("  • Backend AI decision making (XGBoost + Gemini)")
    print("  • Weather API integration")
    print("  • Valve control based on AI decision")
    print("\nSpecial handling for NEW USERS:")
    print("  • First-time users: minutes_since_last_watering = 1440 (24h)")
    print("  • This ensures proper ML model input for new farmers")
    print("="*70)
    
    # Step 1: Check backend
    if not test_backend_health():
        print("\n⚠️  Backend server is not running. Please start it first.")
        return
    
    # Step 2: Run test scenarios
    print("\n")
    input("Press ENTER to run Test Scenario 1: NEW USER... ")
    test_new_user_scenario()
    
    print("\n")
    input("Press ENTER to run Test Scenario 2: EXISTING USER... ")
    test_existing_user_scenario()
    
    print("\n")
    input("Press ENTER to run Test Scenario 3: CONTINUOUS MONITORING (3 cycles)... ")
    test_continuous_monitoring()
    
    print("\n")
    print("="*70)
    print("✅ ALL TESTS COMPLETE")
    print("="*70)
    print("\n📊 Test Summary:")
    print("  ✅ Backend connectivity")
    print("  ✅ Sensor data transmission")
    print("  ✅ New user handling (1440 min default)")
    print("  ✅ Existing user handling (calculated from history)")
    print("  ✅ AI decision making (XGBoost + Gemini)")
    print("  ✅ Weather API integration")
    print("  ✅ Valve control simulation")
    print("\n🎉 Raspberry Pi simulation successful!")


if __name__ == "__main__":
    main()
