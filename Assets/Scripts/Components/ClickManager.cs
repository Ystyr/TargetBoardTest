using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class ClickManager : MonoBehaviour
{

    [SerializeField]
    [HideInInspector]
    BoxCollider trigger;

    [SerializeField]
    float scaleFactor = 3;

    [SerializeField]
    [HideInInspector]
    Material material;

    float[] scores;


    private void OnValidate()
    {
        if (! trigger)
            trigger = gameObject.AddComponent<BoxCollider>();
        
        if (! material) {
            var rend = GetComponent<MeshRenderer>();
            material = rend.sharedMaterial;
        }
        material.SetFloat("_ScaleFactor", scaleFactor);
    }

    private void Start() {
        scores = new float[5] {
            0, 0, 0, 0, 0
        };
    }

    private void CountHitScore(Vector2 point)
    {
        var idx = GetHitShapeIdx(point);
        var value = (++scores[idx] % 10);
        scores[idx] = value;
    }

    private void OnMouseDown()
    {
        if(Input.GetMouseButtonDown(0)) {
            var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(ray, out var hit, 100)) {
                var hitPos = new Vector2(hit.point.x, hit.point.y) * -scaleFactor;
                CountHitScore(hitPos);
                material.SetVector("_TestHitPos", hitPos);
                material.SetFloatArray("_Scores", scores);
            }
        }
    }

    private int GetHitShapeIdx(Vector2 point)
    {
        int layersNum = 5;
        float g = Mathf.Max(0f, -SdHexagram(point, .8f) * layersNum);
        int ri = Mathf.FloorToInt(layersNum - g);
        return ri;
    }

    private float SdHexagram(Vector2 p, float r)
    {
        var k = new Vector4(
            -0.5f, 0.86602540378f,
            0.57735026919f, 1.73205080757f
            );
        var k_xy = new Vector2(k.x, k.y);
        var k_yx = new Vector2(k.y, k.x);
        p = Vec2Abs(p);
        p -= 2f * Mathf.Min(Vector2.Dot(k_xy, p), 0f) * k_xy;
        p -= 2f * Mathf.Min(Vector2.Dot(k_yx, p), 0f) * k_yx;
        p -= new Vector2(Mathf.Clamp(p.x, r * k.z, r * k.w), r);
        return (p).magnitude * Mathf.Sign(p.y);
    }

    private Vector2 Vec2Abs (Vector2 val){
        return new Vector2(
            Mathf.Abs(val.x), Mathf.Abs(val.y)
            );
    }
}
