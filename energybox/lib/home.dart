// import 'dart:html';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:math' as math;
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
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter/services.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<App> {

  // constant values
  int hours_day = 12;
  int leds_num  = 3;
  int lamps_num  = 1;
  int total_lamps = 0;
  int total_leds = 0;

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

  UsbPort? port;
  var ports = [];
  bool isOpened = true;
  UsbDevice? device;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Serial_init();
    //
    // // while(!isOpened) Serial_init();
    // Timer.periodic(Duration(seconds: 8), (timer) {
    //   Serial_init();
    // });

    Timer.periodic(Duration(seconds: 12), (timer) {
      setState(() {
        watt_lamp_prev = watt_lamp;
        watt_led_prev = watt_led;
        cost_lamp_prev = cost_lamp;
        cost_led_prev = cost_led;
      });

         setState((){
           watt_lamp += 60;
           watt_led += 9;

           if (watt_lamp>120) watt_lamp = 0;
           if (watt_led>18) watt_led = 0;
         });

         KWH_calculation();

      });
  }


  void encodeData(String data) {

    setState(() {
      watt_lamp_prev = watt_lamp;
      watt_led_prev = watt_led;
      cost_lamp_prev = cost_lamp;
      cost_led_prev = cost_led;
    });

    if (data.contains("#")) {
      data = data.replaceAll("#", "");
    }

    if (data.contains("lamp") || data.contains("led")) {
      final json = jsonDecode(data);

      setState(() {
        if (data.contains("lamp")) watt_lamp = json["lamp"];
        if (data.contains("led"))  watt_led = json["led"];
        data = "";
        KWH_calculation();
      });
    }

  }

  void Serial_init() async {

    List<UsbDevice> devices = await UsbSerial.listDevices();
    print(devices);

    if (devices.length == 0) {
      isOpened = false;
      return;
    }

    device = null;
    devices.forEach((element) { 
      if ( element.toString().contains("arduino") || element.toString().contains("Arduino") ) {
        device = element;
      }
    });

    if (device==null) {
      isOpened = false;
      return;
    }

    if (!isOpened)  {
      port = await device!.create();
      isOpened = await port!.open();
    }
    else return;


    if ( !isOpened ) {
      print("Failed to open");
      return;
    }

    await port!.setDTR(true);
    await port!.setRTS(true);

    port!.setPortParameters(115200, UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    port!.inputStream!.listen((Uint8List event) {
      print(event);
      String data = String.fromCharCodes(event);

      encodeData(data);
      // port!.close();
    });
    
  }

  void KWH_calculation() {

    if (watt_lamp>100) {
      lamps_num = 2;
      setState((){ total_lamps = 50; });
    } else if (watt_lamp>40) {
      lamps_num = 1;
      setState((){ total_lamps = 25; });
    } else {
      lamps_num = 1;
      setState((){ total_lamps = 0; });
    }

    if (watt_led>14) {
      leds_num = 2;
      setState((){ total_leds = 50; });
    } else if (watt_led>4) {
      leds_num = 1;
      setState((){ total_leds = 25; });
    }
    else {
      leds_num = 1;
      setState((){ total_leds = 0; });
    }

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
    if(kwh<=4000) {
      unit_cost = 0.014;
    } else if(kwh<=6000) {
      unit_cost = 0.017;
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
              flex: 1,
              child: Container()
          ),
          Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                // color: Colors.indigoAccent,
                child: Text("LAMP", style: TextStyle(fontSize: wheight/14, color: Colors.white, fontFamily: "Somar"),),
              )
          ),
          Expanded(
              flex: 3,
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
                                fontSize: wheight/12,
                                // fontFamily: "Lato",
                                color: Colors.white,
                                fontFamily: "Somar"
                            ),
                          )
                      ),
                      Center(
                        child: Text("الاستهلاك اللحظي", style: TextStyle(fontSize: wheight/24, color: Colors.white, fontFamily: "Somar"),),
                      ),
                    ],
                  )


              )
          ),
          Expanded(
              flex: 3,
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
                                    // margin: EdgeInsets.fromLTRB(0, 0, 5,wheight/30),
                                    // color: Colors.deepOrange,
                                    alignment: Alignment.centerLeft,
                                    child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/24, color: Colors.white, fontFamily: "Somar"),),
                                  ),

                                  Container(
                                    // margin: EdgeInsets.fromLTRB(0, 0, wwidth/16,0),
                                    alignment: Alignment.center,
                                    child: Text(cost_lamp==0 ? "0.000" : cost_lamp.toStringAsFixed(3), style: TextStyle(fontSize: wheight/12, color: Colors.white, fontFamily: "Somar")),

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
                          alignment: Alignment.topCenter,
                          child: Text("التكلفة الشهرية | ${total_lamps} مصباح", style: TextStyle(fontSize: wheight/26, color: Colors.white, fontFamily: "Somar"),),
                        )
                    ),

                  ],
                ),
              )
          ),
          Expanded(
            flex: 2,
              child: Container()
          )
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
              flex: 1,
              child: Container()
          ),
          Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.bottomCenter,
                // color: Colors.indigoAccent,
                child: Text("LED", style: TextStyle(fontSize: wheight/14, color: Colors.white, fontFamily: "Somar"),),
              )
          ),
          Expanded(
              flex: 3,
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
                            duration: Duration(seconds: 3),
                            style: TextStyle(
                                fontSize: wheight/12,
                                // fontFamily: "Lato",
                                color: Colors.white
                                , fontFamily: "Somar"
                            ),
                          )
                      ),
                      Center(
                        child: Text("الاستهلاك اللحظي", style: TextStyle(fontSize: wheight/24, color: Colors.white, fontFamily: "Somar"),),
                      ),
                    ],
                  )


              )
          ),
          Expanded(
              flex: 3,
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
                                    // margin: EdgeInsets.fromLTRB(0, 0, 5,wheight/30),
                                    // color: Colors.deepOrange,
                                    alignment: Alignment.centerLeft,
                                    child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/24, color: Colors.white, fontFamily: "Somar"),),
                                  ),

                                  Container(
                                    // margin: EdgeInsets.fromLTRB(0, 0, wwidth/16,0),
                                    alignment: Alignment.center,
                                    child: Text(cost_led==0 ? "0.000" : cost_led.toStringAsFixed(3), style: TextStyle(fontSize: wheight/12, color: Colors.white, fontFamily: "Somar")),

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
                          alignment: Alignment.topCenter,
                          child: Text("التكلفة الشهرية | ${total_leds} مصباح", style: TextStyle(fontSize: wheight/26, color: Colors.white, fontFamily: "Somar"),),
                        )
                    ),

                  ],
                ),
              )
          ),
          Expanded(
              flex: 2,
              child: Container()
          )
        ],
      ),
    );
  }

  Widget LED_(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Container(
      child: Column(
        children: [

          Expanded(
              flex: 1,
              child: Container()
          ),

          Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                // color: Colors.indigoAccent,
                child: Text("LED", style: TextStyle(fontSize: wheight/18, color: Colors.white),),
              )
          ),
          Expanded(
              flex: 4,
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
                            duration: Duration(seconds: 3),
                            style: TextStyle(
                                fontSize: wheight/18,
                                // fontFamily: "Lato",
                                color: Colors.white
                            ),
                          )
                      ),
                      Center(
                        child: Text("الاستهلاك اللحظي", style: TextStyle(fontSize: wheight/30, color: Colors.white),),
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
                                    // margin: EdgeInsets.fromLTRB(0, 0, 5,wheight/30),
                                    // color: Colors.deepOrange,
                                    alignment: Alignment.centerLeft,
                                    child: Text("ريال عماني " , style: TextStyle(fontSize: wheight/30, color: Colors.white),),
                                  ),

                                  Container(
                                    // margin: EdgeInsets.fromLTRB(0, 0, wwidth/16,0),
                                    alignment: Alignment.center,
                                    child: Text(cost_led==0 ? "0.000" : cost_led.toStringAsFixed(3), style: TextStyle(fontSize: wheight/18, color: Colors.white)),
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
                          child: Text("التكلفة الشهرية | ${total_leds} مصباح", style: TextStyle(fontSize: wheight/30, color: Colors.white, fontFamily: "Somar"),),
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

  Widget Header(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Container(
      color: lamp_bg_color,
      child: Column(
        children: [
          Expanded(
              flex: 2,
              child: Transform.rotate(
                angle: - math.pi / 2,
                child: Container(
                  // padding: EdgeInsets.all(wwidth/20),
                  // margin: EdgeInsets.fromLTRB(0, 0, wwidth/20, 0),
                  child: Image.asset("assets/logo.png"),
                ),
              )
          ),

          Expanded(
            flex: 1,
              child: Transform.rotate(
                angle: - math.pi/2,
                child: Container(
                  // child: Icon( (port!=null) ? (isOpened ? Icons.usb_rounded : Icons.usb_off_rounded) : Icons.usb_off_rounded, color: Colors.white,
                  //     size: wheight/15),
                  child: Icon( Icons.usb_rounded, color: Colors.white,
                      size: wheight/15),
                ),
              )
          ),

        ],
      ),
    );
  }

  Widget Content(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
                flex: 1,
                child: Container(
                  color: lamp_bg_color,
                  child: Transform.rotate(
                    angle: - math.pi/2,
                    child: LAMP(context),
                  )
                )
            ),
            Expanded(
                flex: 1,
                child: Container(
                  color: led_bg_color,
                  padding: EdgeInsets.fromLTRB(wwidth/10, 0, 0, 0),
                  child: Transform.rotate(
                    angle: - math.pi/2,
                    child: LED(context),
                  )
                )
            )
          ],
        ),
        Container(
            alignment: Alignment.center,
            child: Column(
              children: [

                Expanded(
                    flex: 6,
                    child: Container()
                ),

                Expanded(
                    flex: 2,
                    child: Transform.rotate(
                      angle: - math.pi/2,
                      child: Container(
                        // margin: EdgeInsets.fromLTRB(0, wheight/17, 0, 0),
                        child: Image.asset("assets/vs.png"),
                      ),
                    ),

                ),

                Expanded(
                    flex: 6,
                    child: Container()
                ),

              ],
            )
        )
      ],
    );
  }

  Widget Body_(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Container(
        child: Column(
          children: [
            Expanded(
                flex: 1,
                child: Header(context)
            ),

            Expanded(
                flex: 8,
                child: Content(context)
            ),

          ],
        )
    );
  }

  Widget Body(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Container(
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Header(context)
            ),

            Expanded(
                flex: 9,
                child: Content(context),
            ),

          ],
        )
    );

    // Transform.scale(
    //   scaleY: sc,
    //   child: Transform.rotate(
    //     angle: - math.pi / 2,
    //     child: Container(
    //         child: Column(
    //           children: [
    //             Expanded(
    //                 flex: 1,
    //                 child: Header(context)
    //             ),
    //
    //             Expanded(
    //                 flex: 8,
    //                 child: Content(context)
    //             ),
    //
    //           ],
    //         )
    //     ),
    //   ),
    // );
  }


  @override
  Widget build(BuildContext context) {

    double wwidth  = MediaQuery.of(context).size.width;
    double wheight = MediaQuery.of(context).size.height;

    return Scaffold(

        body: Container(
          child: Body(context),
        )

    );
  }
}
