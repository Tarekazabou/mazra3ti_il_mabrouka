"""
Quick test to verify Gemini API is working
"""
import os
from dotenv import load_dotenv
import google.generativeai as genai

# Load environment variables
load_dotenv()

print("="*70)
print("🔍 TESTING GEMINI API CONNECTION")
print("="*70)

# Get API key
api_key = os.getenv('GEMINI_API_KEY')
if not api_key:
    print("❌ ERROR: GEMINI_API_KEY not found in environment")
    print("   Make sure .env file exists with GEMINI_API_KEY=your-key")
    exit(1)

print(f"✅ API Key found: {api_key[:10]}...{api_key[-4:]}")
print()

try:
    # Configure API
    genai.configure(api_key=api_key)
    print("✅ API configured successfully")
    print()
    
    # List available models
    print("📋 Available models:")
    for model in genai.list_models():
        if 'generateContent' in model.supported_generation_methods:
            print(f"   • {model.name}")
    print()
    
    # Try a simple generation
    print("🤖 Testing simple generation with gemini-2.0-flash...")
    model = genai.GenerativeModel('gemini-2.0-flash')
    
    response = model.generate_content(
        "Respond with just 'OK' if you can read this.",
        generation_config=genai.types.GenerationConfig(
            temperature=0.1,
            max_output_tokens=10,
        )
    )
    
    print(f"   Response: {response.text}")
    print()
    print("✅ API is working correctly!")
    print("="*70)
    
except Exception as e:
    print(f"❌ ERROR: {e}")
    print()
    
    # Check for specific errors
    error_str = str(e)
    if "429" in error_str or "RATE_LIMIT" in error_str:
        print("   This is a rate limit error. The free tier has limits:")
        print("   • 15 requests per minute")
        print("   • 1,500 requests per day")
        print()
        print("   Wait a minute and try again.")
    elif "API_KEY" in error_str or "401" in error_str or "403" in error_str:
        print("   This is an authentication error. Check your API key:")
        print("   1. Go to https://aistudio.google.com/app/apikey")
        print("   2. Generate a new API key if needed")
        print("   3. Update .env file with new key")
    elif "404" in error_str:
        print("   Model not found. Try listing models to see what's available.")
    else:
        print("   Unknown error. Full details above.")
    
    print("="*70)
    exit(1)
