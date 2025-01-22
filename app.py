from flask import Flask, request, jsonify
from kafka_producer import KafkaHandler
import os

app = Flask(__name__)

# Kafka configuration
KAFKA_BROKER = os.getenv('KAFKA_BROKER', 'your-msk-cluster-endpoint:9092')
INPUT_TOPIC = 'stackgenInput'
OUTPUT_TOPIC = 'formattedJson'

kafka_handler = KafkaHandler(bootstrap_servers=KAFKA_BROKER)

@app.route('/process-file', methods=['POST'])
def process_file():
    """
    API to trigger processing of a file line-by-line to Kafka topics.
    """
    file_path = request.json.get('file_path')
    if not file_path or not os.path.exists(file_path):
        return jsonify({'error': 'File not found or invalid path'}), 400
    
    try:
        # Read file and send each line to the Kafka topic
        with open(file_path, 'r') as file:
            for line in file:
                line = line.strip()
                if line:
                    # Convert line to JSON and send to stackgenInput
                    raw_message = {"line": line}
                    kafka_handler.send_to_topic(INPUT_TOPIC, raw_message)

                    # Format line as JSON and send to formattedJson
                    formatted_message = {"line": line, "formatted": True}
                    kafka_handler.send_to_topic(OUTPUT_TOPIC, formatted_message)
        
        return jsonify({'message': 'File processing completed'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

