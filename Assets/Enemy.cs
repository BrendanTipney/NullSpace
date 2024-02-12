using System.Collections;
using System.Collections.Generic;
using UnityEditor.Rendering;
using UnityEngine;

public class Enemy : MonoBehaviour
{
    public float health = 1;
    private Ship ship;
    public float speed = 1;
    private float damage = 1;
    private Rigidbody rb;
    // Start is called before the first frame update
    void Start()
    {
        ship = FindAnyObjectByType<Ship>();
        rb = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 direction = ship.transform.position-transform.position;
        transform.Translate(direction.normalized*speed*Time.deltaTime);
    }

    void OnCollisionEnter(Collision collision)
    {
        if(collision.collider.GetComponent<Ship>())
        {
            ship = collision.collider.GetComponent<Ship>();
            ship.health -= damage;
            if(ship.health <= 0)
            {
                Destroy(ship);
            }
        }
    }
}
