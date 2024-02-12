using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Weapon : MonoBehaviour
{
    public float fireRate = 1;
    private float lastShot = 0;
    public Bullet bullet;
    public float speed = 100;

    public Vector3 aim = Vector3.zero;

    void Update()
    {
        if(Time.timeSinceLevelLoad - lastShot > fireRate)
        {
            lastShot = Time.timeSinceLevelLoad;
            Vector3 direction = GetTarget().transform.position - transform.position;
            Fire(direction);
        }
    }

    public void Fire(Vector3 direction)
    {
        Bullet shotBullet = Instantiate(bullet,transform.position,transform.rotation);
        shotBullet.gameObject.layer = LayerMask.NameToLayer("Player");
        shotBullet.GetComponent<SphereCollider>().excludeLayers = LayerMask.NameToLayer("Player");
        Rigidbody rb = shotBullet.GetComponent<Rigidbody>();
        rb.excludeLayers = LayerMask.NameToLayer("Player");//I think these are not being set correctly;
        Debug.Log(rb.excludeLayers.ToString());
        rb.AddForce(direction.normalized*speed*Time.deltaTime);
    }

    Enemy GetTarget()
    {
        Enemy[] enemies = FindObjectsByType<Enemy>(sortMode: FindObjectsSortMode.None);
        float distFromAim;
        float closetDist = 9999;
        Enemy closetEnemy = null;
        
        foreach (Enemy enemy in enemies)
        {
            distFromAim = Vector3.Distance(enemy.transform.position, transform.position+aim);
            if (distFromAim < closetDist)
            {
                closetEnemy = enemy;
                closetDist = distFromAim;
            }
        }
        
        return closetEnemy;
    }
}
