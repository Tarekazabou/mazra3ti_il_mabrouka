"""
Weather Service
Wrapper around forecast.py functionality
"""

import sys
import os

# Add parent directory to path to import forecast
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

# Handle imports for running from backend/ or parent directory
try:
    from utils.forecast import get_weather_forecast as _get_forecast
except ImportError:
    from backend.utils.forecast import get_weather_forecast as _get_forecast


def get_weather_forecast(location: str = "Tunis"):
    """
    Get weather forecast for next 24 hours
    
    Returns:
        Dictionary with current weather and hourly forecast
    """
    return _get_forecast(location)


def get_weather_summary(location: str = "Tunis"):
    """Get simplified weather summary for mobile display"""
    weather = get_weather_forecast(location)
    
    if not weather['success']:
        return {
            'success': False,
            'error': weather.get('error', 'Unknown error')
        }
    
    return {
        'success': True,
        'temperature': weather['current']['temperature'],
        'humidity': weather['current']['humidity'],
        'condition': weather['current']['condition'],
        'total_rain_24h': weather['total_rainfall_24h'],
        'max_rain_probability': max(weather['hourly_rain_probability']) if weather['hourly_rain_probability'] else 0
    }
