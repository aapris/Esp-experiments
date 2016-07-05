import paho.mqtt.client as mqtt
import datetime
import json
import sys
import os

# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("#")


# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    #if msg.topic == 'nodemcu/sensor':
    if msg.topic in ['nodemcu/sensor', 'nodemcu/event']:
        channel = msg.topic.split('/')[1]
        msg_data = json.loads(msg.payload)
        now = datetime.datetime.utcnow()
        msg_data['timestamp'] = now.strftime('%Y-%m-%dT%H:%M:%SZ')
        print(msg_data)
        fname = 'mqtt-{}-{}.log'.format(now.strftime('%Y%m%d'), channel)
        fname = os.path.join(sys.argv[1], fname)
        with open(fname, 'at') as f:
            f.write(json.dumps(msg_data) + '\n')
    else:
        print(msg.topic+" "+str(msg.payload))

from mqttconfig import MQTT_SERVER_ADDR, MQTT_USERNAME, MQTT_PASSWORD

client = mqtt.Client()
client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
client.on_connect = on_connect
client.on_message = on_message

client.connect(MQTT_SERVER_ADDR, 1883, 60)

# Blocking call that processes network traffic, dispatches callbacks and
# handles reconnecting.
# Other loop*() functions are available that give a threaded interface and a
# manual interface.
client.loop_forever()
