using System;
using System.Collections;
using System.Collections.Generic;
using Meta.WitAi.Speech;
using Oculus.Interaction;
using OVR.OpenVR;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;
using Oculus.Interaction.Input;

public class ShaderPipe : MonoBehaviour
{
    public Material mat;
    public OVRHand lHand;
    private Transform lHandLast;
    public OVRHand rHand;
    private Transform rHandLast;
    public Vector3 handOffset;
    private Vector3 lHandRotation;
    private Vector3 rHandRotation;
    private float rotationThreshold = 30;
    Vector3 lHandRotationLast = Vector3.zero;
    Vector3 rHandRotationLast = Vector3.zero;
    public float smoothing = 0.1f;
    public Text debug;
    private String debugLog;
    public GameObject controlCube;
    private Transform cubeOffset;

    public GameObject HandDebug;

    void Start()
    {
        cubeOffset = controlCube.transform;
        lHandLast = this.transform;
        rHandLast = this.transform;
    }


    void Update()
    {
        //float unityTime = Time.time;
        //mat.SetFloat("_t",unityTime);

        //HandControl
        if(lHand.IsDataHighConfidence)
        {

            mat.SetVector("_lhp", Vector3.Lerp(lHandLast.position-handOffset, lHand.transform.position-handOffset, smoothing));
            lHandRotation += DetectRotation(lHand.transform, lHandLast);
            mat.SetVector("_lhr", Vector3.Lerp(lHandRotationLast, lHandRotation, smoothing)*(math.PI/180));
            lHandRotationLast = lHandRotation;
            lHandLast = lHand.transform;
        }

        if(rHand.IsDataHighConfidence)
        {
            mat.SetVector("_rhp", Vector3.Lerp(rHandLast.position-handOffset, rHand.transform.position-handOffset, smoothing));
            rHandRotation += DetectRotation(rHand.transform, rHandLast);
            mat.SetVector("_rhr", Vector3.Lerp(rHandRotationLast,rHandRotation, smoothing)*(math.PI/180));

            rHandLast = rHand.transform;
        } 

        if(lHand.IsDataHighConfidence & rHand.IsDataHighConfidence)
        {
            Vector3 handPosRelative = rHand.transform.position-lHand.transform.position;
            Vector3 handPosRelativeLast = rHandLast.position-lHandLast.position;
            //Vector3 handPosDiff =  math.abs(handPosRelative-handPosRelativeLast);

            mat.SetVector("_handPosDiff", Vector3.Lerp(handPosRelativeLast,handPosRelative,smoothing));
        }

        //ObjectControl
        mat.SetVector("_CubeControlTransform", controlCube.transform.position-cubeOffset.position);
        mat.SetVector("_CubeControlRotation", controlCube.transform.rotation.eulerAngles-cubeOffset.rotation.eulerAngles);

        //debugLog += "DiffMag = " + handPosDiff.magnitude.ToString() + "\n";
        //debugLog += "lHandMag = " + lHand.transform.position.magnitude.ToString()+ "\n";
        //debugLog = "Pos = " + lHand.position.ToString() + "\n";
        //debugLog += "DiffMag = " + handPosDiff.magnitude.ToString() + "\n"
        if (lHandRotation != null)
        {
            debugLog += "lHandRotation = " + lHandRotation.ToString()+ "\n";
        }


        Vector3 DetectRotation(Transform  trans, Transform lastTrans)
        {
            float rotXDiff = trans.rotation.eulerAngles.x - lastTrans.rotation.eulerAngles.x;
            if (rotXDiff > 180)
            {
                rotXDiff -= 360;
            } else if (rotXDiff < -180)
            {
                rotXDiff += 360;
            }

            float rotYDiff = trans.rotation.eulerAngles.y - lastTrans.rotation.eulerAngles.y;
            if (rotYDiff > 180)
            {
                rotYDiff -= 360;
            } else if (rotYDiff < -180)
            {
                rotYDiff += 360;
            }

            float rotZDiff = trans.rotation.eulerAngles.z - lastTrans.rotation.eulerAngles.z;
            if (rotZDiff > 180)
            {
                rotXDiff -= 360;
            } else if (rotZDiff < -180)
            {
                rotZDiff += 360;
            }
            return new Vector3(rotXDiff,rotYDiff,rotZDiff);
        }
        

        debug.text = debugLog;
        debugLog = "";
    }
}
