#! /usr/bin/python

# ASE Project 2013/2014 - Instituto Superior Tecnico
# @author - Alexandre Filipe Campos - 66354

import sys
import math
import time
import os
import random
from TOSSIM import *
from tinyos.tossim.TossimApp import *
from threading import Thread
from PingMsg import *
from UpdateFoodDailyDosage import *
from UpdateFeedingSpot import *
from Proximity import *
#from GetFoodDailyDosage import *

def main(argv):


    #vars
    global n_nodes, t, r, msg_id, nodeList
    MAX_NODES = 10000
    nodeList = []
    random.seed()


    n = NescApp()
    t = Tossim(n.variables.variables())
    #what = t.mac()
    r = t.radio()

    # === Welcome
    print "ASE Project 2013/2014 by Alexandre Campos"
    print "+++ "

    # === add debug and log channels ===
    #ff = open("logs.txt", "w+")
    t.addChannel("Boot", sys.stdout)
    #t.addChannel("Boot", ff)
    #f = open("sensor_info.txt", "w")
    #t.addChannel("SensorInfo", f)


    # === prompt for how many motes ===
    prompt_n_nodes(MAX_NODES)

    # === add topology ===
    f = open("topo.txt", "r")
    print "=== Creating Network topology"
    for l in f:
        s = l.split()
        r.add(int(s[0]), int(s[1]), float(s[2]))
    print "+++ Network topology set"



    # ===create nodes ===
    for x in range(0, n_nodes):
        print "=== Creating and starting node %d " % x
        m = t.getNode(x)
        nodeList.append(m)
        # m.turnOn()
        m.bootAtTime((31 + t.ticksPerSecond() / 10) * x + 1)
        print " - its on!"
        # add noise to node
        f = open("noise.txt", "r")
        for l in f:
            s = l.strip()
            if s:
                m.addNoiseTraceReading(int(s))
        m.createNoiseModel()
        print " - added noise "
        print "+++ Node %d start complete! %d" % (x, len(nodeList))
        f.close()


    print "what"
    # === start prompt for user commands ===
    prompt_thr = Thread(target=command_prompt, args=())
    prompt_thr.start()

    #run next event 4ever
    while 1:
        time.sleep(0.001) #slow things a bit
        t.runNextEvent() #run next event


def prompt_n_nodes(max_nodes):

    try:
        global n_nodes
        n_nodes = int(raw_input("Insert number of nodes in the network (max %d):" % max_nodes))
        if n_nodes < 1:
            print "Not a valid input. Try again!"
            prompt_n_nodes(max_nodes);
        print "Creating network of %d nodes!" % n_nodes
    except ValueError:
        print "Not a valid input. Try again!"
        prompt_n_nodes(max_nodes)

def command_prompt():
    #do nothing
    print "=== Command prompt initiated!"
    print "=== Type \'h\' for command list"

    while 1:
        sys.stdout.write('> ')
        line = sys.stdin.readline()
        cmd = line.split()

        if len(cmd) == 0:
            continue
        elif cmd[0] == "get":
            if(len(cmd) < 2):
                print "wrong input. get <mote_id>"
                continue
            get_state_info(cmd[1])
        elif cmd[0] == "updateFood":
            if len(cmd) == 3:
                updateFood(int(cmd[1]), int(cmd[2]))
            else:
                print "command usage updateFood <mote_id> <amount>"
                print "if ( <mote_id> = 0 ) ---> update to all motes"
        elif cmd[0] == "updateSpotFood":
            if len(cmd) == 3:
                updateSpotFood(int(cmd[1]), int(cmd[2]))
            else:
                print "wrong command usage. type h for help"
        elif cmd[0] == "ping":
            ping()
        elif cmd[0] == "getSpotFood":
            if len(cmd) == 2:
                getSpotFood(int(cmd[1]))
            else:
                print "wrong command usage. type h for help"
        elif cmd[0] == "prox":
            if len(cmd) < 2:
                print "wrong input, prox <mote_id>"
                continue
            prox(int(cmd[1]))
        elif cmd[0] == "exit":
            print "leaving . . . . goodbye!"
            os._exit(0)
            break
        elif cmd[0] == "h":
            help_me()
        elif cmd[0] == "read":
            if len(cmd) != 2:
                print "wrong usage, read <mote_id>"
                continue
            read(int(cmd[1]))
        else:
            print "wrong input. type 'h' for help"


def read(mote_id):
    sens = open("sensor_info.txt")
    for l in sens:
        if l.find("node_id: " + str(mote_id)) > -1:
            print l,
            sys.stdout.write('')

def updateFood(mote_id, food):
    msg = UpdateFoodDailyDosage()
    msg.set_msg_id(random.randint(0, pow(2,32)- 1))
    msg.set_new_food_max(food)
    msg.set_mote_dest(mote_id)

    pkt = t.newPacket()
    pkt.setData(msg.data)
    pkt.setType(msg.get_amType())
    pkt.setDestination(0)

    print "Delivering " + str(msg) + " to 0 at " + str(t.time() +3)
    pkt.deliver(0, t.time() + 3)

def updateSpotFood(spot_id, food):
    msg = UpdateFeedingSpot()
    msg.set_food_g(food)
    msg.set_spot_id(spot_id)
    msg.set_msg_id(random.randint(0, pow(2,32)-1))

    pkt = t.newPacket()
    pkt.setData(msg.data)
    pkt.setType(msg.get_amType())
    pkt.setDestination(0)

    print "Delivering " + str(msg) + " to 0 at " + str(t.time() + 3)
    pkt.deliver(0, t.time() + 3)



def prox(mote_id):
    msg = Proximity()
    pkt = t.newPacket()
    pkt.setType(msg.get_amType())
    pkt.setDestination(mote_id)
    print "Delivering " + str(msg) + " to " + str(mote_id) + " at " + str(t.time() + 3)
    pkt.deliver(mote_id, t.time() + 3)


#def getFood(mote_id):
#    msg = GetFoodDailyDosage()
#    msg.set_mote_dest(mote_id)
#    msg.set_msg_id(random.randint(0, pow(2,32)-1))

 #   pkt = t.newPacket()
 #   pkt.setData(msg.data)
 #   pkt.setType(msg.get_amType())
 #   pkt.setDestination(0)

#    print "Delivering " + str(msg) + " to 0 at " + str(t.time() +3)
#    pkt.deliver(0, t.time() + 3)

def getSpotFood(spot_id):
    try:
        s = "fs" + str(spot_id)
        f = open(s, "r")
        for l in f:
            v = l.split()
        print "Spot " + str(spot_id) + " Max_food: " + str(v[1]) + " Current_food: " + str(v[0])
    except Exception:
        print "error, type h for help"

def get_state_info(mote_id):
    try:
        mote = nodeList[int(mote_id)]
        status = mote.isOn()
        busy = mote.getVariable("AnimalC.busy")
        max_food = mote.getVariable("AnimalC.max_food")
        food_intake = mote.getVariable("AnimalC.food_intake")
        gps_la = mote.getVariable("AnimalC.gps_la")
        gps_lo = mote.getVariable("AnimalC.gps_lo")

        print "Status: " + str(status) + " busy: "+ str(busy.getData())+ " | Max_food: " + str(max_food.getData()) + " | food_in: " + str(food_intake.getData()) + " gps " + str(gps_la.getData()) + " " + str(gps_lo.getData())
    except Exception:
        print "error.... how to use get: get <mote_id>"

def help_me():
    print "- h                                 *** for help"
    print "- get <mote_id> (FOR DEBUG)         *** get state info of mote"
    print "- exit                              *** to exit"
    print "- read <mote_id>                    *** get last known GPS and food info"
    print "- updateFood <mote_id> <amount>     *** to update daily food. mote_id 0 for all"
    print "- getSpotFood <spot_id>             *** to get amount of food left in feeding spot. 0 to get all."
    print "- updateSpotFood <spot_id> <amount> *** to update the spots food. 0 for all."
    print "- prox <mote_id>                    *** turn on proximity simulation to feeding spot."



def ping():
    msg = PingMsg()
    msg.set_number(7)
    pkt = t.newPacket()
    pkt.setData(msg.data)
    pkt.setType(msg.get_amType())
    pkt.setDestination(0)

    print "Delivering " + str(msg) + " to 0 at " + str(t.time() + 3)
    pkt.deliver(0, t.time() + 3)

if __name__ == "__main__":
    main(sys.argv[1:])
