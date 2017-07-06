using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class BokehDOF : MonoBehaviour {

    [Header("Game Object in focus")]
    public GameObject objectInFocus = null;
    private Vector3 focusPosition = Vector3.one;

    [Header("Thickness of area in focus")]
    public float depthOfFieldThickness = 20.0f;
    private float depthNearCutOff = 1.0f;
    private float depthFarCutOff = 1.0f;

    [Header("Default Depth Far Cut Off when object is null")]
    public float defaultDepthCutOff = 500.0f;

    [Header("Tweak this to get accurate focus on game object")]
    public float depthOffset = 10.0f;
    
    [Header("To control the blurring")]
    public int downSample = 1;
    public int blurIterations = 1;
    public int blurStep = 1;
    
    public enum BokehType
    {
        Hexagonal,
        Disc
    }

    [Header("Type of Bokeh : Hexagonal is faster than Disc")]
    public BokehType bokehType = BokehType.Hexagonal;

    public enum ColorBleedingFix
    {
        ON,
        OFF
    }

    [Header("Tweak these to fix color bleeding edge artifacts")]
    public ColorBleedingFix colorBleedingFix = ColorBleedingFix.OFF;
    public float depthThreshold = 10.0f;

    [Header("Shader")]
    public Shader shader = null;
    private Material material = null;

    // Use this for initialization
    void Awake ()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;

        if (shader != null)
            material = new Material(shader);

	}
	
	// Use this to add image effects
	void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        if (objectInFocus != null)
        {
            // Calculate Depth far cutoff from the game objects world space position
            focusPosition = objectInFocus.transform.position;
            Vector4 tempVector = Vector4.one;
            tempVector.Set(focusPosition.x, focusPosition.y, focusPosition.z, 1);
            Vector4 focusPositionView = GetComponent<Camera>().worldToCameraMatrix * tempVector;
            depthFarCutOff = -focusPositionView.z + depthOffset;
        }
        else
        {
            // Set depth far cut off to its default value when no game object is in focus
            depthFarCutOff = defaultDepthCutOff;
        }

        // Calculate Depth near cut off value
        depthNearCutOff = depthFarCutOff - depthOfFieldThickness;
        depthNearCutOff = (depthNearCutOff > 0.0f) ? depthNearCutOff : 0.0f;

        // Ensure blur step is greater than or equal to 1
        blurStep = (blurStep <= 0) ? 1 : blurStep;
        
        material.SetFloat("BlurStep", blurStep);

        // Check for color bleeding fix setting
        if(colorBleedingFix == ColorBleedingFix.ON)
        {
            material.EnableKeyword("COLOR_BLEEDING_FIX_ON");
            material.DisableKeyword("COLOR_BLEEDING_FIX_OFF");
            material.SetFloat("DepthThreshold", depthThreshold);
        }
        else
        {
            material.EnableKeyword("COLOR_BLEEDING_FIX_OFF");
            material.DisableKeyword("COLOR_BLEEDING_FIX_ON");
        }

        // Hexagonal Bokeh
        if (bokehType == BokehType.Hexagonal)
        {
            material.EnableKeyword("HEXAGONAL");
            material.DisableKeyword("DISC");

            RenderTexture BlurredTex0 = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);
            RenderTexture BlurredTex1 = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);
            RenderTexture BlurredTex2 = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);

            Graphics.Blit(source, BlurredTex0);

            for (int i = 0; i < blurIterations; ++i)
            {
                Graphics.Blit(BlurredTex0, BlurredTex1, material, 1);
                Graphics.Blit(BlurredTex1, BlurredTex2, material, 2);
                Graphics.Blit(BlurredTex2, BlurredTex0, material, 3);
            }

            material.SetTexture("BlurredTex", BlurredTex0);
            material.SetFloat("DepthNearCutOff", depthNearCutOff);
            material.SetFloat("DepthFarCutOff", depthFarCutOff);

            Graphics.Blit(source, destination, material, 0);

            RenderTexture.ReleaseTemporary(BlurredTex0);
            RenderTexture.ReleaseTemporary(BlurredTex1);
            RenderTexture.ReleaseTemporary(BlurredTex2);
        }
        // Circular Bokeh
        else
        {
            material.EnableKeyword("DISC");
            material.DisableKeyword("HEXAGONAL");

            RenderTexture blurredTex = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);
            RenderTexture temp = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample);

            Graphics.Blit(source, blurredTex);

            for (int i = 0; i < blurIterations; ++i)
            {
                Graphics.Blit(blurredTex, temp, material, 4);
                Graphics.Blit(temp, blurredTex);
            }

            material.SetTexture("BlurredTex", blurredTex);
            material.SetFloat("DepthNearCutOff", depthNearCutOff);
            material.SetFloat("DepthFarCutOff", depthFarCutOff);

            Graphics.Blit(source, destination, material, 0);

            RenderTexture.ReleaseTemporary(blurredTex);
            RenderTexture.ReleaseTemporary(temp);
        }
    }
}