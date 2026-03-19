import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatelessWidget {
  final String callID;
  final String userID;
  final String userName;

  const CallScreen({
    super.key, 
    required this.callID, 
    required this.userID, 
    required this.userName
  });

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      // 👇 Remplace avec tes vrais identifiants console.zego.im
      appID: 123456789, 
      appSign: "ton_app_sign_ici", 
      userID: userID,
      userName: userName,
      callID: callID,
      
      // Configuration visuelle
      config: ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
        ..turnOnCameraWhenJoining = false 
        ..turnOnMicrophoneWhenJoining = true,

      // ✅ LA CORRECTION : Utilisation de l'objet 'events'
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (ZegoCallEndEvent event, defaultAction) {
          Navigator.pop(context);
          return defaultAction();
        },
      ),
    );
  }
}