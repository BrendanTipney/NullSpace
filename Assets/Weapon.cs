using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Weapon : MonoBehaviour
{
    public float fireRate = 3;
    private float lastShot = 0;
    public Bullet bullet;
    public float speed = 1;

    void Update()
    {
        Debug.Log(Time.timeSinceLevelLoad - lastShot);
        if(Time.timeSinceLevelLoad - lastShot > fireRate)
        {
            lastShot = Time.timeSinceLevelLoad;
            Fire();
        }
    }

    public void Fire()
    {
        Bullet shotBullet = Instantiate(bullet,transform.position + transform.forward,transform.rotation);
        shotBullet.transform.position += transform.parent.forward;
        shotBullet.GetComponent<Rigidbody>().AddForce(transform.forward*speed);
    }
}
