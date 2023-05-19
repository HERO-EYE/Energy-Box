// import 'dart:html';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:countup/countup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'dart:async';
// import 'dart:html';
import 'dart:typed_data';
import 'package:serial_port_win32/src/serial_port.dart';
// import 'package:libserialport/libserialport.dart' as lserial;
import 'package:flutter_libserialport/flutter_libserialport.dart' as lserial;


class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<App> {

  // constant values
  int hours_day = 12;
  int leds_num  = 3;
  int lamps_num  = 3;
  int total_lamps = 50;
  int total_leds = 50;

  int watt_lamp = 0;
  int watt_led = 0;
  int watt_lamp_prev = 0;
  int watt_led_prev = 0;
  double cost_lamp = 0;
  double cost_led = 0;
  double cost_lamp_prev = 0;
  double cost_led_prev = 0;
  double unit_cost = 0;
  String device_list = "";
  String data = "";
  // SerialPort? _port;
  Color lamp_bg_color = HexColor("#fcb683").withOpacity(0.9);
  Color led_bg_color  = HexColor("#49c6e2").withOpacity(0.9);

  String json = '{"lamp":"200", "led":"40"}';
  String json2 = '{"ac1":"2000", "ac2":"1000"}';
  SerialPort? port;
  lserial.SerialPort? port_;
  var ports = [];

  @override
  void initState() {
    super.initState();

    Serial_init();

    Timer.periodic(Duration(seconds: 5), (timer) {
      Serial_init();
    });
  }

  void Serial_read() {

    print("reading...");
    String data = "";

    if (port!=null) {
      port!.readOnListenFunction = (value) {
        String s = new String.fromCharCodes(value);
        // print("value: " + s);
        if (s == '#') {
          // print("END");
          print("data: " + data);

          final json = jsonDecode(data);

          setState(() {
            watt_lamp = json["lamp"];
            watt_led = json["led"];
            data = "";
            KWH_calculation();
            // port!.close();
          });
        }
        else {
          // {"led":410,"lamp":3900}
          if (s == '{' || s == '}' || s == '"' || s == ':' || s == ',' ||
              s == 'l' || s == 'e' || s == 'd' || s == 'a' || s == 'm' ||
              s == 'p' || s == '0' || s == '1' || s == '2' || s == '3' ||
              s == '4' || s == '5' || s == '6' || s == '7' || s == '8' ||
              s == '9') {
            // if (s!='#' && s!='\n' && s!='\r\n') {
            print("s: ${s}");
            data += s;
            setState(() {
              watt_lamp_prev = watt_lamp;
              watt_led_prev = watt_led;
              cost_lamp_prev = cost_lamp;
              cost_led_prev = cost_led;
            });
          }
        }
      };
    }

    // write
    // Serial_write();

  }


  void Serial_init() async {

    // try {
    ports = lserial.SerialPort.availablePorts;

    print("devices list : ${ports}");

      if(ports.isNotEmpty){
        if (port==null) {
            port = SerialPort(ports.last);
            // port!.BaudRate = 115200;
            Serial_read();
        } else {
          if (!port!.isOpened) {
            port = SerialPort(ports.last);
            // port!.BaudRate = 115200;
            Serial_read();
          }
          // else {
          //   // port!.close();
          //   port = SerialPort(ports.last);
          //   // port!.BaudRate = 115200;
          //   Serial_read();
          //
          // }
        }
      } else {
        if(port!=null) if (port!.isOpened) port!.close();
      }
    // } catch(e) {
    //   print(e);
    //   if(port!=null) if (port!.isOpened) port!.close();
    // }
  }

  void KWH_calculation() {

    int w_lamp = (watt_lamp / lamps_num).toInt();
    int w_led = (watt_led / leds_num).toInt();


    w_lamp *= total_lamps;
    w_led *= total_leds;
    double kwh_lamp = (w_lamp*hours_day)/1000;
    double kwh_led = (w_led*hours_day)/1000;

    kwh_lamp *= 30;
    kwh_led  *= 30;

    setState((){
      cost_lamp = bill_calculation(kwh_lamp);
      cost_led = bill_calculation(kwh_led);
      print("cost_lamp: ${cost_lamp}");
      print("cost_led : ${cost_led}");
    });
  }

  double bill_calculation(kwh) {
    double unit_cost = 0;
    if(kwh<=2000) {
      unit_cost = 0.015;
    } else if(kwh<=4000) {
      unit_cost = 0.02;
    } else {
      unit_cost = 0.03;
    }

    double cost = kwh * unit_cost;

    return cost;
  }

  Widget LAMP(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Container(
      child: Column(
        children: [
          Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                alignment: Alignment.topLeft,
                // color: Colors.indigoAccent,
                child: Icon( (port!=null) ? (port!.isOpened ? Icons.usb_rounded : Icons.usb_off_rounded) : Icons.usb_off_rounded, color: Colors.white,
                    size: wheight/12),
              )
          ),

          Expanded(
              flex: 4,
              child: Container(
                alignment: Alignment.bottomCenter,
                // color: Colors.indigoAccent,
                child: Text("LAMP", style: TextStyle(fontSize: wheight/6, color: Colors.white),),
              )
          ),
          Expanded(
              flex: 5,
              child: Container(
                // color: Colors.blueGrey,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                          child: Countup(
                            begin: watt_lamp_prev.toDouble(),
                            end: watt_lamp.toDouble(),
                            suffix: " W",
                            duration: Duration(seconds: 3),
                            style: TextStyle(
                                fontSize: wheight/8,
                                // fontFamily: "Lato",
                                color: Colors.white
                            ),
                          )
                      ),
                      Center(
                        child: Text("الاستهلاك اللحظي", style: TextStyle(fontSize: wheight/25, color: Colors.white),),
                      ),
                    ],
                  )


              )
          ),
          Expanded(
              flex: 4,
              child: Container(
                // color: Colors.blue,
                child:
                Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child:
                      Center(
                        child: Column(
                          children: [
                            Expanded(
                              flex: 4,
                              child:  Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                // crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 5,wheight/30),
                                    // color: Colors.deepOrange,
                                    alignment: Alignment.bottomLeft,
                                    child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/27, color: Colors.white),),
                                  ),

                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, wwidth/16,0),
                                    alignment: Alignment.bottomCenter,
                                    child: Text(cost_lamp==0 ? "0.000" : cost_lamp.toStringAsFixed(3), style: TextStyle(fontSize: wheight/8, color: Colors.white)),

                                  ),

                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                      // Container(
                      //   // color: Colors.black12,
                      //   // alignment: Alignment.bottomCenter,
                      //   child:
                      //   Row(
                      //     children: [
                      //
                      //       Expanded(
                      //           flex: 2,
                      //           child: Container(
                      //             margin: EdgeInsets.fromLTRB(0, 0, 0,10),
                      //             // color: Colors.deepOrange,
                      //             alignment: Alignment.bottomRight,
                      //             child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/27, color: Colors.white),),
                      //           )
                      //       ),
                      //
                      //       Expanded(
                      //         flex: 5,
                      //         child: Container(
                      //           // color: Colors.green,
                      //           alignment: Alignment.bottomLeft,
                      //           // child: Countup(
                      //           //   begin: cost_lamp_prev.toDouble(),
                      //           //   end: cost_lamp,
                      //           //   suffix: "",
                      //           //   duration: Duration(seconds: 3),
                      //           //   style: TextStyle(
                      //           //       fontSize: wheight/8,
                      //           //       // fontFamily: "Lato",
                      //           //       color: Colors.white
                      //           //   ),
                      //           // )
                      //           child: Text(cost_lamp==0 ? "0.000" : cost_lamp.toStringAsFixed(3), style: TextStyle(fontSize: wheight/8, color: Colors.white)),
                      //         ),
                      //
                      //       ),
                      //
                      //       Expanded(
                      //         flex: 1,
                      //         child: Container(
                      //           child: Text("" ),
                      //         ),
                      //       ),
                      //
                      //     ],
                      //   ),
                      // ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Container(
                          // color: Colors.black45,
                          alignment: Alignment.topCenter,
                          child: Text("التكلفة الشهرية", style: TextStyle(fontSize: wheight/20, color: Colors.white),),
                        )
                    ),

                  ],
                ),
              )
          ),
        ],
      ),
    );
  }

  Widget LED(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Container(
      child: Column(
        children: [
          Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                alignment: Alignment.bottomCenter,
                // color: Colors.indigoAccent,
                child: Image.asset("assets/logo.png"),
              )
          ),

          Expanded(
              flex: 4,
              child: Container(
                alignment: Alignment.bottomCenter,
                // color: Colors.indigoAccent,
                child: Text("LED", style: TextStyle(fontSize: wheight/6, color: Colors.white),),
              )
          ),
          Expanded(
              flex: 5,
              child: Container(
                // color: Colors.blueGrey,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                          child: Countup(
                            begin: watt_led_prev.toDouble(),
                            end: watt_led.toDouble(),
                            suffix: " W",
                            duration: Duration(seconds:3),
                            style: TextStyle(
                                fontSize: wheight/8,
                                // fontFamily: "Lato",
                                color: Colors.white
                            ),
                          )
                      ),
                      Center(
                        child: Text("الاستهلاك اللحظي", style: TextStyle(fontSize: wheight/25, color: Colors.white),),
                      ),
                    ],
                  )


              )
          ),
          Expanded(
              flex: 4,
              child: Container(
                // color: Colors.blue,
                child:
                // Stack(
                //   children: [
                //     Positioned(
                //       top: 0,
                //       left: 0,
                //       right: 0,
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         // crossAxisAlignment: CrossAxisAlignment.stretch,
                //         children: [
                //
                //           Container(
                //             margin: EdgeInsets.fromLTRB(0, 0, 5,0),
                //             // color: Colors.deepOrange,
                //             alignment: Alignment.bottomLeft,
                //             child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/27, color: Colors.white),),
                //           ),
                //
                //           Container(
                //             margin: EdgeInsets.fromLTRB(0, 0, wwidth/16,0),
                //             alignment: Alignment.bottomCenter,
                //             child: Text(cost_led==0 ? "0.000" : cost_led.toStringAsFixed(3), style: TextStyle(fontSize: wheight/8, color: Colors.white)),
                //
                //           ),
                //
                //         ],
                //       ),
                //     ),
                //
                //     Positioned(
                //       top: 0,
                //       left: wwidth/16,
                //       child: Directionality(
                //         textDirection: TextDirection.rtl,
                //         child: Text("50 مصباح" , style: TextStyle(fontSize: wheight/36, color: Colors.white,),),
                //       ),
                //     ),
                //
                //     Positioned(
                //       bottom: 10,
                //       right: 0,
                //       left: 0,
                //       child:  Container(
                //         // color: Colors.black45,
                //         alignment: Alignment.topCenter,
                //         child: Text("التكلفة الشهرية", style: TextStyle(fontSize: wheight/20, color: Colors.white),),
                //       ),
                //     )
                //
                //   ],
                // ),

                Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
                        // color: Colors.black12,
                        // alignment: Alignment.bottomCenter,
                        child:
                        // Row(
                        //   children: [
                        //
                        //     Expanded(
                        //         flex: 2,
                        //         child: Container(
                        //           margin: EdgeInsets.fromLTRB(0, 0, 0,10),
                        //           // color: Colors.deepOrange,
                        //           alignment: Alignment.bottomRight,
                        //           child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/27, color: Colors.white),),
                        //         )
                        //     ),
                        //
                        //     Expanded(
                        //       flex: 5,
                        //       child: Container(
                        //         // color: Colors.green,
                        //         alignment: Alignment.bottomLeft,
                        //         // child: Countup(
                        //         //   begin: cost_lamp_prev.toDouble(),
                        //         //   end: cost_lamp,
                        //         //   suffix: "",
                        //         //   duration: Duration(seconds: 3),
                        //         //   style: TextStyle(
                        //         //       fontSize: wheight/8,
                        //         //       // fontFamily: "Lato",
                        //         //       color: Colors.white
                        //         //   ),
                        //         // )
                        //         child: Text(cost_led==0 ? "0.000" : cost_led.toStringAsFixed(3), style: TextStyle(fontSize: wheight/8, color: Colors.white)),
                        //       ),
                        //
                        //     ),
                        //
                        //     Expanded(
                        //       flex: 1,
                        //       child: Container(
                        //         child: Text("" ),
                        //       ),
                        //     ),
                        //
                        //   ],
                        // ),

                        Center(
                          child: Column(
                            children: [
                              Expanded(
                                flex: 4,
                                child:  Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [

                                    Container(
                                        margin: EdgeInsets.fromLTRB(0, 0, 5,wheight/30),
                                        // color: Colors.deepOrange,
                                        alignment: Alignment.bottomLeft,
                                        child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/27, color: Colors.white),),
                                    ),

                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, wwidth/16,0),
                                      alignment: Alignment.bottomCenter,
                                      child: Text(cost_led==0 ? "0.000" : cost_led.toStringAsFixed(3), style: TextStyle(fontSize: wheight/8, color: Colors.white)),

                                    ),

                                  ],
                                ),
                              ),

                            ],
                          ),
                        ),


                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child:
                        Container(
                          // color: Colors.black45,
                          alignment: Alignment.topCenter,
                          child: Text("التكلفة الشهرية", style: TextStyle(fontSize: wheight/20, color: Colors.white),),
                        )

                    ),

                  ],
                ),
              )
          ),
        ],
      ),
    );
  }

  Widget Body(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Container(
      // color: Colors.indigoAccent,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Container(
                    color: lamp_bg_color,
                    child: LAMP(context),
                  )
              ),
              Expanded(
                  flex: 1,
                  child: Container(
                    color: led_bg_color,
                    child: LED(context),
                  )
              )
            ],
          ),
          Container(
            alignment: Alignment.center,
            child: Column(
              children: [

                Expanded(
                  flex: 4,
                  child: Container()
                ),

                Expanded(
                  flex: 5,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, wheight/17, 0, 0),
                    child: Image.asset("assets/vs.png"),
                  )
                ),

                Expanded(
                  flex: 4,
                  child: Container()
                ),

              ],
            )
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(""),
      // ),
      body: Container(
        // color: Colors.blueGrey,
        child: Body(context),
      )

    );
  }
}
