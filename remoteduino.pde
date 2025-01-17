#include <avr_stl.h>
#include <avr_config.h>
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <serstream>
#include <iomanip>
#include <sstream>
using namespace std;

/*
 * IRrecord: record and play back IR signals as a minimal 
 * An IR detector/demodulator must be connected to the input RECV_PIN.
 * An IR LED must be connected to the output PWM pin 3.
 * A button must be connected to the input BUTTON_PIN; this is the
 * send button.
 * A visible LED can be connected to STATUS_PIN to provide status.
 *
 * The logic is:
 * If the button is pressed, send the IR code.
 * If an IR code is received, record it.
 *
 * Version 0.11 September, 2009
 * Copyright 2009 Ken Shirriff
 * http://arcfn.com
 */

/*#include <Ports.h>*/
/*#include <RF12.h>*/
#include <SPI.h>
#include <Ethernet.h>
#include <IRremote.h>
#include <RemoteDuinoServer.h>

std::ohserialstream cout(Serial);
std::ihserialstream serial_in(Serial);

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192,168,0, 50 };

EthernetRemoteDuinoServer RDServer(100, mac, ip);


void setup() {
    Serial.begin(9600);
    cout << "starting up..." << endl;
    cout << get_free_memory() << endl;
    RDServer.begin();
    /*rf12_config();*/
}


void loop() {
    if(RDServer.available()) {
        RDServer.process_request();
    }
}
