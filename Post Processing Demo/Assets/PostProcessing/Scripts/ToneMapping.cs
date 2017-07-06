using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class ToneMapping : MonoBehaviour {

    public float exposure = 1.0f;
    public float gamma = 2.2f;

    public enum ToneMappingMethod
    {
        Reinhard,
        Filmic,
        Uncharted
    }

    public ToneMappingMethod toneMappingMethod = ToneMappingMethod.Reinhard;

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
        if(GetComponent<Camera>().hdr && (source.format == RenderTextureFormat.ARGBHalf || source.format == RenderTextureFormat.ARGBFloat || source.format == RenderTextureFormat.DefaultHDR))
        {
            material.SetFloat("Exposure", exposure);
            material.SetFloat("Gamma", gamma);

            if(toneMappingMethod == ToneMappingMethod.Reinhard)
            {
                material.EnableKeyword("REINHARD");
                material.DisableKeyword("FILMIC");
                material.DisableKeyword("UNCHARTED");
            }
            else if(toneMappingMethod == ToneMappingMethod.Filmic)
            {
                material.EnableKeyword("FILMIC");
                material.DisableKeyword("REINHARD");
                material.DisableKeyword("UNCHARTED");
            }
            else
            {
                material.EnableKeyword("UNCHARTED");
                material.DisableKeyword("REINHARD");
                material.DisableKeyword("FILMIC");
            }

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
        
    }
}
