from kafka import KafkaProducer, KafkaConsumer
import json

class KafkaHandler:
    def __init__(self, bootstrap_servers):
        self.bootstrap_servers = bootstrap_servers
        self.producer = KafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
    
    def send_to_topic(self, topic, message):
        try:
            self.producer.send(topic, value=message)
            self.producer.flush()
            print(f"Message sent to {topic}: {message}")
        except Exception as e:
            print(f"Error sending message: {e}")
    
    def consume_from_topic(self, topic):
        consumer = KafkaConsumer(
            topic,
            bootstrap_servers=self.bootstrap_servers,
            value_deserializer=lambda v: json.loads(v.decode('utf-8')),
            auto_offset_reset='earliest',
            enable_auto_commit=True
        )
        return consumer

