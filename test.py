#! /usr/bin/python
import sys
from TOSSIM import *
from PingMsg import *
from GetFoodDailyDosage import *

t = Tossim([])
m = t.mac()
r = t.radio()

t.addChannel("Boot", sys.stdout)

for i in range(0, 2):
    m = t.getNode(i)
    m.bootAtTime((31 + t.ticksPerSecond() / 10) * i + 1)

f = open("topo.txt", "r")
for line in f:
    s = line.split()
    if s:
        if s[0] == "gain":
            r.add(int(s[1]), int(s[2]), float(s[3]))

noise = open("noise.txt", "r")
for line in noise:
    s = line.strip()
    if s:
        val = int(s)
        for i in range(4):
            t.getNode(i).addNoiseTraceReading(val)

for i in range(4):
    t.getNode(i).createNoiseModel()

for i in range(60):
    t.runNextEvent()

msg = GetFoodDailyDosage()
msg.set_foodkg = 1
msg.set_msgId = 1
pkt = t.newPacket()
pkt.setData(msg.data)
pkt.setType(msg.get_amType())
pkt.setDestination(1)

print "Delivering " + str(msg) + " to 0 at " + str(t.time() + 3)
pkt.deliver(1, t.time() + 3)

for i in range(20):
    t.runNextEvent()
