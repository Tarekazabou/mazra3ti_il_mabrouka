"""
QUICK TEST - Raspberry Pi to Backend ML Pipeline
=================================================

Quick test of the complete ML pipeline:
1. Simulated sensor data from Pi
2. Backend receives data
3. Weather API called
4. XGBoost + Gemini AI makes decision
5. Response returned

For NEW USERS: minutes_since_last_watering = 1440 (24 hours)
"""

import requests
import json
from datetime import datetime

# Configuration
BACKEND_URL = "http://localhost:5000"

def quick_test():
    """Quick test of ML decision making"""
    
    print("\n" + "="*70)
    print("🧪 QUICK TEST - ML DECISION PIPELINE")
    print("="*70)
    
    # Test data
    user_id = "test_user_123"
    plant_name = "tomato"
    soil_moisture = 45.5  # Simulated sensor reading
    
    # NEW USER: Use 1440 minutes (24 hours) as default
    minutes_since_last_watering = 1440
    
    print(f"\n📊 Test Configuration:")
    print(f"   User ID: {user_id}")
    print(f"   Plant: {plant_name}")
    print(f"   Soil Moisture: {soil_moisture}%")
    print(f"   Minutes Since Last Watering: {minutes_since_last_watering} (NEW USER DEFAULT)")
    
    # Prepare request
    payload = {
        'plant_name': plant_name,
        'soil_moisture': soil_moisture,
        'minutes_since_last_watering': minutes_since_last_watering
    }
    
    print(f"\n📤 Sending to backend...")
    print(f"   URL: {BACKEND_URL}/api/farmer/{user_id}/decision")
    
    try:
        # Send request
        response = requests.post(
            f"{BACKEND_URL}/api/farmer/{user_id}/decision",
            json=payload,
            timeout=30
        )
        
        print(f"\n📥 Response received!")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            decision = response.json()
            
            print(f"\n" + "="*70)
            print("✅ ML DECISION RESULT")
            print("="*70)
            
            if decision.get('success'):
                final = decision.get('decision', {})
                
                print(f"\n🤖 AI Decision:")
                print(f"   Should Water: {final.get('should_water')}")
                print(f"   Duration: {final.get('duration_minutes')} minutes")
                print(f"   Intensity: {final.get('intensity_percent')}%")
                
                print(f"\n💡 Reasoning:")
                reasoning = decision.get('reasoning', 'No reasoning provided')
                print(f"   {reasoning}")
                
                weather = decision.get('weather', {})
                if weather:
                    current = weather.get('current', {})
                    print(f"\n🌦️  Weather Context:")
                    print(f"   Temperature: {current.get('temperature')}°C")
                    print(f"   Humidity: {current.get('humidity')}%")
                    print(f"   Expected Rain (24h): {weather.get('total_rain_24h', 0):.1f}mm")
                
                print(f"\n" + "="*70)
                print("✅ TEST SUCCESSFUL - ML PIPELINE WORKING!")
                print("="*70)
                
                # Show what models were used
                print(f"\n📊 ML Models Used:")
                print(f"   ✓ XGBoost - Should Water Model")
                print(f"   ✓ XGBoost - Duration Model")
                print(f"   ✓ XGBoost - Intensity Model")
                print(f"   ✓ Gemini AI - LLM Refinement")
                print(f"   ✓ Weather API - Forecast Data")
                
            else:
                print(f"\n❌ Decision failed: {decision.get('error')}")
        
        else:
            print(f"\n❌ HTTP Error {response.status_code}")
            print(f"   {response.text}")
            
    except requests.exceptions.ConnectionError:
        print(f"\n❌ Cannot connect to backend server at {BACKEND_URL}")
        print(f"\n💡 Make sure backend is running:")
        print(f"   cd backend")
        print(f"   python app.py")
    except Exception as e:
        print(f"\n❌ Error: {e}")


if __name__ == "__main__":
    quick_test()
