using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderPipe : MonoBehaviour
{
    public Material mat;

    void Update()
    {
        float unityTime = Time.time;
        mat.SetFloat("_t",unityTime);
    }
}
