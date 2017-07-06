using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class CustomLensFlare : MonoBehaviour {

    public Shader shader = null;
    private Material material = null;

    public Texture lensFlare = null;
    public Texture lensBlur = null;
    public Texture lensDirt = null;

    public Color lensFlareColor = Color.red;
    public float lensDirtIntensity = 0.3f;
    public float effectStrength = 0.3f;
     
	// Use this for initialization
	void Awake () {

        if (shader != null)
            material = new Material(shader);
   	}
	
	// Use this to add image effect
	void OnRenderImage (RenderTexture source, RenderTexture destination) {

        material.SetTexture("_LensFlare", lensFlare);
        material.SetTexture("_LensBlur", lensBlur);
        material.SetTexture("_LensDirt", lensDirt);
        material.SetColor("_LensFlareColor", lensFlareColor);
        material.SetFloat("_LensDirtIntensity", lensDirtIntensity);
        material.SetFloat("EffectStrength", effectStrength);

        Graphics.Blit(source, destination, material);
	}
}
