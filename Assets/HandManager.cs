using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class HandManager : MonoBehaviour
{
    public OVRHand lHand;
    public OVRHand rHand;
    private Transform lHandLast;
    private Transform rHandLast;
    public Vector3 handPosRelativeSmoothed;
    float handDist = 0;
    public float smoothing = 0.5f;
    [HideInInspector]
    public Transform lhandTrans;
    [HideInInspector]
    public Transform rhandTrans;
    [HideInInspector]
    public Transform handsCenter;
    public bool lHandTracking = false;
    public bool rHandTracking = false;
    void Start()
    {
        lHandLast = transform;
        rHandLast = transform;
    }

    // Update is called once per frame
    void Update()
    {
        if(lHand.IsDataHighConfidence)
        {
            lhandTrans.position = Vector3.Lerp(lHandLast.position, lHand.transform.position, smoothing);
            lhandTrans.eulerAngles += DetectRotation(lHand.transform, lHandLast);
            lHandLast = lHand.transform;
            lHandTracking = true;
        } else {
            lHandTracking = false;
        }

        if(rHand.IsDataHighConfidence)
        {
            rhandTrans.position = Vector3.Lerp(rHandLast.position, rHand.transform.position, smoothing);
            rhandTrans.eulerAngles += DetectRotation(rHand.transform, rHandLast);
            rHandLast = rHand.transform;
            rHandTracking = true;
        } else {
            rHandTracking = false;
        }

        if(lHand.IsDataHighConfidence & rHand.IsDataHighConfidence)
        {
            Vector3 handPosRelative = rHand.transform.position-lHand.transform.position;
            Vector3 handPosRelativeLast = rHandLast.position-lHandLast.position;
            handPosRelativeSmoothed = Vector3.Lerp(handPosRelativeLast, handPosRelative, smoothing);

            handDist =  Vector3.Distance(lHand.transform.position, rHand.transform.position);

            handsCenter.position = lhandTrans.position + handPosRelative * 0.5f;
            handsCenter.rotation = Quaternion.Inverse(rHand.transform.rotation) * lHand.transform.rotation;
        }
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
}
