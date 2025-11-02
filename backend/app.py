"""
WIEEMPOWER SMART IRRIGATION SYSTEM - BACKEND
Main Flask application - Self-contained backend

Run from backend/ directory:
  python app.py
"""

from flask import Flask, jsonify
from flask_cors import CORS
import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import route blueprints
from routes.admin_routes import admin_bp
from routes.farmer_routes import farmer_bp

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for mobile app access

# Register blueprints
app.register_blueprint(admin_bp)
app.register_blueprint(farmer_bp)


@app.route('/')
def index():
    """Root endpoint - API documentation"""
    return jsonify({
        'application': 'WiEmpower Smart Irrigation System',
        'description': 'AI-powered irrigation for women farmers in Tunisia',
        'version': '2.0',
        'interfaces': {
            'farmer': {
                'description': 'Mobile app interface for women farmers',
                'base_url': '/api/farmer/<user_id>',
                'endpoints': [
                    'GET /state - Get complete farm state',
                    'POST /valve/open - Manually open valve',
                    'POST /valve/close - Manually close valve',
                    'GET /valve/status - Check valve status',
                    'POST /ai-mode - Toggle AI automatic mode',
                    'POST /decision - Get AI irrigation decision',
                    'GET /history - View irrigation history',
                    'GET /plants - List user plants'
                ]
            },
            'admin': {
                'description': 'Admin dashboard for system management',
                'base_url': '/api/admin',
                'endpoints': [
                    'GET /users - List all users',
                    'POST /users - Add new user',
                    'GET /users/<id> - Get user details',
                    'PUT /users/<id> - Update user',
                    'DELETE /users/<id> - Delete user',
                    'POST /users/<id>/plants - Add plant to user',
                    'DELETE /users/<id>/plants/<name> - Remove plant',
                    'GET /plants - List all available plants',
                    'GET /stats - System statistics'
                ]
            }
        },
        'documentation': {
            'api_docs': '/api/docs (coming soon)',
            'readme': 'See README.md in backend folder'
        }
    })


@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'wieempower-backend',
        'version': '2.0'
    })


if __name__ == '__main__':
    print()
    print("="*70)
    print("🌱 WIEEMPOWER - SMART IRRIGATION SYSTEM")
    print("   Supporting Women Farmers in Tunisia")
    print("="*70)
    print()
    print("📱 USER INTERFACE (Mobile App):")
    print("   GET  /api/farmer/<user_id>/state - Get farm state")
    print("   POST /api/farmer/<user_id>/valve/open - Open valve manually")
    print("   POST /api/farmer/<user_id>/valve/close - Close valve manually")
    print("   POST /api/farmer/<user_id>/ai-mode - Toggle AI auto mode")
    print("   POST /api/farmer/<user_id>/decision - Get AI decision")
    print()
    print("👨‍💼 ADMIN INTERFACE:")
    print("   GET  /api/admin/users - List all users")
    print("   POST /api/admin/users - Add new user (like Mabrouka)")
    print("   PUT  /api/admin/users/<user_id> - Update user details")
    print("   POST /api/admin/users/<user_id>/plants - Add plant")
    print("   GET  /api/admin/stats - System statistics")
    print()
    print("="*70)
    print()
    
    # Run Flask app
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True  # Set to False in production
    )
