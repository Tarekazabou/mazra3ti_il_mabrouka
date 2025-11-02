"""
WEATHER FORECAST MODULE
Uses WeatherAPI.com to get current weather and 24-hour forecast for Tunisia
"""

import requests
import json
from datetime import datetime, timedelta
import os

# WeatherAPI.com API key
API_KEY = os.environ.get('WEATHER_API_KEY', '2df98185da8e47e8940212529250111')
DEFAULT_LOCATION = 'Zaghouan'


def get_weather_forecast(location=DEFAULT_LOCATION):
    """
    Get weather forecast for next 24 hours
    
    Args:
        location: City name or coordinates (e.g., "Tunis" or "36.8065,10.1815")
        
    Returns:
        Dictionary with:
        - success: bool
        - current: {temperature, humidity, condition}
        - hourly_rain_probability: list of 24 floats (0-100%)
        - hourly_precipitation_mm: list of 24 floats (mm)
        - total_rainfall_24h: float (mm)
    """
    try:
        url = f"https://api.weatherapi.com/v1/forecast.json?key={API_KEY}&q={location}&days=2&aqi=no"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Extract current weather
        current = data['current']
        current_weather = {
            'temperature': current['temp_c'],
            'humidity': current['humidity'],
            'condition': current['condition']['text'],
            'wind_kph': current.get('wind_kph', 0),
            'feels_like': current.get('feelslike_c', current['temp_c'])
        }
        
        # Get current time from API
        current_time = datetime.strptime(data["location"]["localtime"], "%Y-%m-%d %H:%M")
        
        # Extract hourly forecast for next 24 hours
        hourly_rain_probability = []
        hourly_precipitation_mm = []
        
        for day in data["forecast"]["forecastday"]:
            for hour in day["hour"]:
                hour_time = datetime.strptime(hour["time"], "%Y-%m-%d %H:%M")
                if current_time <= hour_time < current_time + timedelta(hours=24):
                    # Rain probability (0-100%)
                    hourly_rain_probability.append(float(hour["chance_of_rain"]))
                    # Precipitation in mm
                    hourly_precipitation_mm.append(float(hour["precip_mm"]))
        
        # Ensure we have exactly 24 hours (pad with zeros if needed)
        while len(hourly_rain_probability) < 24:
            hourly_rain_probability.append(0.0)
            hourly_precipitation_mm.append(0.0)
        
        # Truncate to 24 hours if we have more
        hourly_rain_probability = hourly_rain_probability[:24]
        hourly_precipitation_mm = hourly_precipitation_mm[:24]
        
        # Calculate total rainfall
        total_rainfall_24h = sum(hourly_precipitation_mm)
        
        return {
            'success': True,
            'location': location,
            'current': current_weather,
            'hourly_rain_probability': hourly_rain_probability,
            'hourly_precipitation_mm': hourly_precipitation_mm,
            'total_rainfall_24h': total_rainfall_24h,
            'timestamp': datetime.now().isoformat()
        }
        
    except requests.exceptions.RequestException as e:
        print(f"Error fetching weather data: {e}")
        return {
            'success': False,
            'error': str(e),
            'message': 'Failed to fetch weather forecast'
        }
    except Exception as e:
        print(f"Error processing weather data: {e}")
        return {
            'success': False,
            'error': str(e),
            'message': 'Error processing weather data'
        }


def get_weather_json(location=DEFAULT_LOCATION):
    """
    Legacy function for backward compatibility
    Returns JSON string instead of dictionary
    """
    result = get_weather_forecast(location)
    
    if result['success']:
        legacy_format = {
            "Temperature": f"{result['current']['temperature']}°C",
            "Humidity": f"{result['current']['humidity']}%",
            "Hourly forecast (chance of rain)": result['hourly_rain_probability'],
            "Total rainfall (24h)": result['hourly_precipitation_mm']
        }
        return json.dumps(legacy_format, ensure_ascii=False)
    else:
        return json.dumps({"error": result.get('error', 'Unknown error')})


def get_simple_forecast_summary(location=DEFAULT_LOCATION):
    """
    Get simple weather summary (for testing/debugging)
    
    Returns:
        Human-readable weather summary
    """
    weather = get_weather_forecast(location)
    
    if not weather['success']:
        return f"❌ Failed to get weather: {weather.get('error', 'Unknown error')}"
    
    summary = f"""
    📍 Location: {location}
    🌡️ Temperature: {weather['current']['temperature']}°C
    💧 Humidity: {weather['current']['humidity']}%
    ☁️ Condition: {weather['current']['condition']}
    
    Next 24 hours:
    🌧️ Total rainfall: {weather['total_rainfall_24h']:.1f}mm
    📊 Max rain probability: {max(weather['hourly_rain_probability']):.0f}%
    
    Hourly breakdown (next 6 hours):
    """
    
    current_hour = datetime.now().hour
    for i in range(min(6, len(weather['hourly_precipitation_mm']))):
        hour = (current_hour + i) % 24
        rain_prob = weather['hourly_rain_probability'][i]
        rain_mm = weather['hourly_precipitation_mm'][i]
        summary += f"\n    Hour {hour:02d}:00 - Rain: {rain_prob:.0f}% ({rain_mm:.1f}mm)"
    
    return summary


if __name__ == "__main__":
    print("Testing Weather Forecast Module...")
    print("="*60)
    
    # Test default location
    print(f"\n📡 Testing: {DEFAULT_LOCATION}")
    print("-"*60)
    result = get_weather_forecast(DEFAULT_LOCATION)
    
    if result['success']:
        print(f"✅ Success!")
        print(f"   Temperature: {result['current']['temperature']}°C")
        print(f"   Humidity: {result['current']['humidity']}%")
        print(f"   Total rain (24h): {result['total_rainfall_24h']:.1f}mm")
        print(f"   Max rain probability: {max(result['hourly_rain_probability']):.0f}%")
        print(f"   Hours of data: {len(result['hourly_rain_probability'])}")
    else:
        print(f"❌ Failed: {result.get('error', 'Unknown error')}")
    
    print("\n" + "="*60)
    print("\n📋 Detailed summary:")
    print(get_simple_forecast_summary(DEFAULT_LOCATION))
    
    print("\n" + "="*60)
    print("\n🔄 Testing legacy function:")
    print(get_weather_json(DEFAULT_LOCATION))