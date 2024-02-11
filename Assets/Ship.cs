using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Ship : MonoBehaviour
{
    private Material mat;
    private HandManager hm;
    public Weapon weapon;

    void Start()
    {
        mat = GetComponent<MeshRenderer>().material;
        hm = FindAnyObjectByType<HandManager>();
    }


    void Update()
    {
        if(hm.lHandTracking && hm.rHandTracking)
        {
            transform.SetPositionAndRotation(hm.handsCenter.position, hm.handsCenter.rotation);
        }
    }
}
