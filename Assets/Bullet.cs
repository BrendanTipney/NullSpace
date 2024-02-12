using System.Collections;
using System.Collections.Generic;
using Meta.WitAi;
using Unity.VisualScripting;
using UnityEngine;

public class Bullet : MonoBehaviour
{
    private float damage = 1;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void OnCollisionEnter(Collision collision)
    {
        if(collision.collider.gameObject.GetComponent<Enemy>())
        {
            Enemy enemy = collision.collider.gameObject.GetComponent<Enemy>();
            enemy.health -= damage;
            if(enemy.health <= 0)
            {
                Destroy(enemy.gameObject);
            }
        }
    }
}
