#! /usr/bin/python
import sys
from TOSSIM import *

t = Tossim([])

t.addChannel("Boot", sys.stdout);

t.getNode(1).bootAtTime(100001);
t.getNode(2).bootAtTime(800002);

#create nodes


#start prompt for user commands


#run next event 4ever
while 1:
    time.sleep(0.001); #slow things a bit
    t.runNextEvent(); #run next event
