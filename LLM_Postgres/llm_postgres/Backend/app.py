from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from datetime import datetime
import os
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter frontend

# Database configuration
DB_CONFIG = {
    'dbname': os.getenv('DB_NAME', 'llm_postgres'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres'),
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432')
}

def get_db_connection():
    try:
        logger.debug(f"Attempting to connect to database with config: {DB_CONFIG}")
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.Error as e:
        logger.error(f"Database connection error: {e}")
        raise

# Initialize database table
def init_db():
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # First create the database if it doesn't exist
        cur.execute("SELECT 1 FROM pg_database WHERE datname = 'llm_postgres'")
        exists = cur.fetchone()
        
        if not exists:
            # Close the current connection to create new database
            cur.close()
            conn.close()
            
            # Connect to default postgres database to create new database
            conn = psycopg2.connect(
                dbname='postgres',
                user=DB_CONFIG['user'],
                password=DB_CONFIG['password'],
                host=DB_CONFIG['host']
            )
            conn.autocommit = True
            cur = conn.cursor()
            cur.execute('CREATE DATABASE llm_postgres')
            cur.close()
            conn.close()
            
            # Reconnect to new database
            conn = get_db_connection()
            cur = conn.cursor()
        
        # Create table
        cur.execute('''
            CREATE TABLE IF NOT EXISTS prompts (
                id SERIAL PRIMARY KEY,
                user_id TEXT NOT NULL,
                query TEXT NOT NULL,
                casual_response TEXT NOT NULL,
                formal_response TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.commit()
        print("Database initialized successfully!")
    except Exception as e:
        print(f"Error initializing database: {e}")
        raise
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

# Initialize database on startup
init_db()

@app.route('/prompt', methods=['POST'])
def create_prompt():
    try:
        data = request.json
        logger.debug(f"Received POST request with data: {data}")
        
        if not data or 'user_id' not in data or 'query' not in data:
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Mock responses for demonstration
        casual_response = f"Hey! Let me explain {data['query']} in a casual way..."
        formal_response = f"Here is a formal analysis of {data['query']}..."
        
        conn = None
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute('''
                INSERT INTO prompts (user_id, query, casual_response, formal_response)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            ''', (data['user_id'], data['query'], casual_response, formal_response))
            
            new_id = cur.fetchone()[0]
            conn.commit()
            cur.close()
            
            return jsonify({
                'id': new_id,
                'casual_response': casual_response,
                'formal_response': formal_response
            })
        except Exception as e:
            logger.error(f"Database error: {e}")
            return jsonify({'error': str(e)}), 500
        finally:
            if conn:
                conn.close()
                
    except Exception as e:
        logger.error(f"Server error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/prompt', methods=['GET'])
def get_prompts():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id parameter'}), 400
    
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('''
        SELECT id, query, casual_response, formal_response, created_at
        FROM prompts
        WHERE user_id = %s
        ORDER BY created_at DESC
    ''', (user_id,))
    
    rows = cur.fetchall()
    cur.close()
    conn.close()
    
    prompts = [{
        'id': row[0],
        'query': row[1],
        'casual_response': row[2],
        'formal_response': row[3],
        'created_at': row[4].isoformat()
    } for row in rows]
    
    return jsonify(prompts)

if __name__ == '__main__':
    print("Starting Flask server on http://localhost:8000")
    try:
        init_db()
        print("Database initialized successfully!")
        app.run(host='0.0.0.0', port=8000, debug=True)
    except Exception as e:
        print(f"Error starting server: {e}")