using System;
using System.Collections;
using System.Collections.Generic;
using Meta.WitAi.Speech;
using OVR.OpenVR;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

public class ShaderPipe : MonoBehaviour
{
    public Material mat;
    public Transform lHand;
    private Transform lHandLast;
    private Transform lHandSmoothed;
    public Transform rHand;
    private Transform rHandLast;
    public Vector3 handOffset;
    private Vector3 velocity;
    private float smoothTime = 1f;
    public Text debug;
    private String debugLog;
    public GameObject controlCube;
    private Transform cubeOffset;

    void Start()
    {
        lHandLast = lHand;
        rHandLast = rHand;
        lHandSmoothed = lHand;

        cubeOffset = controlCube.transform;
    }


    void Update()
    {
        float unityTime = Time.time;
        mat.SetFloat("_t",unityTime);

        if(lHand.position.magnitude != 0)
        {
            //HandControl
            mat.SetVector("_lhp", Vector3.Lerp(lHand.position-handOffset, lHandLast.position-handOffset, 0.5f));

            mat.SetVector("_lhr", Vector3.Lerp(lHand.rotation.eulerAngles, lHandLast.rotation.eulerAngles, 0.5f)*(math.PI/180));
            lHandSmoothed.rotation = quaternion.Euler(Vector3.SmoothDamp(lHandSmoothed.rotation.eulerAngles, lHand.rotation.eulerAngles, ref velocity, smoothTime));
            //mat.SetVector("_lhr", lHandSmoothed.rotation.eulerAngles*(math.PI/180));

            Vector3 handPosRelative = rHand.position-lHand.position;
            Vector3 handPosRelativeLast = rHandLast.position-lHandLast.position;
            Vector3 handPosDiff =  math.abs(handPosRelative-handPosRelativeLast);
            //mat.SetVector("_handPosDiff", Vector3.Lerp(handPosRelative,handPosRelativeLast,0.5f));
            lHandSmoothed.position = Vector3.SmoothDamp(lHandSmoothed.position, handPosRelative, ref velocity, smoothTime);
            mat.SetVector("_handPosDiff", lHandSmoothed.position);

            lHandLast = lHand;
            rHandLast = rHand;
        }
        //ObjectControl
        mat.SetVector("_CubeControlTransform", controlCube.transform.position-cubeOffset.position);
        mat.SetVector("_CubeControlRotation", controlCube.transform.rotation.eulerAngles-cubeOffset.rotation.eulerAngles);

        //debugLog = "DiffMag = " + handPosDiff.magnitude.ToString() + "\r";
        debugLog = "lHandMag = " + lHand.position.magnitude.ToString()+ "\r";
        //debugLog = "Pos = " + lHand.position.ToString() + "\r";
        //debugLog += "DiffMag = " + handPosDiff.magnitude.ToString() + "\r";
        Vector3 rot = Vector3.Lerp(lHand.rotation.eulerAngles, lHandLast.rotation.eulerAngles, 0.5f)*(math.PI/180);
        debugLog += "Rot = " + rot.ToString() + "\r";

        debug.text = debugLog;
    }
}
