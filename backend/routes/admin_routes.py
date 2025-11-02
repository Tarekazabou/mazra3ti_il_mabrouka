"""
Admin Routes Blueprint
Endpoints for admin interface to manage users and system
"""

from flask import Blueprint, request, jsonify

# Handle imports for running from backend/ or parent directory
try:
    from services import admin_service
    from services.plant_service import list_all_plants
except ImportError:
    from backend.services import admin_service
    from backend.services.plant_service import list_all_plants

# Import Gemini model for plant generation
try:
    from utils.gemini_decision import GeminiIrrigationDecision
except ImportError:
    try:
        from backend.utils.gemini_decision import GeminiIrrigationDecision
    except ImportError:
        from gemini_decision import GeminiIrrigationDecision
    _gemini_instance = None
    
    def get_gemini():
        global _gemini_instance
        if _gemini_instance is None:
            try:
                _gemini_instance = GeminiIrrigationDecision()
            except Exception:
                pass
        return _gemini_instance.model if _gemini_instance else None
except Exception:
    def get_gemini():
        return None


admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')


@admin_bp.route('/users', methods=['GET'])
def list_users():
    """Get all users"""
    role = request.args.get('role')  # Optional filter
    result = admin_service.list_all_users(role)
    return jsonify(result)


@admin_bp.route('/users', methods=['POST'])
def add_user():
    """
    Add new user (farmer)
    
    Body:
    {
        "email": "mabrouka@farm.tn",
        "name": "Mabrouka",
        "location": "Zaghouan",
        "soil_properties": {
            "soil_type": "loam",
            "soil_compaction": 55,
            "slope_degrees": 3.5
        },
        "plants": [
            {"name": "tomato", "area_sqm": 100}
        ]
    }
    """
    try:
        data = request.json
        gemini_model = get_gemini()
        
        result = admin_service.add_user(
            email=data['email'],
            name=data['name'],
            location=data['location'],
            soil_properties=data['soil_properties'],
            plants=data['plants'],
            gemini_model=gemini_model
        )
        
        return jsonify(result), 201 if result['success'] else 400
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400


@admin_bp.route('/users/<user_id>', methods=['GET'])
def get_user(user_id):
    """Get user details"""
    result = admin_service.get_user(user_id)
    return jsonify(result), 200 if result['success'] else 404


@admin_bp.route('/users/<user_id>', methods=['PUT'])
def update_user(user_id):
    """
    Update user details
    
    Body: Dictionary of fields to update
    {
        "location": "New Location",
        "soil_properties": {...}
    }
    """
    try:
        updates = request.json
        result = admin_service.update_user(user_id, updates)
        return jsonify(result), 200 if result['success'] else 400
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400


@admin_bp.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Delete user"""
    result = admin_service.delete_user(user_id)
    return jsonify(result), 200 if result['success'] else 404


@admin_bp.route('/users/<user_id>/plants', methods=['POST'])
def add_plant(user_id):
    """
    Add plant to user
    
    Body:
    {
        "name": "olive",
        "area_sqm": 500
    }
    """
    try:
        data = request.json
        gemini_model = get_gemini()
        
        result = admin_service.add_plant_to_user(
            user_id=user_id,
            plant_name=data['name'],
            area_sqm=data['area_sqm'],
            gemini_model=gemini_model
        )
        
        return jsonify(result), 200 if result['success'] else 400
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400


@admin_bp.route('/users/<user_id>/plants/<plant_name>', methods=['DELETE'])
def remove_plant(user_id, plant_name):
    """Remove plant from user"""
    result = admin_service.remove_plant_from_user(user_id, plant_name)
    return jsonify(result), 200 if result['success'] else 404


@admin_bp.route('/plants', methods=['GET'])
def get_all_plants():
    """Get all available plants in database"""
    plants = list_all_plants()
    return jsonify({
        'success': True,
        'count': len(plants),
        'plants': plants
    })


@admin_bp.route('/stats', methods=['GET'])
def get_stats():
    """Get system statistics"""
    try:
        users_result = admin_service.list_all_users()
        users = users_result.get('users', [])
        
        # Calculate stats
        total_users = len(users)
        active_users = sum(1 for u in users if u.get('ai_mode', True))
        total_plants = sum(len(u.get('plants', [])) for u in users)
        
        return jsonify({
            'success': True,
            'stats': {
                'total_users': total_users,
                'active_ai_users': active_users,
                'total_plants': total_plants,
                'timestamp': users[0].get('created_at') if users else None
            }
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
