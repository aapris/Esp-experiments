import paho.mqtt.client as mqtt
import datetime
import json


# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("#")


# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    if msg.topic == 'nodemcu/sensor':
        msg_data = json.loads(msg.payload)
        msg_data['timestamp'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        print(msg_data)
        with open('mqtt.log', 'at') as f:
            f.write(json.dumps(msg_data) + '\n')
    else:
        print(msg.topic+" "+str(msg.payload))

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

MQTT_SERVER_ADDR = '192.168.0.40'
client.connect(MQTT_SERVER_ADDR, 1883, 60)

# Blocking call that processes network traffic, dispatches callbacks and
# handles reconnecting.
# Other loop*() functions are available that give a threaded interface and a
# manual interface.
client.loop_forever()