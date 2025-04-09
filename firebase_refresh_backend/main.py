import functions_framework
from flask import request, jsonify
import firebase_admin
from firebase_admin import credentials, auth
import os

# Load credentials from local file (relative to function root)
cred = credentials.Certificate('firebase-adminsdk.json')
firebase_admin.initialize_app(cred)

@functions_framework.http
def generate_refresh_token(request):
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405

    data = request.get_json()
    if not data or 'uid' not in data:
        return jsonify({'error': 'Missing uid'}), 400

    try:
        custom_token = auth.create_custom_token(data['uid'])
        return jsonify({
            'customToken': custom_token.decode('utf-8'),
            'expiresIn': 172800,
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
