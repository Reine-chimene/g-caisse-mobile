import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatelessWidget {
  final String callID; // L'identifiant du salon (lié à la tontine)
  final String userID; // L'ID unique du membre
  final String userName; // Le nom du membre

  const CallScreen({
    super.key, 
    required this.callID, 
    required this.userID, 
    required this.userName
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        // 👇 1. REMPLACE CECI PAR TON APP ID (Juste les chiffres, SANS guillemets)
        appID: 123456789, 
        
        // 👇 2. REMPLACE CECI PAR TON APP SIGN (Garde bien les guillemets "" autour)
        appSign: "colle_ton_long_code_app_sign_ici", 
        
        userID: userID,
        userName: userName,
        callID: callID,
        
        // Configuration magique pour un appel de groupe (Parfait pour la tontine)
        config: ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
          ..turnOnCameraWhenJoining = false // On lance en vocal d'abord
          ..turnOnMicrophoneWhenJoining = false, // Le micro est coupé en entrant par politesse
      ),
    );
  }
}