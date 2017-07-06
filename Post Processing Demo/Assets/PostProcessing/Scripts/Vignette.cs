using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Vignette : MonoBehaviour
{

    public Texture vignetteTexture;
    public Shader shader;
    private Material material;

    // Use this for initialization
    void Awake()
    {
        if (shader != null)
            material = new Material(shader);
    }

    // Use this for processing the image texture
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        material.SetTexture("VignetteTexture", vignetteTexture);
        Graphics.Blit(source, destination, material);
    }

}