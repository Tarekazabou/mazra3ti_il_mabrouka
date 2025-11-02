"""
Test the AI decision endpoint to verify it's working
"""
import requests
import json

print("="*70)
print("🧪 TESTING AI DECISION ENDPOINT")
print("="*70)

# Test with Fatma's data (from the logs)
user_id = "fatma_b377be09"
base_url = "http://localhost:5000"

# Prepare request body
request_data = {
    "plant_name": "barley",
    "soil_moisture": 45.5,  # Example value
    "sensor_temperature": 28.3,
    "sensor_humidity": 52.1
}

print(f"\n📤 Sending POST request to:")
print(f"   {base_url}/api/farmer/{user_id}/decision")
print(f"\n📋 Request body:")
print(f"   {json.dumps(request_data, indent=2)}")
print()

try:
    response = requests.post(
        f"{base_url}/api/farmer/{user_id}/decision",
        json=request_data,
        timeout=60  # 60 second timeout for Gemini API
    )
    
    print(f"📥 Response Status: {response.status_code}")
    print()
    
    if response.status_code == 200:
        result = response.json()
        print("✅ SUCCESS! AI Decision received:")
        print(json.dumps(result, indent=2))
        print()
        print("="*70)
        print("🎉 The endpoint is working correctly!")
        print("="*70)
    else:
        print(f"❌ ERROR: Status code {response.status_code}")
        print(f"Response: {response.text}")
        print()
        print("="*70)
        print("⚠️  The endpoint returned an error")
        print("="*70)
        
except requests.exceptions.ConnectionError:
    print("❌ CONNECTION ERROR")
    print("   Backend server is not running at http://localhost:5000")
    print("   Please start the backend with: python app.py")
    print("="*70)
    
except requests.exceptions.Timeout:
    print("⏱️  TIMEOUT ERROR")
    print("   The request took too long (>60 seconds)")
    print("   This might be due to Gemini API being slow or rate limited")
    print("="*70)
    
except Exception as e:
    print(f"❌ UNEXPECTED ERROR: {e}")
    print("="*70)
