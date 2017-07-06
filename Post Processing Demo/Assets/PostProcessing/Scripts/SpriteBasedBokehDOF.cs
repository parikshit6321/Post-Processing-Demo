using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class SpriteBasedBokehDOF : MonoBehaviour {

    public Shader shader = null;

    public enum Quality
    {
        LOW,            // 7x7 blur kernel
        MEDIUM,         // 13x13 blur kernel
        HIGH,           // 25x25 blur kernel
        ULTRA_HIGH      // 49x49 blur kernel
    }

    public Quality quality = Quality.HIGH;
    
    public Texture sprite = null;
    public int downsample = 1;
    public float bokehRadius = 0.25f;
    public float bokehIntensity = 15.0f;
    public float luminanceThreshold = 0.5f;
    public float bokehThreshold = 0.8f;

    public GameObject objectInFocus = null;

    private float focusDistance = 5.0f;
    private Vector3 focusPosition = Vector3.one;
    private Material material = null;

	// Use this for initialization
	void Awake () {

        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;

        if (shader != null)
            material = new Material(shader);

	}
	
	// Update is called once per frame
	void OnRenderImage (RenderTexture source, RenderTexture destination) {

        // Get the render texture for holding the blurred scene
        RenderTexture blurred = RenderTexture.GetTemporary(source.width /downsample, source.height / downsample);

        // Calculate Depth far cutoff from the game objects world space position
        focusPosition = objectInFocus.transform.position;
        Vector4 tempVector = Vector4.one;
        tempVector.Set(focusPosition.x, focusPosition.y, focusPosition.z, 1);
        Vector4 focusPositionView = GetComponent<Camera>().worldToCameraMatrix * tempVector;
        focusDistance = -focusPositionView.z;

        if (quality == Quality.LOW)
            focusDistance += 5.0f;

        // Set the appropriate shader properties
        material.SetTexture("_Sprite", sprite);
        material.SetFloat("_BokehRadius", bokehRadius);
        material.SetFloat("_BokehIntensity", bokehIntensity);
        material.SetFloat("_LuminanceThreshold", luminanceThreshold);
        material.SetFloat("_BokehThreshold", bokehThreshold);
        material.SetFloat("_FocusDistance", focusDistance);

        if(quality == Quality.LOW)
        {
            material.EnableKeyword("LOW_BOKEH");
            material.DisableKeyword("MEDIUM_BOKEH");
            material.DisableKeyword("HIGH_BOKEH");
            material.DisableKeyword("ULTRA_HIGH_BOKEH");
        }
        else if(quality == Quality.MEDIUM)
        {
            material.DisableKeyword("LOW_BOKEH");
            material.EnableKeyword("MEDIUM_BOKEH");
            material.DisableKeyword("HIGH_BOKEH");
            material.DisableKeyword("ULTRA_HIGH_BOKEH");
        }
        else if (quality == Quality.HIGH)
        {
            material.DisableKeyword("LOW_BOKEH");
            material.DisableKeyword("MEDIUM_BOKEH");
            material.EnableKeyword("HIGH_BOKEH");
            material.DisableKeyword("ULTRA_HIGH_BOKEH");
        }
        else if(quality == Quality.ULTRA_HIGH)
        {
            material.DisableKeyword("LOW_BOKEH");
            material.DisableKeyword("MEDIUM_BOKEH");
            material.DisableKeyword("HIGH_BOKEH");
            material.EnableKeyword("ULTRA_HIGH_BOKEH");
        }
        
        // Blur the texture using the sprite based blur pass
        Graphics.Blit(source, blurred, material, 0);

        // Pass the blurred texture to the blending pass
        material.SetTexture("_Blurred", blurred);

        // Blend the two textures
        Graphics.Blit(source, destination, material, 1);

        // Release the blurred render texture
        RenderTexture.ReleaseTemporary(blurred);

	}
}