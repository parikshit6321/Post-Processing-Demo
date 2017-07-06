using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Bloom : MonoBehaviour {

    public Shader shader;
    public float threshold = 0.0f;
    private Material material;

    public enum Setting
    {
        Low,
        Medium,
        High
    }

    public Setting setting = Setting.High;

    // Use this for initialization
    void Awake()
    {
        if (shader != null)
            material = new Material(shader);
    }

    // Use this for processing the image texture
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // High Quality
        if(setting == Setting.High)
        {
            material.SetFloat("Threshold", threshold);

            RenderTextureFormat format;

            if(GetComponent<Camera>().hdr)
            {
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf))
                {
                    format = RenderTextureFormat.ARGBHalf;
                }
                else
                {
                    format = RenderTextureFormat.DefaultHDR;
                }
            }
            else
            {
                format = RenderTextureFormat.Default;
            }

            RenderTexture smallerTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);
            RenderTexture smallerTex8 = RenderTexture.GetTemporary(source.width / 8, source.height / 8, 0, format);
            RenderTexture smallerTex16 = RenderTexture.GetTemporary(source.width / 16, source.height / 16, 0, format);

            RenderTexture HBlurredTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);
            RenderTexture HVBlurredTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);

            RenderTexture HBlurredTex8 = RenderTexture.GetTemporary(source.width / 8, source.height / 8, 0, format);
            RenderTexture HVBlurredTex8 = RenderTexture.GetTemporary(source.width / 8, source.height / 8, 0, format);

            RenderTexture HBlurredTex16 = RenderTexture.GetTemporary(source.width / 16, source.height / 16, 0, format);
            RenderTexture HVBlurredTex16 = RenderTexture.GetTemporary(source.width / 16, source.height / 16, 0, format);

            // For the 1/4th Texture
            // Render the bright pass texture
            Graphics.Blit(source, smallerTex4, material, 0);

            // Blur the bright pass texture
            // Horizontal Blur Pass
            Graphics.Blit(smallerTex4, HBlurredTex4, material, 1);

            // Vertical Blur Pass
            Graphics.Blit(HBlurredTex4, HVBlurredTex4, material, 2);

            // For the 1/8th Texture
            // Render the bright pass texture
            Graphics.Blit(source, smallerTex8, material, 0);

            // Blur the bright pass texture
            // Horizontal Blur Pass
            Graphics.Blit(smallerTex8, HBlurredTex8, material, 1);

            // Vertical Blur Pass
            Graphics.Blit(HBlurredTex8, HVBlurredTex8, material, 2);

            // For the 1/16th Texture
            // Render the bright pass texture
            Graphics.Blit(source, smallerTex16, material, 0);

            // Blur the bright pass texture
            // Horizontal Blur Pass
            Graphics.Blit(smallerTex4, HBlurredTex16, material, 1);

            // Vertical Blur Pass
            Graphics.Blit(HBlurredTex4, HVBlurredTex16, material, 2);

            // Blend the original and blurred textures
            material.SetTexture("BlurredTexture4", HVBlurredTex4);
            material.SetTexture("BlurredTexture8", HVBlurredTex8);
            material.SetTexture("BlurredTexture16", HVBlurredTex16);

            Graphics.Blit(source, destination, material, 3);    // High Quality Blend Pass

            RenderTexture.ReleaseTemporary(smallerTex4);
            RenderTexture.ReleaseTemporary(smallerTex8);
            RenderTexture.ReleaseTemporary(smallerTex16);

            RenderTexture.ReleaseTemporary(HBlurredTex4);
            RenderTexture.ReleaseTemporary(HBlurredTex8);
            RenderTexture.ReleaseTemporary(HBlurredTex16);

            RenderTexture.ReleaseTemporary(HVBlurredTex4);
            RenderTexture.ReleaseTemporary(HVBlurredTex8);
            RenderTexture.ReleaseTemporary(HVBlurredTex16);
        }
        // Medium Quality
        else if(setting == Setting.Medium)
        {
            material.SetFloat("Threshold", threshold);

            RenderTextureFormat format;

            if (GetComponent<Camera>().hdr)
            {
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf))
                {
                    format = RenderTextureFormat.ARGBHalf;
                }
                else
                {
                    format = RenderTextureFormat.DefaultHDR;
                }
            }
            else
            {
                format = RenderTextureFormat.Default;
            }

            RenderTexture smallerTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);
            RenderTexture smallerTex8 = RenderTexture.GetTemporary(source.width / 8, source.height / 8, 0, format);
            
            RenderTexture HBlurredTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);
            RenderTexture HVBlurredTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);

            RenderTexture HBlurredTex8 = RenderTexture.GetTemporary(source.width / 8, source.height / 8, 0, format);
            RenderTexture HVBlurredTex8 = RenderTexture.GetTemporary(source.width / 8, source.height / 8, 0, format);
            
            // For the 1/4th Texture
            // Render the bright pass texture
            Graphics.Blit(source, smallerTex4, material, 0);

            // Blur the bright pass texture
            // Horizontal Blur Pass
            Graphics.Blit(smallerTex4, HBlurredTex4, material, 1);

            // Vertical Blur Pass
            Graphics.Blit(HBlurredTex4, HVBlurredTex4, material, 2);

            // For the 1/8th Texture
            // Render the bright pass texture
            Graphics.Blit(source, smallerTex8, material, 0);

            // Blur the bright pass texture
            // Horizontal Blur Pass
            Graphics.Blit(smallerTex8, HBlurredTex8, material, 1);

            // Vertical Blur Pass
            Graphics.Blit(HBlurredTex8, HVBlurredTex8, material, 2);
            
            // Blend the original and blurred textures
            material.SetTexture("BlurredTexture4", HVBlurredTex4);
            material.SetTexture("BlurredTexture8", HVBlurredTex8);
            
            Graphics.Blit(source, destination, material, 4);    // Medium Quality Blend Pass

            RenderTexture.ReleaseTemporary(smallerTex4);
            RenderTexture.ReleaseTemporary(smallerTex8);
            
            RenderTexture.ReleaseTemporary(HBlurredTex4);
            RenderTexture.ReleaseTemporary(HBlurredTex8);
            
            RenderTexture.ReleaseTemporary(HVBlurredTex4);
            RenderTexture.ReleaseTemporary(HVBlurredTex8);
        }
        // Low Quality
        else
        {
            material.SetFloat("Threshold", threshold);

            RenderTextureFormat format;

            if (GetComponent<Camera>().hdr)
            {
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf))
                {
                    format = RenderTextureFormat.ARGBHalf;
                }
                else
                {
                    format = RenderTextureFormat.DefaultHDR;
                }
            }
            else
            {
                format = RenderTextureFormat.Default;
            }

            RenderTexture smallerTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);
            
            RenderTexture HBlurredTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);
            RenderTexture HVBlurredTex4 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, format);
            
            // For the 1/4th Texture
            // Render the bright pass texture
            Graphics.Blit(source, smallerTex4, material, 0);

            // Blur the bright pass texture
            // Horizontal Blur Pass
            Graphics.Blit(smallerTex4, HBlurredTex4, material, 1);

            // Vertical Blur Pass
            Graphics.Blit(HBlurredTex4, HVBlurredTex4, material, 2);
            
            // Blend the original and blurred textures
            material.SetTexture("BlurredTexture4", HVBlurredTex4);
            
            Graphics.Blit(source, destination, material, 5);    // Low Quality Blend Pass

            RenderTexture.ReleaseTemporary(smallerTex4);

            RenderTexture.ReleaseTemporary(HBlurredTex4);

            RenderTexture.ReleaseTemporary(HVBlurredTex4);
        }
    }
}