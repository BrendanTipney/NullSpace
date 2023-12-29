using System;
using System.Collections;
using System.Collections.Generic;
using OVR.OpenVR;
using UnityEngine;
using UnityEngine.UI;

public class ShaderPipe : MonoBehaviour
{
    public Material mat;
    public Transform lHand;
    public Transform rHand;

    public Vector3 handOffset;

    public Text debug;

    private String debugLog;

    void Update()
    {
        float unityTime = Time.time;
        mat.SetFloat("_t",unityTime);
        mat.SetVector("_cp1", lHand.position-handOffset);
        mat.SetVector("_cp1", lHand.rotation.eulerAngles);
        
        debugLog = "Pos = " + lHand.position.ToString() + "\r";
        debugLog += "Rot = " + lHand.rotation.eulerAngles.ToString();

        debug.text = debugLog;
    }
}
