"""
Farmer Routes Blueprint
Endpoints for women farmers' mobile interface
"""

from flask import Blueprint, request, jsonify

# Handle imports for running from backend/ or parent directory
try:
    from services import farmer_service, valve_service, irrigation_service
except ImportError:
    from backend.services import farmer_service, valve_service, irrigation_service


farmer_bp = Blueprint('farmer', __name__, url_prefix='/api/farmer')


@farmer_bp.route('/<user_id>/state', methods=['GET'])
def get_farm_state(user_id):
    """
    Get complete farm state for mobile app
    Shows everything the farmer needs to see:
    - Name, location, plants
    - Current watering status
    - Weather
    - AI mode
    - Recent activity
    """
    result = farmer_service.get_farm_state(user_id)
    return jsonify(result), 200 if result['success'] else 404


@farmer_bp.route('/<user_id>/plants', methods=['GET'])
def get_plants(user_id):
    """Get user's plants"""
    result = farmer_service.get_user_plants(user_id)
    return jsonify(result), 200 if result['success'] else 404


@farmer_bp.route('/<user_id>/valve/open', methods=['POST'])
def open_valve(user_id):
    """
    Manually open valve (farmer override)
    
    Body:
    {
        "plant_name": "tomato",
        "duration_minutes": 30
    }
    """
    try:
        data = request.json
        result = valve_service.open_valve_manual(
            user_id=user_id,
            plant_name=data['plant_name'],
            duration_minutes=int(data['duration_minutes'])
        )
        return jsonify(result), 200 if result['success'] else 400
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400


@farmer_bp.route('/<user_id>/valve/close', methods=['POST'])
def close_valve(user_id):
    """Manually close valve (farmer override)"""
    result = valve_service.close_valve_manual(user_id)
    return jsonify(result), 200 if result['success'] else 400


@farmer_bp.route('/<user_id>/valve/status', methods=['GET'])
def valve_status(user_id):
    """Get current valve status"""
    result = valve_service.get_valve_status(user_id)
    return jsonify(result), 200 if result['success'] else 404


@farmer_bp.route('/<user_id>/ai-mode', methods=['POST'])
def toggle_ai_mode(user_id):
    """
    Toggle AI automatic mode on/off
    
    Body:
    {
        "ai_mode": true  // or false
    }
    """
    try:
        data = request.json
        ai_mode = data.get('ai_mode', True)
        result = valve_service.set_ai_mode(user_id, ai_mode)
        return jsonify(result), 200 if result['success'] else 400
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400


@farmer_bp.route('/<user_id>/decision', methods=['POST'])
def get_decision(user_id):
    """
    Get AI irrigation decision (called by scheduler or farmer)
    
    Body:
    {
        "plant_name": "tomato",
        "soil_moisture": 45.5,
        "sensor_temperature": 28.3,  // optional
        "sensor_humidity": 52.1       // optional
    }
    """
    try:
        data = request.json
        result = irrigation_service.get_irrigation_decision(
            user_id=user_id,
            plant_name=data['plant_name'],
            soil_moisture=float(data['soil_moisture']),
            sensor_temperature=data.get('sensor_temperature'),
            sensor_humidity=data.get('sensor_humidity')
        )
        return jsonify(result), 200 if result['success'] else 400
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@farmer_bp.route('/<user_id>/history', methods=['GET'])
def get_history(user_id):
    """Get irrigation history"""
    limit = request.args.get('limit', 50, type=int)
    result = irrigation_service.get_irrigation_history(user_id, limit)
    return jsonify(result), 200 if result['success'] else 500
