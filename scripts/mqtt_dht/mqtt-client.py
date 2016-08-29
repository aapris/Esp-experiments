import paho.mqtt.client as mqtt
import datetime
import json
import sys
import os
import shutil

# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("#")


# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    #if msg.topic == 'nodemcu/sensor':
    MAX_LINES = 200
    if msg.topic in ['nodemcu/sensor', 'nodemcu/event']:
        channel = msg.topic.split('/')[1]
        msg_data = json.loads(msg.payload)
        now = datetime.datetime.utcnow()
        msg_data['timestamp'] = now.strftime('%Y-%m-%dT%H:%M:%SZ')
        print(msg_data)
        # Write all data to a log file
        fname = 'mqtt-{}-{}.log'.format(now.strftime('%Y%m%d'), channel)
        fname = os.path.join(sys.argv[1], fname)
        with open(fname, 'at') as f:
            f.write(json.dumps(msg_data) + '\n')
        # Write last lines to a json file per logger
        fname = '{}.json'.format(msg_data.get('chipid', 'null'))
        fname = os.path.join(sys.argv[1], fname)
        lines = []
        if os.path.isfile(fname):
            with open(fname, 'rt') as f:
                lines = json.loads(f.read())
                if len(lines) > MAX_LINES:
                    lines = lines[-MAX_LINES:]
        lines.append(msg_data)
        #with open(fname, 'wt') as f:
        tmpname = fname + '.tmp'
        with open(tmpname, 'wt') as f:
            f.write(json.dumps(lines, indent=1))
        shutil.move(tmpname, fname)

        # Write last MAX_LINES to a logger related file
        # (TO BE REMOVED)
        fname = '{}.log'.format(msg_data.get('chipid', 'null'))
        fname = os.path.join(sys.argv[1], fname)
        lines = []
        if os.path.isfile(fname):
            with open(fname, 'rt') as f:
                lines = f.readlines()
                if len(lines) > MAX_LINES:
                    lines = lines[-MAX_LINES:]
        lines.append(json.dumps(msg_data))
        lines = [line.strip() for line in lines if line.strip() != '']
        with open(fname, 'wt') as f:
            f.write('\n'.join(lines))

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
