using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class GodRays : MonoBehaviour {

    public Shader shader = null;
    private Material material = null;

    public float weight = 1.0f;
    public float decay = 1.0f;
    public float exposure = 1.0f;
    public float numOfSamples = 32.0f;
    
    public int downSample = 4;

    public Vector2 sunScreenPosition = new Vector2(0.0f, 0.5f);

	// Use this for initialization
	void Awake () {
	
        if(shader != null)
        {
            material = new Material(shader);
        }

        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
	}
	
	// This is called once per frame
	void OnRenderImage (RenderTexture source, RenderTexture destination) {

        material.SetFloat("Weight", weight);
        material.SetFloat("Decay", decay);
        material.SetFloat("Exposure", exposure);
        material.SetFloat("NumOfSamples", numOfSamples);

        material.SetVector("SunScreenPos", sunScreenPosition);
        
        RenderTexture maskedTexture = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);
        RenderTexture godRaysTexture = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);
        RenderTexture HBlurredTexture = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);
        RenderTexture HVBlurredTexture = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);

        // Perform masking pass
        Graphics.Blit(source, maskedTexture, material, 0);

        // Perform god rays pass
        Graphics.Blit(maskedTexture, godRaysTexture, material, 1);

        // Blur the obtained god rays texture
        // Horizonatal Blur Pass
        Graphics.Blit(godRaysTexture, HBlurredTexture, material, 2);
        // Vertical Blur Pass
        Graphics.Blit(HBlurredTexture, HVBlurredTexture, material, 3);

        // Blend the two textures together
        material.SetTexture("GodTexture", HVBlurredTexture);

        Graphics.Blit(source, destination, material, 4);

        RenderTexture.ReleaseTemporary(maskedTexture);
        RenderTexture.ReleaseTemporary(godRaysTexture);
        RenderTexture.ReleaseTemporary(HBlurredTexture);
        RenderTexture.ReleaseTemporary(HVBlurredTexture);

    }
}
