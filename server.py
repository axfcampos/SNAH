#! /usr/bin/python
import sys
import math
import time
from TOSSIM import *


def main(argv):

    global n_nodes, t, r;
    nodeList = []

    t = Tossim([])
    r = t.radio()

    # === add debug and log channels ===
    t.addChannel("Boot", sys.stdout);


    # === prompt for how many motes ===
    prompt_n_nodes(10);

    # === add topology ===
    f = open("topo.txt", "r")
    for l in f:
        s = l.split()
        if s:
            r.add(int(s[0]), int(s[1]), float(s[2]));
    print "=== Network topology set\n"



    # ===create nodes ===
    for x in range(0, n_nodes):
        print "=== Creating and starting node %d \n" % x
        m = t.getNode(x)
        nodeList.append(m)
        m.turnOn()
        print " - its on!\n"
        # add noise to node
        f = open("noise.txt", "r")
        for l in f:
            s = l.strip()
            if s:
                m.addNoiseTraceReading(int(s))
        m.createNoiseModel()
        print " - added noise \n"
        print "+++ Node %d start complete! \n" % x


    # === start prompt for user commands ===


    #run next event 4ever
    while 1:
        time.sleep(0.001); #slow things a bit
        t.runNextEvent(); #run next event


def prompt_n_nodes(max_nodes):

    try:
        global n_nodes
        n_nodes = int(raw_input("Insert number of nodes in the network (max %d):\n" % max_nodes));
        if n_nodes < 1:
            print "Not a valid input. Try again!\n"
            prompt_n_nodes(max_nodes);
        print "Creating network of %d nodes!\n" % n_nodes
    except ValueError:
        print "Not a valid input. Try again!\n"
        prompt_n_nodes(max_nodes);

def command_prompt():
    #do nothing
    print "fuck"






if __name__ == "__main__":
    main(sys.argv[1:])
